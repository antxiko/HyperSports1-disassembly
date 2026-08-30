# El juego

Hyper Sports 1 es la mitad de gimnasia y saltos de Hyper Sports de Konami,
convertida al MSX. Tiene **cuatro pruebas**, y sus rótulos están escritos en la
ROM, en 0x6EED: DIVING, TRAMPOLINE, HORSE (el potro) y HORIZONTAL (la barra
fija).

## Por turnos

Dos jugadores juegan por turnos. El estado del intento en curso vive en 0xE050
para el jugador 1 y en 0xE080 para el 2; al cambiar de turno, 0x413E intercambia
los dos bloques enteros, así que el resto del código nunca necesita saber a quién
le toca. La palabra QUALIFY, del rótulo de 0x6F47, marca el paso a la siguiente
ronda.

## Un intento

Cada prueba es una carrera o un impulso, un salto o un ejercicio, y un resultado
que se juzga. La figura del atleta se arma con tiles y sprites y se sube cada
cuadro; el juez (0x7859) puntúa el intento y decide si clasifica, y al final se
suma una bonificación (0x7ABE).
