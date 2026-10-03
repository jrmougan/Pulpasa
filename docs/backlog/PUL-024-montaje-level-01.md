---
id: PUL-024
title: Montar level_01 como el nivel de Unity con la UI integrada
status: review
milestone: M0
role: gameplay-engineer
deps: []
orca_task: null
unity_sources: [Assets/Scenes/Levels/Level_01.unity, Assets/Prefabs/**, Assets/Settings/**]
owns: [godot/scenes/levels/**, godot/entities/environment/**, godot/entities/stations/slot.tscn, godot/tests/integration/test_level_01.gd, godot/tests/integration/test_level_01.gd.uid, godot/tests/integration/test_slot.gd, docs/evidence/PUL-024/**]
touches_scenes: [godot/scenes/levels/level_01.tscn, godot/entities/environment/environment.tscn, godot/entities/environment/kitchen_layout.tscn, godot/entities/stations/slot.tscn]
---

## Target
Fase 8 de M0: `scene-tree.md` §2 y ADR-003 §2 (`level_01.tscn` solo instancia). `GameState.LEVEL_SCENE`
ya apunta a `res://scenes/levels/level_01.tscn`.

## Change
1. `scenes/levels/level.gd` (común, `extends Node`, genérico): `@export round_config`, `@export order_catalog`,
   `@export stands: Array[OrderStand]`… (sin tipos específicos en la firma: usa `Array[Node]` si hace falta,
   ADR-003 §0). En `_ready`: `OrderService.setup(order_catalog)` y `RoundManager.start_round(round_config,
   slot_ids de los puestos)`, en ese orden y una sola vez (B10/B11). Reintentar (recarga de escena) debe
   dejar el estado limpio.
2. `entities/environment/environment.tscn` (WorldEnvironment + DirectionalLight3D con la luz de Unity) y
   `kitchen_layout.tscn` (suelo + las 17 mesas de `Level_01.unity` como placeholders de PUL-008, capa `world`).
3. `scenes/levels/level_01.tscn`: instancias con las **posiciones y rotaciones de `Level_01.unity`**
   convertidas a Godot (−Z adelante; documenta la conversión): nevera, olla, estantería de cajas,
   estantería de especias, 4 puestos (`slot_id` 1–4), jugador 1 con `items_root = Items`, `CameraRig` con la
   cámara de Unity y `UI` (HUD, tickets, pausa, game over). Overrides solo de transform, `slot_id`,
   `player_index`, `controlled_by` y referencias.
4. Pendientes de `docs/design/roadmap.md` (fase 8): Mueblecajas con la rotación de Unity sobre el envoltorio
   −Z; ajustar la colisión `interactable` de `slot.tscn` para que no detenga al jugador ~0,7 m antes del mueble
   (el detector debe seguir alcanzando); colocar las especias para que devolverlas sea viable.

## Constraints
- Nada de lógica en el nivel aparte de `level.gd`. Ninguna escena nueva que duplique entidades existentes.
- `.tscn` con script tipado o editor; no inventes uid. Si necesitas tocar otra escena de entidad, pregunta.

## Acceptance
- [x] AC1 Menú → Jugar carga `level_01` con 1 jugador, 4 puestos con comanda, HUD y tickets visibles → `test_level_01.gd`.
- [x] AC2 Las posiciones de estaciones, puestos, jugador y cámara coinciden con `Level_01.unity` (±0,1 m / ±2°) → `test_level_01.gd` con tabla de referencia documentada.
- [x] AC3 Reintentar tras `round_finished` deja comandas nuevas, olla libre y reloj completo, sin señales duplicadas → `test_level_01.gd`.
- [x] AC4 El jugador puede alcanzar e interactuar con todas las estaciones y slots del nivel (prueba de recorrido) → `test_level_01.gd`.
- [x] AC5 Captura del nivel completo con la cámara de juego junto a una captura de referencia de Unity si existe en el repo (si no, solo la de Godot) en `docs/evidence/PUL-024/`. `tools/verify.sh` en verde, `check_owns` limpio.

## Plan
- **Conversión Unity → Godot** (documentada en `test_level_01.gd` y aquí): posición `(x, y, z)` → `(x, y, −z)`;
  rotación cuaternión `(x, y, z, w)` → `(−x, −y, z, w)` (espejo en Z), es decir, yaw y pitch cambian de signo.
  El frente +Z de un prefab Unity queda en −Z, que es el frente de las escenas Godot.
  Excepciones documentadas en la tabla del test: `Kitchen` (la raíz del prefab está desplazada; se usa el
  centro de su collider y el suelo como Y), `Mueblecajas`/`MuebleEspecias` (el FBX tiene el frente en −X
  local; con −90° de Unity mira a −Z Unity → +Z Godot, así que el envoltorio con frente −Z va a yaw 180°).
- `scenes/levels/level.gd` (común, `extends Node`): `round_config`, `order_catalog`, `stands: Array[Node]`;
  `_ready` → `OrderService.setup` y `RoundManager.start_round(slot_ids)` una vez. Recarga = nodo nuevo, estado limpio.
- `entities/environment/environment.tscn`: `WorldEnvironment` (cielo procedural, ambiente de cielo) +
  `DirectionalLight3D` con la luz de Unity (blanca, 1,34, sombras, rotación convertida).
- `entities/environment/kitchen_layout.tscn`: suelo (`Terrain`, plano 10 m × escala de Unity, capa `world`)
  + 17 mesas (`Prop_KitchenTable_04/06/07` → `table_long/medium/square` de PUL-008), colocadas en el centro
  de su collider Unity convertido.
- `scenes/levels/level_01.tscn`: árbol de `scene-tree.md` §2 (sin Player2/CharacterSwitcher, M2).
- `slot.tscn`: la colisión `interactable` pasa a la de Unity (`InteractableSlot`: 0,43 × 0,1 × 0,475 a la
  altura del ancla) para no frenar al jugador ~0,7 m antes del mueble; la mesa del slot suelto conserva su
  propio cuerpo `world`.
- Escenas generadas con un script tipado headless (PackedScene + ResourceSaver), retirado al terminar.
- Tests (`tests/integration/test_level_01.gd`): AC1 árbol/UI/comandas, AC2 tabla de referencia, AC3
  reintento (segunda instancia del nivel tras `round_finished`), AC4 recorrido (BFS de la cápsula sobre
  rejilla desde el spawn hasta un punto de acceso por objetivo + detector elige el objetivo + interacción).
  `test_slot.gd`: AC4 (colisión del slot no sobresale más de 0,5 m).

## Evidence
- `tools/verify.sh`: ✓ verify OK (gdformat, gdlint, import, GUT 367/367, smoke).
- AC1–AC4: `godot/tests/integration/test_level_01.gd` (11 tests). The reference table and the Unity → Godot
  conversion are documented in the test header. AC4 runs a BFS over the player's capsule on a 0.2 m grid from
  the spawn point. From reachable cells the detector picks each target and the interaction works: fridge → pot,
  the 3 box spawners → the 4 stands, and taking and returning the 3 spices (the empty slot wins with a jar in hand).
- Slot collision: `test_ac4_spice_slots_do_not_stop_player_far_from_the_shelf` fails with the old
  `slot.tscn` (player stops 1.07 m from the slot) and passes with the Unity shape (0.43 × 0.1 × 0.475 at anchor
  height). Added `test_slot.gd` `test_pul024_*`. The standalone slot is still blocked by its table (`world` layer).
- AC5: `docs/evidence/PUL-024/ac5-level_01-camara-juego.png` (Menu → Play via MCP, no errors in
  `get_debug_output`). There is no Unity reference capture in the repo.
- Notes for review: the 4 tickets panel covers the back row of stations (fridge, pot, shelves) with the game
  camera. This is a UI layout issue (`order_tickets_panel.tscn`, outside `owns`), a candidate for PUL-023.
  Unity's scale on the stands (0.78 × 0.975 × 0.975) is applied as a transform override.
  Kitchen uses its collider centre and floor Y (the Unity prefab root is offset). Scenes were generated with a
  typed headless script that was then removed. Spurious anchor overrides on the UI instances were cleaned up by hand.
