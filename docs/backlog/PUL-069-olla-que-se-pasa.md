---
id: PUL-069
title: Quemar el pulpo que se deja en la olla y encender sus efectos
status: done
milestone: M3
role: gameplay-engineer
deps: [PUL-066]
orca_task: task_a701d519e04d
unity_sources: []
owns: [godot/entities/stations/cooking_station.gd, godot/entities/stations/kitchen.tscn, godot/entities/items/ingredient.gd, godot/resources/ingredient_data.gd, godot/resources/kitchen_data.gd, godot/data/config/kitchen.tres, godot/data/ingredients/*.tres, godot/assets/models/food/**, art/blender/octopus.blend, art/blender/cachelos.blend, godot/tests/integration/test_cooking_station.gd, godot/tests/integration/test_octopus.gd, godot/tests/integration/test_burn.gd, godot/tests/integration/test_burn.gd.uid, docs/evidence/PUL-069/**]
touches_scenes: [godot/entities/stations/kitchen.tscn]
---

## Target
`features/olla-que-se-pasa.md` (AC1–AC4) con los contratos de PUL-066. Absorbe PUL-065 (fuego y
vapor solo al cocinar).

## Change
Quemado tras `burn_time` con aviso visual desde `warn_time` (parpadeo de la barra), estado `BURNT`
con malla `*_burnt` (modelado con el MCP de Blender en los `.blend` de pulpo/cachelos, estilo
aprobado) y rechazo al cortarlo; desechable para liberar la plaza (define dónde, p. ej. al
interactuar con la olla con la mano vacía o un cubo). Vapor solo con plazas cociendo y fuego vivo
al cocer; se congela en pausa.

## Constraints
- Datos en `.tres`. Antes de cerrar: `tools/verify.sh` verde y `tools/check_owns.py <tu-rama> jrmougan/agentica-migracion-godot-alpha` limpio.

## Acceptance
- [x] AC1–AC4 de la feature → `test_burn.gd`
- [x] AC5 Vapor/fuego según estado y congelados en pausa → test
- [x] AC6 Capturas cocido, aviso y quemado en `docs/evidence/PUL-069/`
- [x] AC7 `tools/verify.sh` verde, `check_owns` limpio.

## Plan
1. **Datos**: `IngredientData.burn_time`/`warn_time` (0 = no se quema); `octopus.tres` y
   `cachelos.tres` a 10 / 7 s (ADR-006 §5). Test de invariante sobre los `.tres`.
2. **`Ingredient.set_burnt()`** → `BURNT` y malla `*_burnt` (`_apply_state_variants` ya la prevé).
3. **`CookingStation`**: cada plaza guarda `since_finished`, `warned`, `burnt`; en
   `_physics_process` (congelado en pausa) tras `cooking_finished` cuenta mientras el ingrediente
   siga en la plaza: `warn_time` → `burn_warned` y `%CookBar` visible, vaciándose y parpadeando
   (modulate alterno según el reloj de la plaza); `burn_time` → `set_burnt()` + `burnt`, barra oculta.
   Mano vacía: desecha el `BURNT` más antiguo (`discarded`, `queue_free`, plaza libre) antes de
   dar un cocido FIFO; los quemados nunca se dan. Recoger a tiempo detiene el reloj.
4. **Vapor y fuego** (absorbe PUL-065): `Model/Steam.emitting` solo con alguna plaza cociendo;
   `Model/Fire.amount_ratio` bajo en reposo y 1 al cocer. Las partículas se congelan con la pausa.
5. **`kitchen.tscn`**: nodo `%Feedback` (AudioStreamPlayer3D, bus SFX, sin script ni stream) para
   que PUL-071 le ponga `FeedbackPlayer` y conecte las cues; sin audio nuevo.
6. **Mallas**: `octopus_burnt`/`cachelos_burnt` con el MCP de Blender por CLI (copia del cocido,
   encogida y arrugada, tonos carbonizados), reexport con `tools/blender_export.py`.
7. **Tests**: `test_burn.gd` (AC1–AC5), `test_octopus.gd` (malla `_burnt` real del `.glb`).
   Capturas con el MCP de Godot (AC6).

## Evidence
- **Datos**: `IngredientData.burn_time`/`warn_time` (0 = no se quema); `octopus.tres` y
  `cachelos.tres` a 10 / 7 s. Invariante (`warn_time > 0`, `burn_time − warn_time ≥ 3`) en
  `test_burn.gd::test_data_burn_and_warn_times_come_from_tres`.
- **Olla** (`cooking_station.gd`): señales locales `burn_warned`, `burnt`, `discarded` (signals.md
  §4). Reloj por plaza en `_physics_process` tras `cooking_finished`; aviso con `%CookBar` visible,
  vaciándose hacia el quemado y parpadeando (alfa 1 ↔ 0,15 cada 0,2 s de juego: un tinte de color
  dejaba el verde en un marrón poco legible). Mano vacía: desecha el quemado más antiguo antes del
  cocido FIFO; recoger a tiempo para el reloj. `has_burnt()` público para consultas.
- **Vapor y fuego** (absorbe PUL-065): `Model/Steam.emitting` solo con alguna plaza cociendo;
  `Model/Fire.amount_ratio` 0,3 en reposo y 1 al cocer (constantes visuales, no balance).
- **`%Feedback`** en `kitchen.tscn`: `AudioStreamPlayer3D` sin script ni stream, listo para que
  PUL-071 le ponga `FeedbackPlayer` y conecte las cues `cook_start`/`cook_done`/`burn_warning`/
  `burnt`/`discard`. No he cableado audio nuevo.
- **Mallas** con el MCP de Blender por CLI (`execute_blender_code_for_cli`, sin puerto 9876):
  `octopus_burnt` (568 tris, 0,53 × 0,53 × 0,27 m) y `cachelos_burnt` (312 tris), copias del cocido
  encogidas (×0,9 en planta, ×0,82 en alto) y arrugadas, con materiales nuevos de color plano
  `mat_octopus_burnt` `#3B2226`/`_dark` `#1C1012` y `mat_potato_burnt` `#4A3524`/`_dark` `#1E150E`
  (roughness 0,95); el pulpo mantiene los ojos `mat_salt`. Script reproducible:
  `docs/evidence/PUL-069/build_burnt.py`. Reexport: `blender -b art/blender/<asset>.blend --python
  tools/blender_export.py -- --category food --max-tris 1800` → `OK octopus.glb (5 objetos, 1576
  triángulos)`, `OK cachelos.glb (5 objetos, 824 triángulos)`; cada variante ≤ 600 (art-bible §2.2).
- **AC1–AC4** → `test_burn.gd`: quema a los 10 s y no a 9,9 s, `burnt` una sola vez, malla `_burnt`
  (pulpo y cachelos), `burn_time` = 0 nunca quema; aviso a los 7 s con barra visible, parpadeando y
  vaciándose; la caja rechaza cortar un quemado; mano vacía desecha (`discarded`, `queue_free`,
  plaza libre), primero el quemado más antiguo y después da el cocido; recoger a tiempo para el
  reloj; la pausa congela el reloj. `test_octopus.gd`: la malla `octopus_burnt` real del `.glb`.
- **AC5** → `test_burn.gd::test_ac5_*`: vapor solo cociendo, fuego vivo/bajo, y las partículas no
  procesan con el árbol en pausa (siguen `emitting`, quedan congeladas).
- **AC6**: capturas desde la cámara de `level_01` (1920×1080 y recorte ×2), pulpo y cachelos en
  `Stations/Kitchen`: `level_camera_cooking*.png` (vapor, fuego vivo, barras), `level_camera_cooked*.png`,
  `level_camera_warning*.png` y `level_camera_warning_blink*.png` (dos fases del parpadeo),
  `level_camera_burnt*.png`. Script: `capture_burn.gd` (avanza el reloj de la olla a mano).
- **AC7**: `tools/verify.sh` verde (660 tests, 8234 asserts); `check_owns` limpio.
