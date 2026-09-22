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
        ("El atleta no elige sus dibujos: los reescribe cada cuadro",
         "<p>El número de patrón de cada sprite del atleta no está en ninguna "
         "tabla de posturas. Lo clava <b>una sola vez</b> 0x618E al montar la "
         "prueba, con un <code>ld (hl),a / add a,004h</code> que va dejando "
         "0x00, 0x04, 0x08… en los siete sprites. El sprite 1 pinta el patrón "
         "0x04 y lo pintará siempre.</p>"
         "<p>Lo que cambia cada cuadro son <b>los patrones</b>. 0x65AD saca de "
         "la tabla de 0x65F6 el guión de la postura; ese guión son ternas "
         "<code>(dy, dx, color)</code> que 0x65BE deja en las fichas de 0xE0D0, "
         "y lo cierra un byte 0x8N cuyo nibble bajo dice cuántos bloques de "
         "dibujos van detrás. 0x65D9 apunta el VDP a la VRAM 0x1800 —la tabla "
         "de patrones de sprites— y 0x65E5 los sube con el descompresor de "
         "0x69F9.</p>"
         "<p>De ahí salen las ropas. El sprite 1 es siempre el patrón 0x04, "
         "pero en unas posturas ese patrón trae unas zapatillas blancas y en "
         "otras no trae nada. Y como en el MSX1 manda el sprite de número más "
         "bajo, <b>el orden de las ternas dentro del guión es lo que decide qué "
         "pieza tapa a cuál</b>.</p>"),
        ("El orden de las pruebas lo dice la tabla, no los textos",
         "<p>Los cuatro rótulos están seguidos en la ROM desde 0x6F08 en el "
         "orden <code>DIVING</code>, <code>TRAMPOLINE</code>, "
         "<code>LONG HORSE</code>, <code>HORIZONTAL BAR</code>. <b>Ése no es el "
         "orden en que se juegan.</b> Quien elige es la tabla de cuatro punteros "
         "de 0x6F00, que 0x6E38 indexa con <code>0xE052 y 3</code>, y esa tabla "
         "los reordena: 0 <code>DIVING</code>, 1 <code>LONG HORSE</code>, "
         "2 <code>TRAMPOLINE</code>, 3 <code>HORIZONTAL BAR</code>. Leyendo los "
         "textos en vez de la tabla salen <b>la segunda y la tercera "
         "cambiadas</b>, que es exactamente lo que decía esta web hasta que se "
         "comprobó en el emulador leyendo la tabla de nombres como texto "
         "mientras la atracción juega las cuatro.</p>"
         "<p>0xE052 no se reinicia entre vueltas: sigue subiendo, y la prueba "
         "sale de sus dos bits bajos, así que la quinta vuelve a ser "
         "<code>DIVING</code> con el <code>STAGE</code> subido.</p>"),
        ("La fuente del marcador no está en el cartucho",
         "<p>El marcador escribe letras y cifras como números de casilla en "
         "ASCII directo, y esas casillas no las dibuja el juego: 0x43BF toma el "
         "puntero <code>CGTBL</code> de 0x0004 —la tabla de caracteres de la "
         "<b>ROM del MSX</b>—, se salta 0x180 bytes para empezar en el "
         "<code>'0'</code> y sube 48 caracteres a la VRAM. El cartucho sólo pone "
         "de su bolsillo <b>seis</b>, con dos guiones comprimidos: los tiles "
         "0x3A y 0x3B (de ahí sale el guión del <code>1P-000000</code>) y los "
         "0x5C a 0x5F. Cotejado: la fuente de la BIOS más esos retoques da los "
         "384 bytes de la VRAM en los tres tercios, sin una diferencia.</p>"),
        ("El público aplaude con dos guiones, y uno es la cola del otro",
         "<p>Las gradas se animan alternando sobre la VRAM 0x2158 dos guiones "
         "seguidos del cartucho, 0x4976 y 0x498E. El primero no es un bloque "
         "aparte: es <b>la cola del flujo común</b> que 0x4891 descomprime al "
         "montar cualquier prueba, y que además se vuelca suelto para animar. "
         "431 volcados en los primeros 60 segundos, medidos con un punto de "
         "ruptura en 0x440D.</p>"),
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
        ("The athlete does not pick its drawings: it rewrites them every frame",
         "<p>The pattern number of each of the athlete's sprites is in no pose "
         "table at all. 0x618E nails it down <b>once</b>, when the event is set "
         "up, with an <code>ld (hl),a / add a,004h</code> that leaves 0x00, "
         "0x04, 0x08… across the seven sprites. Sprite 1 draws pattern 0x04, "
         "and it always will.</p>"
         "<p>What changes every frame are <b>the patterns</b>. 0x65AD pulls the "
         "pose's script out of the table at 0x65F6; that script is triplets of "
         "<code>(dy, dx, colour)</code> which 0x65BE writes into the sprite "
         "entries at 0xE0D0, closed by a 0x8N byte whose low nibble says how "
         "many blocks of drawings follow. 0x65D9 points the VDP at VRAM 0x1800 "
         "—the sprite pattern table— and 0x65E5 uploads them with the "
         "decompressor at 0x69F9.</p>"
         "<p>That is where the clothing comes from. Sprite 1 is always pattern "
         "0x04, but in some poses that pattern holds a pair of white shoes and "
         "in others it holds nothing. And since the lowest-numbered sprite wins "
         "on the MSX1, <b>the order of the triplets inside the script is what "
         "decides which piece covers which</b>.</p>"),
        ("The order of the events is in the table, not in the texts",
         "<p>The four labels sit back to back in the ROM from 0x6F08 in the "
         "order <code>DIVING</code>, <code>TRAMPOLINE</code>, "
         "<code>LONG HORSE</code>, <code>HORIZONTAL BAR</code>. <b>That is not "
         "the order they are played in.</b> What picks is the four-pointer table "
         "at 0x6F00, which 0x6E38 indexes with <code>0xE052 and 3</code>, and "
         "that table reorders them: 0 <code>DIVING</code>, 1 "
         "<code>LONG HORSE</code>, 2 <code>TRAMPOLINE</code>, 3 "
         "<code>HORIZONTAL BAR</code>. Reading the texts instead of the table "
         "swaps <b>the second and the third</b> — exactly what this site said "
         "until it was checked in the emulator, reading the name table as text "
         "while the attract mode plays all four.</p>"
         "<p>0xE052 is not reset between rounds: it keeps climbing, and the "
         "event comes from its two low bits, so the fifth is "
         "<code>DIVING</code> again with the <code>STAGE</code> gone up.</p>"),
        ("The scoreboard font is not in the cartridge",
         "<p>The scoreboard writes letters and digits as tile numbers in plain "
         "ASCII, and the cartridge does not draw those tiles: 0x43BF takes the "
         "<code>CGTBL</code> pointer at 0x0004 —the character table of the "
         "<b>MSX ROM</b>—, skips 0x180 bytes to start at <code>'0'</code> and "
         "uploads 48 characters to VRAM. The cartridge supplies only <b>six</b> "
         "of its own, through two compressed scripts: tiles 0x3A and 0x3B (where "
         "the dash in <code>1P-000000</code> comes from) and 0x5C to 0x5F. "
         "Checked: the BIOS font plus those touch-ups gives the 384 bytes in "
         "VRAM across all three thirds, without a single difference.</p>"),
        ("The crowd claps with two scripts, and one is the tail of the other",
         "<p>The stands are animated by alternating two consecutive cartridge "
         "scripts, 0x4976 and 0x498E, over VRAM 0x2158. The first is not a "
         "separate block: it is <b>the tail of the common stream</b> that 0x4891 "
         "decompresses when setting up any event, and which is also dumped on "
         "its own to animate. 431 dumps in the first 60 seconds, measured with a "
         "breakpoint at 0x440D.</p>"),
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
    ("prueba_palanca.png",
     "<b>DIVING</b>, la primera prueba. La pantalla no está guardada en ningún "
     "sitio del cartucho: los dibujos —patrones y colores— se descomprimen aquí "
     "desde la ROM con el mismo formato que el Z80, y el mapa de casillas y los "
     "sprites salen de la VRAM del MSX, porque los compone el motor de la prueba "
     "mientras corre. Los 7.680 bytes de dibujo que salen de la ROM cuadran "
     "<b>byte a byte</b> con los de esa VRAM",
     "<b>DIVING</b>, the first event. The screen is stored nowhere in the "
     "cartridge: the drawings —patterns and colours— are decompressed here from "
     "the ROM with the same format the Z80 uses, and the tile map and the "
     "sprites come from the MSX's VRAM, because the event's engine composes them "
     "as it runs. The 7,680 drawing bytes coming out of the ROM match that VRAM "
     "<b>byte for byte</b>"),
    ("prueba_palanca_agua.png",
     "El mismo salto un segundo después: el chapoteo de la entrada en el agua. "
     "Los cinco jueces de la mesa blanca puntúan el intento, y sus notas "
     "aparecen ahí mismo",
     "The same dive a second later: the splash of the entry. The five judges at "
     "the white table score the attempt, and their marks appear right there"),
    ("prueba_potro.png",
     "<b>LONG HORSE</b>, la segunda. El atleta corre por la pista hacia el "
     "trampolín de batida y el potro. En esta escena el público está en su "
     "<b>segunda fase</b> de aplauso, la que el cartucho guarda en 0x498E",
     "<b>LONG HORSE</b>, the second. The athlete runs down the track towards the "
     "springboard and the horse. In this scene the crowd is on its <b>second "
     "clapping frame</b>, the one the cartridge keeps at 0x498E"),
    ("prueba_trampolin.png",
     "<b>TRAMPOLINE</b>, la tercera, y la única con marcador de "
     "<code>TIME</code>: su guión de rótulos (0x4560) es el único que escribe "
     "esa palabra, y sólo se vuelca para esta prueba",
     "<b>TRAMPOLINE</b>, the third, and the only one with a <code>TIME</code> "
     "readout: its label script (0x4560) is the only one that writes that word, "
     "and it is dumped for this event alone"),
    ("prueba_barra.png",
     "<b>HORIZONTAL BAR</b>, la cuarta, con el gimnasta en pleno giro. Es la "
     "prueba con más fotogramas propios: siete de las 52 tiras del bloque de "
     "posturas no las usa ninguna otra",
     "<b>HORIZONTAL BAR</b>, the fourth, with the gymnast mid-swing. It is the "
     "event with the most frames of its own: seven of the 52 strips in the pose "
     "block are used by no other"),
    ("atleta.png",
     "Las 45 posturas del atleta, montadas como las monta el cartucho: 0x65AD "
     "indexa la tabla de guiones de 0x65F6, y cada guión reparte las fichas "
     "<b>y sube a la VRAM los patrones de esa postura</b>. Fíjese en el "
     "calzado: en unas posturas la ficha blanca dibuja unas zapatillas y en "
     "otras no dibuja nada, y sin embargo es siempre <b>el mismo sprite con el "
     "mismo número de patrón</b>. Lo que cambia es el dibujo que hay debajo. "
     "Y tras la fila en blanco, <b>las dieciocho posturas que usa la piscina "
     "—de la 0 a la 17— tal y como las pinta la piscina</b>: en bañador, porque "
     "0x63E8 permuta los planos de las fichas en cada cuadro de esa prueba. En "
     "los cinco volcados de VRAM del emulador el atleta coincide píxel a píxel "
     "con estas figuras, permuta incluida. <b>La primera de la sexta fila (la "
     "40) se corta por la barra</b>: el dibujo lleva dos columnas transparentes "
     "para que el poste de la barra fija, que es un tile, asome a través del "
     "atleta; aquí va sobre el decorado real del volcado de la barra, que es "
     "como se ve",
     "The athlete's 45 poses, built the way the cartridge builds them: 0x65AD "
     "indexes the script table at 0x65F6, and each script lays out the sprite "
     "entries <b>and uploads that pose's patterns to VRAM</b>. Look at the "
     "footwear: in some poses the white entry draws a pair of shoes and in "
     "others it draws nothing at all, yet it is always <b>the same sprite with "
     "the same pattern number</b>. What changes is the drawing underneath. "
     "And after the blank row, <b>the eighteen poses the pool uses —0 to 17— "
     "the way the pool draws them</b>: in a swimsuit, because 0x63E8 swaps the "
     "entries' planes on every frame of that event. In the emulator's five VRAM "
     "dumps the athlete matches these figures pixel for pixel, swap included. "
     "<b>The first one on the sixth row (pose 40) is cut by the bar</b>: the "
     "drawing has two transparent columns so that the post of the horizontal "
     "bar, which is a tile, shows through the athlete; here it sits on the real "
     "scenery from the bar's dump, which is how it looks"),
    ("atleta_por_capas.png",
     "La <b>misma pose</b> del atleta —la de pie— con sus <b>dos ropas</b>. "
     "Arriba, las cuatro fichas en el orden del guión, sueltas y montadas: "
     "rojo y blanco en los dos primeros sprites, que en el MSX1 son los de "
     "encima, y se le ven la camiseta y las botas; así sale en el potro, la "
     "cama elástica y la barra. Abajo, lo que hace <b>la piscina en cada "
     "cuadro</b>: 0x63E8 permuta los sprites 0-1 con los 2-3 (INTERCAMBIA, "
     "ocho bytes) y vuelve a clavar los patrones, de modo que los dos "
     "amarillos pasan delante y tapan el rojo y el blanco. Mismo guión, mismos "
     "dibujos, y el atleta se tira al agua en bañador. El color no está en el "
     "patrón sino en el byte 3 de cada ficha, y la ropa no la decide el dibujo "
     "sino <b>el plano</b>",
     "The <b>same pose</b> of the athlete —standing— in its <b>two outfits</b>. "
     "Top: the four entries in script order, apart and assembled: red and "
     "white on the first two sprites, which on the MSX1 are the topmost, so "
     "the shirt and the boots show; that is how he looks on the horse, the "
     "trampoline and the bar. Bottom: what <b>the pool does every frame</b>: "
     "0x63E8 swaps sprites 0-1 with 2-3 (INTERCAMBIA, eight bytes) and pins "
     "the pattern numbers back, so the two yellows come to the front and cover "
     "the red and the white. Same script, same drawings, and the athlete dives "
     "in a swimsuit. The colour is not in the pattern but in byte 3 of each "
     "entry, and the outfit is decided not by the drawing but by <b>the "
     "plane</b>"),
    ("sprites.png",
     "Los tiles de una prueba, con su color, dibujados desde la ROM por "
     "<code>tools/graficos.py</code> descomprimiendo sus rachas con el mismo "
     "formato que el Z80. Son las piezas del ESCENARIO: el atleta no está "
     "aquí, porque sus dibujos no viven en esta tabla —el guion de cada "
     "postura reescribe la tabla de patrones de sprites cada cuadro—",
     "One event's tiles, with their colour, drawn from the ROM by "
     "<code>tools/graficos.py</code> by decompressing its runs with the same "
     "format the Z80 uses. These are the SETTING's pieces: the athlete is not "
     "here, because its drawings do not live in this table —each pose's script "
     "rewrites the sprite pattern table every frame"),
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
