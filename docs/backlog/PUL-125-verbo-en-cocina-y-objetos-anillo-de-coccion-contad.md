---
id: PUL-125
title: Verbo en cocina y objetos; anillo de cocción, contador de corte y aviso de quemado
status: review
milestone: M3e
role: gameplay-engineer
deps: [PUL-121, PUL-124]
orca_task: null
unity_sources: []
owns: [godot/tests/integration/test_cachelos.gd, godot/entities/items/box.gd*, godot/entities/items/ingredient.gd*, godot/entities/stations/cooking_station.gd*, godot/entities/stations/slot.gd*, godot/entities/stations/item_spawner.gd*, godot/entities/stations/trash_bin.gd*, godot/resources/kitchen_data.gd*, godot/data/config/kitchen.tres, godot/ui/widgets/world_progress_bar.gd*, godot/ui/widgets/world_progress_ring.gd*, godot/tests/integration/test_box.gd*, godot/tests/integration/test_box_on_slot.gd*, godot/tests/integration/test_box_model.gd*, godot/tests/integration/test_box_counter.gd*, godot/tests/integration/test_box_cut_hold.gd*, godot/tests/integration/test_burn.gd*, godot/tests/integration/test_cooking_station.gd*, godot/tests/integration/test_cook_ring.gd*, godot/tests/integration/test_item_spawner.gd*, godot/tests/integration/test_slot.gd*, godot/tests/integration/test_trash_bin.gd*, godot/tests/integration/test_octopus.gd*, godot/tests/integration/test_shelves.gd*, godot/tests/integration/test_hold_component.gd*, godot/tests/integration/test_audio_feedback.gd*, godot/tests/integration/test_kitchen_hints.gd*, godot/tests/integration/test_kitchen_flow.gd*, godot/tests/integration/test_m1_flow.gd*, godot/tests/integration/test_m2_flow.gd*, godot/tests/integration/test_parity_smoke.gd*, godot/tests/integration/test_delivery_e2e.gd*, godot/tests/integration/test_level_01.gd*, godot/tests/integration/test_level_01_r16.gd*, godot/tests/integration/level_walker.gd*, godot/tests/integration/, docs/evidence/PUL-125/**, docs/backlog/PUL-125-verbo-en-cocina-y-objetos-anillo-de-coccion-contad.md]
touches_scenes: [godot/entities/items/box.tscn, godot/entities/stations/kitchen.tscn, godot/ui/widgets/world_progress_bar.tscn, godot/ui/widgets/world_progress_ring.tscn]
---

## Target
D26 (`docs/design/decisions.md`), contrato en `docs/arch/` (ADR-003 §11, ADR-004 §6, ADR-005 Enmienda D26,
ADR-006 §4.1, `signals.md`, `scene-tree.md` §9). Partición original y notas de propietarios entre oleadas:
`docs/backlog/PUL-120-contratos-d26.md` («Partición en fichas»). Oleada 2. Diseño:
`docs/design/features/lenguaje-acciones.md` y `controles-tactiles.md`. Touches scenes original: `godot/entities/items/box.tscn`, `godot/entities/stations/kitchen.tscn`,
  `godot/ui/widgets/world_progress_bar.tscn`, `godot/ui/widgets/world_progress_ring.tscn` (nueva)

## Change
`get_action_hint` + `_resolve` sobre `ActionRules` en caja, pulpo/cachelos, olla,
  pasaplatos, spawners y cubo (§11.2, filas A1–A6, B, C); `can_interact` honesto; `%CutCounter` y
  `get_presses()`; `%CookRing` por plaza; aviso de quemado con repetición; cues `cook_ready` (en lugar
  de `cook_done`) y `box_full`; barras ≥ 8 px. **No** quita `Box.toggle_seasoning()` (PUL-131).

## Constraints
- Solo las rutas de `owns`/`touches_scenes`. Si un cambio rompe un test fuera de tus owns, para y avisa al producer.
- Tipado estático, datos en `.tres`, lógica en `core/` RefCounted; no inventes `uid://`.
- Nombres exactos del contrato (manda sobre el diseño; equivalencias en PUL-120).

## Acceptance
- [x] AC1 (diseño AC2) Para cada fila A1–A6, B y C: el hint publicado coincide con el efecto de `interact` (OK cambia el mundo, BLOQUEADO no, `—` no es objetivo) y `interact` devuelve `true` si el hint no es `NONE` -> `test_kitchen_hints.gd`
- [x] AC2 (diseño AC13) 1,05 s mantenido con pulpo cocido (100 u) y caja vacía -> 6 cortes y 50 u, sin rechazo; soltar y pulsar sobre la llena -> 1 rechazo `full`; toque < 0,2 s -> 1 corte -> `test_box_cut_hold.gd`
- [x] AC3 (diseño AC14) Con k = 1…5 cortes se ve `k/6`, numeral >= 36 px y barra >= 8 px a 1080; k = 0 no se ve; en k = 6 muestra `6/6` 0,5 s, suena `box_full` 1 vez y se oculta -> `test_box_counter.gd` + captura
- [x] AC4 (diseño AC15) Anillo >= 64 px y trazo >= 8 px a 1080; listo verde con ✓ y `cook_ready` 1 vez -> `test_cook_ring.gd` + captura
- [x] AC5 (diseño AC16) Aviso a los 7,0 s (±0,1): parpadeo 3 Hz (±0,5) y `burn_warning` repetido cada 1 s hasta 3 veces; retirar a los 8 s lo para; a los 10 s rojo fijo -> `test_burn.gd`
- [x] AC6 Flujos (`test_kitchen_flow`, `test_m1_flow`, `test_m2_flow`, `test_parity_smoke`, `test_delivery_e2e`, `test_level_01*`) y `test_audio_feedback` en verde con el `can_interact` honesto

## Plan
Ficheros (todos en `owns`/`touches_scenes`):
- `entities/items/box.gd` + `box.tscn`: `get_action_hint`/`_resolve` sobre `ActionRules.for_box`; `interact` ejecuta la rama del hint; `get_presses()`; `%CutCounter` (barra segmentada + numeral); cue `box_full` en el corte que llena (sustituye a `cut`). `%FillBar` se conserva oculto (lo exige `test_items_contract`, fuera de owns). No toca `toggle_seasoning` (PUL-131).
- `entities/items/ingredient.gd`: `_resolve` con `for_loose_item`.
- `entities/stations/cooking_station.gd` + `kitchen.tscn`: `_resolve` con `for_pot`; `%CookRing` por plaza (sustituye a `%CookBar`); cue `cook_ready` (en lugar de `cook_done`); aviso de quemado con parpadeo (`KitchenData.warn_blink_hz`) y repeticion del cue (`warn_repeat_interval`, `warn_repeat_count`).
- `entities/stations/slot.gd`, `item_spawner.gd`, `trash_bin.gd`: `_resolve` con `for_pass_slot` / `for_loose_item` del objeto guardado / `for_spawner` / `for_trash`.
- `resources/kitchen_data.gd` + `data/config/kitchen.tres`: `warn_blink_hz`, `warn_repeat_interval`, `warn_repeat_count`, `ring_thickness_px`, `ring_diameter_px`.
- `ui/widgets/world_progress_bar.{gd,tscn}`: barras >= 8 px, `bar_size` y `segments`. `ui/widgets/world_progress_ring.{gd,tscn}` (nuevo): `Sprite3D` + `SubViewport` con `TextureProgressBar` radial.
Senales: ninguna nueva (el contrato no anade; `burn_warned`, `cooking_finished`, `fill_changed` existentes).
Tests (AC -> fichero): AC1 `test_kitchen_hints.gd` (lee `tests/fixtures/action_matrix.csv`, escenas reales: spawner, loose_item, pass_slot, trash, box, pot; `hint == efecto de interact`); AC2 `test_box_cut_hold.gd`; AC3 `test_box_counter.gd`; AC4 `test_cook_ring.gd`; AC5 `test_burn.gd`; AC6 tests de flujo y `test_audio_feedback` existentes, ajustados a `can_interact` honesto y a `cook_ready`.

## Evidence
`bash tools/verify.sh` completo en verde (gdformat, gdlint, import, GUT, smoke) y
`check_owns` limpio. `test_cachelos.gd:64` se ajusto al `can_interact` honesto (owns ampliado por el coordinador).
Cifras finales de GUT: ver `## Evidence` > Ultima ejecucion al final de esta seccion.

Tests nuevos (41): `test_kitchen_hints.gd` 13 (AC1; lee `action_matrix.csv` y contrasta hint, `can_interact` y
efecto de `interact` en escenas reales: spawner, pulpo suelto, pasaplatos vacio, cubo, caja y olla;
mutando una regla el test falla), `test_box_cut_hold.gd` 5 (AC2), `test_box_counter.gd` 7 (AC3),
`test_cook_ring.gd` 8 (AC4), `test_burn.gd` +7 (AC5). Ajustados al `can_interact` honesto:
`test_box`, `test_box_on_slot`, `test_slot`, `test_item_spawner`, `test_cooking_station`, `test_burn`,
`test_audio_feedback` (`cook_ready`).

Capturas a 1920x1080 (`docs/evidence/PUL-125/`, cada una con su recorte ampliado x2 `_zoom`; las genera
`capture_pul125.gd`, ver cabecera, sobre `level_01.tscn` con la camara de juego):
- AC4 anillo: `ac4_anillo_cociendo.png`, `ac4_anillo_listo_zoom.png` (verde con check, la otra plaza aun cociendo).
- AC5 aviso: `ac5_aviso_quemado_ambar_zoom.png`, `ac5_aviso_quemado_rojo_zoom.png` (llama y arco que se vacia),
  `ac5_quemado_rojo_fijo.png`.
- AC3 contador: `ac3_contador_3_de_6.png`, `ac3_contador_6_de_6.png` (+ zooms de 1/6, 5/6 y oculto tras 0,5 s).
Medidas (tests, a 1080 con `camera_rig.tscn`, size 12,74): anillo 64 px de diametro y 8 px de trazo
(medido tambien sobre la textura dibujada), numeral 37,8 px, barra del contador 9,2 px de relleno y 15,3 px por segmento,
barras restantes 9,2 px.

Desviaciones / decisiones:
- `%FillBar` de la caja se conserva **oculta**: `test_items_contract` (fuera de owns) exige que exista como `WorldProgressBar`; la sustituye `%CutCounter` (PUL-131 puede retirarla).
- `warn_repeat_count` = 3 son los avisos **totales** (el primero a `warn_time` mas dos repeticiones, a 7, 8 y 9 s): una repeticion mas caeria a los 10 s, cuando ya se quema.
- `Box.COUNTER_FULL_TIME` (0,5 s del `6/6`) es una constante de la caja, no un `.tres`: `BoxData` queda fuera de owns.
- `WorldProgressBar` gana `bar_size`, `segments`, `set_segments`, `get_thickness_px` y `get_segment_width_px`; `pixel_size` 0,006 y 120x22 (antes 0,003 y 160x22) para el grosor >= 8 px.
- Los dos anillos de la olla van en fila (separacion 1,05 diametros), no apilados: apilados a 0,35 m se tapaban.
- Deuda para PUL-131: `camera_size` 12,74 fijo en `world_progress_ring.gd` (export) y `cooking_station.gd` (separacion de anillos): leer `CameraProfile` (ya en la base con PUL-130); `Box.COUNTER_FULL_TIME` a `BoxData`; `unique_id` de los nodos nuevos de `world_progress_ring.tscn` y de `CutCounter`/`CutBar`/`CutNumeral` en `box.tscn`.
- Cue `cook_done` sigue en `feedback_map.tres` (lo retira PUL-131); la olla ya reproduce `cook_ready`.
- Las capturas no usan el MCP `run_script` (no disponible en esta sesion): las hace `capture_pul125.gd` con `godot -s` y ventana real.

Ultima ejecucion (tras merge de la integracion con PUL-127/128/130): `verify.sh` OK, GUT 1244 tests, 1244 pasan.
