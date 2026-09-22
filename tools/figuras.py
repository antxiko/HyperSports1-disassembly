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

Y HAY UNA CUARTA COSA, que solo pasa en la piscina -la prueba 0, DIVING- y que
theNestruo cazo en el issue #2 porque la vio jugando: despues de montar el
buffer, 0x63E8 PERMUTA los ocho bytes de los sprites 0-1 con los de los 2-3
(INTERCAMBIA entre 0xE0D0 y 0xE0D8) y vuelve a clavar los patrones a 8, 12, 0 y
4. Cada ficha conserva SU dibujo, pero las dos amarillas del cuerpo pasan a ser
los sprites de encima y la camiseta roja y las botas blancas quedan debajo,
tapadas: el mismo guion, los mismos dibujos, y el atleta sale en banador. El
bucle de patrones no es redundante: el interprete no toca ese byte en cada
cuadro, asi que sin el la permuta los iria dando la vuelta cuadro si, cuadro no.

Uso: figuras.py <rom> <org> <docs/imagenes>
"""
import os
import sys

import graficos as G

TABLA = 0x65F6          # 0x65B1: la tabla de punteros a los guiones
PATRONES = 0x1800       # 0x65D9: la tabla de patrones de sprites
PRIMER_GUION = 0x6650   # el primer guion arranca justo detras de la tabla
POSTURAS = (PRIMER_GUION - TABLA) // 2
# La pose con la que se ensena el cambio de ropa: la de pie. Es de cuatro
# sprites y, segun la medida de tools/posturas.py, la unica de ese grupo que la
# atraccion usa en las CUATRO pruebas -en la piscina con la permuta de 0x63E8 y
# en las otras tres tal cual-, asi que se ve de verdad con las dos ropas.
POSE_EJEMPLO = 0
# Las poses que la piscina usa durante la atraccion: las dieciocho primeras,
# seguidas. Sale de cruzar los guiones con la medida de openMSX
# (tools/posturas.py, que ademas COMPRUEBA que esta lista sigue siendo esa).
# Son las que el juego pinta en banador.
POSES_DE_LA_PISCINA = tuple(range(18))
ATRIBUTOS_DEL_ATLETA = 0x3B28   # 0x640F: los 28 bytes van a los sprites 10-16
VOLCADOS = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                        "src", "vram")


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


def bloques_de(rom, org, n):
    """Los bloques de patrones que el guion de la pose n sube a la VRAM, en su
    orden: las direcciones que 0x65E5 le pasa al descompresor."""
    p = palabra(rom, org, TABLA + n * 2)
    while leelo(rom, org, p) & 0xF0 != 0x80:
        p += 3
    cuantos = leelo(rom, org, p) & 0x0F
    return [palabra(rom, org, p + 1 + k * 2) for k in range(cuantos)]


def en_la_piscina(fichas):
    """Lo que 0x63E8 le hace al buffer en la prueba 0: permuta los sprites 0-1
    con los 2-3 (INTERCAMBIA, ocho bytes) y vuelve a escribir los patrones 8,
    12, 0 y 4, de modo que cada ficha conserva su dibujo y cambia de plano. Las
    45 poses tienen cuatro fichas o mas -nunca menos, medido-, asi que la
    permuta siempre cae sobre el atleta y la quinta y la sexta ficha, si las
    hay, se quedan donde estaban."""
    if len(fichas) < 4:
        return fichas
    return fichas[2:4] + fichas[0:2] + fichas[4:]


def desde_la_vram(v):
    """Las fichas del atleta tal y como estan en un volcado de VRAM: desde
    0x3B28 hasta el 0xD0 que 0x65D6 deja detras de la ultima. Con esto y la
    tabla de patrones del mismo volcado, `pinta` dibuja lo que el VDP estaba
    ensenando, y eso es contra lo que se coteja lo que sale de la ROM."""
    fichas = []
    for i in range(7):
        y, x, p, c = v[ATRIBUTOS_DEL_ATLETA + i * 4:ATRIBUTOS_DEL_ATLETA + i * 4 + 4]
        if y == 0xD0:
            break
        fichas.append((y, x, p, c))
    return fichas


def que_pose_es(rom, org, v, cuantas):
    """Que pose tiene subida un volcado de VRAM: la unica cuyos patrones -los
    32 bytes de cada una de sus fichas, desde 0x1800- coinciden byte a byte."""
    n_bytes = 32 * cuantas
    return [n for n in range(POSTURAS)
            if una_postura(rom, org, n)[1][PATRONES:PATRONES + n_bytes]
            == v[PATRONES:PATRONES + n_bytes]]


def ocupacion(fichas, v):
    """Que columnas del rectangulo de la figura llevan algun pixel encendido.
    Devuelve (x0, [True/False por columna])."""
    vivas = [f for f in fichas if f[3] & 0x0F]
    x0 = min(f[1] for f in vivas)
    ancho = max(f[1] for f in vivas) - x0 + 16
    llena = [False] * ancho
    for _y, x, patron, _color in vivas:
        base = PATRONES + (patron & 0xFC) * 8
        for f in range(16):
            fila = (v[base + f] << 8) | v[base + 16 + f]
            for c in range(16):
                if (fila >> (15 - c)) & 1:
                    llena[x - x0 + c] = True
    return x0, llena


def la_raja_del_poste(fichas, v):
    """Las columnas TRANSPARENTES DE ARRIBA ABAJO que partem la figura en dos,
    con dibujo a los dos lados. En las poses de la barra fija son dos, y no son
    un descuido: por ahi pasa el poste de la barra -un tile negro de dos
    pixeles de ancho- y el atleta parece colgar por detras de el. En la pose
    40 caen en dx=-10 y -9, y en el volcado de la barra (escena_4, atleta en
    x=0x75) el poste esta en x=0x6B y 0x6C: las mismas dos columnas. Aislado
    el sprite, la raja se ve como un corte; el usuario lo cazo en la lamina.
    Devuelve los dx de esas columnas, o [] si la figura es de una pieza."""
    x0, llena = ocupacion(fichas, v)
    primera = llena.index(True)
    ultima = len(llena) - 1 - llena[::-1].index(True)
    return [x0 + i for i in range(primera + 1, ultima) if not llena[i]]


NOMBRES, COLORES = 0x3800, 0x0000   # y los patrones de fondo en 0x2000


def pixel_del_decorado(v, y, x):
    """El color de un pixel de la pantalla en SCREEN 2, leido de un volcado
    de VRAM: tabla de nombres, y patron y color del tercio que toque."""
    fila, col = y >> 3, x >> 3
    if not (0 <= fila < 24 and 0 <= col < 32):
        return G.FONDO
    t = v[NOMBRES + fila * 32 + col]
    donde = (fila >> 3) * 0x800 + t * 8 + (y & 7)
    encendido = (v[0x2000 + donde] >> (7 - (x & 7))) & 1
    c = v[COLORES + donde]
    c = (c >> 4) if encendido else (c & 0x0F)
    return G.PALETA[c] if c else G.FONDO


def pinta(fichas, v, esc=4, margen=2, decorado=None):
    """Las fichas con su color, del ultimo al primero: en el MSX1 el sprite de
    numero mas bajo va encima. Con `decorado` = (volcado, y, x) se pinta
    DEBAJO lo que la pantalla tenia en ese sitio -y, x es donde estaba la
    ficha de dy=dx=0-: es como se ve la pose de la barra fija, que lleva una
    raja transparente para que el poste, que es un tile, asome por ella."""
    vivas = [f for f in fichas if f[3] & 0x0F]
    if not vivas:
        return None
    y0 = min(f[0] for f in vivas)
    x0 = min(f[1] for f in vivas)
    alto = max(f[0] for f in vivas) - y0 + 16
    ancho = max(f[1] for f in vivas) - x0 + 16
    w, h = ancho * esc + margen * 2, alto * esc + margen * 2
    px = bytearray(bytes(G.FONDO) * (w * h))
    if decorado:
        vol, yb, xb = decorado
        for j in range(alto):
            for i in range(ancho):
                col = bytes(pixel_del_decorado(vol, yb + y0 + j, xb + x0 + i))
                for a in range(esc):
                    gy = margen + j * esc + a
                    gx = margen + i * esc
                    px[(gy * w + gx) * 3:(gy * w + gx + esc) * 3] = col * esc
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

    # LAS 45 POSES en el orden del guion -como salen en el potro, la cama y la
    # barra- y, tras una fila en blanco, LAS DIECIOCHO DE LA PISCINA como las
    # pinta la piscina: con la permuta de 0x63E8, en banador. El usuario cazo
    # que esta lamina no ensenaba el banador por ningun sitio (issue #2).
    # Las poses con raja se pintan sobre el decorado REAL del volcado de VRAM
    # que las tiene puestas, en su posicion: la ficha 0 del volcado da (y, x).
    en_pantalla = {}
    if os.path.isdir(VOLCADOS):
        for fn in sorted(os.listdir(VOLCADOS)):
            if not fn.endswith(".vram"):
                continue
            with open(os.path.join(VOLCADOS, fn), "rb") as f:
                vol = bytearray(f.read())
            fv = desde_la_vram(vol)
            if not fv:
                continue
            for n in que_pose_es(rom, org, vol, len(fv)):
                dy, dx = una_postura(rom, org, n)[0][0][:2]
                en_pantalla.setdefault(n, (vol, fv[0][0] - dy, fv[0][1] - dx, fn))
    trozos, con_raja = [], []
    for n in range(POSTURAS):
        fichas, v = una_postura(rom, org, n)
        raja = la_raja_del_poste(fichas, v)
        decorado = None
        if raja:
            con_raja.append((n, raja, en_pantalla.get(n, (None,) * 4)[3]))
            if n in en_pantalla:
                decorado = en_pantalla[n][:3]
        t = pinta(fichas, v, decorado=decorado)
        if t:
            trozos.append(t)
    print("  poses con raja (dx) y el volcado que les pone el decorado: %s"
          % ", ".join("%d %s %s" % c for c in con_raja))
    cols = 8
    hueco = (1, 1, bytearray(bytes(G.FONDO)))
    trozos += [hueco] * ((-len(trozos)) % cols + cols)
    for n in POSES_DE_LA_PISCINA:
        fichas, v = una_postura(rom, org, n)
        trozos.append(pinta(en_la_piscina(fichas), v))
    rejilla(trozos, os.path.join(destino, "atleta.png"), cols=cols)
    print("  atleta.png: las %d posturas del atleta con los patrones que su "
          "guion sube a la VRAM y el color de sus fichas, y debajo las %d de "
          "la piscina tal y como las deja 0x63E8: en banador"
          % (POSTURAS, len(POSES_DE_LA_PISCINA)))

    # LAS DOS ROPAS DEL MISMO ATLETA, con la MISMA pose y los MISMOS dibujos.
    # Arriba, la pose tal y como la deja el guion -rojo y blanco en los dos
    # primeros sprites, que en el MSX1 son los de encima- y montada: camiseta
    # y botas, que es como sale en el potro, la cama y la barra. Abajo, la
    # misma pose despues de la permuta de 0x63E8, que es lo que la prueba 0
    # (DIVING) hace en cada cuadro: los dos amarillos pasan delante y tapan el
    # rojo y el blanco. Es el banador de la piscina. Cada fila lleva los cuatro
    # sprites sueltos, en su orden de plano, y a la derecha el montaje.
    # theNestruo lo pidio asi, con este mismo dibujo, en el issue #2.
    fichas, v = una_postura(rom, org, POSE_EJEMPLO)
    filas = []
    for orden in (fichas, en_la_piscina(fichas)):
        filas += [pinta([f], v) for f in orden] + [pinta(orden, v)]
    rejilla(filas, os.path.join(destino, "atleta_por_capas.png"), cols=5)
    print("  atleta_por_capas.png: la pose %d con las capas en el orden del "
          "guion y en el de la piscina (0x63E8), sueltas y montada"
          % POSE_EJEMPLO)
    return 0


if __name__ == "__main__":
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    sys.exit(main(sys.argv))
