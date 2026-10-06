---
id: PUL-085
title: Rehacer el entorno con la estética de referencia
status: done
milestone: M3b
role: asset-pipeline
deps: [PUL-072, PUL-074, PUL-073, PUL-088]
orca_task: task_aae2ba40e769
unity_sources: []
owns: [art/blender/**, godot/assets/models/environment/**, godot/entities/environment/environment.tscn, docs/evidence/PUL-085/**]
touches_scenes: [godot/entities/environment/environment.tscn]
---

## Target
Adaptar este asset a la estética elegida por el responsable (`docs/art/style-refs/referencia-elegida-2026-10-06.png`).

## Change
Suelo de tierra con rodadas, charcos y manchas; valla metálica, árboles y helechos; bidones, generador, bombonas, cables y tuberías; carpa/toldo y cartel y toldo de **PulpaSA** (D21); mesas con comensales **estáticos** (Won't: NPC animados); guirnaldas de bombillas. Divide en varios `.glb` (suelo, carpa, fondo, atrezo) y deja fuera de la zona jugable todo lo denso.

## Constraints
- Referencia visual: `docs/art/style-refs/referencia-elegida-2026-10-06.png`; reglas en `docs/art/art-bible.md` v2 (PUL-072) y materiales de PUL-074.
- Modela con el MCP de Blender (por CLI; no uses el puerto 9876 si hay un Blender del responsable).
  Godot para capturas siempre con `--audio-driver Dummy`.
- No cambies la jugabilidad: colisiones, anclas, nodos de contrato (`scene-tree.md`), posiciones en
  `level_01` y los tests de selección/entrega deben seguir en verde. Resaltado con contorno fino
  (`OutlineHull` si el modelo es abierto, nota de PUL-049).
- Conserva la legibilidad (biblia §3): siluetas, crudo/cocido/quemado, pegatinas, colores por puesto.
- Capturas desde la cámara de `level_01` (antes/después, con resaltado) y render del `.blend` en
  `docs/evidence/<id>/`. La licencia propia la registra el coordinador.
- Antes de cerrar: `tools/verify.sh` verde y `tools/check_owns.py <tu-rama> jrmougan/agentica-migracion-godot-alpha` limpio.

## Acceptance
- [x] AC1 Escala, frente y presupuesto de la biblia v2 → `test_assets_models.gd`
- [x] AC2 Legible y coherente con la referencia junto a los assets v2 ya hechos
- [x] Captura antes/después desde la cámara del nivel y render del `.blend`
- [x] `tools/verify.sh` verde, `check_owns` limpio.

## Plan
1. Medir lo que ve la cámara de `level_01` (ortográfica, `size` 12,74, 38°): suelo visible x ∈ [−10,6, 12,0],
   z ∈ [−14, 6,6]; zona jugable x ∈ [−6,8, 9,2], z ∈ [−4,5, 6,5]. Detrás del muro (z < −4,56) solo se ve
   lo que asoma por encima de él (a z > −7 casi nada): el atrezo de fondo va a z ≤ −7 o fuera de los laterales.
2. Como cada `.glb` está limitado a 12 m de planta (`test_assets_models.gd`), dividir el entorno en siete
   piezas modeladas en coordenadas del nivel y colocadas por `environment.tscn` (giradas 180°, frente a la
   cámara): `ground_w/e` (Z0), `back_w/e` (muro y fondo), `tent` (toldo y cartel), `props_w/e` (laterales).
3. Texturas propias (art-bible §3.3) generadas por script sin imágenes de terceros: atlas de atrezo 512²
   (ropa de comensales, banderines, follaje, fento, pizarra), decals de suelo 1024² (rodadas, charcos,
   manchas, hojas), malla de valla 256², placa del toldo y cartel luminoso a partir de los PNG de PUL-088.
4. Modelar por `bpy`/`bmesh` con el MCP de Blender en modo CLI (`execute_blender_code_for_cli`, nunca el
   puerto 9876) sobre una copia de `_template.blend`, con los `mat_*` enlazados de la biblioteca v2.
5. Exportar con `tools/blender_export.py`, ajustar los `.png.import` (VRAM, normal maps) y sustituir los
   `.glb` de `Model` en `environment.tscn` sin tocar `WorldEnvironment`, `Sun`, `Bulbs` ni `Vignette`.
6. Capturas antes/después desde la cámara del nivel con resaltado encendido, render del `.blend`,
   comprobación de contraste de los decals de Z0 y `tools/verify.sh`.

## Evidence
- **Fuente**: `art/blender/environment_v2.blend` (copia de `_template.blend`, materiales v2 enlazados) generado
  por `art/blender/environment_v2_src/build_environment.py` con `execute_blender_code_for_cli` del MCP de
  Blender; texturas propias de `art/blender/environment_v2_src/gen_textures.py` →
  `art/blender/textures/environment_v2/`; export reproducible con `export_environment.sh` (renombra en
  memoria `export_<pieza>`/`Anchor_Front_<pieza>`, como PUL-055). Sustituye a `romeria/` de PUL-055 (borrado;
  `art/blender/romeria.blend` queda como archivo de la v1).
- **Piezas** (`godot/assets/models/environment/romeria_v2/`, triángulos tras triangular):

  | Pieza | Tris | Contenido | Zona |
  |---|---|---|---|
  | `ground_w` / `ground_e` | 688 / 768 | Tierra `mat_ground_dirt` (1 UV = 4 m), hierba fuera del perímetro, decals planos de rodadas (dos ruedas), charcos (`roughness` 0,1), manchas, hojas y piedrecitas; rejillas de desagüe de 1,5 cm delante de los cocedores y en el pasillo de los kioscos; matas bajas solo fuera del perímetro | Z0 + borde Z3 |
  | `back_w` / `back_e` | 3 613 / 3 844 | Muro de sillares `mat_granite` (2,05 m, albardilla, pilastras, musgo abajo), patio y prado, valla de malla con postes, dos carballos por lado, fentos, tres tanques de gas con tapa roja, generador `paint_beige` con panel y rejilla, bidones, bombonas azules, barriles, cajas, sacos y cables | Z3 |
  | `tent` | 2 394 | Toldo de 16 rayas `canvas_red`/`canvas_paper` con faldón festoneado y ribete marino, placa PulpaSA horizontal con lema sobre papel con borde marino, cartel luminoso (caja noche, «Pulpa» y símbolo en neón emisivo, «SA» blanco), dos cámaras de vigilancia, dos pizarras de menú con logo pequeño y tiza ilegible, guirnalda de 20 bombillas `mat_emissive_bulb` | Z3, por encima del plano de juego |
  | `props_w` / `props_e` | 9 071 / 5 502 | Tres mesas largas con mantel de papel, bancos y 14 comensales estáticos con ropa de romería (boina, pañuelo, chaleco, rebeca; tonos apagados, sin `player_*`/`stand_*`/marino), platos de madera con pulpo, cuncas, jarras y vasos PulpaSA; barriles, cajas, sacos, fentos; postes con guirnaldas de bombillas y banderines apagados | Z3 |

  Total del entorno: **25 880 tris** (presupuesto 80 000; cada mesa con comensales ≈ 4 000 ≤ 5 000). Alturas
  ≤ 5,71 m, plantas ≤ 11,98 m. Sin luces, cámaras ni colisiones nuevas.
- **Texturas**: propias 512² (atlas), 1024² (decals de suelo), 256² (valla), 1024×352 (placa) y 1024×384
  (cartel albedo + emisión); el resto, de la biblioteca v2. Embebidas en cada `.glb` y extraídas por Godot
  (132 PNG, `compress/mode=2`, mipmaps, normal maps con `normal_map=1`) ≈ 60 MB de VRAM (≤ 256 MB).
  Para PUL-087: siete `.glb` con materiales embebidos suman 98 superficies (≈ 98 draw calls) y 83 recursos de
  material del entorno (la biblioteca se repite por `.glb`); si el límite de «≤ 60 materiales» de §4.3
  cuenta recursos, habrá que compartirlos (p. ej. `materials/extract`), lo que hoy prohíbe el test.
- **AC1**: `test_assets_models.gd` pasa con las siete piezas (escala aplicada, base en y = 0, `Anchor_Front` en
  −Z, planta ≤ 12 m, alto ≤ 6 m); medidas de §2.1 de la v1: bancos 0,45 m, mesas 0,74 m, barriles 0,85 m,
  muro 2,05 m, alero del toldo 2,62 m.
- **AC2**: [`comparativa.png`](../evidence/PUL-085/comparativa.png) (antes, después, referencia y render) y
  capturas 1920×1080 desde la cámara de `level_01` en [`antes/`](../evidence/PUL-085/antes/) y
  [`despues/`](../evidence/PUL-085/despues/) (`00` sin HUD, `01` con HUD, recortes de cocina, toldo, oeste y
  este), con el contorno de resaltado encendido en el tanque, un cocedor, el rack y el kiosco 4: se sigue
  viendo sobre el muro de granito y la tierra. Legibilidad: todo el atrezo queda fuera de x ∈ [−6,8, 9,2] o
  detrás del muro; el faldón y la guirnalda (borde inferior a ≈ 2,1 m en z = −4,45) quedan por encima de lo
  más alto de la fila de cocina en pantalla; la cocina, la barra, los kioscos y los cocineros se ven
  enteros. Decals de Z0 contra `ground_dirt`: rodada 1,23:1, charcos 1,22:1, manchas 1,15:1, hojas
  1,23:1 (≤ 1,3:1, [`check_decals.py`](../evidence/PUL-085/check_decals.py)). Marca solo donde dice §7: cartel
  luminoso (horizontal sin lema), placa del toldo (con lema, sobre papel, nunca sobre las rayas), pizarras
  (horizontal pequeña) y vasos de los comensales.
- **Render**: [`blender_render.png`](../evidence/PUL-085/blender_render.png) (Cycles, mismo encuadre que la
  cámara del nivel; `render_blend.py`).
- **Reproducir**: `python3 art/blender/environment_v2_src/gen_textures.py`, construir el `.blend` con el MCP
  (instrucciones en `build_environment.py`), `art/blender/environment_v2_src/export_environment.sh`,
  `godot --headless --path godot --import`; capturas con
  `xvfb-run -a godot --audio-driver Dummy --path godot --resolution 1920x1080 -s $PWD/docs/evidence/PUL-085/capture_pul085.gd -- <dir>`.
- **verify / check_owns**: `tools/verify.sh` verde (725/725 tests GUT, smoke OK); `tools/check_owns.py jrmougan/pul-085 jrmougan/agentica-migracion-godot-alpha` limpio.
- **Licencia**: propia (D20); texturas propias generadas por script y logotipo de PUL-088. La registra el
  coordinador (la fila de `romeria/` de PUL-055 en `docs/assets/licenses.md` pasa a `romeria_v2/`).
