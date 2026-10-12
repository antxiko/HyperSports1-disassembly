#!/usr/bin/env python3
"""La musica del cartucho, ejecutando su motor de sonido (ver motor_musica.py).

Pide el sonido con la rutina de 0x7B8F (`SUMA_BONUS_7B8F` en el listado, A =
numero; la entrada 0x7B89 solo suena en partida) y corre `ACTUALIZA_SONIDO`
(0x7C3D), el reproductor de cada cuadro. Tres voces de 11 bytes desde 0xE010;
la copia del registro 7 del PSG, en 0xE043.
Uso:  musica.py registros 0x93 [cuadros] | mp3 0x93 f.mp3 | todas docs/audio
      musica.py barrido 0x80 0xFF | emu
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import motor_musica  # noqa: E402
from motor_musica import P  # noqa: E402

TABLA = "ninguna llamada directa: está en la tabla de pistas"

PIEZAS = [
    P(0x93, "La pieza del 0x63CA", "The tune at 0x63CA",
      "`MOTOR_ATLETA_63CA`"),
    P(0x96, "La pieza de la marca medida", "The measured-mark tune",
      "`MIDE_MARCA_6EB7`"),
    P(0x99, "La pieza del rótulo", "The sign tune",
      "`ESTADO_ROTULO`: un rótulo con sonido y una espera"),
    P(0x92, "Una pista de la tabla", "A track in the table", TABLA),
    P(0x94, "Otra pista de la tabla", "Another track in the table", TABLA),
    P(0x95, "Una tercera pista de la tabla", "A third track in the table",
      TABLA),
    P(0x97, "Una cuarta pista de la tabla", "A fourth track in the table",
      TABLA),
    P(0x98, "Una quinta pista de la tabla", "A fifth track in the table",
      TABLA),
    P(0x9A, "Una sexta pista de la tabla", "A sixth track in the table",
      TABLA),
    P(0x9B, "Una séptima pista de la tabla", "A seventh track in the table",
      TABLA),
]

PAGINA = motor_musica.pagina_basica(
    "`ACTUALIZA_SONIDO`, 0x7C3D, y la rutina de petición de 0x7B8F, que le "
    "reparte las voces; lo llama la interrupción",
    "`ACTUALIZA_SONIDO`, 0x7C3D, and the request routine at 0x7B8F, which "
    "hands it the voices; the interrupt calls it",
    "C-BIOS MSX1 japonés",
    [("la pieza 0x93 entera, 194 cuadros",
      "tune 0x93, whole, 194 frames"),
     ("la pieza 0x96 entera, 314 cuadros",
      "tune 0x96, whole, 314 frames"),
     ("la pieza 0x99 entera, 266 cuadros, tal como el juego la pide",
      "tune 0x99, whole, 266 frames, just as the game asks for it")],
    [("Cómo se pide una pieza",
      "La rutina de 0x7B8F recibe el número en A (la de 0x7B89 solo suena en "
      "partida, con el bit 6 de 0xE002). Los números por debajo de 0x4D son "
      "efectos; del 0x4D al 0x92, dos voces, y del 0x93 en adelante, tres. "
      "Las voces ocupan 11 bytes cada una desde 0xE010 y 0xE043 guarda la "
      "copia del mezclador del PSG, que el arranque deja en 0xB8. Las "
      "pistas «de la tabla» están en la tabla pero ninguna rutina las pide "
      "con un `ld a`. Los nombres con número de dirección son los que el "
      "listado aún no ha bautizado.",
      "How a piece is asked for",
      "The routine at 0x7B8F takes the number in A (the one at 0x7B89 only "
      "sounds during a game, bit 6 of 0xE002). Numbers below 0x4D are "
      "effects; 0x4D to 0x92, two voices, and from 0x93 up, three. The "
      "voices take 11 bytes each from 0xE010 and 0xE043 holds the copy of "
      "the PSG mixer, which start-up leaves at 0xB8. The tracks marked "
      "«in the table» are in the table but no routine asks for them with an "
      "`ld a`. Names carrying an address are ones the listing has not named "
      "yet.")])

CFG = dict(rom="hypersports1.rom", org=0x4000, frame=0x7C3D, pide=0x7B8F,
           ram=(0xE010, 0xE034), ram0=[(0xE043, 0xB8)],
           excluye=[0xE019, 0xE024, 0xE02F], hz=60, psg0={7: 0xB8},
           piezas=PIEZAS, pagina=PAGINA,
           cotejado=[(0x93, 194, None), (0x96, 314, None)])

if __name__ == "__main__":
    sys.exit(motor_musica.main(CFG, sys.argv[1:]))
