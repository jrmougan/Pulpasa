# Feedback mínimo: audio y respuesta visual (Must)

**Slug:** audio-y-fx · **Original:** tabla «Música y efectos» (FOL, BG, FX).

## Descripción
Sonido **y** respuesta visual (destello, partícula o animación) en coger, cocer, condimentar, entrega
correcta y entrega errónea; más música de fondo (BG) y ambiente de romería (FOL).

## Criterios de aceptación
- **AC1** Given una partida iniciada, When pasa 1 s, Then suenan FOL y BG en buses distintos (`Ambience`, `Music`).
- **AC2** Given cada evento de la lista (corte, caldero, coger, soltar, nueva comanda, entrega, caducada), When se emite su señal de `EventBus`, Then se reproduce exactamente 1 sonido FX asociado.
- **AC5** Given cada acción de la lista (coger, cocer, condimentar, entrega correcta, entrega errónea), When ocurre, Then se reproduce 1 sonido y 1 respuesta visual de ≥ 0,3 s; la entrega correcta y la errónea suenan y se ven distintas.
- **AC6 (D25)** Given una tirada al cubo de basura (`cubo-basura.md`), When el cubo emite su señal local `trashed`, Then suena exactamente 1 cue `trash` y hay una respuesta visual de ≥ 0,3 s; una pulsación en el cubo con la mano vacía no suena. *Test:* `test_trash_bin.gd` (contador del servicio de audio).
- **AC7 (D25)** Given un aliño aplicado (dulce o picante), Given una caja llena sin aliño, Then suena 1 cue `season` (no 3: sal, aceite y pimentón no suenan por separado) y el gesto visual de sal gorda, aceite y pimentón dura ≥ 0,3 s; al sustituir un aliño por el otro suenan `unseason` y `season`, en ese orden (ADR-006 §4); reaplicar el mismo aliño no suena. *Test:* `test_seasoning_station.gd`.
- **AC3** Given la partida en curso, When se pausa, Then los buses `Music` y `Ambience` bajan ≥ 12 dB y vuelven al reanudar.

## Datos (`.tres`)
Mapa evento → sonido (incluye el cue `trash` de D25), volúmenes por defecto por bus. Los sliders de volumen son el Should `opciones-de-volumen.md`.
