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
    siguiente byte; un byte 0x00 cierra el bloque. El destino es externo."""
    p, wr = src, dest & 0x3FFF
    while True:
        x = rom[p - org]
        c = x & 0x7F
        p += 1
        if x == 0:
            break
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

    # La tabla de 0x4859 (bloque graficos_eventos) apunta, por prueba, a una
    # lista de pares [destino_VRAM][puntero_a_datos_comprimidos]. Se descomprime
    # la lista de la primera prueba a un buffer de VRAM y se dibujan sus tiles.
    ini, _fin = rango_por_nombre(notas, "graficos_eventos")

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
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
