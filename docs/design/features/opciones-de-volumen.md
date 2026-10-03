# Opciones de volumen (Should)

**Slug:** opciones-de-volumen

## Criterios de aceptación
- **AC1** Given el menú de pausa u opciones, Then hay sliders independientes para Música, Ambiente y Efectos de 0 a 100 %.
- **AC2** Given un slider a 0 %, Then su bus queda en silencio (−80 dB); a 100 % en 0 dB.
- **AC3** Given que se cierra y se reabre el juego, Then los valores se conservan.
- **AC4** Given el valor por defecto, Then Música 70 %, Ambiente 70 %, Efectos 100 %.

## Datos
Valores por defecto en `.tres`; persistencia en `user://settings.cfg`.
