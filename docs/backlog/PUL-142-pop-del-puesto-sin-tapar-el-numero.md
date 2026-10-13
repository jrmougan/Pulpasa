---
id: PUL-142
title: Hacer que el POP del puesto no tape su número
status: review
milestone: M4
role: gameplay-engineer
deps: []
orca_task: null
unity_sources: []
owns: [godot/entities/stations/order_stand.tscn, godot/entities/stations/order_stand.gd, godot/entities/stations/order_stand_model.gd, godot/tests/integration/test_stand_pop_number.gd*, docs/evidence/PUL-142/**, docs/backlog/PUL-142-pop-del-puesto-sin-tapar-el-numero.md]
touches_scenes: [godot/entities/stations/order_stand.tscn]
---

## Target
Pendiente de PUL-071 («El POP del puesto tapa un instante su número»), confirmado vivo en PUL-139:
`docs/evidence/PUL-139/deliver_ok_strip.png` (captura reproducible `capture_stand_pop.gd`). Con
`deliver_ok`, el «1» de `StandNumber` (Label3D hijo de la raíz de `order_stand.tscn`, fuera de `Model`)
se ve en reposo y **desaparece** en los fotogramas al 15, 35 y 55 % de `visual_time`: queda el disco de
la placa vacío. `order_new` (POP de `%OrderLabel`) no lo tapa.

## Change
1. Diagnosticar por qué la placa tapa el número durante el POP del puesto (`FeedbackPlayer` escala
   `pulse_target`, hoy sin asignar → el padre, la raíz del puesto) y anotarlo en Evidence.
2. Arreglarlo para que el número se vea durante todo el POP, sin cambiar la respuesta visual
   (`pop_scale` y `visual_time` de `deliver_ok` en `data/audio/feedback_map.tres` se quedan).

## Constraints
- `docs/arch/scene-tree.md` describe el puesto (`%Feedback … pulse_target = el puesto`, `StandNumber`
  fuera de `Model`, `number_label` de `order_stand_model.gd`). **Pregunta para el arquitecto**: si el
  arreglo cambia `pulse_target` o mueve `StandNumber` bajo `Model`, es una enmienda de contrato y
  necesita ADR o enmienda de `scene-tree.md` antes de implementar. Un arreglo que no cambie el
  árbol (p. ej. orden de dibujo o separación del Label3D respecto a la placa) no la necesita.
- No tocar `feedback_map.tres` ni `components/feedback_player.gd`. Tipado estático.

## Acceptance
- [x] AC1 Given el puesto 1 en `level_01` When se emite `order_completed` de su comanda Then en los
  fotogramas al 0, 15, 35, 55 y 100 % de `visual_time` de `deliver_ok` el número es visible →
  tira de capturas en `docs/evidence/PUL-142/` con el mismo método que `docs/evidence/PUL-139/capture_stand_pop.gd`.
- [x] AC2 Test que falla con el árbol de hoy y pasa con el arreglo (p. ej. el número queda por
  delante de la placa en el eje de la cámara durante el POP) → `test_stand_pop_number.gd`.
- [x] AC3 Sin regresión: `test_order_stand.gd` en verde, `order_new` y `order_expired` siguen sobre
  `%OrderLabel`; `tools/verify.sh` en verde; `check_owns` limpio.

## Plan
- **Diagnóstico.** `play_cue(&"deliver_ok")` sin objetivo → `pulse_target` vacío → el padre (el puesto) →
  `FeedbackPlayer._visual_node` lo cambia por su `Model`. El POP escala solo `Model` desde el origen del
  puesto (pico ×1,2 y algo más por `TRANS_BACK`). La placa (`Anchor_Number`, z −0,23, y 0,5) sale
  hacia delante hasta z ≈ −0,276 y sube; `StandNumber`, hermano de `Model`, se queda en z −0,232 y
  queda **detrás** de la placa: el test de profundidad lo oculta. `order_new`/`order_expired` animan
  `%OrderLabel` y no tocan `Model`.
- **Arreglo, sin cambiar el árbol** (sin enmienda de `scene-tree.md`): `order_stand_model.gd` guarda el
  transform de `number_label` relativo a `Model` en `_ready` y, con
  `NOTIFICATION_LOCAL_TRANSFORM_CHANGED`, lo reaplica cuando cambia el de `Model`. El número sigue el
  POP del puesto pegado a su placa (2 mm por delante, escalados). Sin `_process`, sin señales nuevas;
  `pulse_target`, `feedback_map.tres` y `feedback_player.gd` intactos.
- **AC2** `tests/integration/test_stand_pop_number.gd`: a 0/15/35/55/100 % de `visual_time` el número
  está delante de la placa hacia la cámara de juego y en −Z, y sigue a `Model`; vuelve a reposo.
  **AC3**: `order_expired` sigue sobre `%OrderLabel` sin mover el número; `test_order_stand.gd` en verde.
- **AC1** `docs/evidence/PUL-142/capture_stand_pop.gd` (copia de la de PUL-139) + tiras con `montage`.

## Evidence
- **Diagnóstico** (Change 1): `pulse_target` vacío → el puesto → `_visual_node` → su `Model`. El POP
  escala `Model` desde el origen del puesto; `StandNumber` (hermano) no. En el pico (×1,2) la placa
  (`Anchor_Number`) pasa de z −0,23 a −0,276 y el número, quieto en z −0,232, queda 4,4 cm detrás:
  la placa lo tapa por profundidad. Medido por el test sin el arreglo: a lo largo de la cámara el
  número queda −0,016 / −0,096 / −0,066 m detrás de la placa al 15 / 35 / 55 % (escala 1,036 /
  1,200 / 1,138); a 0 y 100 % está delante (por eso se ve en reposo).
- **Arreglo** (`godot/entities/stations/order_stand_model.gd`): `Model` guarda en `_ready` el transform
  de `number_label` relativo a sí mismo y lo reaplica con `NOTIFICATION_LOCAL_TRANSFORM_CHANGED`. El
  número acompaña el POP del puesto pegado a su placa. Sin cambios de árbol, `pulse_target`,
  `feedback_map.tres` ni `feedback_player.gd` (no hace falta enmienda de `scene-tree.md`). Nota para el
  responsable: el número ahora crece con el puesto (antes se quedaba quieto en reposo y el puesto crecía
  a su alrededor); `pop_scale` y `visual_time` son los mismos.
- **AC1** `docs/evidence/PUL-142/deliver_ok_strip.png` (5 fotogramas, 0/15/35/55/100 %): el «1» se ve en
  todos. Comparar con `docs/evidence/PUL-139/deliver_ok_strip.png`. `order_new_strip.png` sin cambios.
  Script y uso en `docs/evidence/PUL-142/README.md`.
- **AC2** `godot/tests/integration/test_stand_pop_number.gd`: con el `order_stand_model.gd` de `main`
  falla 9 asserts (15/35/55 %: detrás de la placa hacia la cámara, detrás en −Z, no sigue a `Model`);
  con el arreglo pasa.
- **AC3** `test_order_stand.gd` en verde; `test_ac3_order_cues_stay_on_order_label` comprueba que
  `order_expired` anima `%OrderLabel` y no mueve el número. `tools/verify.sh`: gdformat 236 sin cambios,
  gdlint OK, import OK, GUT 1338/1338 (27302 asserts), smoke OK → `✓ verify OK`.
