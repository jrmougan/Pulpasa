---
id: PUL-094
title: Rehacer la estación de condimentos como línea al paso (arte, Codex)
status: review
milestone: M3c
role: asset-pipeline
deps: []
orca_task: null
unity_sources: []
owns: [art/blender/seasoning_station.blend, godot/assets/models/stations/seasoning_station/**, godot/data/seasonings/*.tres, godot/tests/unit/test_data_integrity.gd, docs/evidence/PUL-094/**, docs/backlog/PUL-094-arte-estacion-al-paso.md]
touches_scenes: []
---

## Target
Modelos de `art/blender/seasoning_station.blend` → `godot/assets/models/stations/seasoning_station/` (`seasoning_station.glb`, `seasoning_dispenser.glb`, `cachelos_bowl.glb`). Concepto de partida: `art/concepts/estaciones/A_station.png`.

## Change
1. **Mostrador sin bandeja** (D23): la estación es una línea; frente de servicio claramente distinto del de cocina (faja marino, chevrones pintados hacia el lado de uso, alfombrilla o cambio de suelo en el lado de servicio). Mismos anclajes de dispensadores pero separación ≥ 1,0 m entre centros (orden del ticket: dulce, picante, sal, aceite, cachelos).
2. **Dispensadores** dirección A: silueta distinta por condimento (lata ancha baja, lata estrecha facetada con llama, salero con tapa oscura, botella con pico) y botón circular papel con icono en el frente de servicio, legible sin color (≥ 12 px a 1080p). Dulce y picante juntos como pareja.
3. **Cuenco de cachelos** con 5 estados visibles de raciones (0–4) como sub-mallas nombradas `Portions0..4` para que gameplay alterne visibilidad.
4. **Colores**: armoniza en `data/seasonings/*.tres` los colores de dulce, picante y cachelos con la biblia §2.5 (divergencia anotada en PUL-091 §1), para que dispensador, pegatina y ticket coincidan.

## Constraints
- Lo hace **Codex** (D23): no se ejecutan los hooks de `.claude/`; respeta tú mismo `owns` y comprueba
  `tools/check_owns.py jrmougan/pul-094 jrmougan/agentica-migracion-godot-alpha` y `tools/verify.sh` en verde antes de cerrar.
- Blender solo por CLI (`blender -b ... --python ...`); nunca el puerto 9876 ni procesos Blender ajenos.
- Godot con `--audio-driver Dummy` (xvfb). Reglas: `docs/art/art-bible.md`, `docs/art/brand.md`, `docs/art/materials-v2.md`,
  `docs/art/pipeline.md`; dirección **A · Señalética de pase** de `docs/art/rediseno-estaciones-arte.md` adaptada a D23.
- Highlight: patrón `OutlineHull` en mallas abiertas (no rellenar de amarillo). No cambies anchors/colisiones sin decirlo en Evidence.
- Fila de licencia: propia (equipo Pulpasa); propónla en Evidence, la añade el coordinador.
- No toques las escenas `.tscn` (las integra PUL-097). Mantén los nombres de los `.glb`.

## Acceptance
- [x] AC1 Mostrador sin bandeja con los dos frentes distinguibles: [servicio](../evidence/PUL-094/native_1080.png) y [pase](../evidence/PUL-094/rear_1080.png), cámara de juego a 1080p
- [x] AC2 Los 4 dispensadores se distinguen en [escala de grises a 1080p](../evidence/PUL-094/grayscale_1080.png)
- [x] AC3 Cuenco con `Portions0..4` y colores armonizados: [captura](../evidence/PUL-094/native_1080.png), [test de datos](../evidence/PUL-094/final_asset_tests.log)
- [x] AC4 [2.912 / 6.000 tris](../evidence/PUL-094/budget.json), incluyendo todas las variantes y estados

## Plan
1. Conservar raíces y variantes; retirar bandeja y tabla del mostrador, ampliar la línea a 5,2 m y situar los cinco centros a 1 m.
2. Incorporar faja, chevrones, botones con iconos canónicos y estados exclusivos `Portions0..4`; armonizar los tres colores de datos.
3. Exportar mediante el validador existente, medir geometría y capturar desde la cámara ortográfica de juego sin editar escenas.

## Evidence
Arte completo, pendiente de revisión/integración. [Entrega, anclajes, licencias propuestas y reproducción](../evidence/PUL-094/README.md).

Mostrador de 5,20 m; centros X=−2/−1/0/1/2 a 1 m. Retirados `tray`, `cutting_board`, `Anchor_Tray`; posiciones de dispensadores y cuenco cambiadas y documentadas para PUL-097. No se editó ningún `.tscn` ni colisión. Colores de dulce, picante y cachelos armonizados con §2.5.

El responsable autorizó ampliar `owns` para `godot/tests/unit/test_data_integrity.gd` el 2026-10-07: el test exigía colores antiguos y ahora valida los cinco hex normativos con comparación aproximada para decimales, sin relajar opacidad ni distinción entre pimentones.

[`tools/verify.sh` en verde: 735/735 tests, smoke OK](../evidence/PUL-094/verify.log). [Auditoría de alcance del árbol de trabajo conjunto](../evidence/PUL-094/validation.json); las ramas individuales nombradas en Constraints no existen en este checkout. Exportaciones por CLI, presupuesto y reglas del importador validados.
