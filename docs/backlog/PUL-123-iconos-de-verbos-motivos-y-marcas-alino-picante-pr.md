---
id: PUL-123
title: Iconos de verbos, motivos y marcas; aliño picante propio; rack y caja sin S/M/L
status: done
milestone: M3e
role: asset-pipeline
deps: [PUL-119, PUL-120]
orca_task: null
unity_sources: []
owns: [godot/assets/textures/ui/actions/**, godot/resources/action_icon_set.gd*, godot/data/config/action_icons.tres, art/blender/box_shelf.blend, godot/assets/models/stations/box_shelf/**, art/blender/box.blend, godot/assets/models/items/box/**, godot/assets/textures/ui/box_sizes/**, godot/tests/unit/test_icons_silhouettes.gd*, godot/tests/unit/test_action_icon_set.gd*, docs/evidence/PUL-123/**, docs/backlog/PUL-123-iconos-de-verbos-motivos-y-marcas-alino-picante-pr.md]
touches_scenes: []
---

## Target
D26 (`docs/design/decisions.md`), contrato en `docs/arch/` (ADR-003 §11, ADR-004 §6, ADR-005 Enmienda D26,
ADR-006 §4.1, `signals.md`, `scene-tree.md` §9). Partición original y notas de propietarios entre oleadas:
`docs/backlog/PUL-120-contratos-d26.md` («Partición en fichas»). Oleada 1. Diseño:
`docs/design/features/lenguaje-acciones.md` y `controles-tactiles.md`. Touches scenes original: ninguna (los `.glb` cambian contenido, no las escenas que los instancian)

## Change
SVG propios, monocromos, 128×128, trazo ≥ 8 % del lado, según «Iconografía» de
  `lenguaje-acciones.md`: `icon_verb_<id>.svg` × 8 (ids del contrato), `icon_reason_<id>.svg` × 6
  (`box_not_full`, `busy`, `empty`, `full`, `already_applied`, `not_cooked`), `icon_mark_<nombre>.svg`
  (`cross`, `replace`, `ready`, `burn_warning`, `active`, `offscreen`, `player_1`, `player_2`, `plate`
  si la placa es textura). `ActionIconSet` (ADR-003 §11.5) y `action_icons.tres` con las claves
  literales del contrato y los valores del diseño. Rack y textura de señales de la caja sin letras
  S/M/L (pipeline de PUL-043). Sin créditos externos.

## Constraints
- Solo las rutas de `owns`/`touches_scenes`. Si un cambio rompe un test fuera de tus owns, para y avisa al producer.
- Tipado estático, datos en `.tres`, lógica en `core/` RefCounted; no inventes `uid://`.
- Nombres exactos del contrato (manda sobre el diseño; equivalencias en PUL-120).

## Acceptance
- [x] AC1 (diseño AC4) Verbos a 64 px y motivos a 32 px, en gris y binarizados al 50 %: IoU de cualquier par <= 0,6; dulce y picante incluidos. IoU máximo medido: verbos 0,521; motivos 0,486 -> `test_icons_silhouettes.gd`
- [x] AC2 `action_icons.tres` tiene exactamente las claves de verbos y motivos del contrato, todas con textura que importa, y los valores del diseño -> `test_action_icon_set.gd`
- [x] AC3 (diseño AC19, parte de arte) `box_shelf.glb` y `box.glb` sin S, M ni L; capturas y hoja de contacto en `docs/evidence/PUL-123/`

## Plan
1. 23 SVG propios 128x128 (8 verbos, 6 motivos, 9 marcas incl. `plate`), monocromos blancos, trazo >= 10 px.
2. `ActionIconSet` + `action_icons.tres` (diccionarios tipados, valores del diseño).
3. Tests de siluetas (rasteriza con `Image.load_svg_from_string`) y de datos; iterar siluetas hasta IoU <= 0,6.
4. `box.blend`: quitar `SizeRim_*` y `SizeLetter_*`. `box_shelf.blend`: quitar `SizeFront_*` y `RackTop*`; las placas
   `SizePanel_*` se quedan lisas (material `mat_plastic_blue`) porque `test_level_01.gd` (fuera de owns) las exige.
   Quitados los materiales/imagenes `box_size_signs` y `rack_size_signs`. Reexport con `tools/blender_export.py`.
5. Baja de `assets/textures/ui/box_sizes/` y de los PNG `*_size_signs.png` (sin referencias: grep).
6. Evidencia y verify.

## Evidence
- `docs/evidence/PUL-123/contact_sheet_64px_gray.png`: verbos y marcas (incluida `plate`) a 64 px, motivos a 32 px, en gris (`contact_sheet.gd`).
- `docs/evidence/PUL-123/rack_in_game.png`, `box_in_game.png`: rack y caja en `level_01` (`capture.gd`), sin letras.
- Presupuestos: `box.glb` 1034 tris; `box_shelf.glb` 5912 tris (< 6000).
- Pendiente fuera de owns: el icono del aliño picante en `data/seasonings/hot_dressing.tres`/ticket (ver informe), `docs/assets/licenses.md` (fila de PUL-095 cita las letras).
- Revisión (CHANGES): trazos subidos a >= 11 px (`already_applied`, `busy`, `not_cooked`, `cook`); el test comprueba trazo con una apertura circular de radio 5 que conserva >= 85 % de la máscara, marcas incluidas; `.svg.import` con `mipmaps/generate=true`; caja de `box_in_game.png` recolocada en suelo despejado.
- Las listas literales de verbos y motivos de `test_action_icon_set.gd` y `test_icons_silhouettes.gd` se sustituyen por `ActionVerb.ALL`/`ActionReason.ALL` en PUL-131.
