---
id: PUL-142
title: Hacer que el POP del puesto no tape su número
status: draft
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
- [ ] AC1 Given el puesto 1 en `level_01` When se emite `order_completed` de su comanda Then en los
  fotogramas al 0, 15, 35, 55 y 100 % de `visual_time` de `deliver_ok` el número es visible →
  tira de capturas en `docs/evidence/PUL-142/` con el mismo método que `docs/evidence/PUL-139/capture_stand_pop.gd`.
- [ ] AC2 Test que falla con el árbol de hoy y pasa con el arreglo (p. ej. el número queda por
  delante de la placa en el eje de la cámara durante el POP) → `test_stand_pop_number.gd`.
- [ ] AC3 Sin regresión: `test_order_stand.gd` en verde, `order_new` y `order_expired` siguen sobre
  `%OrderLabel`; `tools/verify.sh` en verde; `check_owns` limpio.

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker: salida de verify.sh, capturas, notas.)
