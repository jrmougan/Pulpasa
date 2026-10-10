---
id: PUL-114
title: Aliño de una pulsación y catálogo de 4 comandas
status: done
milestone: M3d
role: gameplay-engineer
deps: [PUL-112, PUL-113]
orca_task: null
unity_sources: []
owns: [godot/core/seasoning_rules.gd, godot/core/order_validator.gd, godot/resources/seasoning_data.gd, godot/resources/seasoning_station_data.gd, godot/resources/box_badge_style.gd, godot/data/seasonings/**, godot/data/recipes/**, godot/data/orders/**, godot/data/config/seasoning_station.tres, godot/data/config/box_badges.tres, godot/data/audio/feedback_map.tres, godot/entities/items/**, godot/entities/stations/seasoning_*, godot/entities/stations/cachelos_bowl.*, godot/entities/stations/sandbox/**, godot/scenes/sandbox/**, godot/ui/tickets/**, godot/tests/**, docs/evidence/PUL-114/**, docs/backlog/PUL-114-alino-una-pulsacion.md]
touches_scenes: [godot/scenes/levels/level_01.tscn, godot/entities/stations/seasoning_station.tscn, godot/entities/stations/seasoning_dispenser.tscn]
---

## Target
Parte «aliño» y «recetas por contenido» de D25 con el contrato de ADR-003 §10.2 y §10.4 (PUL-111), `signals.md` y ADR-006 §4. Features: `condimentacion.md`, `estacion-condimentos.md`, `comandas.md`, `audio-y-fx.md` AC7.

## Change
- `sweet_dressing.tres` / `hot_dressing.tres` (`SWEET_DRESSING`/`HOT_DRESSING` al final de `SeasoningType`, grupo `dressing`), bajas de `salt/oil/paprika/hot_paprika.tres`.
- `SeasoningRules.apply` + `Box.apply_seasoning`; `ALREADY_APPLIED` silencioso; `BOX_NOT_FULL`; sustitución con `seasoning_removed` antes que `seasoned` (cues `unseason` + `season`); `paprika_swap` fuera; `toggle_guard` solo cuenco.
- Estación: 2 dispensadores de aliño + cuenco en x local −1/0/1, mostrador 5,2 m sin cambios; gesto visual `%Gesture` al aplicar.
- Catálogo: 4 recetas/comandas (`a_feira`, `picante`, `con_cachelos`, `bravo_cachelos`; precios y `max_time` de `comandas.md`), `order_catalog.tres` rehecho, bajas de `individual/combo_duo/familiar.tres`, `order_1..6.tres`, `order_catalog_basic.tres`; `kitchen_sandbox` y `test_data_integrity` a `order_catalog.tres`.
- Pegatinas e iconos del ticket para los 2 aliños + cachelos.

## Constraints
- Contrato tal cual; si no encaja, para y pregunta. Datos en `.tres`, `.uid` versionados, sin inventar `uid://`. Las fases (`PhaseData.orders`) son de PUL-115.
- `tools/verify.sh` en verde.

## Acceptance
- [x] AC1 Los AC de `condimentacion.md` y `estacion-condimentos.md` marcados como D25 → tests
- [x] AC2 Catálogo de 4 comandas con nombres ≤ 14 caracteres que no se recortan en el ticket → test + captura
- [x] AC3 `audio-y-fx.md` AC7 → test
- [x] AC4 Captura de la estación con los 2 dispensadores en `docs/evidence/PUL-114/`
- [x] AC5 `tools/verify.sh` en verde

## Plan
Contrato tal cual (ADR-003 §10.1, §10.2, §10.4; `signals.md`; ADR-006 §4). Sin señales nuevas.

**Núcleo y datos**
- `core/seasoning_rules.gd`: `Rejection.ALREADY_APPLIED` (valor 8, al final); `apply(current, seasoning, is_full)`; `toggle()` sin `swap_exclusive`; helper privado `_put` que sustituye por grupo. Orden: nulo → `NOT_ACCEPTED`; no lleno → `BOX_NOT_FULL`; ya lo lleva → `ALREADY_APPLIED`; mismo grupo → sustituye; si no, añade.
- `resources/seasoning_data.gd`: `SWEET_DRESSING`/`HOT_DRESSING` al final del enum (5 y 6). `resources/seasoning_station_data.gd` y `seasoning_station.tres`: fuera `paprika_swap`. `resources/box_badge_style.gd`: `has_hot_mark` mira `HOT_DRESSING`. `core/order_validator.gd`: sin cambios (ya era solo de contenido por PUL-113).
- `data/seasonings/`: alta `sweet_dressing.tres`/`hot_dressing.tres` (grupo `dressing`, `sort_order` 0); baja `salt/oil/paprika/hot_paprika.tres`.
- `data/recipes/` y `data/orders/`: `a_feira`, `picante`, `con_cachelos`, `bravo_cachelos` (receta 1:1 con comanda; precios y `max_time` de `comandas.md`); `order_catalog.tres` rehecho; bajas de `individual/combo_duo/familiar`, `order_1..6` y `order_catalog_basic`.

**Escenas**
- `entities/items/box.gd`: `apply_seasoning()` y `toggle_seasoning()` sobre `_commit()` (`seasoning_removed` antes que `seasoned`; con rechazo no emite).
- `entities/stations/seasoning_dispenser.gd/.tscn`: sin `clock`/antirrebote; `ALREADY_APPLIED` en silencio; `BOX_NOT_FULL` → `rejected`; `%Gesture` (`GPUParticles3D` one_shot, 0,5 s, hijos `Salt` y `Oil`; el pimentón toma `seasoning.color`). `cachelos_bowl.gd`: `toggle_seasoning(seasoning)`.
- `entities/stations/seasoning_station.tscn`: `SweetDressing` (x −1), `HotDressing` (x 0), `CachelosBowl` (x 1); mostrador de 5,2 m intacto. `kitchen_sandbox.tscn` y el sandbox de la estación, al nuevo catálogo/dispensadores.
- `level_01.tscn` y `box_badges.tres`: sin cambios (la instancia de la estación hereda los dispensadores; las pegatinas ya mostraban lo que lleva la caja). `ui/tickets/**` y `feedback_map.tres`: sin cambios (el ticket ya era D25; las cues `season`/`unseason` ya existían).

**Tests por AC**
- AC1 (`condimentacion.md`): AC1–AC4/AC7 → `test_seasoning_rules.gd`; AC5 → `test_box.gd`; AC6/AC18 → `test_station_level.gd` (+ `test_level_01.gd` sin bandeja/botes ya existente); AC8 → `test_cachelos.gd` (sin cambios); AC9 → `test_data_integrity.gd` + `test_data_catalog.gd`. (`estacion-condimentos.md`): AC1/AC2/AC4–AC8/AC19/AC20 → `test_seasoning_station.gd`; AC3 → ídem (cuenco); AC9/AC10 → `test_cachelos.gd`/`test_seasoning_station.gd`; AC11/AC12 → `test_station_level.gd` y `test_seasoning_station.gd` (R8); AC14 → `test_box_badges.gd`; AC16/AC17 → `test_station_level.gd`/`test_level_01_r16.gd`.
- AC2: `test_order_catalog.gd` (AC5/AC11/AC12 de `comandas.md`) + `test_order_tickets.gd` (nombres sin recortar) + captura de 4 tickets a 1280×720.
- AC3: `test_seasoning_station.gd` (`test_audio_ac7_*`) + `test_audio_feedback.gd`.
- AC4: captura con la escena `tests/tools/capture_pul114.tscn`.
- Flujos adaptados: `test_m1_flow`, `test_m2_flow`, `test_m2b_flow`, `test_m2b_station_selection`, `test_kitchen_flow`, `test_parity_smoke`, `test_delivery_e2e`, `test_order_stand`, `test_trash_bin`, `test_slot`, `test_box_on_slot`, `test_box_model`, `test_level_01` (`B_PASS_TO_STATION`).

**Fuera de alcance:** `PhaseData.orders` y el reparto por fase (PUL-115; `comandas.md` AC13).

## Evidence
- `tools/verify.sh` en verde: gdformat, gdlint, import, GUT **817 tests, 817 en verde** (línea base de la rama: 800 tests con 1 fallo, `test_level_01_r16`, que con el catálogo nuevo pasa) y smoke.
- **AC1**: `test_seasoning_rules.gd` (apply/toggle/orden, 23), `test_box.gd` (`apply_seasoning`, orden `seasoning_removed` antes que `seasoned`, `ALREADY_APPLIED`, `BOX_NOT_FULL`, 0/1/2 entradas), `test_seasoning_station.gd` (AC1, AC2 a 0,1 s y a 5 s, AC4, AC5, AC6, AC7, R4, R8, AC10, AC11, AC19, AC20), `test_cachelos.gd`, `test_box_badges.gd` (AC14), `test_station_level.gd` (AC11/AC12 con barrido de objetivos, AC16–AC18), `test_data_integrity.gd`/`test_data_catalog.gd` (AC9: solo `cachelos`, `hot_dressing`, `sweet_dressing`; grupo `dressing`).
- **AC2**: `test_order_catalog.gd` (4 plantillas con nombres/aliños/cachelos/precios/paciencias de la tabla; AC11: máximo 14 caracteres; AC12: 12 > 8 y 13 > 9, rango 8–14), `test_order_tickets.gd::test_pul114_ac11_*` (nombre sin recortar, ticket de 212 px). Captura: `docs/evidence/PUL-114/ticket_4_recetas_1280x720.png` (los 4 nombres, «Bravo cachelos» entero; a 1920×1080 el HUD escala uniforme, mismo ancho en unidades de interfaz; captura a 1920×1080 no necesaria, aceptado por el coordinador). AC20: `test_order_stand.gd::test_ac20_*` (Á feira con picante rechazada, caja en la mano, aliño dulce y entrega aceptada).
- **AC3**: `test_seasoning_station.gd::test_audio_ac7_*` (1 `season`; `unseason` y `season` en ese orden al sustituir; reaplicar no suena; caja sin llenar solo `season_error`) y `test_audio_feedback.gd::test_ac5_seasoning_pops_the_box`. Gesto: `test_ac19_*` (`%Gesture` one_shot, 0,5 s ≥ 0,3 s, color del aliño; sin gesto con `ALREADY_APPLIED` ni `BOX_NOT_FULL`).
- **AC4**: `docs/evidence/PUL-114/estacion_2_dispensadores_gesto.png` (+ `_2`): los 2 dispensadores en x −1 / 0, el cuenco en x 1, el gesto de sal gorda, pimentón y aceite, la caja con su pegatina (generada con `tests/tools/capture_pul114.tscn`). `docs/evidence/PUL-114/target_map.txt`: mapa de objetivos `dddppppcc` (0 `_`, 0 `T`, sin huecos).
- Tests dados de baja (probaban reglas eliminadas): en `test_seasoning_station.gd` el alternar de sal (`..._second_press_after_guard_removes_salt`), el antirrebote del dispensador (`test_ac3_second_press_within_guard_is_ignored_silently` del dispensador, `..._guard_is_per_dispenser`, `..._guard_reads_toggle_guard_from_data`, `test_ac3_rejection_does_not_arm_guard`) y `test_ac4_without_paprika_swap_other_paprika_is_rejected` (el antirrebote se prueba ahora solo en el cuenco); en `test_seasoning_rules.gd` los 5 de `paprika_swap`/`EXCLUSIVE_TAKEN`/`swap_exclusive`; en `test_box.gd` el alternar de sal y `..._paprika_without_swap_is_rejected_silently`; en `test_data_catalog.gd` `test_pul028_*` (aceite y grupo `paprika`) y `test_pul033_*` (cachelos + aceite/sal); en `test_data_integrity.gd` `test_comandas_ac5_m1_data_ranges` (sustituido por `test_order_catalog.gd`) y `test_pul057_every_seasoning_color_is_opaque` conserva solo los 3 `.tres`.
- Tests adaptados (nuevos datos/API): `test_seasoning_rules`, `test_box`, `test_box_badges`, `test_box_model`, `test_box_on_slot`, `test_audio_feedback`, `test_cachelos`, `test_slot`, `test_trash_bin`, `test_order_stand`, `test_delivery_e2e`, `test_order_tickets` (la pegatina clara usa un condimento de prueba: ya no hay `.tres` de sal), `test_order_validator`, `test_order_board`, `test_data_catalog`, `test_data_integrity`, `test_m1_flow` (margen para las penalizaciones), `test_m2_flow`, `test_m2b_flow`, `test_m2b_station_selection`, `test_kitchen_flow`, `test_parity_smoke`, `test_station_level`, `test_level_01_r16`, `test_level_01` (`B_PASS_TO_STATION` 1,0 → 2,4 m por el cuenco en x 1), `tests/helpers/m0_data/orders/order_{1,2}.tres` y `tests/tools/capture_pul030.gd`. Nuevos: `test_order_catalog.gd`, `tests/tools/capture_pul114.{gd,tscn}`.
- Notas para el coordinador: (1) **Iconos**: el aliño dulce y el picante comparten `pepper-hot-solid.svg` (distintos por color y por la llama del picante); un icono propio del dulce es de asset-pipeline (`assets/` fuera de `owns`). (2) Los modelos `.glb` del rack y de la caja siguen mostrando S/M/L y la «M» (arte). (3) `comandas.md` AC13 (20 comandas por fase) queda para PUL-115 (`PhaseData.orders`). (4) `Rejection.NO_BOX`/`HAND_BUSY`/`EXCLUSIVE_TAKEN`/`NOT_ACCEPTED` siguen en el enum, sin emisores (como pide `signals.md`).
