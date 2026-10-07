---
id: PUL-094
title: Rehacer la estación de condimentos como línea al paso (arte, Codex)
status: ready
milestone: M3c
role: asset-pipeline
deps: []
orca_task: null
unity_sources: []
owns: [art/blender/seasoning_station.blend, godot/assets/models/stations/seasoning_station/**, godot/data/seasonings/*.tres, docs/evidence/PUL-094/**, docs/backlog/PUL-094-arte-estacion-al-paso.md]
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
- [ ] AC1 Mostrador sin bandeja con los dos frentes distinguibles: captura a la cámara del juego (1080p)
- [ ] AC2 Los 4 dispensadores se distinguen en escala de grises a 1080p (captura desaturada)
- [ ] AC3 Cuenco con `Portions0..4` y colores armonizados en los `.tres` (test de datos en verde)
- [ ] AC4 Presupuesto de triángulos dentro de la biblia §4

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
