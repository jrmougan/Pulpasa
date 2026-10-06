---
id: PUL-055
title: Modelar el entorno de romería
status: review
milestone: M3
role: asset-pipeline
agent: claude + MCP de Blender (PUL-043)
deps: [PUL-042, PUL-043, PUL-041]
orca_task: null
unity_sources: []
owns: [art/blender/romeria.blend, godot/assets/models/environment/romeria/**, godot/entities/environment/environment.tscn, docs/evidence/PUL-055/**]
touches_scenes: [godot/entities/environment/environment.tscn]
---

## Target
D20: arte propio en Blender con un agente con MCP de Blender (pipeline de PUL-043), siguiendo la
biblia de arte (`docs/art/art-bible.md`, PUL-042).

## Change
1. Suelo (tierra/hierba/piedra), carpa o toldo de pulpería, bancos corridos, farolillos y banderines; decoración fuera de la zona jugable sin estorbar la cámara.
2. Fuente en `art/blender/romeria.blend`; export `.glb` en `godot/assets/models/environment/romeria/` con
   `tools/blender_export.py`.
3. Sustituir el placeholder en su escena (`Model`), sin cambiar colisiones ni nodos de contrato
   (`scene-tree.md` §3) salvo que se pida. Depende de la planta elegida (PUL-041).
4. Registrar la licencia (propia) en `docs/assets/licenses.md` → pedirlo al coordinador (fuera de `owns`).

## Ajustes de la biblia de arte (PUL-042)
Ajuste de la biblia (§4): dividir en 3 `.glb` (`ground`, `tent`, `decor`) dentro de `romeria/**`. Temática de la planta B: pulpeira de barra.

Nota de PUL-049: si el modelo tiene mallas abiertas o huecas (cubas, cestos, baldas), el contorno inverted-hull del resaltado lo rellena entero. Solución usada: nodo `OutlineHull` con cajas cerradas ocultas y `Highlightable.root` apuntando a él; comprueba la captura resaltada.

Nota de PUL-051: la estantería de cajas (1,8 m de ancho) queda en parte dentro de la pared oscura de la planta B; las paredes y encimeras nuevas deben dejarla libre y visible.

## Constraints
- Presupuesto de polígonos, escala, frente −Z y paleta de la biblia de arte.
- Antes de cerrar: `tools/verify.sh` verde y `tools/check_owns.py <tu-rama> jrmougan/agentica-migracion-godot-alpha` limpio.

## Acceptance
- [x] AC1 Escala y frente correctos frente a `scale_check.tscn` → `test_assets_models.gd`
- [x] AC2 Legible desde la cámara del nivel: captura en `docs/evidence/PUL-055/`
- [x] AC3 `.blend` y `.glb` versionados; escena sin errores de import
- [x] AC4 `tools/verify.sh` verde, `check_owns` limpio.

## Plan
1. Medir la planta B en `level_01` (zona jugable x ∈ [−6,8, 9,2], z ∈ [−4,5, 6,5]) y la proyección de la
   cámara ortográfica: lo que está detrás de la cocina (z < −4,5) y por encima de ≈ 2,3 m queda sobre las
   estaciones en pantalla sin taparlas; lo que está fuera de x ∈ [−6,8, 9,2] nunca se superpone a la zona
   jugable (ortográfica, sin paralaje en X).
2. `test_assets_models.gd` limita cada `.glb` a 12 m de planta, así que suelo y decoración son módulos que
   `environment.tscn` instancia dos veces: `ground` (8 × 11 m, medio campo) en x = −2,8 y 5,2; `decor`
   (franja de 2,6 × 11,8 m) a la izquierda (girada 180°) y a la derecha. `tent` (11,9 m) va una vez detrás
   de la cocina, girada 180° para que su frente (+Y de Blender) mire a la cámara.
3. Modelar con `bpy`/`bmesh` en `art/blender/romeria.blend` (copia de `_template.blend`) por el MCP de
   Blender en modo CLI (`execute_blender_code_for_cli`), tres colecciones `export*` con su raíz y su
   `Anchor_Front`, materiales `mat_*` de la paleta; exportar con `tools/blender_export.py`.
4. Instanciar bajo un nodo `Model` nuevo en `environment.tscn`, conservando `WorldEnvironment` y `Sun`, sin
   colisiones. Capturas desde la cámara de `level_01`, frente a `scale_check` y render del `.blend`.

## Evidence
- **Fuente**: `art/blender/romeria.blend`, generado por `docs/evidence/PUL-055/build_romeria.py` (ejecutado con
  `execute_blender_code_for_cli` del MCP de Blender sobre una copia de `_template.blend`); export reproducible
  con `docs/evidence/PUL-055/export_romeria.sh` (renombra en memoria cada colección a `export`, como PUL-052).
- **Export** (`godot/assets/models/environment/romeria/`): `ground.glb` 42 tris, `tent.glb` 1 476 tris,
  `decor.glb` 2 018 tris → 3 536 triángulos por pieza única (presupuesto del entorno 6 000, objetivo ≈ 3 500).
  En el nivel, con las instancias dobles, el entorno suma ≈ 5 600 tris (escena total ≤ 40 000).
  - `ground`: losa de tierra (`ground_dirt`) con la cara superior a 0,012 m sobre el suelo de `KitchenLayout`,
    bordes rectos para que las dos instancias empalmen sin junta. Sin piedras en la zona jugable: en una
    iteración se leían como objetos tirados; solo dos piedras de 0,055 m bajo celdas de pared de la fila 10.
  - `tent`: carpa a dos aguas (alero a 2,6 m en z = −4,75, cumbrera a 3,8 m) con 23 rayas
    `canvas_cream`/`canvas_stripe`, faldón festoneado (borde inferior a 2,2 m), postes y mástiles de
    `wood_dark`, suelo de losas `ground_stone` hasta el borde de la cocina, cartel «PULPO Á FEIRA» con letras
    de píxeles en la cumbrera, dos cuerdas de banderines y tres farolillos emisivos (`lantern_warm`, 0,6).
  - `decor`: mesa corrida con mantel y tres platos de pulpo, dos bancos, cuatro barriles, cajas de pescado,
    cuatro sacos, dos arcos de banderines, ristra de 7 farolillos y matas de hierba.
- **Escena**: `environment.tscn` conserva `WorldEnvironment` y `Sun` y añade `Model` con `GroundWest`,
  `GroundEast`, `Tent`, `DecorWest` y `DecorEast`. Ninguna colisión nueva; no se tocan `kitchen_layout.tscn`
  ni `level_01.tscn`.
- **AC1**: `test_assets_models.gd` pasa con los tres `.glb` (escala aplicada, base en y = 0, `Anchor_Front` en
  −Z, planta ≤ 12 m, alto ≤ 6 m). `scale_check.png`: carpa, franja de decoración y suelo junto al cubo de 1 m
  y el personaje de 1,8 m (bancos a 0,45 m, mesa a 0,75 m, barriles de 0,85 m).
- **AC2**: `level_camera.png` (vista completa a 1920×1080) frente a `level_camera_before.png`, y recortes
  `level_camera_tent.png`, `_west.png` y `_east.png`. El faldón y los farolillos de la carpa quedan por encima
  del arcón de pulpo (lo más alto de la fila 0, borde superior en ≈ 373 px; el faldón acaba en ≈ 340 px y los
  farolillos se colocaron fuera de su columna); estaciones, barra, pasaplatos, puestos y personajes se ven
  enteros. La decoración está toda fuera de x ∈ [−6,8, 9,2] y, en z, entre −7,9 y 3,9 (nada delante del plano
  de juego). HUD y tickets son `CanvasLayer` y se dibujan siempre encima. `blender_render.png`: render del
  `.blend` (carpa de frente y franja de decoración).
- **AC3**: `.blend`, `.glb` y `.glb.import` versionados; `godot --headless --import` y las capturas sin errores.
- **AC4**: `tools/verify.sh` verde (645/645 tests, smoke OK); `tools/check_owns.py` limpio.
- **Licencia**: propia (D20); la registra el coordinador en `docs/assets/licenses.md`.
