---
id: PUL-024
title: Montar level_01 como el nivel de Unity con la UI integrada
status: ready
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
- [ ] AC1 Menú → Jugar carga `level_01` con 1 jugador, 4 puestos con comanda, HUD y tickets visibles → `test_level_01.gd`.
- [ ] AC2 Las posiciones de estaciones, puestos, jugador y cámara coinciden con `Level_01.unity` (±0,1 m / ±2°) → `test_level_01.gd` con tabla de referencia documentada.
- [ ] AC3 Reintentar tras `round_finished` deja comandas nuevas, olla libre y reloj completo, sin señales duplicadas → `test_level_01.gd`.
- [ ] AC4 El jugador puede alcanzar e interactuar con todas las estaciones y slots del nivel (prueba de recorrido) → `test_level_01.gd`.
- [ ] AC5 Captura del nivel completo con la cámara de juego junto a una captura de referencia de Unity si existe en el repo (si no, solo la de Godot) en `docs/evidence/PUL-024/`. `tools/verify.sh` en verde, `check_owns` limpio.

## Plan

## Evidence
