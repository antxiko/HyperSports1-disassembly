#!/usr/bin/env python3
"""Que fotogramas del atleta usa cada prueba.

El bloque `posturas_atleta` son 3425 bytes -la quinta parte del cartucho- en
tiras encadenadas que solo lee DIBUJA_ATLETA, con un descompresor propio
(0x69FE) que saca los bytes al puerto del VDP sin pasar por la BIOS. Aqui se
hacen tres cosas:

  1. Se trocea el bloque con las reglas del descompresor y a cada byte se le
     asigna su PAPEL: cuenta, literal o repetido.
  2. Se coteja ese reparto contra la medida de openMSX (tools/omsx_posturas.tcl),
     que apunta que direcciones se leen y DESDE QUE PC -0x69FE lee las cuentas,
     0x6A09 los literales y 0x6A12 el byte que se repite-. Que los dos repartos
     coincidan byte a byte es lo que demuestra que el formato esta bien leido.
  3. Y de paso sale que fotogramas usa cada prueba.

Lo que NO demuestra nada, y estuvo a punto de publicarse como si lo demostrara:
que las tiras "encajen clavadas" en el final del bloque. Empezando en cualquier
byte tambien encajan -comprobado con desplazamientos de 1 a 11-, porque el
formato resincroniza enseguida. Encajar era una propiedad del bucle, no del
cartucho.

El formato, leido de 0x69FE: un byte de cuenta; con el bit alto puesto copia
esa cantidad de bytes literales y con el bit alto claro repite el siguiente
byte. Un 0x00 cierra la TIRA, no el fotograma: la figura tiene tantas tiras como
dice B (0x69F3), y el bucle de 0x6A1B las va contando.

Uso: posturas.py <rom> <org> <notas> [medida.txt]
"""
import re
import sys

PRUEBAS = ["DIVING", "LONG HORSE", "TRAMPOLINE", "HORIZONTAL BAR"]


def rango_por_nombre(notas, nombre):
    with open(notas, encoding="utf-8") as f:
        for linea in f:
            m = re.match(r"^D\s+0x([0-9A-Fa-f]+)\s+0x([0-9A-Fa-f]+)\s+(\S+)",
                         linea)
            if m and m.group(3) == nombre:
                return int(m.group(1), 16), int(m.group(2), 16)
    raise SystemExit("  no hay ningun bloque llamado %r en %s" % (nombre, notas))


def columnas(rom, org, ini, fin):
    """Trocea el bloque en tiras. Devuelve una lista de (inicio, fin,
    bytes_que_produce).

    Cada tira se lee hasta SU PROPIO 0x00, sin cortar en `fin`: si se cortara,
    la ultima acabaria siempre justo ahi por construccion. Aun asi, que acaben
    donde acaba el bloque NO prueba nada -empezando en cualquier byte tambien
    acaban ahi-; lo que prueba el formato es el cotejo de papeles contra la
    medida."""
    fuera = []
    p = ini
    tope = org + len(rom)
    while p < fin and p < tope:
        arranque, salen = p, 0
        while p < tope:
            x = rom[p - org]
            p += 1
            if x == 0:
                break
            c = x & 0x7F
            if x != c:                      # bit alto: copia literal
                p += c
            else:                           # repite el siguiente byte
                p += 1
            salen += c
        fuera.append((arranque, p, salen))
    return fuera


# Que PC lee cada cosa dentro del descompresor de DIBUJA_ATLETA.
PAPEL_DEL_PC = {0x69FE: "cuenta", 0x6A09: "literal", 0x6A12: "repetido"}


def papeles(rom, org, ini, fin):
    """El papel que el troceado le da a cada byte del bloque."""
    fuera = {}
    p = ini
    while p < fin:
        x = rom[p - org]
        fuera[p] = "cuenta"
        p += 1
        if x == 0:
            continue
        c = x & 0x7F
        if x != c:
            for i in range(c):
                fuera[p + i] = "literal"
            p += c
        else:
            fuera[p] = "repetido"
            p += 1
    return fuera


def lee_medida(ruta):
    """De la medida de openMSX: por prueba, que direcciones se leen; y por
    direccion, con que papel la lee el MSX."""
    por_prueba, papel_medido, cabecera = {}, {}, {}
    with open(ruta, encoding="utf-8") as fichero:
        lineas = fichero.read().splitlines()
    for linea in lineas:
        linea = linea.strip()
        if linea.startswith("t="):
            for trozo in linea.split():
                if "=" in trozo:
                    k, v = trozo.split("=", 1)
                    cabecera[k] = v
            continue
        if not linea or linea.startswith("#"):
            continue
        ev, addr, pc = linea.split()
        addr = int(addr, 16)
        por_prueba.setdefault(int(ev), set()).add(addr)
        papel_medido.setdefault(addr, set()).add(
            PAPEL_DEL_PC.get(int(pc, 16), "?"))
    return cabecera, por_prueba, papel_medido


def main(argv):
    if len(argv) < 4:
        print(__doc__)
        return 2
    rom = open(argv[1], "rb").read()
    org = int(argv[2], 0)
    notas = argv[3]
    medida = argv[4] if len(argv) > 4 else None

    ini, fin = rango_por_nombre(notas, "posturas_atleta")
    cols = columnas(rom, org, ini, fin)
    print("  el bloque posturas_atleta va de 0x%04X a 0x%04X (%d bytes)"
          % (ini, fin, fin - ini))
    print("  troceado con las reglas de 0x69FE salen %d tiras, que producen "
          "%d bytes de dibujo: %d casillas de 8x8"
          % (len(cols), sum(c[2] for c in cols), sum(c[2] for c in cols) // 8))

    if not medida:
        return 0

    cabecera, por_prueba, papel_medido = lee_medida(medida)
    print("\n  medido en openMSX: %s lecturas del bloque en %s s emulados, con "
          "%s pasadas por 0x0038 de control"
          % (cabecera.get("lecturas"), cabecera.get("t"),
             cabecera.get("control_0x0038")))
    if int(cabecera.get("control_0x0038", 0)) == 0:
        raise SystemExit("  el control esta a cero: la medida no vale")

    # El cotejo que da valor a todo lo demas: cada byte que el MSX leyo, leido
    # con el mismo papel que le asigna el troceado.
    mio = papeles(rom, org, ini, fin)
    iguales, distintos = 0, []
    for addr, vistos in sorted(papel_medido.items()):
        if len(vistos) == 1 and mio.get(addr) in vistos:
            iguales += 1
        else:
            distintos.append((addr, mio.get(addr), sorted(vistos)))
    print("\n  el MSX leyo %d de los %d bytes del bloque, y el papel de cada uno"
          " -cuenta, literal o repetido- coincide con el troceado en %d y no "
          "coincide en %d" % (len(papel_medido), fin - ini, iguales,
                              len(distintos)))
    for addr, m, otros in distintos[:5]:
        print("    0x%04X: el troceado dice %s y el MSX lo lee como %s"
              % (addr, m, "/".join(otros)))
    if distintos:
        return 1

    print("\n  %-16s %8s %8s  tiras que toca" % ("prueba", "bytes", "tiras"))
    usadas = {}
    for ev in sorted(por_prueba):
        vistas = por_prueba[ev]
        cuales = [i for i, (a, z, _n) in enumerate(cols)
                  if any(a <= d < z for d in vistas)]
        usadas[ev] = set(cuales)
        print("  %-16s %8d %8d  de la %d a la %d"
              % (PRUEBAS[ev], len(vistas), len(cuales), cuales[0], cuales[-1]))

    todas = set(range(len(cols)))
    tocadas = set().union(*usadas.values())
    print("\n  tiras que no toca ninguna prueba en la atraccion: %d de %d"
          % (len(todas - tocadas), len(cols)))
    compartidas = set.intersection(*usadas.values()) if usadas else set()
    print("  tiras que usan las CUATRO: %d" % len(compartidas))
    for ev in sorted(usadas):
        solo = usadas[ev] - set().union(*(usadas[o] for o in usadas if o != ev))
        print("  solo %-16s %d tiras" % (PRUEBAS[ev], len(solo)))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
