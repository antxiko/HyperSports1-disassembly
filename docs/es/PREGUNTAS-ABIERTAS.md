# Preguntas abiertas

Lo que el binario no cierra por sí solo:

- **Las melodías no están despiezadas.** Los datos de sonido del final de la ROM
  son una tabla de tonos seguida de las melodías; el reproductor se entiende,
  pero las notas de cada tema no se transcriben aquí.
- **Los fotogramas del atleta, sueltos.** Se sabe dónde están (0x53EC-0x614C),
  cómo se descomprimen y cuántas tiras usa cada prueba, pero no se dibujan uno a
  uno en esta web: DIBUJA_ATLETA reparte cada tira por la tabla de patrones con
  un destino que sale de la posición y del estado del intento, así que sacar la
  figura suelta pediría reproducir ese reparto. En las escenas se ven montadas.
- **Once tiras que no toca nadie.** De las 52 del bloque de posturas, once no las
  lee ninguna prueba en los 230 segundos de atracción medidos. Puede que sólo
  aparezcan en partida —la atracción no falla ningún intento ni llega a las
  últimas fases— o que sean fotogramas muertos. No se ha comprobado jugando.
- **Qué es la tabla de pasos de 0x6F9C.** Ocho valores de 16 bits, uno por
  escalón de la marca, que 0x6F8B suma a la coordenada 0xE101; el primero es
  negativo. Se sabe qué hace la rutina, no para qué sirve el salto.
