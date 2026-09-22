#!/usr/bin/env python3
"""El atleta que se dibuja desde la ROM tiene que ser el que el MSX tenia en la
VRAM, permuta de la piscina incluida.

Necesitan el cartucho: sin `hypersports1.rom` en la raiz se saltan. Lo que
vigilan salio del issue #2 de theNestruo: que las figuras de tools/figuras.py
coincidan PIXEL A PIXEL con el atleta de los volcados de openMSX, que en la
piscina los planos vayan permutados (0x63E8) y en las otras tres pruebas no, y
que la lista de poses de la piscina que figuras.py lleva escrita sea la que se
midio.

Cada guardian trae su comprobacion de que SIRVE: se falsea el dato y se mira
que el test lo caza.
"""
import hashlib
import os
import sys
import unittest


def huella(trozo):
    """El (ancho, alto, pixeles) de figuras.pinta resumido en un hash, para
    comparar dibujos sin volcar cien kilobytes de pixeles en cada fallo."""
    w, h, px = trozo
    return (w, h, hashlib.sha1(bytes(px)).hexdigest()[:12])

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(RAIZ, "tools"))

ROM = os.path.join(RAIZ, "hypersports1.rom")
NOTES = os.path.join(RAIZ, "src", "hypersports1.notes")
VRAM = os.path.join(RAIZ, "src", "vram")
ORG = 0x4000
PISCINA = 0                      # 0xE052 & 3 de la prueba DIVING
ROPA = {6, 15}                   # camiseta roja y botas blancas, en un orden u otro
CUERPO = (11, 11)                # torso y piernas, los dos amarillos


def colores(fichas):
    return tuple(f[3] & 0x0F for f in fichas)


def rom():
    if not os.path.exists(ROM):
        raise unittest.SkipTest("hace falta hypersports1.rom en la raiz")
    with open(ROM, "rb") as f:
        return f.read()


class Atleta(unittest.TestCase):

    def setUp(self):
        import escenas
        import figuras
        self.F = figuras
        self.rom = rom()
        self.escenas = []
        for fichero, ev, _imagen, _t, _tit in escenas.escenas(
                os.path.join(VRAM, "escenas.txt")):
            with open(os.path.join(VRAM, fichero), "rb") as f:
                v = bytearray(f.read())
            fichas = figuras.desde_la_vram(v)
            if fichas:
                self.escenas.append((fichero, int(ev), fichas, v))

    def desde_la_rom(self, fichas_vram, v, ev, permuta=None):
        """La misma pose dibujada desde la ROM, con la permuta de la piscina si
        la prueba es la piscina (o lo que diga `permuta`)."""
        F = self.F
        quien = F.que_pose_es(self.rom, ORG, v, len(fichas_vram))
        self.assertEqual(len(quien), 1, "los patrones del volcado casan con "
                         "%d poses, y tienen que casar con una" % len(quien))
        fichas, pv = F.una_postura(self.rom, ORG, quien[0])
        if permuta is None:
            permuta = ev == PISCINA
        if permuta:
            fichas = F.en_la_piscina(fichas)
        return quien[0], F.pinta(fichas, pv)

    def test_hay_volcados_con_atleta_y_uno_es_de_la_piscina(self):
        self.assertGreaterEqual(len(self.escenas), 4)
        self.assertIn(PISCINA, [ev for _f, ev, _fi, _v in self.escenas])

    def test_el_atleta_de_cada_volcado_es_el_de_la_rom_pixel_a_pixel(self):
        for fichero, ev, fichas, v in self.escenas:
            real = self.F.pinta(fichas, v)
            n, mio = self.desde_la_rom(fichas, v, ev)
            self.assertEqual(huella(mio), huella(real),
                             "%s: la pose %d dibujada desde la ROM no es la "
                             "del volcado" % (fichero, n))

    def test_el_cotejo_caza_la_permuta_al_reves(self):
        """Si el dibujo de la piscina SIN permuta tambien cuadrara, el test de
        arriba no vigilaria nada. Solo vale exigirlo en la piscina: en otras
        poses las fichas no se solapan y el orden no cambia un pixel."""
        for fichero, ev, fichas, v in self.escenas:
            if ev != PISCINA:
                continue
            real = self.F.pinta(fichas, v)
            _n, al_reves = self.desde_la_rom(fichas, v, ev, permuta=False)
            self.assertNotEqual(huella(al_reves), huella(real),
                                "%s: sin la permuta tambien cuadra, asi que "
                                "el cotejo no distingue" % fichero)
        # y en la pose de pie, la que ensena la lamina, las dos ropas difieren
        fichas, pv = self.F.una_postura(self.rom, ORG, self.F.POSE_EJEMPLO)
        self.assertNotEqual(huella(self.F.pinta(fichas, pv)),
                            huella(self.F.pinta(self.F.en_la_piscina(fichas), pv)))

    def test_la_pose_de_la_barra_lleva_la_raja_del_poste(self):
        """La pose 40 es la unica partida en dos: dos columnas transparentes
        por las que asoma el poste de la barra fija. En el volcado de la barra
        el poste negro cae justo en esas dos columnas de pantalla."""
        F = self.F
        con_raja = {n: F.la_raja_del_poste(*F.una_postura(self.rom, ORG, n))
                    for n in range(F.POSTURAS)}
        con_raja = {n: r for n, r in con_raja.items() if r}
        self.assertEqual(list(con_raja), [40])
        self.assertEqual(con_raja[40], [-10, -9])
        for _fichero, _ev, fichas, v in self.escenas:
            if 40 not in F.que_pose_es(self.rom, ORG, v, len(fichas)):
                continue
            dy, dx = F.una_postura(self.rom, ORG, 40)[0][0][:2]
            yb, xb = fichas[0][0] - dy, fichas[0][1] - dx
            for raja in con_raja[40]:
                for y in range(yb + 6, yb + 22):     # del remate a la base blanca
                    self.assertEqual(F.pixel_del_decorado(v, y, xb + raja),
                                     F.G.PALETA[1], "no hay poste negro en "
                                     "(%d, %d)" % (y, xb + raja))
            break
        else:
            self.fail("ningun volcado tiene puesta la pose 40")

    def test_la_piscina_lleva_los_planos_permutados(self):
        """En cada volcado, los colores de las fichas son los del guion de su
        pose -en la piscina, con las dos parejas cambiadas- y los patrones los
        que 0x6404 vuelve a clavar."""
        F = self.F
        for fichero, ev, fichas, v in self.escenas:
            n = F.que_pose_es(self.rom, ORG, v, len(fichas))[0]
            guion, _pv = F.una_postura(self.rom, ORG, n)
            patrones = tuple(p for _y, _x, p, _c in fichas[:4])
            if ev == PISCINA:
                self.assertEqual(colores(fichas), colores(F.en_la_piscina(guion)),
                                 fichero)
                self.assertEqual(patrones, (8, 12, 0, 4), fichero)
                self.assertEqual(colores(fichas)[:2], CUERPO,
                                 "%s: en la piscina los amarillos van delante" % fichero)
            else:
                self.assertEqual(colores(fichas), colores(guion), fichero)
                self.assertEqual(patrones, (0, 4, 8, 12), fichero)

    def test_toda_pose_tiene_cuatro_fichas_y_en_la_piscina_la_ropa_va_delante(self):
        """Cuatro fichas o mas en las 45 es lo que hace que la permuta de
        0x63E8 -ocho bytes fijos- nunca alcance el terminador 0xD0. El ORDEN de
        los colores lo elige cada guion (las poses 18-29 llevan los amarillos
        delante, las 41-44 empiezan por una ficha de color 0); lo que hace que
        la permuta desnude al atleta es que en las DIECIOCHO de la piscina la
        ropa -rojo y blanco- va en las dos primeras y el cuerpo -los dos
        amarillos- en las dos siguientes."""
        F = self.F
        for n in range(F.POSTURAS):
            fichas, _v = F.una_postura(self.rom, ORG, n)
            self.assertGreaterEqual(len(fichas), 4, "la pose %d tiene %d fichas"
                                    % (n, len(fichas)))
        for n in F.POSES_DE_LA_PISCINA:
            c = colores(F.una_postura(self.rom, ORG, n)[0])
            self.assertEqual(set(c[:2]), ROPA, "pose %d: %s" % (n, c))
            self.assertEqual(c[2:4], CUERPO, "pose %d: %s" % (n, c))

    def test_las_poses_de_la_piscina_son_las_medidas(self):
        """figuras.POSES_DE_LA_PISCINA esta escrita a mano; aqui se recalcula
        desde la medida de openMSX y tiene que dar lo mismo."""
        import posturas as P
        F = self.F
        medida = os.path.join(VRAM, "posturas_medidas.txt")
        if not os.path.exists(medida):
            self.skipTest("falta la medida de openMSX")
        ini, fin = P.rango_por_nombre(NOTES, "posturas_atleta")
        cols = P.columnas(self.rom, ORG, ini, fin)
        _cab, por_prueba, _papel = P.lee_medida(medida)
        leidas = {i for i, (a, z, _n) in enumerate(cols)
                  if any(a <= d < z for d in por_prueba[PISCINA])}
        donde = {a: i for i, (a, _z, _n) in enumerate(cols)}
        piscina = set()
        for n in range(F.POSTURAS):
            idx = [donde.get(b) for b in F.bloques_de(self.rom, ORG, n)]
            if idx and all(i is not None and i in leidas for i in idx):
                piscina.add(n)
        self.assertEqual(piscina, set(F.POSES_DE_LA_PISCINA))
        self.assertEqual(len(piscina), 18)


if __name__ == "__main__":
    unittest.main()
