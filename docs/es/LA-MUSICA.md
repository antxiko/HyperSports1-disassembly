# La música

Todo lo que suena aquí sale de ejecutar el motor de sonido del cartucho (`ACTUALIZA_SONIDO`, 0x7C3D, y la rutina de petición de 0x7B8F, que le reparte las voces; lo llama la interrupción) en un Z80 emulado, cuadro a cuadro y a 60 por segundo, igual que lo llama el juego. Lo que el motor escribe en el PSG pasa a sonido con un AY-3-8910 (`tools/musica.py`). Cada MP3 es la pieza entera hasta donde vuelve a empezar, más 8 segundos de la vuelta apagándose; las que no se repiten acaban donde acaba el motor.

## Cotejado con openMSX

Las escrituras al PSG se han comparado cuadro a cuadro con las de openMSX (C-BIOS MSX1 japonés). En todos los cuadros el PSG queda igual:

- la pieza 0x93 entera, 194 cuadros;
- la pieza 0x96 entera, 314 cuadros;
- la pieza 0x99 entera, 266 cuadros, tal como el juego la pide.

El timbre no está cotejado: es el de un AY-3-8910 de manual, no una grabación del emulador. Las sondas están en `tools/omsx_psg.tcl` y `tools/coteja_psg.py`.

## Cómo se pide una pieza

La rutina de 0x7B8F recibe el número en A (la de 0x7B89 solo suena en partida, con el bit 6 de 0xE002). Los números por debajo de 0x4D son efectos; del 0x4D al 0x92, dos voces, y del 0x93 en adelante, tres. Las voces ocupan 11 bytes cada una desde 0xE010 y 0xE043 guarda la copia del mezclador del PSG, que el arranque deja en 0xB8. Las pistas «de la tabla» están en la tabla pero ninguna rutina las pide con un `ld a`. Los nombres con número de dirección son los que el listado aún no ha bautizado.

## Las músicas

**La pieza del 0x63CA** (0x93)

Lo pide `MOTOR_ATLETA_63CA`; dura 3,2 s.

<audio controls preload="none" src="../audio/musica_93.mp3?v=1ceb4dc9"></audio>

**La pieza de la marca medida** (0x96)

Lo pide `MIDE_MARCA_6EB7`; dura 5,2 s.

<audio controls preload="none" src="../audio/musica_96.mp3?v=67a891a4"></audio>

**La pieza del rótulo** (0x99)

Lo pide `ESTADO_ROTULO`: un rótulo con sonido y una espera; dura 4,4 s.

<audio controls preload="none" src="../audio/musica_99.mp3?v=0ec2742d"></audio>

**Una pista de la tabla** (0x92)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 3,2 s.

<audio controls preload="none" src="../audio/musica_92.mp3?v=38115eeb"></audio>

**Otra pista de la tabla** (0x94)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 5,2 s.

<audio controls preload="none" src="../audio/musica_94.mp3?v=a696ca68"></audio>

**Una tercera pista de la tabla** (0x95)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 5,2 s.

<audio controls preload="none" src="../audio/musica_95.mp3?v=894e1c90"></audio>

**Una cuarta pista de la tabla** (0x97)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 4,4 s.

<audio controls preload="none" src="../audio/musica_97.mp3?v=6be29686"></audio>

**Una quinta pista de la tabla** (0x98)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 4,4 s.

<audio controls preload="none" src="../audio/musica_98.mp3?v=02a89370"></audio>

**Una sexta pista de la tabla** (0x9A)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 4,4 s.

<audio controls preload="none" src="../audio/musica_9A.mp3?v=6b7f622e"></audio>

**Una séptima pista de la tabla** (0x9B)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 4,4 s.

<audio controls preload="none" src="../audio/musica_9B.mp3?v=243f1123"></audio>
