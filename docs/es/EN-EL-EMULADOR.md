# En el emulador

El listado y cada cifra de esta web salen del binario y se reproducen con `make`.
Aquí no se ha medido nada a ojo.

## Ejecutarlo

    openmsx -machine Philips_VG_8020 -cart hypersports1.rom

Basta una máquina MSX1; el cartucho se mapea en la página 1 y mueve todo desde la
interrupción de cada cuadro.

## Qué se puede medir

Para confirmar un estado o una cadencia, pon un breakpoint y vigila la RAM que
nombran las notas: 0xE000 es el estado principal, 0xE052 el evento, 0xE054 los
intentos que quedan. El coste por cuadro de una rutina es la diferencia de
`machine_info time` entre un breakpoint en su entrada y otro en su `ret`, por
3579545 para dar los ciclos del Z80.

Las rutas de salida de cualquier script Tcl tienen que ser de Windows, nunca
`/tmp`.

## Los dos guiones que trae el repositorio

`make vram` los lanza los dos. Ninguno necesita que nadie juegue: la demo de
atracción juega las cuatro pruebas sola desde el encendido, y es **determinista**
—dos pasadas independientes dan los mismos volcados byte a byte—.

- `tools/omsx_escenas.tcl` espera al segundo apuntado de cada escena y vuelca los
  16 KB de VRAM, más los 384 bytes de la fuente de la BIOS que 0x43BF copia. De
  ahí salen los cinco `.vram` de `src/vram`, que son el mapa de casillas de las
  imágenes de esta web.
- `tools/omsx_posturas.tcl` pone un punto de observación de lectura sobre el
  bloque de fotogramas del atleta y apunta, por prueba, qué direcciones se leen
  y **desde qué PC**. Con eso se sabe qué tiras usa cada prueba y se comprueba el
  formato: 679.198 lecturas en 230 segundos emulados, con 11.463 pasadas por
  0x0038 de control.

## Lo que NO funciona: las capturas de pantalla

El `screenshot` de openMSX **va por detrás del guion Tcl**, y no coincide con la
lectura de la VRAM del mismo instante. Comprobado dos veces, y también con la
máquina en pausa: pidiendo la escena del trampolín salió la pantalla de la prueba
anterior, y pidiendo la de la barra fija salió el logotipo del arranque. La VRAM,
que se lee síncrona con `debug read_block`, sí es del instante que se pide, y por
eso las imágenes de esta web se dibujan de ella y de la ROM, no de una captura.
