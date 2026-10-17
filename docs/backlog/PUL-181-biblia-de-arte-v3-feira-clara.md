---
id: PUL-181
title: Escribir la biblia de arte v3 «Feira Clara» y partir su implementación en fichas
status: review
milestone: M3f
role: game-designer
deps: [PUL-180]
orca_task: null
unity_sources: []
owns: [docs/art/art-bible.md, docs/art/art-bible-v2.md, docs/art/moodboard-v3*, docs/backlog/PUL-18[2-9]-*.md, docs/evidence/PUL-181/**, docs/backlog/PUL-181-biblia-de-arte-v3-feira-clara.md]
touches_scenes: []
---

## Target
D28 (2026-10-17): el responsable elige la dirección **A · «Feira Clara»** de PUL-180
(`docs/art/minimal/direccion-a-color-plano.md`, `README.md` y el prototipo
`docs/evidence/PUL-180/capture_minimal.gd`), con una **primera oleada solo de materiales y escena**,
sin remodelar `.glb`. La biblia vigente (`docs/art/art-bible.md`, v2, D22) queda sustituida en estilo,
materiales y post-proceso.

## Change
1. Archiva la v2 como `docs/art/art-bible-v2.md` y reescribe `docs/art/art-bible.md` como **v3**. Debe
   incluir:
   - qué cambia frente a la v2 (tabla, como en la §0 de la v2);
   - la paleta cerrada en hex con el uso de cada color;
   - la biblioteca de materiales planos compartidos: nombre del `.tres`, color, roughness y
     metallic, y a qué superficies se aplica;
   - luz y entorno (`WorldEnvironment`, `DirectionalLight3D` y post-proceso permitido: SSAO sí o
     no, sombras);
   - qué atrezo se quita y cuál se queda;
   - legibilidad de estados y de los colores de §3.4, con los contrastes recalculados;
   - impacto en la UI y el HUD.

   Lo que la v2 tenía y la v3 conserva (unidades, escala, nodos de contrato, nombres, cámara) se
   referencia, no se copia. Resuelve en la biblia los puntos débiles que vio la revisión de PUL-180:
   - el cartel superior, que en el prototipo queda como un rectángulo vacío;
   - los números de los puestos, que salen delineados o degradados en móvil;
   - el entorno con textura (`env_plate`);
   - el SSAO.
2. Lámina de paleta propia `docs/art/moodboard-v3.svg`.
3. Parte la implementación en **fichas `draft` PUL-182 a PUL-189** con el formato de `_TEMPLATE.md`:
   - en oleadas, sin solapar `owns` ni `touches_scenes`, y con `level_01.tscn` en una sola ficha de
     integración;
   - con roles de `.claude/agents/` (asset-pipeline, gameplay-engineer o ui-engineer) y ≤ 5 AC con
     números y su test o captura;
   - sin `.glb` nuevos ni remodelados.

   Incluye la ficha de QA visual: antes y después con el mismo script de captura y la misma cámara, a
   1920×1080 y a 800×370, y rendimiento medido con el mismo método antes y después. Incluye también la
   limpieza de los materiales y texturas v2 que queden sin uso. Revisa si PUL-144, PUL-145 y PUL-146
   (arte v2) quedan obsoletas o se absorben, y dilo en la evidencia (no edites esas fichas).
4. `docs/evidence/PUL-181/README.md`: plan de oleadas, dependencias, fichas creadas y preguntas para el
   responsable.

## Constraints
- Solo documentación: no se cambia código, escenas, `.tres` ni `.glb`. No edites
  `docs/backlog/README.md`, `docs/design/decisions.md` ni `roadmap.md`: los actualiza el coordinador.
- Siguen D14, D16, D20, D21 (marca PulpaSA), D26 (iconos, prompts y legibilidad en móvil) y los colores
  de §3.4.
- Lo que deba decidir el responsable va como pregunta, no como supuesto.

## Acceptance
- [x] AC1 Given la v2, When se abre `docs/art/art-bible.md`, Then dice «v3», enlaza la v2 archivada y
  D28, y tiene la tabla de cambios, una paleta cerrada de entre 12 y 20 colores en hex y la biblioteca de
  materiales (≤ 20 `.tres`) con su uso.
- [x] AC2 Given la paleta v3, When se calculan los contrastes de los 5 colores de §3.4 frente a cada
  superficie donde aparecen, Then todos son ≥ 3:1 (tabla y script en `docs/evidence/PUL-181/`).
- [x] AC3 Given los 4 puntos débiles de PUL-180 (cartel, números, `env_plate`, SSAO), When se lee la
  biblia, Then cada uno tiene una regla concreta.
- [x] AC4 Given las fichas PUL-182.., When se comparan sus `owns` y `touches_scenes` dentro de cada
  oleada, Then no se solapan, `level_01.tscn` aparece en una sola ficha, y hay una ficha de QA visual con
  medida de rendimiento antes y después.
- [x] AC5 `tools/verify.sh --quick` en verde y `tools/check_owns.py` limpio.

## Plan
1. Archivar el contenido íntegro de `docs/art/art-bible.md` (v2) en `docs/art/art-bible-v2.md` con cabecera de archivo enlazando a la v3 y a D28.
2. Inspeccionar la estructura real de todos los `.glb`, `.glb.import`, escenas `.tscn` y tests GUT (`test_assets_models.gd`, `test_render_config.gd`, `test_level_01.gd`, `test_order_stand_model.gd`) para asegurar que las reglas de la biblia v3 y las fichas de implementación sean técnicamente exactas sin remodelar `.glb`.
3. Redactar `docs/art/art-bible.md` como **v3 · «Feira Clara»** con: §0 tabla de cambios respecto a la v2 y referencias a v1/v2; §2 paleta cerrada de 16 colores en hex; §3 biblioteca cerrada de 18 materiales `.tres` en `godot/assets/materials/v3/` y regla de `env_plate`; §4 luz (`Sun` `1.18`, 0 `Bulbs`), `WorldEnvironment` y regla de SSAO suave activo (`radius = 0.45`, `intensity = 1.1`) sin `glow`/LUT/`Vignette`; §5 tabla de atrezo que se quita/queda y eliminación del cartel superior vacío (`env_sign`/`env_board` con `mat_hidden_alpha.tres`); §6 contrastes recalculados de estados, de los 5 colores de §3.4 (todos ≥ 3.24:1) y regla de números macizos (`outline_size = 0`, 11.24:1) en `order_stand.tscn`; §7 impacto en UI/HUD; §8 tabla de fichas y estado de `PUL-144..146`; §10 preguntas abiertas para el responsable.
4. Crear la lámina de paleta propia `docs/art/moodboard-v3.svg` y el script reproducible `docs/evidence/PUL-181/calc_contrasts_v3.py` que genera `docs/evidence/PUL-181/contrastes_v3.md`.
5. Partir la implementación en 8 fichas `draft` (`PUL-182` a `PUL-189`) organizadas en 4 oleadas sin solape de `owns` ni `touches_scenes`, con `level_01.tscn` solo en `PUL-188` y QA visual + rendimiento antes/después en `PUL-189`.
6. Documentar el plan de oleadas, dependencias, revisión de `PUL-144..146` y preguntas al responsable en `docs/evidence/PUL-181/README.md`, y verificar `tools/verify.sh --quick` y `tools/check_owns.py`.

## Evidence
- **AC1 (`art-bible-v2.md` archivada, `art-bible.md` v3 y `moodboard-v3.svg`)**:
  - `docs/art/art-bible-v2.md` archiva la v2 de PUL-072 con nota de archivo apuntando a `art-bible.md` (v3) y a D28.
  - `docs/art/art-bible.md` se titula «v3 · Feira Clara», enlaza `art-bible-v2.md`, `art-bible-v1.md` y D28, incluye la tabla de cambios (§0), la paleta cerrada de **16 colores en hex** (§2, entre 12 y 20) y la biblioteca cerrada de **18 recursos `.tres`** en `godot/assets/materials/v3/` (§3.1, ≤ 20 `.tres`) con hex, roughness, `metallic = 0.0`, `specular_mode = SPECULAR_DISABLED` y superficies de aplicación.
  - Lámina vectorial propia creada en `docs/art/moodboard-v3.svg`.
- **AC2 (Contrastes WCAG 2.1 de los 5 colores de §3.4 ≥ 3:1)**:
  - Script reproducible en `docs/evidence/PUL-181/calc_contrasts_v3.py` y tabla generada en `docs/evidence/PUL-181/contrastes_v3.md` (e incluida en `docs/art/art-bible.md` §6.2).
  - Las **17 combinaciones** de los 5 colores de §3.4 (`paprika_sweet` `#D6361F`, `paprika_hot` `#8F1A14`, `salt` `#F7F4EC`, `oil` `#F2C230`, `cachelos` `#F2D56B`) frente a cada superficie donde aparecen cumplen **≥ 3.0000 : 1** (mínimo absoluto **3.2409 : 1** en el anillo interior `StickerInk` `#2A2320` sobre `#D6361F`, y mínimo sobre soportes primarios de estación/caja **3.4290 : 1** / **3.9052 : 1**).
- **AC3 (Reglas concretas para los 4 puntos débiles de PUL-180)**:
  1. **Cartel superior vacío (`env_sign` / `env_board`)**: en `docs/art/art-bible.md` §5.2 se fija que las superficies `env_sign` y `env_board` de `tent_structure` (`tent.glb`) se mapean a `mat_hidden_alpha.tres` (`TRANSPARENCY_ALPHA`, `albedo_color.a = 0.0`), ocultando el cartel vacío sobre el toldo y las dos pizarras sin remodelar `tent.glb`, y dejando la marca PulpaSA concentrada en `tent_plate` (`mat_tent_plate.tres`).
  2. **Números de los puestos en móvil (`800×370`)**: en `docs/art/art-bible.md` §6.3 se prohíbe el contorno hueco (`outline_size = 0`): `%OrderLabel` (`#1..#4`) usa glifo macizo `#1D3557` sobre `OrderPlatePaper` `#F7F4EC` con marco `OrderPlateFrame` `#1D3557` (**11.24 : 1**), y `StandNumber` (`1..4`) usa glifo macizo `#F7F4EC` sobre el frente `#1D3557` (**11.24 : 1**).
  3. **Entorno con textura (`env_plate`)**: en `docs/art/art-bible.md` §3.2 se prohíben todas las texturas PBR de superficie en 3D (0 albedo de ruido, 0 ORM, 0 normal maps) y se permite únicamente `env_plate` (`mat_tent_plate.tres` en `tent_plate` con logotipo plano PulpaSA) y los iconos planos de señalética/UI D26 y §3.4.
  4. **SSAO**: en `docs/art/art-bible.md` §4.2 se fija activo el SSAO suave de contacto (`ssao_enabled = true`, `ssao_radius = 0.45`, `ssao_intensity = 1.1`, `ssao_detail = 0.0`) para separar bloques planos contiguos, y se prohíben `Bulbs` (0 `OmniLight3D`), `glow`, LUT, `Vignette` y DoF.
- **AC4 (Fichas `PUL-182` a `PUL-189`, oleadas sin solape, `level_01.tscn` único, QA visual y revisión de `PUL-144..146`)**:
  - Plan completo en `docs/evidence/PUL-181/README.md` (actualizado tras Ronda 2):
    - **Oleada 1 (3 workers en paralelo, 0 solapes)**: `PUL-182` (`asset-pipeline`, biblioteca de 18 `.tres`), `PUL-183` (`asset-pipeline`, luz, `render_config.tres`, post-proceso y poda en `environment.tscn`), `PUL-185` (`ui-engineer`, `default_theme.tres`, `sticker_ink.gd`, `badge_row.gd`, `ticket_entry.gd`, `hud.tscn`, `order_ticket.tscn`).
    - **Oleada 2 (3 workers en paralelo, 0 solapes)**: `PUL-184` (`ui-engineer`, `deps: [PUL-181, PUL-182]`, `order_stand.tscn`, `stand_palette.tres` y números macizos), `PUL-186` (`asset-pipeline`, `deps: [PUL-182]`, `.glb.import` con `embedded_image_handling = 0` y escenas de encimeras y estaciones con slots reales de `slots_reales.md`), `PUL-187` (`asset-pipeline`, `deps: [PUL-182, PUL-183]`, `.glb.import` con `embedded_image_handling = 0`, entorno `romeria_v2` con `mat_hidden_alpha`/`mat_tent_plate`, comida, cajas y cocineros).
    - **Oleada 3**: `PUL-188` (`asset-pipeline`, **única ficha que toca `level_01.tscn`**, limpieza de `materials/v2/**`, `textures/v2/**`, `models/**/*.png` y `art/blender/romeria.blend`, eximiendo slots funcionales y `_pipeline/**`).
    - **Oleada 4**: `PUL-189` (`qa-tester`, QA visual antes/después con el mismo script y cámara a `1920×1080` y `800×370`, y rendimiento/VRAM antes y después con el mismo script `measure_perf.gd` con línea base medida sobre `main`).
  - **Estado de `PUL-144`, `PUL-145` y `PUL-146`** (sin editar esas fichas):
    - `PUL-144`: parcialmente absorbida en `PUL-186` (visibilidad del vapor `Steam` en `kitchen.tscn`); el remodelado de la tapa en `pot.blend` queda fuera por D28 (no remodelar `.glb`).
    - `PUL-145`: obsoleta, sustituida por `PUL-183` y `PUL-186` (se apagan las `Bulbs` y desaparece el acero especular).
    - `PUL-146`: absorbida y superada por `PUL-186`, `PUL-187` y `PUL-188` (materiales compartidos en `materials/v3/`, borrado de texturas PBR extraídas y retirada de `art/blender/romeria.blend`).
- **Ronda 2 — Corrección de los 9 hallazgos de revisión**:
  1. Catálogo real de 68 slots extraído en `docs/evidence/PUL-181/slots_reales.md`; reglas para atlas (`counters_atlas` a `#9A948C` en import con override `#1D3557` en escena, `env_atlas` a `#9A948C`), slots compartidos y `SweetDressing`/`HotDressing` como nodos de escena.
  2. `gltf/embedded_image_handling = 0` explícito en `art-bible.md`, `PUL-186` y `PUL-187`.
  3. Protocolo de benchmark unificado `docs/evidence/PUL-189/measure_perf.gd` (medición sobre `main` antes de la oleada 1, commit base `e86baf3`) y rol `qa-tester` en `PUL-189`.
  4. Evaluación de fondos de pegatinas sobre caja `#C8402F` y suelo `#C4A882` con anillo exterior `StickerInk.INK` (`#2A2320`) en todos los discos (`PUL-185`).
  5. Exención explícita en `PUL-188` AC2 para slots funcionales y `_pipeline/**`; corrección de `owns` en `PUL-187` (`_pipeline/**/*.glb.import` y retirada de ruta inexistente de player).
  6. `PUL-184` en Oleada 2 (`deps: [PUL-181, PUL-182]`); `PUL-186` con `deps: [PUL-182]`.
  7. Textura de `mat_tent_plate.tres` fijada a `res://assets/models/environment/romeria_v2/tent_plate_albedo.png`, preservada explícitamente en `PUL-188`.
  8. Refinamientos de Dirección A (§0.1) declarados en `art-bible.md`.
  9. Erratas subsanadas ($L$ de `#4FA05A` a 0.2754, 11 sub-mallas en `PUL-183`, paréntesis cerrado en §3.2).
- **Ronda 3 — Corrección de re-revisión (hallazgos N1–N6)**:
  - **N1 y N2**: `PUL-186` y `PUL-187` derivadas de `slots_reales.md` §1 y §2 como única fuente normativa de verdad; eliminados nombres inventados (`mat_rock`, `mat_wood`, `picnic_table`, `mat_eyes`, `mat_white`), corregidas asignaciones de `mat_steel_dark` a `#1D3557`, `seasoning_station_atlas` a `#EDE8DF`, `atlas_octopus` a `#B8283D` e incluidos todos los slots reales de estaciones y entorno.
  - **N3**: `res://assets/models/environment/romeria_v2/tent_plate_albedo.png` como ruta única en `art-bible.md`, `PUL-182`, `PUL-187` y `PUL-188`; preservada explícitamente en `PUL-188`.
  - **N4**: regla unificada del anillo delimitador `StickerInk.INK` (`#2A2320`) en todos los discos en `art-bible.md` §6.2.1 y `PUL-185`, con discriminación unívoca del picante por silueta octogonal D26 e icono chispa interior crema `#F7F4EC` (**8.21 : 1**).
  - **N5**: contraste frentes navy corregido a **10.12 : 1** en §0.1.2; luminancia de `wall_granite #9A948C` corregida a **0.2994** en §0.1.1, §2, §10.1 y `moodboard-v3.svg`; cabecera de 7 columnas en tabla §3.1 y corrección a `mat_wall_granite.tres`.
  - **N6**: mallas de dispensadores referenciadas con sus nombres reales `paprika_sweet` y `paprika_hot` de `seasoning_dispenser.glb` en §3.1, §3.3.4 y §5.3, sin geometrías añadidas (D28).
  - Verificación estricta mediante `docs/evidence/PUL-181/check_names.py`.
- **AC5 (`tools/verify.sh --quick` y `tools/check_owns.py`)**:
  ```text
  $ tools/verify.sh --quick
  == gdformat --check
  241 files would be left unchanged

  == gdlint
  Success: no problems found

  == import

  ✓ verify OK

  $ python3 tools/check_owns.py jrmougan/pul-181 main
  check_owns: 15 rutas dentro de owns de PUL-181.
  ```
