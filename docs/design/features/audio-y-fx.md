# Feedback mínimo: audio y respuesta visual (Must)

**Slug:** audio-y-fx · **Original:** tabla «Música y efectos» (FOL, BG, FX).

## Descripción
Sonido **y** respuesta visual (destello, partícula o animación) en coger, cocer, condimentar, entrega
correcta y entrega errónea; más música de fondo (BG) y ambiente de romería (FOL).

## Criterios de aceptación
- **AC1** Given una partida iniciada, When pasa 1 s, Then suenan FOL y BG en buses distintos (`Ambience`, `Music`).
- **AC2** Given cada evento de la lista (corte, caldero, coger, soltar, nueva comanda, entrega, caducada), When se emite su señal de `EventBus`, Then se reproduce exactamente 1 sonido FX asociado.
- **AC5** Given cada acción de la lista (coger, cocer, condimentar, entrega correcta, entrega errónea), When ocurre, Then se reproduce 1 sonido y 1 respuesta visual de ≥ 0,3 s; la entrega correcta y la errónea suenan y se ven distintas.
- **AC3** Given la partida en curso, When se pausa, Then los buses `Music` y `Ambience` bajan ≥ 12 dB y vuelven al reanudar.

## Datos (`.tres`)
Mapa evento → sonido, volúmenes por defecto por bus. Los sliders de volumen son el Should `opciones-de-volumen.md`.
