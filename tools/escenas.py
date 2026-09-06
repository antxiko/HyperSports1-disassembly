#!/usr/bin/env python3
"""Dibuja las pantallas de las cuatro pruebas, con los dibujos sacados de la ROM.

Ni un pixel de estas imagenes es una captura: los patrones y los colores se
descomprimen aqui en Python ejecutando el mismo descompresor que el Z80 corre en
0x440D, y salen de los bytes del cartucho. Lo unico que se toma del emulador es
el MAPA DE CASILLAS (que tile va en cada sitio) y los sprites, porque no estan
en el cartucho: DIBUJA_MARCO (0x4816) sube los dibujos a la VRAM y es el motor
de cada prueba el que va componiendo la pantalla mientras corre.

Antes de dibujar nada se COTEJA: los patrones y los colores descomprimidos de la
ROM tienen que coincidir BYTE A BYTE con los del volcado. Si no coinciden, el
programa aborta. Ese cotejo es lo que demuestra que la lectura del binario es
correcta; si el rango o el formato estuvieran mal, no cuadraria un solo byte.

La unica diferencia que se admite es la del PUBLICO, que tiene dos fases -dos
guiones que se alternan sobre la misma VRAM para que las gradas aplaudan-, y el
volcado pilla una de las dos. El programa prueba las dos y dice cual era.

No se escribe ninguna direccion a mano: la tabla de marcos y los dos guiones del
publico se buscan por el NOMBRE de su bloque en las anotaciones (`D <ini> <fin>
<nombre>`), y los dos destinos comunes se sacan decodificando los `ld de,nn` y
`ld hl,nn` del propio codigo de DIBUJA_MARCO.

Uso: escenas.py <rom> <org> <notas> <dir_vram> <docs/imagenes>
"""
import os
import re
import struct
import sys
import zlib

# La paleta del TMS9918 tal como la miden las tablas al uso.
PALETA = [
    (0, 0, 0), (0, 0, 0), (62, 184, 73), (116, 208, 125),
    (89, 85, 224), (128, 118, 241), (185, 94, 81), (101, 219, 239),
    (219, 101, 89), (255, 137, 125), (204, 195, 94), (222, 208, 135),
    (58, 162, 65), (183, 102, 181), (204, 204, 204), (255, 255, 255),
]

# Donde vive cada tabla en la VRAM. Sale de los registros del VDP que el propio
# volcado trae apuntados (02 E2 0E 7F 07 76 03 E1): R2=0x0E pone los nombres en
# 0x3800, R4 los patrones en 0x2000, R3 los colores en 0x0000, R5 los atributos
# de sprite en 0x3B00 y R6 sus patrones en 0x1800. R1=0xE2 dice que los sprites
# son de 16x16 y SIN ampliar.
NOMBRES, PATRONES, COLORES = 0x3800, 0x2000, 0x0000
SPR_ATR, SPR_PAT = 0x3B00, 0x1800


def png(w, h, px, fn):
    raw = b"".join(b"\0" + bytes(px[y * w * 3:(y + 1) * w * 3]) for y in range(h))

    def chunk(t, d):
        return (struct.pack(">I", len(d)) + t + d
                + struct.pack(">I", zlib.crc32(t + d) & 0xFFFFFFFF))
    with open(fn, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n"
                + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0))
                + chunk(b"IDAT", zlib.compress(raw)) + chunk(b"IEND", b""))


def rango_por_nombre(notas, nombre):
    with open(notas, encoding="utf-8") as f:
        for linea in f:
            m = re.match(r"^D\s+0x([0-9A-Fa-f]+)\s+0x([0-9A-Fa-f]+)\s+(\S+)",
                         linea)
            if m and m.group(3) == nombre:
                return int(m.group(1), 16), int(m.group(2), 16)
    raise SystemExit("  no hay ningun bloque llamado %r en %s" % (nombre, notas))


def etiqueta(notas, nombre):
    with open(notas, encoding="utf-8") as f:
        for linea in f:
            m = re.match(r"^L\s+0x([0-9A-Fa-f]+)\s+(\S+)", linea)
            if m and m.group(2) == nombre:
                return int(m.group(1), 16)
    raise SystemExit("  no hay ninguna etiqueta %r en %s" % (nombre, notas))


class Cartucho(object):
    def __init__(self, rom, org):
        self.rom, self.org = rom, org

    def b(self, a):
        return self.rom[a - self.org]

    def w16(self, a):
        return self.b(a) | (self.b(a + 1) << 8)

    def descomprime(self, src, dest, vram, escritas=None, hasta=None):
        """El descompresor de 0x440D. Del flujo sale un byte de cuenta: con el
        bit alto puesto copia esa cantidad de bytes literales y con el bit alto
        claro repite el siguiente byte. Un 0x00 cierra el flujo; un 0x80 -cuenta
        cero pero byte no nulo- trae DOS bytes con otra direccion de VRAM y
        sigue, que es el `cp c / jr nz` de 0x4419 volviendo a la entrada que lee
        el destino."""
        p, wr = src, dest & 0x3FFF
        while True:
            if hasta is not None and p >= hasta:
                return p
            x = self.b(p)
            c = x & 0x7F
            p += 1
            if x == 0:
                return p
            if c == 0:                       # 0x80: viene otra direccion
                wr = (self.b(p) | (self.b(p + 1) << 8)) & 0x3FFF
                p += 2
                continue
            if x != c:                       # bit alto puesto: copia literal
                for _ in range(c):
                    vram[wr & 0x3FFF] = self.b(p)
                    if escritas is not None:
                        escritas.add(wr & 0x3FFF)
                    p += 1
                    wr += 1
            else:                            # bit alto claro: repite un byte
                v = self.b(p)
                p += 1
                for _ in range(c):
                    vram[wr & 0x3FFF] = v
                    if escritas is not None:
                        escritas.add(wr & 0x3FFF)
                    wr += 1


def destinos_comunes(cart, dibuja_marco, hasta):
    """Los dos bloques que DIBUJA_MARCO sube SIEMPRE, sea cual sea la prueba, no
    estan en ninguna tabla: son cuatro instrucciones al final de la rutina
    (`ld de,nn` / `ld hl,nn`, dos veces). Se sacan decodificando esos opcodes en
    el cuerpo de la rutina, para no escribir aqui sus direcciones."""
    pares, a = [], dibuja_marco
    while a < hasta - 5:
        if cart.b(a) == 0x11 and cart.b(a + 3) == 0x21:
            pares.append((cart.w16(a + 1), cart.w16(a + 4)))
            a += 6
            continue
        a += 1
    if len(pares) != 2:
        raise SystemExit("  DIBUJA_MARCO no tiene los dos pares ld de/ld hl "
                         "esperados (encontrados %d)" % len(pares))
    return pares


def vram_desde_la_rom(cart, notas, evento):
    """Repite lo que hace DIBUJA_MARCO (0x4816) para una prueba: cuatro bloques
    de su lista mas los dos comunes, y cada flujo volcado en los TRES tercios
    (el `ld a,008h / add a,d` de 0x4850 sube 0x800 al destino cada vuelta)."""
    tabla, _ = rango_por_nombre(notas, "tabla_marcos")
    marco = etiqueta(notas, "DIBUJA_MARCO")
    vram, escritas = bytearray(0x4000), set()
    lista = cart.w16(tabla + 2 * (evento & 3))
    entradas = [(cart.w16(lista + 4 * k), cart.w16(lista + 4 * k + 2))
                for k in range(4)]
    for dest, src in entradas + destinos_comunes(cart, marco, tabla):
        for tercio in range(3):
            cart.descomprime(src, (dest + 0x800 * tercio) & 0x3FFF, vram, escritas)
    return vram, escritas


def sitio_del_publico(cart, notas):
    """Donde cae el publico dentro del primer tercio. No se escribe a mano: el
    flujo comun se descomprime dos veces, una entera y otra cortada justo donde
    empieza el bloque `publico_a`, y lo que sobra es su sitio."""
    marco = etiqueta(notas, "DIBUJA_MARCO")
    tabla, _ = rango_por_nombre(notas, "tabla_marcos")
    (dest, src), _colores = destinos_comunes(cart, marco, tabla)
    pub, _ = rango_por_nombre(notas, "publico_a")
    todo, antes = set(), set()
    cart.descomprime(src, dest, bytearray(0x4000), todo)
    cart.descomprime(src, dest, bytearray(0x4000), antes, hasta=pub)
    return todo - antes


def coteja(cart, notas, mia, escritas, real):
    """Compara lo descomprimido de la ROM con el volcado de la VRAM. Devuelve
    (fases_del_publico, distintos).

    La fase A es la que deja DIBUJA_MARCO. Si el volcado pillo la B, se aplica
    su guion TERCIO A TERCIO: el juego no anima los tres a la vez, solo aquellos
    donde las gradas se ven, asi que aplicar la fase B en los tres estropearia
    el que ya estaba bien."""
    def fallos(v):
        return sorted(a for a in escritas if v[a] != real[a])

    malos = fallos(mia)
    if not malos:
        return "A A A", []
    b, _ = rango_por_nombre(notas, "publico_b")
    sitio = sitio_del_publico(cart, notas)
    fases = []
    for tercio in range(3):
        donde = set((a + 0x800 * tercio) & 0x3FFF for a in sitio)
        if not any(mia[a] != real[a] for a in donde):
            fases.append("A")
            continue
        cart.descomprime(b, (min(donde)) & 0x3FFF, mia)
        fases.append("B")
    return " ".join(fases), fallos(mia)


def reparto(volcado, escritas):
    """De las casillas que la pantalla usa de verdad, cuantas tienen su dibujo en
    el cartucho y cuantas no. Las que no son las del marcador: su fuente no esta
    en la ROM del juego, la copia 0x43BF de la ROM del MSX (CGTBL, 0x0004)."""
    del_cartucho, de_fuera = set(), set()
    for fila in range(24):
        tercio = fila // 8
        for col in range(32):
            t = volcado[NOMBRES + fila * 32 + col]
            a = PATRONES + tercio * 0x800 + t * 8
            (del_cartucho if a in escritas else de_fuera).add((tercio, t))
    return len(del_cartucho), len(de_fuera)


def dibuja(vram_rom, volcado, esc=2):
    """La pantalla tal como la ve el VDP: las casillas con los dibujos de la ROM
    y encima los sprites, que son 16x16 sin ampliar."""
    w, h = 256 * esc, 192 * esc
    px = bytearray(w * h * 3)

    def pon(x, y, c):
        if 0 <= x < 256 and 0 <= y < 192:
            for dy in range(esc):
                base = ((y * esc + dy) * w + x * esc) * 3
                for dx in range(esc):
                    px[base + dx * 3:base + dx * 3 + 3] = bytes(c)

    for fila in range(24):
        tercio = fila // 8
        for col in range(32):
            t = volcado[NOMBRES + fila * 32 + col]
            pb = PATRONES + tercio * 0x800 + t * 8
            cb = COLORES + tercio * 0x800 + t * 8
            for f in range(8):
                linea, color = vram_rom[pb + f], vram_rom[cb + f]
                tinta, papel = PALETA[color >> 4], PALETA[color & 15]
                for c in range(8):
                    pon(col * 8 + c, fila * 8 + f,
                        tinta if (linea >> (7 - c)) & 1 else papel)

    # Los sprites se leen de delante a atras hasta el 0xD0 que cierra la lista, y
    # se pintan en orden inverso para que el plano 0 quede encima.
    activos = []
    for n in range(32):
        if volcado[SPR_ATR + n * 4] == 0xD0:
            break
        activos.append(n)
    for n in reversed(activos):
        y, x, pat, col = volcado[SPR_ATR + n * 4:SPR_ATR + n * 4 + 4]
        if col & 0x80:                       # bit EC: 32 pixeles a la izquierda
            x -= 32
        col &= 15
        if col == 0:
            continue
        y = (y + 1) & 0xFF                   # la Y del VDP va una linea alta
        if y > 208:
            y -= 256
        base = SPR_PAT + (pat & 0xFC) * 8
        for mitad in range(2):               # izquierda y derecha del 16x16
            for f in range(16):
                fila = volcado[base + mitad * 16 + f]
                for c in range(8):
                    if (fila >> (7 - c)) & 1:
                        pon(x + mitad * 8 + c, y + f, PALETA[col])
    return w, h, px


PRUEBAS = ["DIVING", "LONG HORSE", "TRAMPOLINE", "HORIZONTAL BAR"]


def escenas(indice):
    """fichero, evento, imagen, instante, titulo"""
    with open(indice, encoding="utf-8") as f:
        lineas = f.read().splitlines()
    for linea in lineas:
        linea = linea.split("#")[0].strip()
        if not linea:
            continue
        campos = linea.split(None, 4)
        yield campos[0], int(campos[1]), campos[2], campos[3], campos[4]


def main(argv):
    if len(argv) < 6:
        print(__doc__)
        return 2
    rom = open(argv[1], "rb").read()
    cart = Cartucho(rom, int(argv[2], 0))
    notas, dir_vram, destino = argv[3], argv[4], argv[5]
    os.makedirs(destino, exist_ok=True)

    indice = os.path.join(dir_vram, "escenas.txt")
    if not os.path.exists(indice):
        raise SystemExit("  falta %s" % indice)

    total = 0
    for fichero, evento, imagen, _t, _titulo in escenas(indice):
        ruta = os.path.join(dir_vram, fichero)
        volcado = open(ruta, "rb").read()
        if len(volcado) != 0x4000:
            raise SystemExit("  %s no son 16384 bytes" % ruta)
        mia, escritas = vram_desde_la_rom(cart, notas, evento)
        fases, malos = coteja(cart, notas, mia, escritas, volcado)
        if malos:
            raise SystemExit(
                "  %s: %d de %d bytes NO cuadran con la ROM (el primero, la "
                "VRAM 0x%04X: la ROM da 0x%02X y el volcado 0x%02X)"
                % (fichero, len(malos), len(escritas), malos[0],
                   mia[malos[0]], volcado[malos[0]]))
        # los dibujos que el cartucho no trae -la fuente del marcador, que sale
        # de la ROM del MSX- se toman del volcado tal cual; el cotejo de arriba
        # garantiza que todo lo demas es exactamente lo que descomprime la ROM
        pantalla = bytearray(volcado)
        for a in escritas:
            pantalla[a] = mia[a]
        png(*dibuja(pantalla, volcado), os.path.join(destino, imagen))
        rom_tiles, fuera = reparto(volcado, escritas)
        print("  %-26s %-15s %4d bytes cuadran byte a byte; %d casillas del "
              "cartucho y %d de la fuente de la BIOS; publico %s"
              % (imagen, PRUEBAS[evento & 3], len(escritas), rom_tiles, fuera,
                 fases))
        total += 1
    print("  %d escenas dibujadas desde la ROM, 0 diferencias" % total)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
