# El cartucho

16 KB en la página 1 (0x4000-0x7FFF), sin cambio de banco. La cabecera "AB"
declara solo **INIT** (0x4077).

## Qué hace INIT

INIT pone modo de interrupción 1, escribe un `jp` en el gancho H.KEYI (0xFD9A)
que apunta a **0x402C**, pone la pila en 0xE400, limpia la RAM de trabajo
0xE000-0xE3FF, y cae en un `jr` a sí mismo en 0x40A4. A partir de ahí el programa
principal no hace nada: la interrupción, una vez por cuadro, mueve todo el juego.

## La pantalla

SCREEN 2. El cartucho no guarda pantallas enteras: guarda guiones. La tabla de
nombres la rellena el intérprete de 0x405E, y las de patrones y color el
descompresor de rachas de 0x440D.

## El mapa de la RAM

Todo lo que el juego toca vive de 0xE000 hacia arriba, bajo la pila en 0xE400:

- **0xE000** estado principal, el índice en la tabla de manejadores de 0x40C2
- **0xE001** subestado, repartido dentro de cada manejador
- **0xE002** banderas de modo: bit6 la demo, bit7 el marcador
- **0xE005** el candado de reentrada de la interrupción
- **0xE050-0xE06F** el estado del jugador 1; **0xE080-0xE09F** el del 2
- **0xE052** el evento en curso; **0xE054** los intentos que quedan
- **0xE010-0xE03A** los tres canales de sonido, once bytes cada uno
- **0xE100..** los actores y sprites de la prueba en curso
