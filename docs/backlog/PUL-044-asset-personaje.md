---
id: PUL-044
title: Modelar y animar el personaje (dos variantes)
status: done
milestone: M3
role: asset-pipeline
agent: claude + MCP de Blender (PUL-043)
deps: [PUL-042, PUL-043]
orca_task: task_f939e1617273
unity_sources: []
owns: [art/blender/cook.blend, godot/assets/models/characters/cook/**, godot/entities/player/player.tscn, godot/entities/player/player_animation.gd, godot/entities/player/player_animation.gd.uid, godot/tests/integration/test_player_animation.gd, godot/tests/integration/test_player_animation.gd.uid, godot/assets/materials/active_indicator_p1.tres, godot/assets/materials/active_indicator_p2.tres, docs/evidence/PUL-044/**]
touches_scenes: [godot/entities/player/player.tscn]
---

## Target
D20: arte propio en Blender con un agente con MCP de Blender (pipeline de PUL-043), siguiendo la
biblia de arte (`docs/art/art-bible.md`, PUL-042).

## Change
1. Personaje cocinero/a de pulpería con dos variantes de color (J1, J2; paleta en la biblia). Rig y clips Idle, Walk, Pick, WalkWhileHolding y Cut (corte con pulsación repetida, D13). Sustituye a PUL-013 (bloqueada por licencia).
2. Fuente en `art/blender/cook.blend`; export `.glb` en `godot/assets/models/characters/cook/` con
   `tools/blender_export.py`.
3. Sustituir el placeholder en su escena (`Model`), sin cambiar colisiones ni nodos de contrato
   (`scene-tree.md` §3) salvo que se pida. AnimationTree con StateMachine (`speed`, `is_holding`) como pedía PUL-013; el aro de PUL-035 sigue visible.
4. Registrar la licencia (propia) en `docs/assets/licenses.md` → pedirlo al coordinador (fuera de `owns`).

## Ajustes de la biblia de arte (PUL-042)
Ajuste de la biblia (§4): `Idle` en bucle de 1–2 s y `Cut` con ciclo corto (D13); dos variantes en un mismo `.blend` con malla y rig compartidos y materiales distintos; marcador `Anchor_Hold` en las manos.

Nota de PUL-045: con el pulpo ×1,4 en la mano entra 6–9 cm en la cápsula; el `Anchor_Hold` del personaje (o adelantar `%HoldPoint` ~0,1 m) debe resolverlo.

Nota de PUL-047: en la mano el plato queda tapado por el `HoldPoint` provisional; el agarre del personaje debe dejar visible el plato y su relleno desde la cámara.

## Constraints
- Presupuesto de polígonos, escala, frente −Z y paleta de la biblia de arte.
- Antes de cerrar: `tools/verify.sh` verde y `tools/check_owns.py <tu-rama> jrmougan/agentica-migracion-godot-alpha` limpio.

## Acceptance
- [x] AC1 Escala y frente correctos frente a `scale_check.tscn` → `test_assets_models.gd`
- [x] AC2 Legible desde la cámara del nivel: captura en `docs/evidence/PUL-044/`
- [x] AC3 `.blend` y `.glb` versionados; escena sin errores de import
- [x] AC4 `tools/verify.sh` verde, `check_owns` limpio.

## Plan
1. `art/blender/cook.blend` desde `_template.blend`, generado con el MCP de Blender por
   `docs/evidence/PUL-044/build_cook.py` (registro reproducible, como PUL-045..047): malla low-poly
   con skin rígido (cada pieza pesa 1 en un hueso), esqueleto de 13 huesos sin dedos, frente +Y.
2. Variantes: misma geometría y mismo rig; J1/J2 solo cambian materiales (§2.6) y el gorro
   (J1 redondo, J2 alto de cocinero, tercer rasgo de §3.1.6). Como glTF no admite materiales por
   objeto, el `.glb` lleva `cook_body_j1/_j2` (copias de la misma malla) y `cook_hat_j1/_j2`.
3. Clips (30 fps, desde el fotograma 0): Idle (bucle 1,2 s), Walk (0,67 s), Pick (0,4 s),
   WalkWhileHolding (0,67 s), Cut (0,3 s, D13) y **IdleHolding** (bucle 1,2 s; quieto con algo en
   la mano sin bajar los brazos). Bucles marcados en `_subresources` del `.glb.import`.
4. `player.tscn`: `Model` = `cook.glb` (sin rotar, frente −Z); `%AnimationTree` nuevo (al final de
   los hijos para no mover el `index` que `level_01.tscn` usa en `Player2/Control`) con
   `player_animation.gd` (`PlayerAnimation`): StateMachine con transiciones por expresión
   (`speed > 0.1`, `is_holding`), Pick al `item_picked_up` del `Holder`, Cut en cada
   `amount_changed` del ingrediente que se lleva (el corte de `Box._cut` gasta el pulpo de la mano).
   Variante por `%Control.player_index` (se re-evalúa cada tick: vale aunque el índice cambie tras
   `_ready`). `player.gd` no se toca: el árbol lee `speed`/`is_holding` del `Player`.
5. `%HoldPoint` en `Anchor_Hold` (0, 1,20, −0,62): agarre centrado delante del pecho (ronda del
   responsable). Los objetos tienen el origen por encima de su base (plato 0,17 m, pulpo 0,26 m), así
   que la base del plato queda a 1,03 m, sobre las manos de la pose de llevar (brazos hacia delante,
   manos a ±0,22 m, 0,48 m por delante, 1,03 m de alto). Colisiones y demás nodos de contrato sin cambios.

## Evidence
- Fuente: `art/blender/cook.blend` (+ `build_cook.py`). Export:
  `blender -b art/blender/cook.blend --python tools/blender_export.py -- --category characters --animations --max-tris 2700`
  → `godot/assets/models/characters/cook/cook.glb` (8 objetos, 2 626 triángulos en total con las dos
  variantes; **1 320 por variante visible**, presupuesto 2 500). Alto 1,77 m (J1) / 1,90 m (J2, gorro
  alto), hombros 0,69 m con los brazos; origen en la base, `Anchor_Front` en +Y.
- Paleta: `mat_cook_j1_accent #2F6FB5`, `mat_cook_j2_accent #E0A02E`, `mat_cook_shirt #F7F4EC`,
  `mat_cook_trousers #4A4F63`, `mat_cook_j1_skin #EBC49A`, `mat_cook_j2_skin #A8734D`, más
  `mat_iron_black` (zapatos, ojos) y `mat_wood_dark` (pelo): 6 colores por variante.
- Tests: `godot/tests/integration/test_player_animation.gd` (13 casos: modelo y clips, duraciones
  de la biblia, estados Idle/Walk/Pick/IdleHolding/WalkWhileHolding/Cut, Cut por pulsación,
  variante por `player_index`, `%HoldPoint` = `Anchor_Hold` fuera de la cápsula, centrado a la altura del pecho, aro visible y
  colores del aro J1 `#2F6FB5` / J2 `#E0A02E`).
  `test_assets_models.gd` valida el `.glb` (escala, frente, base). `tools/verify.sh`: 639/639 OK.
- Capturas desde la cámara de `level_01` (1920×1080), tras los ajustes del responsable:
  `hold_j1_octopus_j2_plate_{front,back,side,three_quarter}.png` (J1 con pulpo cocido ×1,4, J2 con
  plato grande lleno) y `hold_j1_plate_j2_octopus_*.png` (al revés), con sus recortes ×2
  `hold_zoom_j1_octopus_j2_plate.png` / `hold_zoom_j1_plate_j2_octopus.png`; `animation_frames.png`
  y `animations.gif` (todos los clips, J1 de tres cuartos, IdleHolding/WalkWhileHolding/Cut con el
  pulpo); `blender_render.png`. Script de captura: `capture_level.gd.txt`
  (`xvfb-run -a godot --path godot --resolution 1920x1080 -s <script>`).
- Observaciones para el coordinador:
  - Ajustes del responsable: (1) agarre centrado a la altura del pecho con los brazos hacia delante;
    de frente, de perfil y de tres cuartos pulpo ×1,4 y plato grande se ven enteros y no atraviesan
    el cuerpo; (2) aros J1 azul `#2F6FB5` y J2 ámbar `#E0A02E` (`active_indicator_p1/p2.tres`).
  - **Limitación aceptada (opción A del coordinador)**: de espaldas a la cámara (38°) el pulpo asoma
    a los lados de la cabeza, pero el plato lo tapan la cabeza y el gorro alto de J2 (en J1 solo
    asoma el borde). Probado: ni adelantándolo a 0,70 m ni subiéndolo a los hombros asoma tras el
    gorro de J2. De espaldas el plato se identifica por su fila de pegatinas (PUL-059); el gorro
    alto de J2 (rasgo para daltónicos) no se toca. Capturas `hold_*_back.png`.
  - El aro sigue a `controlled_by` y la variante a `player_index` (identidad del personaje).
  - Licencia propia: la registra el coordinador en `docs/assets/licenses.md`.
