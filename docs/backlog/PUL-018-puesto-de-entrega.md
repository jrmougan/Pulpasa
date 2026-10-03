---
id: PUL-018
title: Crear el puesto de entrega conectado a OrderService
status: ready
milestone: M0
role: gameplay-engineer
deps: [PUL-016]
orca_task: null
unity_sources: [Assets/Scripts/Game/OrderStand.cs, Assets/Prefabs/KitchenStations/OrderStand.prefab]
owns: [godot/entities/stations/order_stand.tscn, godot/entities/stations/order_stand.gd, godot/entities/stations/order_stand.gd.uid, godot/tests/integration/test_order_stand.gd, godot/tests/integration/test_order_stand.gd.uid, docs/evidence/PUL-018/**]
touches_scenes: [godot/entities/stations/order_stand.tscn]
---

## Target
Fase 6 de M0, puesto de entrega (`scene-tree.md` §3 `order_stand.tscn`; ADR-002 reglas 1 y 5; signals.md).

## Change
1. `order_stand.tscn` (`order_stand.fbx` de PUL-008) + `order_stand.gd` (`class_name OrderStand`, `@export slot_id`).
2. `%DeliveryZone` (`Area3D`, capa `delivery_zone`): al entrar una caja **y también al interactuar**
   con ella en la mano (B12), llama `OrderService.try_deliver(slot_id, contents)`. Una entrega → una
   completada (B1); el puesto no completa nada por su cuenta.
3. `%OrderLabel` (`Label3D`): `#id` de la comanda del puesto o «–», actualizado por señales
   (`orders_reset`, `order_generated`, `order_completed`, `order_expired`), sin consultar sistemas (B16).
4. Sonidos ok/error (PUL-009) según `order_completed` / `delivery_rejected` de su `slot_id`.
5. La caja entregada se libera; la rechazada se queda en la mano (paridad, D8 es M1).

## Constraints
- `.tscn` con el MCP o el editor; no inventes uid. Escenas pequeñas: una por entidad (ADR-003 §1).
- La lógica contextual vive en el **receptor** (ADR-003 §4): la caja decide si el objeto en la mano la llena o la condimenta.
- Datos de balance solo en `.tres` (ADR-001). Paridad M0: valores de Unity; D8–D10 son M1.

## Acceptance
- [ ] AC1 Entregar una caja válida emite exactamente 1 `order_completed` para ese puesto, libera la caja y el label pasa a la comanda repuesta → `test_order_stand.gd`.
- [ ] AC2 Una caja inválida emite `delivery_rejected`, suena error y la caja sigue en la mano → `test_order_stand.gd`.
- [ ] AC3 Si el jugador ya estaba dentro de la zona, interactuar entrega (B12) → `test_order_stand.gd`.
- [ ] AC4 `tools/verify.sh` en verde, `check_owns` limpio.

## Plan

## Evidence
