# El código

## La máquina de estados

La interrupción (0x402C) llama a 0x40A6 cada cuadro. Lee 0xE000, el **estado
principal**, y con él un salto por la tabla de 0x40C2 llega a uno de los
manejadores; el byte alto, 0xE001, es el **subestado**. El bit6 de 0xE002 marca
la demo, y 0x40A6 empuja como retorno el manejador de juego (0x430A) o el de demo
(0x44C9) antes de saltar al manejador del estado.

## Dos intérpretes de dibujo

Nada de lo que sale en pantalla es un mapa de bits guardado. Dos intérpretes
arman la VRAM:

- **0x405E** copia byte a byte a la tabla de nombres, con una palabra de destino,
  un salto a un nuevo destino (0xFE) y un fin (0xFF).
- **0x440D** descomprime por rachas a las tablas de patrones y color: un byte de
  cuenta cuyo bit alto distingue copia literal de relleno de un byte, y un 0x00
  que cierra el bloque. Las figuras de esta web salen de ejecutar este en Python.

## Dos jugadores en el mismo sitio

La prueba corre sobre el bloque de 0xE050. Al cambiar de turno, 0x413E
intercambia ese bloque con el de 0xE080 en una sola rutina de 32 bytes, así que
las demas rutinas siempre trabajan sobre 0xE050 sin enterarse de quién juega.

## El sonido

0x7C3D es el reproductor de cada cuadro: tres fichas de canal de once bytes en
0xE010, cada una leyendo su melodía con un pequeño intérprete de órdenes y
escribiendo el PSG por la BIOS. Es el armazón que Konami reutilizó entre sus
cartuchos de MSX, con su tabla de tonos y sus efectos al final de la ROM.
