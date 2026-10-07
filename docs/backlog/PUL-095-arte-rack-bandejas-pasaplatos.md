---
id: PUL-095
title: Rehacer rack, bandejas S/M/L y marcas de pasaplatos (arte, Codex)
status: ready
milestone: M3c
role: asset-pipeline
deps: []
orca_task: null
unity_sources: []
owns: [art/blender/box_shelf.blend, art/blender/box.blend, art/blender/counters.blend, godot/assets/models/stations/box_shelf/**, godot/assets/models/items/box/**, godot/assets/models/furniture/counters/**, godot/assets/textures/ui/box_sizes/**, docs/evidence/PUL-095/**, docs/backlog/PUL-095-arte-rack-bandejas-pasaplatos.md]
touches_scenes: []
---

## Target
Rack `box_shelf`, bandejas S/M/L (`box`) y encimeras modulares (`counters`). Conceptos: `art/concepts/estaciones/A_rack.png`, `A_trays.png`, `A_counters.png`.

## Change
1. **Rack**: placa S/M/L en el frente de cada pila (dirección A) y repetida en la cara visible con la orientación real del nivel (el rack está girado 90°).
2. **Bandejas**: silueta S/M/L (círculo/óvalo/rectángulo) más legible y letra en el borde; espacio para la barra de progreso de corte que no se confunda con el papel.
3. **Iconos de tamaño** S/M/L en `godot/assets/textures/ui/box_sizes/` (PNG con la silueta y la letra), los mismos que usarán el ticket y `BoxData.icon`.
4. **Marca de pasaplatos** (esquinas en papel y marino, dirección A) como pieza `pass_mark` en `counters` y **umbral** del hueco de la barra (cambio de suelo o remate) para que no parezca más barra.

## Constraints
- Lo hace **Codex** (D23): no se ejecutan los hooks de `.claude/`; respeta tú mismo `owns` y comprueba
  `tools/check_owns.py jrmougan/pul-095 jrmougan/agentica-migracion-godot-alpha` y `tools/verify.sh` en verde antes de cerrar.
- Blender solo por CLI (`blender -b ... --python ...`); nunca el puerto 9876 ni procesos Blender ajenos.
- Godot con `--audio-driver Dummy` (xvfb). Reglas: `docs/art/art-bible.md`, `docs/art/brand.md`, `docs/art/materials-v2.md`,
  `docs/art/pipeline.md`; dirección **A · Señalética de pase** de `docs/art/rediseno-estaciones-arte.md` adaptada a D23.
- Highlight: patrón `OutlineHull` en mallas abiertas (no rellenar de amarillo). No cambies anchors/colisiones sin decirlo en Evidence.
- Fila de licencia: propia (equipo Pulpasa); propónla en Evidence, la añade el coordinador.
- No toques `.tscn` ni `.tres` (los integran PUL-098 y PUL-101).

## Acceptance
- [ ] AC1 Rack con S/M/L legible a 1080p con la orientación del nivel (captura)
- [ ] AC2 Bandejas S/M/L distinguibles aisladas y en la mano (captura) + iconos S/M/L exportados
- [ ] AC3 `pass_mark` y umbral del hueco exportados con captura a la cámara del juego
- [ ] AC4 Presupuesto dentro de la biblia §4

## Plan
1. Auditar mallas, atlas, anchors y orientación real; conservar contratos y colisiones.
2. Reforzar siluetas y rotular bordes S/M/L; repetir placas del rack en frente y plano visible, con atlas Montserrat.
3. Exportar iconos S/M/L, pieza pass_mark y remate bajo de paso, sin editar escenas ni datos.
4. Capturar fixtures a 1920×1080 con cámara real, medir presupuesto y validar importación, GUT, smoke y owns tras commit.

## Evidence
(Lo rellena el worker.)
