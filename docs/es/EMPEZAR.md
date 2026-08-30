# Empezar

Un desensamblado comentado de **Hyper Sports 1**, el RC-715 de Konami para MSX,
un cartucho de 16 KB que se mapea en la página 1 (0x4000-0x7FFF). Reensambla
dando la ROM exacta, byte a byte, y cada uno de sus 16.384 bytes está explicado.

## El cartucho no está aquí

Ningún repositorio distribuye el juego. Pon tu propio volcado en la raíz como
`hypersports1.rom`, 16384 bytes, sha256

    440dae57676a98b5a3dd29f3e97b9c83a8cbe58a3d3f2172c6072d07e6f00754

`make comprueba` lo verifica.

## Qué hace cada orden

    make            traza el flujo, arma el listado, lo reensambla y pasa los tests
    make verify     la prueba que decide: reensamblar tiene que devolver la ROM
    make sanity     que ni un byte quede sin explicar, y que ningún dato salga como código
    make densidad   cuánto está comentado, rutina a rutina
    make web        rehace esta web desde la ROM y las notas

## Cómo está montado

El listado no se edita a mano: `tools/mkasm.py` lo arma desde un trazado de flujo
y un fichero de notas ancladas a direcciones, así que los comentarios sobreviven
a un retrazado. El trazador sigue el flujo desde los puntos de entrada; los que
no puede deducir solo -el gancho de la interrupción y las tablas de saltos en
línea- van declarados en `src/hypersports1.entries`, cada uno con su motivo.
