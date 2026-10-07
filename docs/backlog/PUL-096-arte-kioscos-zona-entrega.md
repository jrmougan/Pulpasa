---
id: PUL-096
title: Rehacer los kioscos con placa de comanda y zona de entrega (arte, Codex)
status: ready
milestone: M3c
role: asset-pipeline
deps: []
orca_task: null
unity_sources: []
owns: [art/blender/order_stand.blend, godot/assets/models/stations/order_stand/**, docs/evidence/PUL-096/**, docs/backlog/PUL-096-arte-kioscos-zona-entrega.md]
touches_scenes: []
---

## Target
Kioscos `order_stand`. Concepto: `art/concepts/estaciones/A_kiosks.png`. QA PUL-087 D1 (`#id` sin placa sobre las rayas).

## Change
1. **Placa papel** con borde marino detrás del `#id` de la comanda, separada de las rayas del toldillo; el número fijo del puesto sigue en el disco inferior.
2. **Zona de entrega en el suelo** delante de cada kiosco: pieza `delivery_zone` (recuadro pintado/alfombrilla) con dos materiales, apagado y encendido (emisivo suave en el color del toldo del puesto), para que gameplay los alterne.
3. Los colores de toldo por puesto (rojo, azul, amarillo, verde) quedan documentados en hex para el recurso `StandPalette`.

## Constraints
- Lo hace **Codex** (D23): no se ejecutan los hooks de `.claude/`; respeta tú mismo `owns` y comprueba
  `tools/check_owns.py jrmougan/pul-096 jrmougan/agentica-migracion-godot-alpha` y `tools/verify.sh` en verde antes de cerrar.
- Blender solo por CLI (`blender -b ... --python ...`); nunca el puerto 9876 ni procesos Blender ajenos.
- Godot con `--audio-driver Dummy` (xvfb). Reglas: `docs/art/art-bible.md`, `docs/art/brand.md`, `docs/art/materials-v2.md`,
  `docs/art/pipeline.md`; dirección **A · Señalética de pase** de `docs/art/rediseno-estaciones-arte.md` adaptada a D23.
- Highlight: patrón `OutlineHull` en mallas abiertas (no rellenar de amarillo). No cambies anchors/colisiones sin decirlo en Evidence.
- Fila de licencia: propia (equipo Pulpasa); propónla en Evidence, la añade el coordinador.
- No toques `order_stand.tscn` (lo integra PUL-100).

## Acceptance
- [ ] AC1 `#id` legible sobre placa a 1080p en los 4 kioscos (captura)
- [ ] AC2 `delivery_zone` con estados apagado/encendido (captura de ambos)
- [ ] AC3 Hex de los 4 colores de puesto en Evidence

## Plan
1. Inspeccionar modelo, atlas, orientación y contratos; conservar los anchors y colisiones actuales.
2. Añadir placa papel con borde marino y pieza `delivery_zone`; exportar GLB y materiales apagado/encendido por puesto.
3. Capturar los cuatro kioscos en Godot a 1920×1080 con cámara de juego, documentar colores e integración PUL-100.
4. Ejecutar verify, commitear únicamente owns y comprobar check_owns tras el commit.

## Evidence
(Lo rellena el worker.)
