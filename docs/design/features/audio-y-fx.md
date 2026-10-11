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
- **AC8 (D26, cues distintos)** Given el mapa evento → sonido, Then `trash`, `discard`, `cook_done`, `burn_warning`, `box_full`, `character_switch` y `action_rejected` usan 7 streams **distintos entre sí** y distintos de `pick_up`, `drop`, `cook_start`, `cut` y `season` (hoy `cook_done` reutiliza `fx_ui_click` y `trash` suena como `drop`: *superado*); y cada evento hace sonar su cue **exactamente 1 vez** (`burn_warning` suena al empezar el aviso y cada 1 s, 1 vez por repetición). *Test:* test de datos del mapa de audio + `test_feedback_cues.gd`.
- **AC9 (D26, ninguna pulsación muda)** Given cualquier pulsación con objetivo (o con la mano llena y sin objetivo), When se procesa, Then se reproduce **exactamente 1 respuesta visual de ≥ 0,3 s y 1 cue**: el del verbo si es éxito (tabla de cues de `lenguaje-acciones.md`) o `action_rejected` si es rechazo. Given una pulsación sin objetivo y con la mano vacía, Then no suena nada. *Test:* `test_action_matrix.gd` (cuenta de señales de respuesta y contador del servicio de audio). El `season_error` y el `deliver_error` pasan a alias de `action_rejected` en estos casos (el contrato lo fija).
- **AC10 (D26, cambio de personaje)** Given Individual, When se cambia de personaje, Then suena 1 cue `character_switch` y el anillo del nuevo activo se anima ≥ 0,3 s. *Test:* `test_player_switch.gd` + `test_feedback_cues.gd`.

*AC2 y AC5 se amplían por D26:* la lista de eventos con sonido incluye ahora rechazo, caja llena, aviso de quemado y cambio de personaje (AC8–AC10).

## Datos (`.tres`)
Mapa evento → sonido (incluye el cue `trash` de D25 y, D26, `box_full`, `character_switch`, `action_rejected` *(propuesta)* y samples propios para `cook_done`, `burn_warning`, `discard` y `trash`), volúmenes por defecto por bus. Los sliders de volumen son el Should `opciones-de-volumen.md`.
