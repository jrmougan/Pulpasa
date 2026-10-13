# PUL-139 — Triaje de los pendientes sueltos del roadmap

Rama `jrmougan/pul-139` sobre `ac249d1` (M3e cerrado hasta PUL-138). Fecha: 2026-10-13. Fuente: las
secciones «Pendientes detectados para la fase 8», «en M1», «en M3» y «en M3b» de
`docs/design/roadmap.md` (la de arte M3 ya está resuelta en PUL-067 y no se repite).

Estados: **resuelto** (con la ficha o commit), **vivo** (sigue pasando hoy) u **obsoleto** (el diseño
actual ya no tiene la pieza). Rutas de `godot/` relativas a `godot/`.

## Contenido

| Ruta | Qué es |
|---|---|
| `capture_stand_pop.gd` | Captura reproducible del POP del puesto 1 (`order_new` y `deliver_ok`) por fracciones de `visual_time` |
| `order_new_strip.png`, `deliver_ok_strip.png` | Tiras de 5 fotogramas (0, 15, 35, 55 y 100 % de `visual_time`) |
| `pop/full_deliver_ok_0.png` | Captura completa del nivel (1920×1080, Xvfb); el script deja también los fotogramas sueltos en `pop/`, que no se versionan |

Uso: `xvfb-run -a godot --path godot --audio-driver Dummy --resolution 1920x1080 -s
"$PWD/docs/evidence/PUL-139/capture_stand_pop.gd" -- "$PWD/docs/evidence/PUL-139/pop"`.

## Tabla de pendientes

| # | Pendiente (sección) | Estado | Prueba | Ficha / nota |
|---|---|---|---|---|
| F8-1 | Colisión `interactable` de `slot.tscn` (1,37 m) detiene al jugador ~0,7 m antes (fase 8) | **resuelto** | Reducida en PUL-024 (`2388634`); hoy `entities/stations/slot.tscn:9` `size = Vector3(0.43, 0.1, 0.475)` (PUL-101 la conserva) | — |
| F8-2 | Colocar Mueblecajas con la rotación de Level_01 (−90°) (fase 8) | **resuelto** | PUL-024 montó el rack girado; hoy `box_shelf.tscn` (modelo propio de PUL-081) en `scenes/levels/level_01.tscn:72` con `Transform3D(0, 0, -1, …, 1, 0, 0, -6.3, 0, 2.5)` | — |
| F8-3 | Con un bote en la mano el detector prefiere el bote al slot vacío de la estantería (fase 8) | **obsoleto** | D18 quitó los botes (estación de condimentos) y D23/D25 la dejaron en dispensadores al paso; no hay botes en `entities/items/` | — |
| F8-4 | La caja del `SmallSpawner` no coincide en color con su cajón (fase 8) | **obsoleto** | D25 (caja única): un solo `BoxSpawner` (`entities/stations/box_shelf.tscn:24`; `docs/arch/scene-tree.md:602`) | — |
| M1-1 | Test FIFO de PUL-029 no distingue finalización de índice (A plaza 0, B plaza 1 a 2,5 s, recoger A, C en plaza 0 → sale B) (M1) | **resuelto** | `test_ac3_fifo_discriminates_finish_order_from_slot_index` (`tests/integration/test_cooking_station.gd:335`), PUL-032 (`c2c231a`); es exactamente el caso del roadmap | — |
| M1-2 | Sin test del cambio de material crudo/cocido del cachelo (M1) | **resuelto** | `test_pul046_state_meshes_and_palette` (`tests/integration/test_cachelos.gd:110`), PUL-046 (`e38ac9a`): mallas por estado, `mat_food_potato_raw`/`_cooked` y luminancia | — |
| M1-3 | Sin test de la posición de las plazas de la olla (M1) | **vivo** | `cooking_station.gd:106-139` coloca anclas (`SLOT_SPACING = 0.3`) y anillos por plaza; ningún test lo mira (solo `test_ac2_octopus_anchor_point_sits_on_pot_anchor`, plaza 0) | **PUL-143** |
| M1-4 | El cachelo no se ve en la captura (M1) | **resuelto** | Modelo propio en PUL-046 y v2 en PUL-080; se ve en las capturas de PUL-102/PUL-116 | — |
| M3-1 | Escucha humana del audio: BG celta, FOL de multitud, `cook_start`/`cook_done` reutilizan FX (M3) | **vivo** (escucha humana) | Sin cambios de `data/audio/` en ese sentido; no es verificable por un agente | **Nota, sin ficha**: va a los playtests de M4 (PUL-141) |
| M3-2 | Balance fase 3: `order_2` (56 s) frente a ~54 s de ruta (M3) | **obsoleto** en su forma; balance vivo | `order_2` ya no existe: D25 dejó 4 comandas por contenido (`data/orders/`); el ritmo se re-mide en PUL-116 (`m3d-gate.md`) | **Nota, sin ficha**: balance de M4 (PUL-141) |
| M3-3 | El POP del puesto tapa un instante su número (M3, PUL-071) | **vivo** | `deliver_ok_strip.png`: el «1» del frente se ve en reposo (fotogramas 0 y 4) y **desaparece** en 15–55 % del POP (queda el disco de la placa vacío). `order_new` (POP de `%OrderLabel`) no lo tapa; `#998` roza los bordes de la placa en el pico | **PUL-142** |
| M3-4 | Segundo playtest de M2b con arte y audio (M3) | **resuelto** (superado) | Las puertas humanas posteriores ya jugaron con arte y audio: `docs/design/m3c-gate.md`, `docs/design/m3d-gate.md` | — |
| M3b-D1 | Rótulo #id de los kioscos sin placa (QA PUL-087) | **resuelto** | PUL-096 (`118b094`): `%OrderLabel` sobre la placa papel del modelo (`docs/arch/scene-tree.md:292`); en `order_new_strip.png` `#998` va sobre la placa clara | — |
| M3b-D2 | Vapor de la olla apenas visible | **vivo** | `entities/stations/kitchen.tscn:119` `Steam` sigue con `amount = 8`; el último cambio de la escena (PUL-125) no toca el vapor | **PUL-144** |
| M3b-D3 | La tapa abierta de la olla flota | **vivo** | `assets/models/stations/pot/` sin cambios desde PUL-078; en `pop/full_deliver_ok_0.png` las tapas siguen como discos grises sobre las ollas | **PUL-144** |
| M3b-D4 | Ambiente algo claro/amarillo | **vivo** | `data/config/render_config.tres:35` `ambient_light_energy = 0.5`, `:48` `adjustment_contrast = 1.1` (los de la propuesta); último cambio PUL-089 | **PUL-145** (decisión de dirección de arte) |
| M3b-D5 | Materiales duplicados por .glb (239 recursos) | **vivo** | Ninguno de los 40 `*.glb.import` de `assets/models/` usa materiales externos | **PUL-146** |
| M3b-D6 | Texturas duplicadas al importar | **vivo** | `assets/models/**`: 367 PNG, solo 64 distintos por md5 | **PUL-146** (con pregunta sobre §4.2) |
| M3b-D7 | Acero delantero brilla casi blanco | **vivo** | `assets/materials/v2/mat_steel_brushed_top.tres` sin cambios desde PUL-074 y luces de `environment.tscn` sin cambios desde PUL-085 | **PUL-145** |
| M3b-D8 | Panel «Turno» tapa la mesa de comensales izquierda | **vivo** (aceptado) | `pop/full_deliver_ok_0.png`: el panel tapa los comensales de la izquierda (zona no jugable); PUL-087 lo dio por aceptable (grav. B) | **Nota, sin ficha**: no afecta al juego; si el responsable lo quiere, cabe en una ficha de HUD de M4 |
| M3b-D9a | Los `PassSlot` instancian `table_square.tscn` oculto | **resuelto** | PUL-101 (`3c394e7`) rehízo `slot.tscn`; `grep table_square` en `slot.tscn` y `level_01.tscn`: 0 | — |
| M3b-D9b | `art/blender/romeria.blend` (fuente v1) sigue en el repo | **vivo** | El fichero existe; ninguna escena usa ya modelos de esa fuente (`environment.tscn` carga `romeria_v2/*.glb`) | **PUL-146** |
| M3b-SC | `scene-tree.md` sin `Bulbs`/`Vignette` | **resuelto** | PUL-093 (`a84a807`): `docs/arch/scene-tree.md:125,424-432` | — |
| M3b-MCP | El MCP no admite `--audio-driver Dummy` | **vivo** (herramienta) | Limitación de godot-mcp-runtime, no del juego; documentada en la skill `godot-verify` («comprueba el audio por señales») | **Nota, sin ficha**: no es trabajo del juego |

Resumen: 24 pendientes → 9 resueltos o superados, 3 obsoletos, 12 vivos. De los vivos, 9 van en las
fichas PUL-142..146 y 3 quedan como nota (escucha de audio, D8 aceptado, limitación del MCP). El
balance de la fase 3 es obsoleto en su forma y lo recoge el plan de M4 (PUL-141).

## Fichas creadas (todas `draft`, hito M4)

| Ficha | Pendientes | Rol | Escenas | Pregunta abierta |
|---|---|---|---|---|
| PUL-142 | M3-3 POP del puesto | gameplay-engineer | `order_stand.tscn` | Si el arreglo cambia `pulse_target` o mueve `StandNumber`, es enmienda de `scene-tree.md` (arquitecto) |
| PUL-143 | M1-3 test de plazas de la olla | gameplay-engineer | — | — |
| PUL-144 | D2 vapor, D3 tapa | asset-pipeline | `kitchen.tscn` | — |
| PUL-145 | D4 ambiente, D7 acero | asset-pipeline | `environment.tscn` | Sí: ¿se aplica la propuesta de PUL-087? (gusto, la decide el responsable) |
| PUL-146 | D5, D6, D9b | asset-pipeline | — | Sí: ¿los 256 MB de §4.2 cuentan solo assets? |

`owns` sin solapes: PUL-146 excluye `assets/models/stations/pot/` (lo lleva PUL-144, que depende de
PUL-146 para aplicar la convención) y no toca `mat_steel_brushed_top.tres` ni `render_config.tres`
(PUL-145).

## Observación fuera de alcance

`godot/assets/materials/` aún tiene materiales de placeholder (`ph_*.tres`, `small_box.tres`,
`medium_box.tres`, `large_box.tres`…) que pueden haberse quedado sin uso tras D25 y el arte v2. No es
un pendiente del roadmap; no se ha comprobado su uso. Se apunta para el coordinador.

## Verificación

Ver la sección Evidence de la ficha (`tools/verify.sh --quick` y `check_owns`).
