---
id: PUL-095
title: Rehacer rack, bandejas S/M/L y marcas de pasaplatos (arte, Codex)
status: review
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
- [x] AC1 Rack con S/M/L legible a 1080p con giro −90°: [captura](../evidence/PUL-095/native_1080.png)
- [x] AC2 Bandejas [aisladas](../evidence/PUL-095/native_1080.png) y en la mano de ambos jugadores: [S](../evidence/PUL-095/hands_small_1080.png), [M](../evidence/PUL-095/hands_medium_1080.png), [L](../evidence/PUL-095/hands_large_1080.png); iconos PNG exportados
- [x] AC3 `pass_mark` y `pass_threshold` exportados: [captura](../evidence/PUL-095/native_1080.png)
- [x] AC4 [Rack 5.960/6.000](../evidence/PUL-095/budget.json); [bandejas llenas S/M=1.952, L=1.932 / 2.000](../evidence/PUL-094/validation.json), incluyendo hulls y reserva para badges/barra

## Plan
1. Reutilizar siluetas y hulls de bandejas; añadir letras en el borde y placas S/M/L frontales y visibles con giro de 90° del rack.
2. Exportar iconos PNG desde el mismo atlas y piezas independientes `pass_mark` y `pass_threshold` en counters.
3. Validar presupuesto y capturar orientación real, bandejas aisladas/sostenidas y marcas, sin editar escenas ni datos.

## Evidence
Arte completo, pendiente de revisión/integración. [Entrega y contratos](../evidence/PUL-095/README.md). Raíces, anclajes, dimensiones nominales y `OutlineHull` conservados; contornos simplificados para cumplir el presupuesto con relleno máximo. Letras de borde y placas delanteras/superiores del rack; iconos `size_s.png`, `size_m.png`, `size_l.png` para PUL-098/099.

Nuevas piezas independientes `pass_mark.glb` y `pass_threshold.glb` en counters; relieve expuesto máximo 2 cm con base empotrada. Módulos anteriores intactos. No se modificaron `.tscn` ni `.tres` de gameplay.

[`tools/verify.sh`: 735/735 y smoke OK](../evidence/PUL-094/verify.log); [31 tests específicos](../evidence/PUL-094/final_asset_tests.log); [auditoría de alcance](../evidence/PUL-094/validation.json). Licencia propia propuesta en Evidence; Montserrat e iconos existentes mantienen sus atribuciones.
