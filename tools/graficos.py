#!/usr/bin/env python3
"""Dibuja para la web los graficos que el cartucho lleva DENTRO, desde sus bytes.

Las imagenes de esta web no son ilustraciones ni capturas: se dibujan leyendo
los propios bytes del cartucho. Los graficos van COMPRIMIDOS por rachas, asi que
aqui se ejecuta en Python el mismo descompresor que el Z80 corre en 0x440D (un
byte de cuenta, con el bit alto para distinguir copia literal de relleno), y lo
que sale es la prueba de que la lectura del binario es correcta: si el rango o el
formato estuvieran mal, saldria ruido.

No se escribe ninguna direccion a mano: el rango se busca por el NOMBRE del
bloque en las anotaciones (`D <inicio> <fin> <nombre> ...`).

Lo que dibuja:
  sprites.png  los tiles y las figuras de una prueba, descomprimidos a la tabla
               de patrones tal como los pone el cartucho.

Uso: graficos.py <rom> <org> <notas> <docs/imagenes>
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

FONDO = (0x20, 0x20, 0x30)
TINTA = (0xF0, 0xF0, 0xE0)
REJA = (0x38, 0x38, 0x4A)


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
    for linea in open(notas, encoding="utf-8"):
        m = re.match(r"^D\s+0x([0-9A-Fa-f]+)\s+0x([0-9A-Fa-f]+)\s+(\S+)", linea)
        if m and m.group(3) == nombre:
            return int(m.group(1), 16), int(m.group(2), 16)
    raise SystemExit("  no hay ningun bloque llamado %r en %s" % (nombre, notas))


def descomprime(rom, org, src, dest, vram):
    """Descompresor de 0x440D: cuenta = byte and 0x7F; con el bit alto puesto
    copia esa cantidad de bytes literales, con el bit alto claro repite el
    siguiente byte. Un 0x00 cierra el flujo entero y un 0x80 -cuenta cero pero
    byte no nulo- trae DOS bytes con otra direccion de VRAM y sigue: es el
    `cp c / jr nz,VUELCA_TABLA_VDP` de 0x4419, que vuelve a la entrada que lee
    el destino. El destino de la primera vez es externo."""
    p, wr = src, dest & 0x3FFF
    while True:
        x = rom[p - org]
        c = x & 0x7F
        p += 1
        if x == 0:
            break
        if c == 0:                           # 0x80: viene otra direccion
            wr = (rom[p - org] | (rom[p - org + 1] << 8)) & 0x3FFF
            p += 2
            continue
        if x != c:                           # bit alto puesto: copia literal
            for _ in range(c):
                vram[wr & 0x3FFF] = rom[p - org]
                p += 1
                wr += 1
        else:                                # bit alto claro: repite un byte
            v = rom[p - org]
            p += 1
            for _ in range(c):
                vram[wr & 0x3FFF] = v
                wr += 1
    return p


def guion(rom, org, p, vram, mascara=0xFF):
    """VUELCA_GUION_MASC (0x4062): del flujo sale primero la casilla de la
    tabla de nombres y luego los tiles, uno por byte; 0xFE trae otra casilla y
    0xFF acaba. La mascara es el registro C: 0xFF escribe y 0x00 borra."""
    def b(a):
        return rom[a - org]

    dest = b(p) | (b(p + 1) << 8)
    p += 2
    while True:
        x = b(p)
        p += 1
        if x == 0xFF:
            return p
        if x == 0xFE:
            dest = b(p) | (b(p + 1) << 8)
            p += 2
            continue
        vram[dest & 0x3FFF] = x & mascara
        dest += 1


def vram_del_rotulo(rom, org):
    """DIBUJA_TITULO (0x4198) y el guion que vuelca PINTA_ROTULO_JUEGO (0x4324).

    Ahi esta el rotulo del juego, y no en la pantalla que sube el logotipo de
    Konami: son 22 x 2 casillas en las filas 5 y 6. Los dibujos son el bloque
    que 0x41A9 descomprime en la VRAM 0x2600 -el tile 0xC0 del primer tercio- y
    los colores los pone el mismo 0x4198: blanco liso (0xF0) para la fila de
    arriba y, para la de abajo, las 0x11 copias del patron de rayas de
    tabla_titulo (0x41CC), que es de donde sale el degradado.
    """
    def w16(a):
        return rom[a - org] | (rom[a - org + 1] << 8)

    vram = bytearray(0x4000)
    descomprime(rom, org, 0x4631, w16(0x462F), vram)     # 0x41A9
    for i in range(0x98):                                # 0x41AF: blanco liso
        vram[(0x0600 + i) & 0x3FFF] = 0xF0
    wr = 0x0600 + 0x98                                   # 0x41BA: las rayas
    for _ in range(0x11):
        for i in range(8):
            vram[wr & 0x3FFF] = rom[0x41CC - org + i]
            wr += 1
    guion(rom, org, 0x4335, vram)                        # 0x4324
    return vram


def pinta(vram, f0, f1, c0, c1, esc=4):
    """Las casillas [f0,f1]x[c0,c1] como las lee el VDP en SCREEN 2."""
    w, h = (c1 - c0 + 1) * 8 * esc, (f1 - f0 + 1) * 8 * esc
    px = bytearray(w * h * 3)
    for fila in range(f0, f1 + 1):
        tercio = fila // 8
        for col in range(c0, c1 + 1):
            t = vram[0x3800 + fila * 32 + col]
            pb, cb = 0x2000 + tercio * 0x800 + t * 8, tercio * 0x800 + t * 8
            for f in range(8):
                linea, color = vram[pb + f], vram[cb + f]
                tinta, papel = PALETA[color >> 4], PALETA[color & 15]
                for x in range(8):
                    c = tinta if (linea >> (7 - x)) & 1 else papel
                    for dy in range(esc):
                        base = ((((fila - f0) * 8 + f) * esc + dy) * w
                                + ((col - c0) * 8 + x) * esc) * 3
                        for dx in range(esc):
                            px[base + dx * 3:base + dx * 3 + 3] = bytes(c)
    return w, h, px


def hoja(vram, primero, ultimo, cols=16, esc=3, margen=1):
    n = ultimo - primero + 1
    filas = (n + cols - 1) // cols
    celda = 8 * esc + margen
    w, h = cols * celda + margen, filas * celda + margen
    px = bytearray(bytes(REJA) * (w * h))

    def pon(x, y, c):
        if 0 <= x < w and 0 <= y < h:
            i = (y * w + x) * 3
            px[i:i + 3] = bytes(c)

    for k in range(n):
        gx = margen + (k % cols) * celda
        gy = margen + (k // cols) * celda
        base = (primero + k) * 8
        for f in range(8):
            v = vram[base + f]
            for c in range(8):
                col = TINTA if (v >> (7 - c)) & 1 else FONDO
                for a in range(esc):
                    for b in range(esc):
                        pon(gx + c * esc + b, gy + f * esc + a, col)
    return w, h, px


def main(argv):
    if len(argv) < 5:
        print(__doc__)
        return 2
    rom = open(argv[1], "rb").read()
    org = int(argv[2], 0)
    notas, destino = argv[3], argv[4]
    os.makedirs(destino, exist_ok=True)

    # El bloque tabla_marcos apunta, por prueba, a una lista de pares
    # [destino_VRAM][puntero_a_datos_comprimidos]. Se descomprime la lista de la
    # primera prueba a un buffer de VRAM y se dibujan sus tiles. Las pantallas
    # enteras de las cuatro pruebas las monta tools/escenas.py.
    ini, _fin = rango_por_nombre(notas, "tabla_marcos")

    def w16(a):
        return rom[a - org] | (rom[a - org + 1] << 8)

    vram = bytearray(0x4000)
    lista = w16(ini)                         # lista de la primera prueba
    for _ in range(6):
        dest = w16(lista)
        src = w16(lista + 2)
        lista += 4
        if not (org <= src < org + len(rom)):
            break
        descomprime(rom, org, src, dest, vram)
    # los tiles con dibujo de la tabla de patrones
    w, h, px = hoja(vram, 0x20, 0x9F)
    png(w, h, px, os.path.join(destino, "sprites.png"))
    print("  sprites.png: figuras y tiles de una prueba, descomprimidos desde 0x%04X"
          % ini)

    # El rotulo del juego: filas 5 y 6, columnas 6 a 27, tal como las deja el
    # guion de 0x4335. Se saca de la VRAM montada, no se recorta a ojo.
    v2 = vram_del_rotulo(rom, org)
    png(*pinta(v2, 5, 6, 6, 27), os.path.join(destino, "rotulo.png"))
    print("  rotulo.png: el rotulo HYPER SPORTS 1, 22 x 2 casillas del guion "
          "de 0x4335")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
