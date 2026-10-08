---
id: PUL-096
title: Rehacer los kioscos con placa de comanda y zona de entrega (arte, Codex)
status: done
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
- [x] AC1 `#id` legible sobre placa a 1080p en los 4 kioscos: [#17/#28/#39/–](../evidence/PUL-096/zone_off_1080.png)
- [x] AC2 `delivery_zone`: [apagado](../evidence/PUL-096/zone_off_1080.png) y [encendido](../evidence/PUL-096/zone_on_1080.png)
- [x] AC3 [Hex y colocación final](../evidence/PUL-096/integration.json): #D2473F / #3F7CC8 / #E8C23A / #4FA05A

## Plan
1. Preservar cuerpo, toldillos y número fijo; incorporar placa papel/marino para el ID variable.
2. Exportar `delivery_zone` con materiales apagado y encendido, y documentar centro, tamaño y paleta para integración.
3. Capturar cuatro kioscos con IDs diferentes del número fijo y ambos estados; validar exportación, presupuesto y proyecto.

## Evidence
[README de entrega (materiales, anclajes, notas para PUL-099/100)](../evidence/PUL-096/README.md). Revisión posterior al trabajo de Codex: se regeneraron las capturas con `capture_zone.gd` (las originales mostraban apagado y encendido casi idénticos porque el marco es blanco y una emisión sola no lo tiñe) y se corrigió `delivery_zone_on.tres`, que ahora lleva `albedo_color` + `emission` del color del puesto.

GLB conservado; añadidos placa papel/marino, `Anchor_OrderLabel`, `delivery_zone` y `Anchor_DeliveryZone`. **Centro de entrega Z local = 3,40 m** (huella 1,45 x 1,05 m, relieve <= 2 cm), al lado +Z como el `DeliveryZone` Area3D actual (1,17 m) pero más lejos: a Z~2,5 el toldillo lo oculta a cámara de juego. PUL-100 debe decidir si mueve el Area3D al nuevo centro o acerca la alfombrilla. `Anchor_OrderLabel`=(0, 1,905, -0,23). No se tocó `order_stand.tscn`, ni colisión ni número fijo.

[Presupuesto: 3.032 / 6.000 tris](../evidence/PUL-096/budget.json). `tools/verify.sh` en verde (735/735 y smoke OK). Capturas en estudio; iluminación y oclusión del nivel son de integración y QA. Fila de licencia propia propuesta en el README; la añade el coordinador.
