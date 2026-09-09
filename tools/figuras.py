#!/usr/bin/env python3
"""Monta el ATLETA como lo monta el cartucho, postura a postura y con su color.

Una hoja de los patrones de sprite en blanco y negro no ensena nada: en el
MSX1 el color de un sprite va en su FICHA, y el atleta son CUATRO sprites de
16x16 superpuestos, cada uno del suyo. Peor aun, aqui los patrones no estan
quietos en la VRAM: el cartucho REESCRIBE la tabla de patrones de sprites cada
cuadro con los dibujos de la postura que toca.

Los tres pasos que da el Z80, y que este programa repite:

  - 0x65AD dobla la postura (0xE10B) e indexa la tabla de punteros de 0x65F6;
  - el GUION que sale de ahi son ternas (dy, dx, color) que 0x65BE deja en el
    buffer de fichas de 0xE0D0, hasta un byte 0x8N que las cierra; ese N dice
    cuantos bloques de patrones van detras, y 0x65E5 los sube a la VRAM 0x1800
    con el descompresor de 0x69F9;
  - y el numero de patron NO esta en el guion: lo clava 0x618E una sola vez al
    montar la prueba -0x00, 0x04, 0x08...- , asi que el sprite n pinta siempre
    el patron 4n. Lo que cambia es el dibujo que hay debajo.

De ahi salen las ropas distintas con el mismo juego de sprites: el sprite 1 es
siempre el patron 0x04, pero lo que ese patron contiene lo decide el bloque que
la postura suba. Y como en el MSX1 manda el sprite de numero mas bajo, el ORDEN
de las ternas dentro del guion es lo que decide que pieza tapa a cual.

Uso: figuras.py <rom> <org> <docs/imagenes>
"""
import os
import sys

import graficos as G

TABLA = 0x65F6          # 0x65B1: la tabla de punteros a los guiones
PATRONES = 0x1800       # 0x65D9: la tabla de patrones de sprites
PRIMER_GUION = 0x6650   # el primer guion arranca justo detras de la tabla
POSTURAS = (PRIMER_GUION - TABLA) // 2


def leelo(rom, org, a):
    return rom[a - org]


def con_signo(b):
    return b - 256 if b >= 0x80 else b


def palabra(rom, org, a):
    return leelo(rom, org, a) | (leelo(rom, org, a + 1) << 8)


def descomprime(rom, org, p, v, vram, bloques):
    """El descompresor de 0x69F9: 0 acaba un bloque, el bit 7 marca literales
    y sin el se repite el byte que sigue. D cuenta los bloques.

    Devuelve (siguiente byte de la ROM, siguiente direccion de VRAM). Lo
    segundo hace falta porque 0x65D9 apunta el VDP a 0x1800 UNA sola vez y
    luego 0x65E5 sube los N bloques seguidos: el puerto autoincrementa, asi
    que el segundo bloque continua donde acabo el primero.
    """
    while True:
        n = leelo(rom, org, p)
        p += 1
        if n == 0:
            bloques -= 1
            if bloques == 0:
                return p, vram
            continue
        if n & 0x80:                       # literales
            for i in range(n & 0x7F):
                v[(vram + i) & 0x3FFF] = leelo(rom, org, p + i)
            p += n & 0x7F
            vram += n & 0x7F
        else:                              # repeticion
            x = leelo(rom, org, p)
            p += 1
            for i in range(n):
                v[(vram + i) & 0x3FFF] = x
            vram += n


def una_postura(rom, org, n):
    """Devuelve (fichas, vram) de la postura n: las fichas ya con su patron."""
    p = palabra(rom, org, TABLA + n * 2)
    fichas, i = [], 0
    while True:
        b = leelo(rom, org, p)
        if b & 0xF0 == 0x80:               # 0x65C1: el 0x8N cierra el guion
            break
        # dy y dx son DESPLAZAMIENTOS CON SIGNO: 0x65C6 y 0x65CB los suman a la
        # posicion del atleta con un `add a,` de ocho bits, asi que el 0xF4 de
        # un guion son doce puntos hacia arriba, no doscientos cuarenta abajo.
        # 0x618E clava el patron por indice: el sprite i pinta el patron 4i
        fichas.append((con_signo(b), con_signo(leelo(rom, org, p + 1)), i * 4,
                       leelo(rom, org, p + 2)))
        p += 3
        i += 1
    cuantos = b & 0x0F                     # 0x65E1: los bloques que van detras
    v = bytearray(0x4000)
    p += 1
    # LOS BLOQUES VAN UNO DETRAS DE OTRO, no todos al principio de la tabla.
    # 0x65D9 apunta el VDP a 0x1800 una vez y 0x65E5 sube los N seguidos; como
    # el puerto autoincrementa, cada bloque continua donde acabo el anterior.
    # Descomprimiendolos todos en PATRONES se pisaban entre si y solo quedaba
    # el ultimo: las posturas de un solo bloque salian bien y las de varios
    # perdian piezas -el atleta se quedaba sin camiseta y con los pies
    # sueltos-. Lo vio theNestruo (issue #2).
    donde = PATRONES
    for k in range(cuantos):
        origen = palabra(rom, org, p + k * 2)
        _, donde = descomprime(rom, org, origen, v, donde, 1)
    return fichas, v


def pinta(fichas, v, esc=4, margen=2):
    """Las fichas con su color, del ultimo al primero: en el MSX1 el sprite de
    numero mas bajo va encima."""
    vivas = [f for f in fichas if f[3] & 0x0F]
    if not vivas:
        return None
    y0 = min(f[0] for f in vivas)
    x0 = min(f[1] for f in vivas)
    alto = max(f[0] for f in vivas) - y0 + 16
    ancho = max(f[1] for f in vivas) - x0 + 16
    w, h = ancho * esc + margen * 2, alto * esc + margen * 2
    px = bytearray(bytes(G.FONDO) * (w * h))
    for y, x, patron, color in reversed(vivas):
        col = G.PALETA[color & 0x0F]
        base = PATRONES + (patron & 0xFC) * 8
        for f in range(16):
            fila = (v[base + f] << 8) | v[base + 16 + f]
            for c in range(16):
                if not (fila >> (15 - c)) & 1:
                    continue
                gx = margen + (x - x0 + c) * esc
                gy = margen + (y - y0 + f) * esc
                for a in range(esc):
                    for b in range(esc):
                        i = ((gy + a) * w + gx + b) * 3
                        if 0 <= i < len(px) - 2:
                            px[i:i + 3] = bytes(col)
    return w, h, px


def rejilla(trozos, fn, cols=8, hueco=10, margen=10):
    anchos = max(t[0] for t in trozos)
    altos = max(t[1] for t in trozos)
    filas = (len(trozos) + cols - 1) // cols
    w = cols * anchos + (cols - 1) * hueco + margen * 2
    h = filas * altos + (filas - 1) * hueco + margen * 2
    px = bytearray(bytes(G.FONDO) * (w * h))
    for k, (tw, th, tpx) in enumerate(trozos):
        ox = margen + (k % cols) * (anchos + hueco) + (anchos - tw) // 2
        oy = margen + (k // cols) * (altos + hueco) + (altos - th)
        for y in range(th):
            i = ((oy + y) * w + ox) * 3
            px[i:i + tw * 3] = tpx[y * tw * 3:(y + 1) * tw * 3]
    G.png(w, h, px, fn)


def main(argv):
    if len(argv) < 4:
        print(__doc__)
        return 2
    rom = open(argv[1], "rb").read()
    org = int(argv[2], 0)
    destino = argv[3]
    os.makedirs(destino, exist_ok=True)

    trozos, composiciones = [], {}
    for n in range(POSTURAS):
        fichas, v = una_postura(rom, org, n)
        t = pinta(fichas, v)
        if t:
            trozos.append(t)
        if len(fichas) == 4:
            # La firma de una composicion es el ORDEN de sus colores. Cambiarlo
            # es lo unico que hace falta para vestir al atleta de otra manera.
            firma = tuple(f[3] & 0x0F for f in fichas)
            composiciones.setdefault(firma, (fichas, v, n))
    rejilla(trozos, os.path.join(destino, "atleta.png"))
    print("  atleta.png: las %d posturas del atleta, cada una con los patrones"
          " que su guion sube a la VRAM y el color de sus fichas" % len(trozos))

    # LAS COMPOSICIONES, una fila por cada una: los cuatro sprites sueltos y
    # luego montados. Lo que ensena esto es doble: que el color no esta en el
    # patron sino en la ficha, y que la ropa del atleta NO se cambia cambiando
    # de dibujos, sino cambiando el ORDEN de los colores en el guion. Con
    # 6,15,11,11 el rojo de la camiseta va en el sprite de encima y se ve
    # vestido; con 11,11,15,6 el rojo baja al ultimo, queda tapado por los dos
    # amarillos, y el mismo atleta sale en banador. theNestruo lo pregunto en
    # el issue #1 y lo volvio a pedir en el #2.
    filas = []
    for firma in sorted(composiciones, key=lambda f: -composiciones[f][2]):
        fichas, v, n = composiciones[firma]
        filas += [pinta([f], v) for f in fichas] + [pinta(fichas, v)]
    rejilla(filas, os.path.join(destino, "atleta_por_capas.png"), cols=5)
    print("  atleta_por_capas.png: las %d composiciones de cuatro sprites, cada"
          " una con sus capas sueltas y montada" % len(composiciones))
    return 0


if __name__ == "__main__":
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    sys.exit(main(sys.argv))
