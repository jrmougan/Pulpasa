# Audio y efectos (Should)

**Slug:** audio-y-fx · **Original:** tabla «Música y efectos» (FOL, BG, FX).

## Descripción
Ambiente de romería (FOL), música de fondo (BG) y efectos: corte, cocción, interacción, nueva
comanda, entrega correcta, comanda caducada.

## Criterios de aceptación
- **AC1** Given una partida iniciada, Then suenan FOL y BG en buses distintos (`Ambience`, `Music`).
- **AC2** Given cada evento de la lista (corte, caldero, coger, soltar, nueva comanda, entrega, caducada), When se emite su señal de `EventBus`, Then se reproduce exactamente 1 sonido FX asociado.
- **AC3** Given la pausa, Then los buses `Music` y `Ambience` bajan ≥ 12 dB y vuelven al reanudar.
- **AC4** Given el menú de pausa, Then el volumen de cada bus es configurable de 0 a 100 %.

## Datos (`.tres`)
Mapa evento → sonido, volúmenes por bus.
