#!/usr/bin/env python3
"""Genera la portada de la web, en los dos idiomas.

El diseno es el compartido por la serie (tools/estilo_web.py) y la pagina sale
autocontenida, con las imagenes embebidas como data URI.

Las imagenes NO son ilustraciones ni capturas: se dibujan a partir de los
propios bytes de la ROM por tools/graficos.py, ejecutando en Python el mismo
descompresor de rachas que el Z80 corre en 0x440D. Ninguna se ha retocado.

Uso: make_web.py <docs/imagenes> <salida.html> <idioma>
"""
import base64
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from estilo_web import ESTILO                                   # noqa: E402

# Las cifras salen de contar sobre el listado generado, no de escribirlas a ojo:
# 16384 = 5953 + 10431, que es lo que imprime tools/presupuesto.py (make sanity).
# RUTINAS son las etiquetas de codigo con nombre propio (directiva L del .notes).
# EVENTOS son las cuatro pruebas: DIVING, TRAMPOLINE, LONG HORSE y HORIZONTAL BAR.
CODIGO = 5953
DATOS = 10431
RUTINAS = 387
EVENTOS = 4


def mil(n, idioma):
    return f"{n:,}".replace(",", "." if idioma == "es" else ",")


TXT = {
    "es": dict(
        titulo="Hyper Sports 1 — desensamblado comentado",
        aviso="<b>Aquí no hay ninguna ilustración ni captura.</b> Los gráficos "
              "están <b>dibujados desde los bytes de la ROM</b>, ejecutando en "
              "Python el mismo descompresor de rachas que corre el Z80. El "
              "listado y las cifras salen del binario y se reproducen con "
              "<code>make</code>.",
        claim="Las cuatro pruebas de gimnasia y saltos de Hyper Sports en un "
              "cartucho de 16 KB: salto de trampolín, salto del potro, barra "
              "horizontal y saltos de natación, para dos jugadores por turnos, "
              "movido todo por la interrupción de cada cuadro.",
        ficha=["Konami · <b>© Konami 1984</b>",
               "Cartucho <b>RC-715</b>, 16 KB",
               "MSX1 · <b>página 1</b>", "Volcado <b>440dae57…</b>"],
        nav=[("#numbers", "Las cifras"), ("#findings", "Hallazgos"),
             ("#screens", "Lo que dibuja")],
        docnav=[("EMPEZAR.html", "Empezar"), ("EL-JUEGO.html", "El juego"),
                ("EL-CARTUCHO.html", "El cartucho"),
                ("EL-CODIGO.html", "El código"),
                ("HALLAZGOS.html", "Hallazgos"),
                ("EN-EL-EMULADOR.html", "En el emulador"),
                ("PREGUNTAS-ABIERTAS.html", "Preguntas abiertas")],
        otro=("../", "In English"),
        h_num="El cartucho en cifras", h_find="Lo que apareció al desmontarlo",
        h_scr="Lo que el cartucho dibuja",
        cifras=[("100 %", "del binario explicado"),
                (str(RUTINAS), "rutinas identificadas"),
                (str(EVENTOS), "pruebas"),
                (mil(CODIGO, "es"), "bytes de código"),
                (mil(DATOS, "es"), "bytes de datos"),
                ("0", "bytes sin identificar")],
        nota_scr="Debajo de la imagen está de dónde sale y qué se está viendo.",
        pie_leg="Esto es trabajo de documentación y preservación: el código y "
                "los gráficos siguen siendo de sus autores y de Konami, y la "
                "imagen del cartucho no se distribuye.",
    ),
    "en": dict(
        titulo="Hyper Sports 1 — a commented disassembly",
        aviso="<b>There is not one illustration or capture here.</b> The "
              "graphics are <b>drawn from the bytes of the ROM</b>, by running "
              "in Python the same run-length decompressor the Z80 runs. The "
              "listing and the numbers come from the binary and are "
              "reproducible with <code>make</code>.",
        claim="The four gymnastics and diving events of Hyper Sports in a 16 KB "
              "cartridge: trampoline, long horse, horizontal bar and diving, "
              "for two players taking turns, all driven by the per-frame "
              "interrupt.",
        ficha=["Konami · <b>© Konami 1984</b>",
               "An <b>RC-715</b> 16 KB cartridge",
               "MSX1 · <b>page 1</b>", "Dump <b>440dae57…</b>"],
        nav=[("#numbers", "The numbers"), ("#findings", "What turned up"),
             ("#screens", "What it draws")],
        docnav=[("GETTING-STARTED.html", "Getting started"),
                ("THE-GAME.html", "The game"),
                ("THE-CARTRIDGE.html", "The cartridge"),
                ("THE-CODE.html", "The code"),
                ("FINDINGS.html", "Findings"),
                ("IN-THE-EMULATOR.html", "In the emulator"),
                ("OPEN-QUESTIONS.html", "Open questions")],
        otro=("es/", "En castellano"),
        h_num="The cartridge in numbers",
        h_find="What turned up when we took it apart",
        h_scr="What the cartridge draws",
        cifras=[("100%", "of the binary explained"),
                (str(RUTINAS), "routines identified"),
                (str(EVENTOS), "events"),
                (mil(CODIGO, "en"), "bytes of code"),
                (mil(DATOS, "en"), "bytes of data"),
                ("0", "bytes unidentified")],
        nota_scr="Under the picture is where it comes from and what is on it.",
        pie_leg="This is documentation and preservation work: the code and "
                "artwork still belong to their authors and to Konami, and the "
                "cartridge image is not distributed.",
    ),
}

HALLAZGOS = {
    "es": [
        ("Las cuatro pruebas están escritas en la ROM",
         "<p>Sus rótulos, en 0x6EED, dicen <code>DIVING</code>, "
         "<code>TRAMPOLINE</code>, <code>HORSE</code> y <code>HORIZONTAL</code>: "
         "el salto de natación, el trampolín, el potro y la barra fija. Es la "
         "tanda de gimnasia y saltos de <em>Hyper Sports</em> repartida en el "
         "primero de los cartuchos de la conversión para MSX. Se juega por "
         "turnos, con la palabra <code>QUALIFY</code> para pasar de fase.</p>"),
        ("Un solo bucle muerto y toda la máquina en la interrupción",
         "<p>INIT engancha la interrupción a 0x402C y cae en un <code>jr</code> "
         "a sí mismo. A partir de ahí <b>el programa principal no hace nada</b>: "
         "cada cuadro la interrupción lee 0xE000 (el estado), salta por la tabla "
         "de manejadores de 0x40C2, y dentro de cada uno el byte 0xE001 reparte "
         "los subestados. El bit6 de 0xE002 marca la demo.</p>"),
        ("Dos intérpretes de dibujo distintos",
         "<p>El cartucho no guarda pantallas: guarda guiones. Uno, en 0x405E, "
         "copia byte a byte a la tabla de nombres con saltos de destino (0xFE) y "
         "un fin (0xFF); el otro, en 0x440D, <b>descomprime por rachas</b> con "
         "un byte de cuenta cuyo bit alto distingue copia literal de relleno. "
         "Las figuras de esta web salen de ejecutar ese segundo en Python.</p>"),
        ("El sonido es el reproductor de tres canales de la casa",
         "<p>El motor de 0x7C3D recorre tres fichas de once bytes (0xE010), lee "
         "las melodías con su intérprete de órdenes y escribe el PSG por la "
         "BIOS. Es el mismo armazón de reproductor que Konami repartía entre sus "
         "cartuchos de MSX, con su tabla de tonos y sus efectos.</p>"),
        ("Dos jugadores que se turnan el mismo bloque de estado",
         "<p>El estado de la prueba vive en 0xE050 para el jugador 1 y en 0xE080 "
         "para el 2. Al cambiar de turno, 0x413E <b>intercambia los dos bloques "
         "enteros</b> con una sola rutina de 32 bytes, así que el resto del "
         "código siempre trabaja sobre el mismo sitio sin enterarse de a quién "
         "le toca.</p>"),
        ("No lleva la marca oculta de Konami",
         "<p>Muchos cartuchos de la casa esconden al final de la ROM su número "
         "de catálogo y el título en katakana; lo descubrió <b>Manuel Pazos</b> "
         "(<a href=\"https://twitter.com/ManuelPazosMSX\">@ManuelPazosMSX</a>). "
         "Aquí no está: los últimos bytes son datos del reproductor de sonido, "
         "sin el 0xAA que cierra la marca. El RC-715 viene del catálogo, no del "
         "binario.</p>"),
    ],
    "en": [
        ("The four events are written into the ROM",
         "<p>Their labels, at 0x6EED, read <code>DIVING</code>, "
         "<code>TRAMPOLINE</code>, <code>HORSE</code> and "
         "<code>HORIZONTAL</code>: springboard diving, trampoline, the long "
         "horse and the horizontal bar. It is <em>Hyper Sports</em>' gymnastics "
         "and diving set, in the first of the cartridges of the MSX conversion. "
         "It is played in turns, with the word <code>QUALIFY</code> to move "
         "on.</p>"),
        ("One dead loop, and the whole machine in the interrupt",
         "<p>INIT hooks the interrupt to 0x402C and falls into a <code>jr</code> "
         "to itself. From there <b>the main program does nothing</b>: each frame "
         "the interrupt reads 0xE000 (the state), jumps through the handler "
         "table at 0x40C2, and inside each handler the byte 0xE001 splits the "
         "sub-states. Bit 6 of 0xE002 marks the demo.</p>"),
        ("Two different drawing interpreters",
         "<p>The cartridge stores no screens: it stores scripts. One, at 0x405E, "
         "copies byte by byte into the name table with destination jumps (0xFE) "
         "and an end (0xFF); the other, at 0x440D, <b>decompresses by runs</b> "
         "with a count byte whose top bit tells a literal copy from a fill. This "
         "site's figures come from running that second one in Python.</p>"),
        ("The sound is the house's three-channel player",
         "<p>The engine at 0x7C3D walks three eleven-byte records (0xE010), "
         "reads the melodies with its command interpreter and writes the PSG "
         "through the BIOS. It is the same player framework Konami spread across "
         "its MSX cartridges, with its tone table and its effects.</p>"),
        ("Two players sharing one state block by turns",
         "<p>The event state lives at 0xE050 for player 1 and at 0xE080 for "
         "player 2. On a change of turn, 0x413E <b>swaps the two whole blocks</b> "
         "with a single 32-byte routine, so the rest of the code always works on "
         "the same place without knowing whose turn it is.</p>"),
        ("It does not carry Konami's hidden mark",
         "<p>Many of the house's cartridges hide their catalogue number and the "
         "title in katakana at the end of the ROM; <b>Manuel Pazos</b> "
         "(<a href=\"https://twitter.com/ManuelPazosMSX\">@ManuelPazosMSX</a>) "
         "found it. Here it is absent: the last bytes are sound-player data, "
         "with no 0xAA to close the mark. RC-715 comes from the catalogue, not "
         "the binary.</p>"),
    ],
}

GALERIA = [
    ("sprites.png",
     "Las figuras y los tiles de una prueba, dibujados desde la ROM por "
     "<code>tools/graficos.py</code> descomprimiendo sus rachas con el mismo "
     "formato que el Z80. Son las piezas con las que se arma el atleta y su "
     "escenario",
     "The figures and tiles of one event, drawn from the ROM by "
     "<code>tools/graficos.py</code> by decompressing its runs with the same "
     "format the Z80 uses. They are the pieces the athlete and its setting are "
     "built from"),
]


def img64(ruta):
    with open(ruta, "rb") as f:
        return "data:image/png;base64," + base64.b64encode(f.read()).decode()


def main(argv):
    if len(argv) < 4:
        print(__doc__)
        return 2
    imgdir, salida, idioma = argv[1:4]
    t = TXT[idioma]

    # El "logotipo" de la cabecera no es un montaje ni una captura: es el rotulo
    # que el propio cartucho pinta, las 22 x 2 casillas del guion de 0x4335,
    # dibujadas desde la ROM por graficos.py. Si el PNG no esta, se cae al texto.
    ruta_logo = os.path.join(imgdir, "rotulo.png")
    cabecera = (f'<img src="{img64(ruta_logo)}" alt="Hyper Sports 1">'
                if os.path.exists(ruta_logo) else "<h1>Hyper Sports 1</h1>")

    nav = "".join(f'<a href="{h}">{x}</a>' for h, x in t["nav"])
    nav += "".join(f'<a href="{h}">{x}</a>' for h, x in t["docnav"])
    nav += (f'<a href="{t["otro"][0]}" style="margin-left:auto;color:var(--oro)">'
            f'{t["otro"][1]}</a>')

    cifras = "".join(f'<div class="cifra"><b>{v}</b><span>{e}</span></div>'
                     for v, e in t["cifras"])
    halls = "".join(f'<div class="hall"><h3>{tit}</h3>{cuerpo}</div>'
                    for tit, cuerpo in HALLAZGOS[idioma])
    imgs = ""
    faltan = []
    for fich, es, en in GALERIA:
        ruta = os.path.join(imgdir, fich)
        if not os.path.exists(ruta):
            faltan.append(fich)
            continue
        pie = es if idioma == "es" else en
        imgs += (f'<figure><img src="{img64(ruta)}" alt="{pie}">'
                 f'<figcaption>{pie}</figcaption></figure>')
    if faltan:
        print("  (faltan %d imagenes: %s)" % (len(faltan), " ".join(faltan)))

    html = f"""<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>{t['titulo']}</title>
<style>{ESTILO}</style>
<header class="top">
  {cabecera}
  <p class="claim">{t['claim']}</p>
  <p class="ficha">{' · '.join(t['ficha'])}</p>
</header>
<p class="ficha" style="border:1px solid var(--oro);padding:.8em 1em;margin:1.5em 0">
{t['aviso']}</p>
<nav>{nav}</nav>
<section id="numbers">
  <h2>{t['h_num']}</h2>
  <div class="cifras">{cifras}</div>
</section>
<section id="findings"><h2>{t['h_find']}</h2>{halls}</section>
<section id="screens">
  <h2>{t['h_scr']}</h2>
  <p class="n">{t['nota_scr']}</p>
  <div class="galeria">{imgs}</div>
</section>
<footer><p>{t['pie_leg']}</p></footer>
"""
    with open(salida, "w", encoding="utf-8") as f:
        f.write(html)
    print("  %s: %d KB (%s)" % (salida, len(html) // 1024, idioma))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
