# Hallazgos

## Las cuatro pruebas están escritas en la ROM

Sus rótulos, en 0x6EED, dicen DIVING, TRAMPOLINE, HORSE y HORIZONTAL: la tanda de
gimnasia y saltos de Hyper Sports, en el primero de los cartuchos de la
conversión para MSX. Se juega por turnos, y la palabra QUALIFY (0x6F47) marca el
paso a la siguiente ronda.

## Todo el juego es una interrupción

INIT cae en un `jr` muerto en 0x40A4 y no vuelve. Cada cuadro la interrupción lee
el estado de 0xE000 y salta por la tabla de manejadores de 0x40C2; dentro de cada
manejador el subestado de 0xE001 mueve las fases.

## Dos intérpretes de dibujo distintos

El cartucho guarda guiones, no pantallas. 0x405E copia bytes a la tabla de
nombres con saltos de destino; 0x440D descomprime por rachas a la tabla de
patrones. Los dos escriben en la VRAM por el mismo núcleo `out (c),a` reubicado
en 0x4010.

## Dos jugadores que se turnan el mismo bloque

El intento en curso corre sobre 0xE050. Al cambiar de turno, 0x413E intercambia
el bloque entero con el de 0xE080, así que el resto del código se escribe una vez
y nunca tiene que preguntar de quién es el turno.

## Comparte el reproductor de sonido, y no lleva marca oculta

El reproductor de tres canales de 0x7C3D es el mismo armazón que Konami reutilizó
entre sus cartuchos de MSX. Y a diferencia de algunos de la casa, este no lleva
marca oculta al final de la ROM: el formato que documentó Manuel Pazos
([@ManuelPazosMSX](https://twitter.com/ManuelPazosMSX)) -el título en katakana
cerrado por un 0xAA- no está. Los últimos bytes son datos del reproductor.
