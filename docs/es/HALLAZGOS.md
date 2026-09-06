# Hallazgos

## El orden de las pruebas lo dice la tabla, no los textos

Los cuatro rótulos están seguidos en la ROM desde 0x6F08 en el orden DIVING,
TRAMPOLINE, LONG HORSE, HORIZONTAL BAR. **Ése no es el orden en que se juegan.**
Quien elige es la tabla de cuatro punteros de 0x6F00, que 0x6E38 indexa con
`0xE052 y 3`, y esa tabla los reordena: 0 DIVING, 1 LONG HORSE, 2 TRAMPOLINE,
3 HORIZONTAL BAR. Leyendo los textos en vez de la tabla salen **la segunda y la
tercera cambiadas**, que es justo lo que decía esta web hasta que se comprobó en
el emulador leyendo la tabla de nombres como texto mientras la atracción juega
las cuatro.

## La fuente del marcador no está en el cartucho

El marcador escribe letras y cifras como números de casilla en ASCII directo, y
esas casillas no las dibuja el juego: 0x43BF toma el puntero `CGTBL` de 0x0004
—la tabla de caracteres de la **ROM del MSX**—, se salta 0x180 bytes para empezar
en el `'0'` y sube 48 caracteres a la VRAM, en los tres tercios. El cartucho sólo
pone de su bolsillo **seis**, con dos guiones comprimidos: los tiles 0x3A y 0x3B
—de ahí sale el guión del `1P-000000`— y los 0x5C a 0x5F.

Cotejado: la fuente de la BIOS más esos retoques da los 384 bytes que hay en la
VRAM, en los tres tercios, sin una diferencia.

## El público aplaude con dos guiones, y uno es la cola del otro

Las gradas se animan alternando sobre la VRAM 0x2158 dos guiones seguidos del
cartucho, 0x4976 y 0x498E. El primero no es un bloque aparte: es **la cola del
flujo común** que 0x4891 descomprime al montar cualquier prueba, y que además se
vuelca suelto para animar. 431 volcados en los primeros 60 segundos, medidos con
un punto de ruptura en 0x440D.

Eso explica la única diferencia que aparece al cotejar los dibujos de la ROM
contra la VRAM: el volcado pilla una de las dos fases, y no siempre la misma en
los tres tercios —el juego sólo anima aquel donde las gradas se ven—.

## La pantalla de una prueba no está guardada en ninguna parte

DIBUJA_MARCO (0x4816) sube a la VRAM los dibujos de la prueba: cuatro bloques de
su lista más dos comunes, cada uno volcado en los tres tercios. Pero **el mapa de
casillas no lo escribe nadie de golpe**: lo va componiendo el motor de la prueba
mientras corre, casilla a casilla —1.692 escrituras a la tabla de nombres en los
primeros 22 segundos, todas por el intérprete de guiones de 0x405E—. Reproducir
la pantalla sería reproducir el juego, así que las escenas de esta web llevan los
dibujos de la ROM y el mapa de la VRAM del MSX, cotejados byte a byte.

Y las listas de bloques de 0x4861 **solapan a propósito**: la del evento 0
empieza en 0x4861 y la del 2 en 0x4869, así que las cuatro pruebas comparten
entradas de dos en dos.

## Los fotogramas del atleta son la quinta parte del cartucho

3.425 bytes, de 0x53EC a 0x614C, en 52 tiras. No los toca el descompresor
general: los lee DIBUJA_ATLETA con uno propio (0x69FE) en el que **el bit alto
significa lo contrario** —puesto copia literales, claro repite—, y que saca los
bytes al puerto del VDP sin pasar por la BIOS.

Que el formato esté bien leído no lo demuestra que las tiras encajen al final del
bloque: empezando en cualquier byte también encajan. Lo demuestra la medida. Un
punto de observación de lectura sobre el rango entero apunta, además de la
dirección, **el PC que la lee**: 0x69FE lee las cuentas, 0x6A09 los literales y
0x6A12 el byte que se repite. De los 3.425 bytes, el MSX leyó 2.912 en la
atracción, y el papel de los 2.912 coincide con el del troceado. Cero
discrepancias.

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
