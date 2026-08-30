# Preguntas abiertas

Lo que el binario no cierra por sí solo:

- **Qué rutina mueve cada prueba.** Las cuatro comparten mucho código: el mismo
  motor de figuras, el mismo juez, el mismo marcador. Los nombres del listado
  siguen lo que hace cada rutina; atar cada motor a una de las cuatro pruebas por
  su nombre pediría una partida con 0xE052 a la vista.
- **Las melodías no están despiezadas.** Los datos de sonido del final de la ROM
  son una tabla de tonos seguida de las melodías; el reproductor se entiende,
  pero las notas de cada tema no se transcriben aquí.
- **El dibujado de una pantalla entera.** La web dibuja las figuras y los tiles
  de una prueba desde la ROM ejecutando el descompresor de rachas (0x440D) en
  Python; componer una pantalla de prueba entera pediría portar también el
  intérprete de la tabla de nombres (0x405E) y el reparto por prueba.
