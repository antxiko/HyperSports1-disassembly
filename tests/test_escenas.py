#!/usr/bin/env python3
"""Las escenas de las pruebas, y lo que se afirma de ellas.

Estos si necesitan el cartucho: sin `hypersports1.rom` en la raiz se saltan
solos, porque el repositorio no lo distribuye. Lo que vigilan es que las cinco
imagenes de las pruebas sigan saliendo de la ROM y cuadrando byte a byte con la
VRAM del MSX, y que las cifras publicadas en la web sean las medidas.

Cada guardian trae ademas su propia comprobacion de que SIRVE: se falsea el dato
y se comprueba que el test lo caza. Un test que pasa con el dato falseado no
vigila nada.
"""
import os
import sys
import unittest

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(RAIZ, "tools"))

ROM = os.path.join(RAIZ, "hypersports1.rom")
NOTES = os.path.join(RAIZ, "src", "hypersports1.notes")
VRAM = os.path.join(RAIZ, "src", "vram")
IMAGENES = os.path.join(RAIZ, "docs", "imagenes")
ORG = 0x4000

def rom():
    """El cartucho no se distribuye: sin el, estos tests se saltan, como en el
    resto de la serie."""
    if not os.path.exists(ROM):
        raise unittest.SkipTest("hace falta hypersports1.rom en la raiz")
    with open(ROM, "rb") as f:
        return f.read()


class Escenas(unittest.TestCase):
    """Lo que se dibuja desde la ROM tiene que ser lo que el MSX tiene en la
    VRAM. Si no, la lectura del binario esta mal."""

    def setUp(self):
        import escenas
        self.e = escenas
        self.cart = escenas.Cartucho(rom(), ORG)

    def indice(self):
        return list(self.e.escenas(os.path.join(VRAM, "escenas.txt")))

    def test_hay_cinco_escenas_y_sus_volcados(self):
        idx = self.indice()
        self.assertEqual(len(idx), 5)
        for fichero, _ev, imagen, _t, _tit in idx:
            ruta = os.path.join(VRAM, fichero)
            self.assertTrue(os.path.exists(ruta), ruta)
            self.assertEqual(os.path.getsize(ruta), 0x4000,
                             "%s no son 16384 bytes de VRAM" % fichero)
            png = os.path.join(IMAGENES, imagen)
            self.assertTrue(os.path.exists(png), "falta la imagen %s" % png)
            # una pantalla entera comprimida no baja de 1 KB; un PNG negro si
            self.assertGreater(os.path.getsize(png), 1500,
                               "%s pesa muy poco: puede estar en negro" % imagen)

    def test_la_rom_cuadra_con_la_vram_byte_a_byte(self):
        for fichero, ev, _imagen, _t, _tit in self.indice():
            with open(os.path.join(VRAM, fichero), "rb") as f:
                volcado = f.read()
            mia, escritas = self.e.vram_desde_la_rom(self.cart, NOTES, ev)
            _fases, malos = self.e.coteja(self.cart, NOTES, mia, escritas, volcado)
            self.assertEqual(malos, [], "%s: %d bytes no cuadran" %
                             (fichero, len(malos)))
            self.assertGreater(len(escritas), 5000,
                               "%s: se cotejaron muy pocos bytes" % fichero)

    def test_el_cotejo_caza_un_byte_cambiado(self):
        """El guardian de arriba solo vale si un byte distinto lo tumba."""
        fichero, ev = self.indice()[0][0], self.indice()[0][1]
        with open(os.path.join(VRAM, fichero), "rb") as f:
            volcado = bytearray(f.read())
        mia, escritas = self.e.vram_desde_la_rom(self.cart, NOTES, ev)
        picado = min(a for a in escritas if 0x2000 <= a < 0x2800)
        volcado[picado] ^= 0xFF
        _fases, malos = self.e.coteja(self.cart, NOTES, mia, escritas,
                                      bytes(volcado))
        self.assertIn(picado, malos)

    def test_el_publico_tiene_dos_fases_y_solo_dos(self):
        """La unica diferencia admitida entre la ROM y la VRAM es el publico
        aplaudiendo, y son exactamente dos guiones seguidos en el cartucho."""
        a_ini, a_fin = self.e.rango_por_nombre(NOTES, "publico_a")
        b_ini, b_fin = self.e.rango_por_nombre(NOTES, "publico_b")
        self.assertEqual(a_fin, b_ini, "publico_b no va detras de publico_a")
        sitio = self.e.sitio_del_publico(self.cart, NOTES)
        self.assertEqual(len(sitio), 24, "el publico no ocupa tres casillas")
        va, vb = bytearray(0x4000), bytearray(0x4000)
        destino = min(sitio)
        self.cart.descomprime(a_ini, destino, va)
        self.cart.descomprime(b_ini, destino, vb)
        self.assertNotEqual(bytes(va), bytes(vb),
                            "las dos fases del publico son iguales")

    def test_alguna_escena_pillo_cada_fase(self):
        fases = set()
        for fichero, ev, _i, _t, _tit in self.indice():
            with open(os.path.join(VRAM, fichero), "rb") as f:
                volcado = f.read()
            mia, escritas = self.e.vram_desde_la_rom(self.cart, NOTES, ev)
            f2, _m = self.e.coteja(self.cart, NOTES, mia, escritas, volcado)
            fases.update(f2.split())
        self.assertEqual(fases, {"A", "B"},
                         "los volcados no cubren las dos fases del publico")


class FuenteDelMarcador(unittest.TestCase):
    """La fuente del marcador NO esta en el cartucho: 0x43BF la copia de la ROM
    del MSX (CGTBL, 0x0004) y el cartucho solo retoca seis caracteres."""

    def setUp(self):
        import escenas
        self.e = escenas
        self.cart = escenas.Cartucho(rom(), ORG)
        with open(os.path.join(VRAM, "fuente_bios.bin"), "rb") as f:
            self.bios = f.read()
        with open(os.path.join(VRAM, "escena_0.vram"), "rb") as f:
            self.vram = f.read()

    def test_la_fuente_de_la_bios_son_48_caracteres(self):
        self.assertEqual(len(self.bios), 0x180)

    def monta(self):
        """Lo que hace 0x43BF: la fuente de la BIOS a 0x2180 y 0x2600 en los tres
        tercios, y encima los tres retoques comprimidos del cartucho."""
        v = bytearray(0x4000)
        for dest in (0x2180, 0x2600):
            for tercio in range(3):
                w = (dest + 0x800 * tercio) & 0x3FFF
                v[w:w + 0x180] = self.bios
        for src, dest in ((0x452A, 0x21D0), (0x453A, 0x2760), (0x453A, 0x22E0)):
            for tercio in range(3):
                self.cart.descomprime(src, (dest + 0x800 * tercio) & 0x3FFF, v)
        return v

    def test_bios_mas_retoques_dan_la_fuente_de_la_vram(self):
        v = self.monta()
        for base in (0x2000, 0x2800, 0x3000):
            a, z = base + 0x30 * 8, base + 0x60 * 8
            distintos = [i for i in range(a, z) if v[i] != self.vram[i]]
            self.assertEqual(distintos, [],
                             "la fuente del tercio 0x%04X no cuadra" % base)

    def test_sin_los_retoques_NO_cuadra(self):
        """Los seis caracteres que el cartucho pisa son de verdad suyos: sin
        ellos la fuente de la BIOS sola ya no da la VRAM."""
        v = bytearray(0x4000)
        for tercio in range(3):
            w = (0x2180 + 0x800 * tercio) & 0x3FFF
            v[w:w + 0x180] = self.bios
        malos = [i for i in range(0x2180, 0x2300) if v[i] != self.vram[i]]
        self.assertEqual(sorted(set((i - 0x2000) // 8 for i in malos)),
                         [0x3A, 0x3B, 0x5C, 0x5D, 0x5E, 0x5F],
                         "los caracteres retocados no son los seis esperados")


class OrdenDeLasPruebas(unittest.TestCase):
    """El orden de las cuatro pruebas lo fija la TABLA de 0x6F00, no el orden en
    que los textos estan guardados. Leyendo los textos salen la segunda y la
    tercera cambiadas."""

    def setUp(self):
        import escenas
        self.e = escenas
        self.cart = escenas.Cartucho(rom(), ORG)

    def texto(self, p):
        """El rotulo de un guion: dos bytes de destino y luego los caracteres
        hasta el 0xFF, con el 0x00 haciendo de espacio."""
        p += 2
        fuera = []
        while True:
            x = self.cart.b(p)
            if x == 0xFF:
                return "".join(fuera).strip()
            fuera.append(" " if x == 0 else chr(x))
            p += 1

    def test_la_tabla_da_el_orden_bueno(self):
        ini, fin = self.e.rango_por_nombre(NOTES, "tabla_rotulos_prueba")
        self.assertEqual(fin - ini, 8, "la tabla no son cuatro punteros")
        leidos = [self.texto(self.cart.w16(ini + 2 * i)) for i in range(4)]
        self.assertEqual(leidos, self.e.PRUEBAS)

    def test_el_orden_de_los_textos_es_OTRO(self):
        """Si algun dia coincidieran, este test avisa de que la advertencia del
        .notes ya no hace falta."""
        ini, _fin = self.e.rango_por_nombre(NOTES, "rotulos_prueba")
        seguidos, p = [], ini
        for _ in range(4):
            seguidos.append(self.texto(p))
            while self.cart.b(p) != 0xFF:
                p += 1
            p += 1
        self.assertEqual(seguidos, ["DIVING", "TRAMPOLINE", "LONG HORSE",
                                    "HORIZONTAL BAR"])
        self.assertNotEqual(seguidos, self.e.PRUEBAS)


class PosturasDelAtleta(unittest.TestCase):
    """Los 3425 bytes de fotogramas se trocean en 52 tiras. Lo que demuestra que
    el formato esta bien leido no es que las tiras encajen -eso sale igual
    empezando en cualquier byte-, sino que el PAPEL de cada byte coincida con el
    que el MSX le da de verdad, separado por el PC que lo lee."""

    def setUp(self):
        import posturas
        self.p = posturas
        self.rom = rom()
        self.medida = os.path.join(VRAM, "posturas_medidas.txt")

    def test_el_bloque_se_trocea_en_52_tiras(self):
        ini, fin = self.p.rango_por_nombre(NOTES, "posturas_atleta")
        self.assertEqual(fin - ini, 3425)
        cols = self.p.columnas(self.rom, ORG, ini, fin)
        self.assertEqual(len(cols), 52)
        self.assertEqual(sum(c[2] for c in cols), 5312)

    def test_encajar_al_final_NO_prueba_el_formato(self):
        """Se publico como si lo probara y no lo prueba: con el arranque movido
        uno o dos bytes las tiras siguen acabando donde acaba el bloque. Este
        test deja constancia, para que a nadie le tiente volver a usarlo."""
        ini, fin = self.p.rango_por_nombre(NOTES, "posturas_atleta")
        encajan = sum(1 for salto in range(1, 12)
                      if self.p.columnas(self.rom, ORG, ini + salto, fin)[-1][1] == fin)
        self.assertGreater(encajan, 5,
                           "si ya no encajaran movidas, el argumento valdria")

    def test_el_papel_de_cada_byte_es_el_que_lee_el_msx(self):
        ini, fin = self.p.rango_por_nombre(NOTES, "posturas_atleta")
        cab, _por_prueba, medido = self.p.lee_medida(self.medida)
        self.assertGreater(int(cab["control_0x0038"]), 10000,
                           "el control de interrupciones dice que la medida no vale")
        mio = self.p.papeles(self.rom, ORG, ini, fin)
        distintos = [a for a, vistos in medido.items()
                     if len(vistos) != 1 or mio.get(a) not in vistos]
        self.assertEqual(distintos, [], "%d bytes con papel distinto" %
                         len(distintos))
        self.assertEqual(len(medido), 2912)

    def test_ese_cotejo_caza_un_formato_mal_leido(self):
        """Si el bit alto se leyera al reves -como en el descompresor de 0x440D,
        que es justo la confusion facil-, el reparto de papeles se descuadraria
        casi entero."""
        ini, fin = self.p.rango_por_nombre(NOTES, "posturas_atleta")
        _cab, _pp, medido = self.p.lee_medida(self.medida)
        alreves = {}
        p, datos = ini, self.rom
        while p < fin:
            x = datos[p - ORG]
            alreves[p] = "cuenta"
            p += 1
            if x == 0:
                continue
            c = x & 0x7F
            if x == c:                       # al reves a proposito
                for i in range(c):
                    alreves[p + i] = "literal"
                p += c
            else:
                alreves[p] = "repetido"
                p += 1
        malos = [a for a, vistos in medido.items()
                 if len(vistos) != 1 or alreves.get(a) not in vistos]
        self.assertGreater(len(malos), 1000,
                           "leyendo el formato al reves tambien cuadra")

    def test_cada_prueba_usa_sus_tiras(self):
        ini, fin = self.p.rango_por_nombre(NOTES, "posturas_atleta")
        cols = self.p.columnas(self.rom, ORG, ini, fin)
        _cab, por_prueba, _m = self.p.lee_medida(self.medida)
        self.assertEqual(sorted(por_prueba), [0, 1, 2, 3])
        cuantas = {}
        for ev, vistas in por_prueba.items():
            cuantas[ev] = sum(1 for (a, z, _n) in cols
                              if any(a <= d < z for d in vistas))
        self.assertEqual(cuantas, {0: 20, 1: 30, 2: 13, 3: 30},
                         "las tiras por prueba no son las publicadas")


if __name__ == "__main__":
    unittest.main()


class GuionesDelEmulador(unittest.TestCase):
    """Los guiones de openMSX llegan copiados del proyecto anterior, y con ellos
    llegan las direcciones del juego anterior. Once de los catorce que habia en
    este repositorio hablaban de OTRO cartucho -uno decia que la prueba en curso
    esta en 0xE016 y la monta 0x4234, cuando aqui son 0xE052 y 0x4214-, y ademas
    escribian su salida en el directorio de otro proyecto. Este guardian exige
    que toda direccion citada en un .tcl exista de verdad en ESTE cartucho."""

    def direcciones_buenas(self):
        import re
        with open(os.path.join(RAIZ, "src", "hypersports1.asm"),
                  encoding="utf-8") as f:
            asm = f.read()
        with open(NOTES, encoding="utf-8") as f:
            notas = f.read()
        # toda direccion que el listado imprime al margen es inicio de instruccion
        buenas = set(int(m, 16) for m in re.findall(r";([0-9a-f]{4})\b", asm))
        # y todo lo que cae dentro de un bloque de datos con nombre
        for a, z in re.findall(r"^D\s+0x([0-9A-Fa-f]+)\s+0x([0-9A-Fa-f]+)",
                               notas, re.M):
            buenas.update(range(int(a, 16), int(z, 16) + 1))
        # la RAM de trabajo, tal como el listado la escribe: 0eNNNh
        ram = set(int(m, 16) for m in re.findall(r"0([0-9a-fA-F]{4})h", asm))
        return buenas, ram

    def test_ningun_tcl_nombra_direcciones_de_otro_cartucho(self):
        import glob
        import re
        buenas, ram = self.direcciones_buenas()
        malas = {}
        for ruta in sorted(glob.glob(os.path.join(RAIZ, "tools", "*.tcl"))):
            with open(ruta, encoding="utf-8", errors="ignore") as f:
                txt = f.read()
            fuera = set()
            for m in re.findall(r"0x([4-7][0-9A-Fa-f]{3})", txt):
                if int(m, 16) not in buenas:
                    fuera.add("0x" + m.upper())
            for m in re.findall(r"0x([Ee][0-9A-Fa-f]{3})", txt):
                if int(m, 16) not in ram:
                    fuera.add("0x" + m.upper())
            if fuera:
                malas[os.path.basename(ruta)] = sorted(fuera)
        self.assertEqual(malas, {}, "guiones con direcciones ajenas: %s" % malas)

    def test_ningun_tcl_apunta_a_otro_repositorio(self):
        import glob
        for ruta in sorted(glob.glob(os.path.join(RAIZ, "tools", "*.tcl"))):
            with open(ruta, encoding="utf-8", errors="ignore") as f:
                txt = f.read()
            for otro in ("TIMEPILOT_DISAM", "GOONIES_DISAM", "STARDUST_DISAM",
                         "MAHJONG_DISAM", "PINGPONG_DISAM"):
                self.assertNotIn(otro, txt,
                                 "%s escribe en el repositorio de otro juego"
                                 % os.path.basename(ruta))
