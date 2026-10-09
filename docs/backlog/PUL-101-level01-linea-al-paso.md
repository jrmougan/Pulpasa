---
id: PUL-101
title: Montar level_01 con la línea al paso, el hueco nuevo y 6 pasaplatos
status: review
milestone: M3c
role: gameplay-engineer
deps: [PUL-097, PUL-098, PUL-100]
orca_task: null
unity_sources: []
owns: [godot/entities/stations/slot.tscn, godot/entities/stations/slot.gd, godot/components/hold_component.gd, godot/tests/**/test_slot.gd, godot/tests/**/test_hold*.gd, godot/scenes/levels/level_01.tscn, godot/entities/environment/kitchen_layout.tscn, godot/tests/integration/level_walker.gd, godot/tests/integration/test_level_01.gd, godot/components/holder.gd, godot/components/interaction_component.gd, godot/tests/integration/test_level_01_r16.gd, godot/tests/integration/test_level_01_r16.gd.uid, docs/evidence/PUL-101/**, docs/backlog/PUL-101-level01-linea-al-paso.md]
touches_scenes: [godot/entities/stations/slot.tscn, godot/scenes/levels/level_01.tscn, godot/entities/environment/kitchen_layout.tscn]
---

## Target
Nivel `level_01` (planta B) según D23 y `level-layouts.md` reescrito.

## Change
Hueco de la barra a x≈3,2 con el umbral de PUL-095; 6 `PassSlot` con `pass_mark` visible y el resto de la barra sin `Slot`; estación sin bandeja; `GAP_X` del `level_walker`. `pass_mark` va en `slot.tscn` (ADR-003 §9). Si R11 exige que pulsar fuera de un `PassSlot` no suelte la caja, cámbialo en `HoldComponent` con su test. Retira los restos ocultos de QA D9 en `PassSlot` (placeholder `table_square`). Revisión de PUL-095: las placas `SizePanel_*`/`SizeFront_*` de `box_shelf.glb` quedan ~0,5 m fuera de la colisión del rack; ajústala si el jugador las atraviesa. Revisión de PUL-097: la estación mide 5,2 m (en `level_01` en x=0,2 ocupa −2,4…2,8) y se solapa con `PassSlot04` (x=−2,3) y `PassSlot05` (x=2,7), que usan `test_m2b_flow` y los tests de flujo: recoloca los 6 `PassSlot` fuera del tramo y ajusta esos tests. `get_tray()`/`get_box()` ya no existen (la caja se condimenta en la mano). La raíz de dispensadores y cuenco queda 0,45/0,25 m hacia el pase respecto al arte: para anclar algo al arte usa su nodo `Model`. Los cortes son ahora 4/6/10 (PUL-098). Hallazgos de PUL-100: los kioscos de `level_01` están en y=−0,04 y la marca `delivery_zone` (y −0,02…0,004) queda bajo el suelo: ponlos en y=0 o la zona encendida no se verá. Las 4 zonas (mundo Z≈2,35) no chocan con nada; cualquier ruta del walker de la barra al kiosco las cruza y entrega si lleva la caja correcta (comportamiento deseado).

## Constraints
- `tools/verify.sh` en verde; GDScript tipado; datos en `.tres`. Godot con `--audio-driver Dummy`; con el MCP, silencia los buses.
- Diseño: D23 en `docs/design/decisions.md` y `docs/design/rediseno-estaciones.md` (R1–R17). Las features reescritas (PUL-092) y los contratos (PUL-093) mandan.

## Acceptance
- [x] AC1 R11: exactamente 6 `PassSlot` marcados; fuera de ellos y de la estación no se suelta nada → test
- [x] AC2 R14: camino más corto cara de condimentar ↔ cara de pase 6–10 m → test
- [x] AC3 R16: Individual, 2 pedidos S con un pulpo y 2 cambios en total → test con el walker
- [x] AC4 Captura del nivel completo a 1080p

## Plan
Ficheros: `slot.tscn` (Model = `pass_mark.glb`, sin `table_square`), `level_01.tscn` (6 `PassSlot` 3+3 fuera del tramo -2,4..2,8, hueco x 2,8..4,2 (centro 3,5), `pass_threshold`, kioscos y=0, sin overrides de Model/Body, rack), `kitchen_layout.tscn` (barra este desde x 4,0 hasta la pared, sin hueco en x 7,7, rejilla del hueco), `level_walker.gd` (`GAP_X`), `test_level_01.gd`, `hold_component.gd` (+ su test) y los tests de flujo que usan `PassSlot0N`/coordenadas.

- AC1 (R11): `test_level_01.gd::test_r11_*`: 6 `Slot` exactos, nombres `PassSlot01..06`, fuera de la estación (-2,4..2,8) y del hueco; cada marca >= 18 px a 1280x720 con la cámara real; ningún otro `Slot` en el nivel; barrido de la barra con el walker: con una caja en la mano frente a la barra (fuera de los pasaplatos y de la estación) la caja no queda sobre/dentro de la barra (HoldComponent suelta a los pies si el punto cae en la capa `world`; test en `test_hold_component.gd`).
- AC2 (R14): Dijkstra de `test_level_01.gd` de la cara de condimentar a la cara de pase de la estación, 6-10 m; hueco en x en [2,7; 3,7+] con >= 1,0 m libre; x 7,7 cerrado.
- AC3 (R16): `test_level_01.gd::test_r16_*` con el walker (teclado): Individual, 2 pedidos S con un pulpo, `order_completed` x2 y exactamente 2 `p1_switch`.
- AC4: `docs/evidence/PUL-101/capture_level.gd` -> PNG 1080p del nivel completo.
- Señales: ninguna nueva.

## Evidence
- `tools/verify.sh`: gdformat y gdlint limpios, import, **778 tests GUT en verde** (69 scripts), smoke OK.
- **AC1 R11** (`test_level_01.gd::test_r11_*`): exactamente 6 `Slot` en el nivel (`PassSlot01..06`, x -5,3 / -4,3 / -3,3 / 4,7 / 5,7 / 6,7), todos con `pass_mark.glb`, fuera de la estación (-2,4..2,8) y del hueco; cada marca >= 18 px a 1280x720 con la cámara real; barrido de la barra con una caja en la mano fuera de pasaplatos y estación (cada 0,5 m, por los dos lados, al menos 8 posiciones comprobadas): la mano no cambia (la caja sigue en ella) y ningún `Slot` la guarda. Test de `HoldComponent` en `test_hold_component.gd` (`test_r11_*`). El barrido falla sin el cambio de `HoldComponent` (comprobado) y pasa con él.
- **AC2 R14** (`test_r14_*`, Dijkstra con la cápsula real): cara de condimentar (`%OperatorSide`) a cara de pase (`%PassSide`) = **7,93 m** (rango 6-10). Hueco libre de 1,4 m (x 2,8..4,2, centro 3,5), umbral `pass_threshold` en el hueco, x 7,7 cerrado (`test_r11_bar_is_closed_*`).
- **AC3 R16** (`test_level_01_r16.gd`, con el walker y el teclado): Individual, 2 pedidos S (dulce+sal y aceite+dulce), un solo pulpo cocido (una vez de nevera), 2 `order_completed` y exactamente 2 pulsaciones de `p1_switch` (y 2 `character_switched`), sin `delivery_rejected`.
- **AC4**: [nivel completo a 1080p](level_1080.png) y [zoom de la barra](bar_zoom.png) (6 marcas, hueco con umbral, estación al paso; cajas S y M sobre dos marcas). Script: `capture_level.gd`.
- Rack (revisión PUL-095): las placas `SizePanel_*`/`SizeFront_*` quedan ~0,5 m fuera de la colisión del rack, pero las cajas (spawners, capa interactable) bloquean al jugador antes de ellas: `test_rack_plates_cannot_be_walked_into` lo comprueba en la rejilla alcanzable. No hizo falta tocar `box_shelf.tscn` ni su colocación.
- Kioscos de `level_01` y `y=0`: marca `delivery_zone` sobre el suelo. `slot.tscn` sin restos de `table_square` ni overrides de Model/Body en el nivel.

Decisiones y desviaciones:
- Layout 3 + 3 pasaplatos (no 4 + 2 de `scene-tree.md`): la estación de 5,2 m deja 3,4 m al oeste (3 marcas de 1 m) y las marcas se alinean con las ventanas de los módulos de barra `pass_*` (1 por metro) para que no queden marcos huérfanos. Barra oeste: `pass_2m` + `pass_1m` + `counter_1m`; barra este (4,2..8,2): `pass_end` girado + `pass_2m` + `counter_1m`.
- Hueco x 2,8..4,2 (1,4 m, centro 3,5 en [2,7; 3,7]); `GAP_X` del walker = 3,5.
- R11 literal (decisión del coordinador): `Holder.can_drop_freely()` (por defecto `true`; `HoldComponent` lo hace `false` si el punto de soltar cae en la capa `world`) e `InteractionComponent.interact_pressed()` consume la pulsación sin soltar; `drop()` no cambia para las transferencias (slot, olla, cuenco, puesto). Añadidos `holder.gd` e `interaction_component.gd` a `owns`.
- `B_EXIT_J2_TO_J1` de `test_level_01.gd` pasa de 18,2 a 12,3 m (el hueco se acorta por D23; el resto de distancias de PUL-041 siguen dentro de +-1 m).
- `test_slot.gd`: el test de la mesa propia del slot se sustituye por uno de la marca `pass_mark` (D23, §9.5).
- `test_level_01.gd` superaba 1000 líneas: R16 va en `test_level_01_r16.gd` (nuevo, añadido a `owns` con su `.uid`).
- Ficheros fuera de `owns` adaptados: ninguno (los tests de flujo `test_m2b_flow`, `test_delivery_e2e`, `test_parity_smoke`, `test_m2b_station_selection`, `test_station_level` pasan sin cambios; `PassSlot05` queda en x 5,7).
- Pendiente para una ficha de sandbox: los `Slot` de `kitchen_sandbox`, `player_sandbox` e `items_sandbox` quedan con la marca flotando sin mesa.
