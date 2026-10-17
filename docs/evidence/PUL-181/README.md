# Evidencia PUL-181 — Biblia de arte v3 «Feira Clara» y plan de implementación (PUL-182..PUL-189)

Fecha: 2026-10-17 · Rol: `game-designer` (con soporte de `asset-pipeline`) · Decisión: **[D28](../../design/decisions.md)**

---

## 1. Entregables de PUL-181

1. **Archivo de la biblia v2**: [`docs/art/art-bible-v2.md`](../../art/art-bible-v2.md) (copia íntegra de la v2 con cabecera de archivo enlazando a la v3 y a D28).
2. **Biblia de arte v3 «Feira Clara»**: [`docs/art/art-bible.md`](../../art/art-bible.md):
   - **§0 / §0.1**: tabla de cambios frente a la v2, referencias a lo conservado de v1/v2 y declaración de refinamientos de Dirección A (`wall_granite #9A948C`, frentes navy `#1D3557` y `env_atlas` neutro `#9A948C`).
   - **§2**: paleta cerrada de **16 colores en hex** con su luminancia relativa $L$ corregida y uso obligatorio.
   - **§3**: biblioteca cerrada de **18 materiales `.tres`** en `godot/assets/materials/v3/`, todos `StandardMaterial3D` con `metallic = 0.0` y `specular_mode = SPECULAR_DISABLED`, mapeo por `.glb` a slots reales, reglas para atlas multicolor, slots compartidos y funcionales, `gltf/embedded_image_handling = 0` y textura única `tent_plate_albedo.png`.
   - **§4**: luz (`Sun` `DirectionalLight3D` a `1.18`, 0 `Bulbs`), `WorldEnvironment` (`render_config.tres`), regla de post-proceso (SSAO suave activo `radius = 0.45`, `intensity = 1.1`; `glow`, LUT, `Vignette` y DoF prohibidos) y protocolo de medida antes/después con script común sobre `main`.
   - **§5**: tabla de poda de atrezo por zonas (Z0–Z3) sin remodelar `.glb`, regla de ocultación del cartel superior vacío (`env_sign` y `env_board` con `mat_hidden_alpha.tres`), y aclaración de que `SweetDressing`/`HotDressing` son nodos de escena y no slots de `.glb`.
   - **§6**: estados de cocción, tabla de contrastes WCAG 2.1 (recalculada y extendida a fondos de pegatinas en caja y suelo con anillo exterior `StickerInk.INK` `#2A2320`), y regla de números macizos (`outline_size = 0`, contraste **11.24 : 1**) en puestos de entrega.
   - **§7**: impacto en UI, HUD, tickets y `StickerInk`.
   - **§8 & §10**: plan de oleadas corregido (PUL-184 en Oleada 2, PUL-186 con `deps: [PUL-182]`, PUL-189 con rol `qa-tester`).
3. **Catálogo de slots reales de los 40 `.glb`**: [`docs/evidence/PUL-181/slots_reales.md`](slots_reales.md).
4. **Lámina de paleta propia v3**: [`docs/art/moodboard-v3.svg`](../../art/moodboard-v3.svg).
5. **Script reproducible y tabla de contrastes WCAG 2.1 (AC2)**:
   - [`docs/evidence/PUL-181/calc_contrasts_v3.py`](calc_contrasts_v3.py)
   - [`docs/evidence/PUL-181/contrastes_v3.md`](contrastes_v3.md)
6. **8 fichas `draft` de implementación (`PUL-182` a `PUL-189`)**:
   - [`docs/backlog/PUL-182-biblioteca-materiales-planos-v3.md`](../../backlog/PUL-182-biblioteca-materiales-planos-v3.md)
   - [`docs/backlog/PUL-183-luz-entorno-y-postproceso-v3.md`](../../backlog/PUL-183-luz-entorno-y-postproceso-v3.md)
   - [`docs/backlog/PUL-184-puestos-entrega-y-numeros-v3.md`](../../backlog/PUL-184-puestos-entrega-y-numeros-v3.md)
   - [`docs/backlog/PUL-185-tema-ui-hud-y-pegatinas-v3.md`](../../backlog/PUL-185-tema-ui-hud-y-pegatinas-v3.md)
   - [`docs/backlog/PUL-186-encimeras-suelo-y-estaciones-v3.md`](../../backlog/PUL-186-encimeras-suelo-y-estaciones-v3.md)
   - [`docs/backlog/PUL-187-materiales-entorno-comida-y-personajes-v3.md`](../../backlog/PUL-187-materiales-entorno-comida-y-personajes-v3.md)
   - [`docs/backlog/PUL-188-integracion-level01-y-limpieza-v2.md`](../../backlog/PUL-188-integracion-level01-y-limpieza-v2.md)
   - [`docs/backlog/PUL-189-qa-visual-y-rendimiento-v3.md`](../../backlog/PUL-189-qa-visual-y-rendimiento-v3.md)

---

## 2. Resolución de los 4 puntos débiles de PUL-180 (AC3)

| # | Punto débil detectado en PUL-180 | Regla cerrada en `docs/art/art-bible.md` v3 | Ficha que lo implementa |
|---:|---|---|---|
| 1 | **Cartel superior vacío (`env_sign` / `env_board`)**: al pintarlo de `#1D3557` quedaba un rectángulo azul vacío sobre el toldo y dos pizarras vacías en el muro | En `tent.glb`, `tent_structure` tiene las superficies `['mat_paint_worn_grey', 'env_atlas', 'env_sign', 'env_board']`. Los slots `env_sign` y `env_board` se asignan a `res://assets/materials/v3/mat_hidden_alpha.tres` (`TRANSPARENCY_ALPHA`, `albedo_color.a = 0.0`), ocultándolos sin remodelar `tent.glb`. La marca PulpaSA queda en `tent_plate` (`mat_tent_plate.tres`, §5.2). | `PUL-182` + `PUL-187` |
| 2 | **Números de los puestos en móvil (`800×370`)**: `%OrderLabel` (`#1..#4`) salía delineado/hueco (`outline_size = 14` oscuro sobre relleno blanco y placa blanca) y `StandNumber` (`1..4`) perdía contraste sobre el frente `#1D3557` | Prohibido el contorno hueco (`outline_size = 0`). `%OrderLabel` usa glifo macizo `#1D3557` sobre `OrderPlatePaper` `#F7F4EC` con marco `OrderPlateFrame` `#1D3557` (**11.24 : 1**); `StandNumber` usa glifo macizo `#F7F4EC` sobre el frente `#1D3557` (**11.24 : 1**, §6.3). | `PUL-184` |
| 3 | **Entorno con textura (`env_plate`)**: faltaba criterio sobre qué texturas se permiten y cuáles se prohíben | Prohibidas todas las texturas PBR de superficie 3D (0 albedo de ruido, 0 ORM, 0 normal maps; se borran `textures/v2/` y `models/**/*.png`). Solo se permiten `env_plate` (`mat_tent_plate.tres`, con textura albedo `res://assets/models/environment/romeria_v2/tent_plate_albedo.png` en el faldón del toldo) y los iconos planos de señalética/UI D26 y §3.4 (§3.2). | `PUL-182` + `PUL-187` + `PUL-188` |
| 4 | **SSAO y post-proceso**: faltaba fijar si el SSAO se conserva o se apaga en estilo plano | Se apagan `Bulbs` (0 `OmniLight3D`), `glow`, LUT, `Vignette` y DoF; se **conserva activo el SSAO suave de contacto** (`ssao_radius = 0.45`, `ssao_intensity = 1.1`, `ssao_detail = 0.0`) para separar planos mates del mismo color entre módulos contiguos y con el suelo (§4.2). | `PUL-183` |

---

## 3. Plan de oleadas, dependencias y verificación de no-solape (AC4)

### 3.1 Grafo de dependencias

```
                   ┌─────────┐
                   │ PUL-181 │ (Biblia v3 + fichas)
                   └────┬────┘
         ┌──────────────┼──────────────┐
         ▼              ▼              ▼
    ┌─────────┐    ┌─────────┐    ┌─────────┐
    │ PUL-182 │    │ PUL-183 │    │ PUL-185 │   Oleada 1 (3 workers en paralelo)
    │Mat. v3  │    │Luz/Env  │    │UI / HUD │
    └────┬────┘    └────┬────┘    └────┬────┘
         ├──────────────┼──────┐       │
         ▼              ▼      ▼       │
    ┌─────────┐    ┌─────────┐ ┌────────────┐
    │ PUL-184 │    │ PUL-186 │ │  PUL-187   │   Oleada 2 (3 workers en paralelo)
    │ Puestos │    │Encimeras│ │Env/Comida/J│
    └────┬────┘    └────┬────┘ └─────┬──────┘
         └──────────────┼────────────┴─────────┘
                        ▼
                   ┌─────────┐
                   │ PUL-188 │                  Oleada 3 (integración level_01 + limpieza v2)
                   └────┬────┘
                        ▼
                   ┌─────────┐
                   │ PUL-189 │                  Oleada 4 (QA visual + rendimiento antes/después)
                   └─────────┘
```

### 3.2 Tabla de fichas (`PUL-182` a `PUL-189`) y comprobación de no-solape

| Oleada | Ficha | Rol (`.claude/agents/`) | `deps` | Nº AC | `owns` (globs exclusivos) | `touches_scenes` |
|:---:|---|---|---|:---:|---|---|
| **1** | `PUL-182` | `asset-pipeline` | `[PUL-181]` | 4 | `godot/assets/materials/v3/**`, `godot/tests/unit/test_materials_v3.gd*`, `docs/evidence/PUL-182/**`, ficha `PUL-182` | `[]` |
| **1** | `PUL-183` | `asset-pipeline` | `[PUL-181]` | 5 | `godot/data/config/render_config.tres`, `godot/entities/environment/environment.tscn`, `godot/tests/unit/test_render_config.gd`, `godot/tests/integration/test_level_01.gd`, `docs/evidence/PUL-183/**`, ficha `PUL-183` | `[godot/entities/environment/environment.tscn]` |
| **1** | `PUL-185` | `ui-engineer` | `[PUL-181]` | 4 | `godot/ui/theme/default_theme.tres`, `godot/ui/widgets/sticker_ink.gd`, `godot/entities/items/badge_row.gd`, `godot/ui/tickets/ticket_entry.gd`, `godot/ui/hud/hud.tscn`, `godot/ui/tickets/order_ticket.tscn`, `godot/tests/unit/test_ui_theme_v3.gd*`, `docs/evidence/PUL-185/**`, ficha `PUL-185` | `[godot/ui/hud/hud.tscn, godot/ui/tickets/order_ticket.tscn]` |
| **2** | `PUL-184` | `ui-engineer` | `[PUL-181, PUL-182]` | 4 | `godot/data/config/stand_palette.tres`, `godot/entities/stations/order_stand.tscn`, `godot/entities/stations/order_stand_model.gd`, `godot/tests/unit/test_order_stand_model.gd`, `docs/evidence/PUL-184/**`, ficha `PUL-184` | `[godot/entities/stations/order_stand.tscn]` |
| **2** | `PUL-186` | `asset-pipeline` | `[PUL-182]` | 5 | `godot/assets/models/furniture/counters/*.glb.import`, `godot/assets/models/stations/**/*.glb.import`, `godot/entities/environment/kitchen_layout.tscn`, 9 escenas `godot/entities/stations/*.tscn` (todas salvo `order_stand.tscn`), `godot/tests/integration/test_stations_v3.gd*`, `docs/evidence/PUL-186/**`, ficha `PUL-186` | `[kitchen_layout.tscn, kitchen.tscn, octopus_storage.tscn, cachelos_storage.tscn, box_shelf.tscn, seasoning_station.tscn, seasoning_dispenser.tscn, cachelos_bowl.tscn, trash_bin.tscn, slot.tscn]` |
| **2** | `PUL-187` | `asset-pipeline` | `[PUL-182, PUL-183]` | 5 | `godot/assets/models/environment/romeria_v2/*.glb.import`, `godot/assets/models/characters/cook/*.glb.import`, `godot/assets/models/food/**/*.glb.import`, `godot/assets/models/items/box/*.glb.import`, `godot/assets/models/_pipeline/**/*.glb.import`, `godot/entities/items/{box,octopus,cachelos}.tscn`, `godot/entities/player/player.tscn`, `godot/tests/unit/test_items_and_env_v3.gd*`, `docs/evidence/PUL-187/**`, ficha `PUL-187` | `[box.tscn, octopus.tscn, cachelos.tscn, player.tscn]` |
| **3** | `PUL-188` | `asset-pipeline` | `[PUL-183, PUL-184, PUL-185, PUL-186, PUL-187]` | 4 | `godot/scenes/levels/level_01.tscn`, `godot/assets/materials/v2/**`, `godot/assets/textures/v2/**`, `godot/assets/models/**/*.png`, `godot/assets/models/**/*.png.import`, `godot/assets/models/furniture/counters/kitchen_floor_dirt.tres*`, `art/blender/romeria.blend`, `godot/tests/unit/test_assets_models.gd`, `docs/evidence/PUL-188/**`, ficha `PUL-188` | `[godot/scenes/levels/level_01.tscn]` |
| **4** | `PUL-189` | `qa-tester` | `[PUL-188]` | 5 | `docs/evidence/PUL-189/**`, ficha `PUL-189` | `[]` |

- **Solapes de `owns` o `touches_scenes` en Oleada 1 (`PUL-182, PUL-183, PUL-185`)**: **0**.
- **Solapes de `owns` o `touches_scenes` en Oleada 2 (`PUL-184, PUL-186, PUL-187`)**: **0**.
- **Solapes de `owns` o `touches_scenes` entre todas las fichas (`PUL-182..189`)**: **0** (son disjuntas incluso entre oleadas distintas).
- **Fichas que tocan `godot/scenes/levels/level_01.tscn`**: **1 única ficha (`PUL-188`)**.
- **Nuevos `.glb` o remodelados de `.glb`**: **0** en todas las fichas.

---

## 4. Revisión de `PUL-144`, `PUL-145` y `PUL-146` (arte v2)

Según las restricciones de `PUL-181`, no se han editado las fichas `PUL-144`, `PUL-145` ni `PUL-146`. Su estado técnico tras D28 es el siguiente:

| Ficha v2 | Título | Estado tras D28 (`PUL-181`) | Detalle y ficha v3 que la absorbe o sustituye |
|---|---|---|---|
| **[`PUL-144`](../../backlog/PUL-144-vapor-y-tapa-de-la-olla.md)** | Hacer visible el vapor de la olla y apoyar su tapa abierta | **Parcialmente absorbida en `PUL-186` / pospuesta en geometría** | Su parte de escena (AC1 y AC2: hacer que el `GPUParticles3D` `Steam` de `kitchen.tscn` sea claramente visible al cocer, D2 de PUL-087) **queda absorbida en `PUL-186` (AC4)**. Su parte de remodelar la tapa abierta en `art/blender/pot.blend` y reexportar `pot.glb` (AC3, D3 de PUL-087) queda **fuera de alcance en esta primera oleada** porque D28 ordena no remodelar `.glb`. |
| **[`PUL-145`](../../backlog/PUL-145-ambiente-y-acero-delantero.md)** | Ajustar el ambiente y el brillo del acero delantero a la referencia | **Obsoleta (sustituida por `PUL-183` y `PUL-186`)** | Buscaba acercar la luma a la referencia oscura de la v2 (D4) y apagar los brillos especulares de las 5 `OmniLight3D` (`Bulbs`) sobre `mat_steel_brushed_top.tres` (D7). Con D28 el ambiente pasa al estilo diurno «Feira Clara» (`PUL-183`), se apagan las `Bulbs` y el acero cepillado desaparece en favor de `mat_surface_top.tres` (`#EDE8DF`, `specular_mode = SPECULAR_DISABLED`) en `PUL-186`. Puede cerrarse como obsoleta/cancelada. |
| **[`PUL-146`](../../backlog/PUL-146-materiales-y-texturas-compartidos-al-importar.md)** | Compartir materiales y texturas entre los `.glb` y retirar la fuente v1 | **Absorbida y superada por `PUL-186`, `PUL-187` y `PUL-188`** | Buscaba deduplicar los 239 materiales instanciados y las 410 texturas PBR extraídas de la v2, y borrar `art/blender/romeria.blend`. En la v3, `PUL-186` y `PUL-187` redirigen todos los `.glb.import` a los 18 `.tres` planos de `res://assets/materials/v3/`, y `PUL-188` borra todas las texturas PBR extraídas (`assets/models/**/*.png`), `assets/textures/v2/**`, `assets/materials/v2/**` y `art/blender/romeria.blend`. |

---

## 5. Preguntas para el responsable

1. **P1 · SSAO en perfiles móviles / bajo consumo**: la biblia v3 mantiene activo el SSAO suave de contacto (`ssao_radius = 0.45`, `ssao_intensity = 1.1`) porque separa los bloques planos contiguos del mismo color sin añadir texturas. ¿Quieres que siga siempre activo en todas las plataformas o prefieres que se desactive en Android / perfiles modestos si en la medición de `PUL-189` supera `0,5 ms` de GPU?
2. **P2 · Cierre administrativo de `PUL-144`, `PUL-145` y `PUL-146`**: una vez que `PUL-183` deja obsoleta `PUL-145` y `PUL-186..188` absorben el vapor de `PUL-144` y la deduplicación/limpieza de `PUL-146`, ¿marcamos las tres como canceladas/absorbidas en `docs/backlog/README.md`, o dejamos `PUL-144` reservada por si más adelante se abre una segunda oleada con remodelado de `.glb` en Blender (tapa de la olla)?
3. **P3 · Segunda oleada opcional de `.glb` tras `PUL-189`**: cuando `PUL-189` valide el antes/después de esta primera oleada de solo materiales y escena, ¿querrás abrir una segunda oleada para limpiar físicamente en Blender las sub-mallas ocultas (`gas_bottle`, `pump`, `cartons`, `env_sign`, flechas pre-D25), o damos por cerrado el arte de M3f si el rendimiento y la imagen ya cumplen en `PUL-189`?

---

## 6. Resolución de los 9 hallazgos de la revisión (Ronda 2)

| Hallazgo | Gravedad | Causa identificada | Resolución técnica aplicada |
|---|:---:|---|---|
| **1. Slots reales de `.glb`** | Alta | La biblia y fichas usaban nombres supuestos (`mat_wood_varnished`, `octopus_raw.glb`, etc.). | Inspección binaria de los 40 `.glb` (glTF JSON chunks) documentada en [`slots_reales.md`](slots_reales.md). Reemplazo íntegro por los 68 slots reales en `art-bible.md`, `PUL-186` y `PUL-187`. Reglas explícitas para atlas multicolor (`counters_atlas` a `#9A948C` en import con override `#1D3557` en escena, `env_atlas` a `#9A948C`), slots compartidos y `surface_material_override` en `.tscn` dueñas (`SweetDressing`/`HotDressing` son nodos de escena). |
| **2. `embedded_image_handling = 0`** | Alta | Los `.import` actuales tenían `=1` (extraer), lo que regeneraba los `.png` al importar e impedía cumplir `PUL-188` AC1. | Se exige explícitamente `gltf/embedded_image_handling = 0` en `art-bible.md` §3.3, `PUL-186` (Change y AC1) y `PUL-187` (Change y Constraints). |
| **3. Medición de rendimiento antes/después** | Alta | `PUL-189` citaba fichas inexistentes y no podía medir el "antes" al depender de `PUL-188`. Rol discordante. | Se fijó el protocolo con el script `docs/evidence/PUL-189/measure_perf.gd` ejecutado sobre `main` antes de iniciar la oleada 1 (`docs/evidence/PUL-189/antes/perf_v2.json`, commit base `e86baf3`) y después de `PUL-188` (`despues/perf_v3.json`). Rol corregido a `qa-tester` en frontmatter y biblia. |
| **4. Contraste de pegatinas sobre caja y suelo** | Media | La tabla de contrastes evaluaba pares teóricos no existentes en el juego y omitía fondos reales (caja roja y suelo). | Cálculo en [`calc_contrasts_v3.py`](calc_contrasts_v3.py) y [`contrastes_v3.md`](contrastes_v3.md) de las pegatinas sobre caja (`#C8402F`) y suelo (`#C4A882`). Norma de anillo exterior `StickerInk.INK` (`#2A2320`) en todos los discos (contraste 3.11:1 y 6.82:1 frente al fondo, e interior ≥ 3.24:1). `PUL-185` extiende `owns` a `badge_row.gd` y `ticket_entry.gd`. |
| **5. Slots funcionales y `owns` de PUL-187** | Media | `test_assets_models.gd` no contemplaba slots funcionales (`mat_outline_hull`, `delivery_zone_off.tres`, stickers) ni mallas `_pipeline/`. Rango glob incompleto en `owns` de `PUL-187` y ruta inexistente de player. | Exención explícita en `art-bible.md` §3.3 y `PUL-188` AC2. En `PUL-187`: `owns` ajustado a `_pipeline/**/*.glb.import` y retirada de `godot/entities/player/materials/**`. |
| **6. Dependencias de PUL-184 y orden de oleadas** | Media | `PUL-184` usaba materiales de `PUL-182` estando en la misma oleada sin declararlo. | `PUL-184` movida a Oleada 2 con `deps: [PUL-181, PUL-182]`. Se eliminó la falsa dependencia de `PUL-186` sobre `PUL-184` (`deps: [PUL-182]`), permitiendo que `PUL-184`, `PUL-186` y `PUL-187` corran concurrentemente en Oleada 2. |
| **7. Textura de `mat_tent_plate.tres`** | Baja | La biblia dejaba abierta la duda entre `tent_env_plate.png` y moverla a `brand/`. | Criterio cerrado: textura única `res://assets/models/environment/romeria_v2/tent_plate_albedo.png` en `art-bible.md` §3.2, `PUL-182`, `PUL-187` y `PUL-188`. |
| **8. Refinamientos de Dirección A en §0** | Baja | §0 no recogía explícitamente la evolución de Dirección A tras las revisiones de PUL-180. | Añadida sección §0.1 en `art-bible.md` declarando `wall_granite #9A948C`, frentes navy `#1D3557` y `env_atlas` neutro `#9A948C`. |
| **9. Erratas menores** | Baja | Paréntesis roto en §3.2, luma de `#4FA05A` listada como 0.3235 (la real es 0.2754), PUL-183 citaba 10 sub-mallas en vez de 11. | Subsanadas las tres erratas en `art-bible.md` §2, §3.2 y `PUL-183` línea 29. |

---

## 7. Resolución de los hallazgos de la re-revisión (Ronda 3)

| Hallazgo | Gravedad | Causa identificada | Resolución técnica aplicada |
|---|:---:|---|---|
| **N1 / N2. Mapeos de slots en PUL-186 y PUL-187** | Alta | Fichas inventaban slots (`mat_rock`, `mat_wood`, `mat_eyes`, `mat_white`) o contradecían `slots_reales.md`. | Se fijó `slots_reales.md` §1 y §2 como fuente única de verdad en `PUL-186` y `PUL-187`; `counters_atlas` a `#9A948C` con override navy en `.tscn`; `mat_steel_dark` a `#1D3557`; `seasoning_station_atlas` a `#EDE8DF`; `atlas_octopus` a `#B8283D`; incluidos todos los slots reales de estaciones y entorno. |
| **N3. Textura de `tent_plate`** | Alta | La textura se apuntaba a `textures/brand/` (inexistente) y `PUL-188` borraba la única copia en `models/`. | Se fijó la ruta real única `res://assets/models/environment/romeria_v2/tent_plate_albedo.png` en `art-bible.md`, `PUL-182`, `PUL-187` y `PUL-188`; `PUL-188` la preserva explícitamente junto con su `.import` en el borrado. |
| **N4. Regla de anillo de pegatinas** | Media | Se daba anillo claro al picante que fallaba en suelo (2.06:1) y encimera (1.11:1), e inconsistencia con PUL-185. | Regla unificada: todos los discos llevan anillo exterior oscuro `StickerInk.INK` (`#2A2320`, 3.11:1 en caja, 6.82:1 en suelo); el picante se distingue con contraste 8.21:1 mediante icono interior crema `#F7F4EC` y silueta octogonal D26. |
| **N5. Errores de cifras y tabla** | Baja | Contraste frentes navy era 10.12:1 (no 23.16:1), luminancia de `#9A948C` es 0.2994 (no 0.3005), y tabla §3.1 tenía 8 columnas separadoras y `wall_granite.tres`. | Corregidos a 10.12:1, 0.2994 (en biblia, moodboard SVG y notas), 7 columnas en la tabla §3.1 y `mat_wall_granite.tres`. |
| **N6. Nodos de malla de aliño** | Baja | Se citaban `paprika_sweet_v3` y `paprika_hot_v3` y geometrías añadidas. | Corregido a los nodos reales `paprika_sweet` y `paprika_hot` de `seasoning_dispenser.glb`, prohibiendo geometrías añadidas o remodelados (D28). |
