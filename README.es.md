# Hyper Sports 1 (Konami, RC-715) — desensamblado comentado

Un desensamblado comentado del cartucho de MSX de 16 KB, reproducible byte a byte.

**[Lee la documentación →](https://antxiko.github.io/HyperSports1-disassembly/es/)**
· [In English](README.md)

    make            # traza, genera el listado, lo reensambla y pasa los tests
    make verify     # la prueba que decide: reensamblar tiene que devolver la ROM
    make sanity     # que ni un byte quede sin explicar
    make densidad   # cuánto está comentado, rutina a rutina
    make web        # rehace la web

La ROM **no se distribuye aquí**. Va en la raíz como `hypersports1.rom`, 16384
bytes, sha256

    440dae57676a98b5a3dd29f3e97b9c83a8cbe58a3d3f2172c6072d07e6f00754

`make comprueba` lo verifica.

## Cómo está

| | |
|---|---|
| reensambla byte a byte | sí |
| bytes explicados | 16.384 de 16.384 (100 %) |
| código trazado | 5.953 bytes, 3.177 instrucciones |
| datos identificados | 10.431 bytes en 47 rangos con nombre |
| comentado | 784 comentarios de línea, 25,1 % |
| rutinas flojas (bajo el 10 %) | 0 de 386 |

Las anotaciones viven aparte del listado, ancladas a la dirección que describen,
así que sobreviven a un retrazado. Lo que guarda el fichero `.notes`:

| | |
|---|---|
| etiquetas con nombre | 387 |
| comentarios anclados | 784 |
| rangos de datos con explicación | 47 |

## Qué hay aquí

- `src/hypersports1.asm` — el listado; generado, no editado a mano
- `src/hypersports1.notes` — las anotaciones, ancladas a direcciones
- `src/hypersports1.entries` — los puntos de entrada, cada uno justificado
- `docs/` — la web, en inglés y castellano
- `src/vram/` — cinco volcados de la VRAM del MSX, uno por escena de la web, con
  el mapa de casillas que el cartucho no guarda; y la medida de qué fotogramas
  usa cada prueba
- `tools/` — el trazador, el generador del listado, los recorredores de datos, el
  descompresor de rachas que dibuja las imágenes de la web desde la ROM y los dos
  guiones de openMSX que sacan los volcados

## La documentación

| | |
|---|---|
| [Empezar](docs/es/EMPEZAR.md) | qué necesitas y qué hace cada orden |
| [El juego](docs/es/EL-JUEGO.md) | cuatro pruebas de gimnasia y saltos, dos jugadores |
| [El cartucho](docs/es/EL-CARTUCHO.md) | la cabecera, el mapa de memoria y la pantalla |
| [El código](docs/es/EL-CODIGO.md) | la máquina de estados, los dos intérpretes y el sonido |
| [Hallazgos](docs/es/HALLAZGOS.md) | lo que dice el binario |
| [En el emulador](docs/es/EN-EL-EMULADOR.md) | lo que se puede medir, y cómo |
| [Preguntas abiertas](docs/es/PREGUNTAS-ABIERTAS.md) | lo que aún no está cerrado |

Ver `AVISO-LEGAL.md`.
