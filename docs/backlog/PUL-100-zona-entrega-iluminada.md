---
id: PUL-100
title: Encender la zona de entrega del kiosco con la caja correcta
status: ready
milestone: M3c
role: gameplay-engineer
deps: [PUL-093, PUL-096, PUL-099]
orca_task: null
unity_sources: []
owns: [godot/entities/stations/order_stand.gd, godot/entities/stations/order_stand.tscn, godot/entities/stations/order_stand_model.gd, godot/tests/integration/test_order_stand.gd, godot/tests/unit/test_order_stand_model.gd, docs/evidence/PUL-100/**, docs/backlog/PUL-100-zona-entrega-iluminada.md]
touches_scenes: [godot/entities/stations/order_stand.tscn]
---

## Target
Kiosco de entrega (D23, E-A).

## Change
Integra el modelo de PUL-096 (placa del `#id`, `delivery_zone`). La zona se enciende (material encendido, color de `StandPalette` en `albedo_color` y `emission` de `delivery_zone_on.tres`) cuando un portador a ≤ 2,0 m lleva una caja que coincide con la comanda viva del puesto; si no coincide, apagada. **Alinea el `Area3D` de entrega con la marca `delivery_zone` de PUL-096**, que se desplazó hacia la cocina (centro Z local ≈ 2,5) para que se vea desde la cámara; el centro final es Z local **3,40** (no 2,5; tamaño en `docs/evidence/PUL-096/README.md`). Mueve también `OrderLabel` a `Anchor_OrderLabel` sobre la placa nueva. Revisión de PUL-096: el chevron apunta hacia la cocina; valida con diseño si debe apuntar al kiosco.

## Constraints
- `tools/verify.sh` en verde; GDScript tipado; datos en `.tres`. Godot con `--audio-driver Dummy`; con el MCP, silencia los buses.
- Diseño: D23 en `docs/design/decisions.md` y `docs/design/rediseno-estaciones.md` (R1–R17). Las features reescritas (PUL-092) y los contratos (PUL-093) mandan.

## Acceptance
- [ ] AC1 R12: caja que coincide → zona encendida en ≤ 0,1 s; que no coincide → apagada → test
- [ ] AC2 Captura de un kiosco encendido y otro apagado

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
