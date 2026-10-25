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

## Código compartido con otros cartuchos de Konami

Este desensamblado se ha comparado, instrucción por instrucción, con
todos los demás de Konami de la serie. Cuenta un bloque cuando las
mismas instrucciones, al menos seis desde una etiqueta hasta su `ret`
o su salto sin condición, están en los dos cartuchos; las direcciones
no se miran, porque cambian de un cartucho a otro. De los otros 57,
**42** tienen al menos un bloque en común con este; estos son los
que más comparten:

| Cartucho | Bloques | Instrucciones | Por ejemplo (aquí = allí) |
|---|---:|---:|---|
| [Magical Tree](https://antxiko.github.io/MagicalTree-disassembly/es/) | 25 | 341 | `MANEJADOR_DEMO` (0x44C9) = `atiende_el_menu` |
| [Circus Charlie](https://antxiko.github.io/CircusCharlie-disassembly/es/) | 21 | 276 | `MANEJADOR_DEMO` (0x44C9) = `atiende_el_menu` |
| [Cabbage Patch Kids](https://antxiko.github.io/CabbagePatchKids-disassembly/es/) | 17 | 210 | `LEE_TECLADO` (0x44A4) = `LEE_EL_TECLADO` |
| [Konami’s Mahjong Dojo](https://antxiko.github.io/KonamisMahjongDojo-disassembly/es/) | 15 | 186 | `SUMA_BONUS_7BE3` (0x7BE3) = `carga_los_canales` |
| [Comic Bakery](https://antxiko.github.io/ComicBakery-disassembly/es/) | 12 | 174 | `MANEJADOR_DEMO` (0x44C9) = `atiende_el_menu` |
| [Hyper Olympic 1](https://antxiko.github.io/HyperOlympic1-disassembly/es/) | 9 | 105 | `SUMA_BONUS_7BE3` (0x7BE3) = `MONTA_UN_CANAL` |
| [Hyper Olympic 2](https://antxiko.github.io/HyperOlympic2-disassembly/es/) | 9 | 105 | `SUMA_BONUS_7BE3` (0x7BE3) = `MONTA_UN_CANAL` |
| [Super Cobra](https://antxiko.github.io/SuperCobra-disassembly/es/) | 9 | 117 | `DESCOMPRIME_A_TERCIOS_4748` (0x4748) = `SUBE_LOGOTIPO` |
| [Konami's Ping Pong](https://antxiko.github.io/KonamisPingPong-disassembly/es/) | 7 | 88 | `LEE_TECLADO` (0x44A4) = `lee_teclado_1` |
| [Road Fighter](https://antxiko.github.io/RoadFighter-disassembly/es/) | 7 | 76 | `SUMA_BONUS_7C17` (0x7C17) = `enciende_o_apaga_canales` |

La matriz entera, los 58 cartuchos entre sí, está en
[Las rutinas](https://antxiko.github.io/MSX-disassembly-database/es/LAS-RUTINAS.html) de la base de datos de la
serie, con el método y el programa que la mide.
