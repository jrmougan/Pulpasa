---
id: PUL-028
title: Añadir el aceite, la exclusividad de pimentones y la validación exacta
status: review
milestone: M1
role: gameplay-engineer
agent: antigravity · gemini-3.8-flash-high (media)
deps: []
orca_task: null
unity_sources: []
owns: [godot/resources/seasoning_data.gd, godot/data/seasonings/**, godot/core/order_validator.gd, godot/core/box_contents.gd, godot/entities/items/box.gd, godot/entities/stations/spice_shelf.tscn, godot/tests/unit/test_order_validator.gd, godot/tests/unit/test_data_*.gd, godot/tests/integration/test_box.gd, godot/tests/integration/test_shelves.gd, godot/tests/integration/test_kitchen_flow.gd, godot/tests/integration/test_parity_smoke.gd, docs/evidence/PUL-028/**]
touches_scenes: [godot/entities/stations/spice_shelf.tscn]
---

## Target
M1, feature `condimentacion.md` (AC1–AC4) y `entrega-y-puntuacion.md` AC3 (coincidencia exacta). D4.

## Change
1. `SeasoningData`: tipo ACEITE y grupo de exclusividad (pimentón dulce y picante son excluyentes).
   `data/seasonings/oil.tres` (color e icono: usa el de PUL-031 si ya existe; si no, deja el campo vacío).
2. Caja: rechaza un pimentón si ya tiene el otro; idempotente con el mismo condimento.
3. `OrderValidator`: **igualdad exacta** del conjunto de condimentos (adiós a la regla ⊆ de M0, B15/D17).
4. Estantería de especias con un cuarto slot para el aceite.

## Constraints
- Desde M1 manda el diseño (`docs/design/gdd.md`, `features/`, `decisions.md`), no Unity (D17). Donde una feature cite «paridad», prevalecen D8–D10 y D17.
- Capa común (ADR-003 §0) y núcleos `RefCounted` con dependencias inyectadas (ADR-002). Datos de balance en `.tres`.
- Cambios de firma de señales: solo si la ficha lo dice; actualiza `docs/arch/signals.md` en ese caso.
- Antes de cerrar: `tools/verify.sh` en verde y `tools/check_owns.py <tu-rama> jrmougan/agentica-migracion-godot-alpha` limpio (los hooks de Claude Code no corren en tu agente: el merge gate sí).

## Acceptance
- [x] AC1 `condimentacion` AC1–AC4 con tests (exclusividad, idempotencia, caja sin llenar).
- [x] AC2 Validación exacta: condimento de más → inválida; de menos → inválida; exacta → válida.
- [x] AC3 La estantería ofrece 4 condimentos y se pueden devolver a su slot.
- [x] AC4 `tools/verify.sh` en verde, `check_owns` limpio.

## Plan
1. Extender `SeasoningData` con tipo OIL (y alias ACEITE = 3), propiedad `exclusivity_group: StringName` y campo `icon: Texture2D`.
2. Asignar grupo de exclusividad `"paprika"` a `paprika.tres` y `hot_paprika.tres`; crear recurso `oil.tres`.
3. Implementar en `box.gd` la exclusividad mutua por grupo y la idempotencia al re-aplicar condimentos, manteniendo el rechazo en cajas no llenas.
4. Actualizar `OrderValidator.matches` para requerir igualdad exacta entre los conjuntos de condimentos pedidos y entregados (adiós a B15).
5. Añadir `OilSlot` a `spice_shelf.tscn` y redistribuir los 4 slots de forma equidistante en la mesa.
6. Adaptar y expandir tests unitarios y de integración para cubrir todas las nuevas reglas de AC1, AC2 y AC3.
7. Con autorización del coordinador vía Orca, incorporar a `owns` y adaptar los tests de integración preexistentes `test_kitchen_flow.gd` (regla de validación exacta) y `test_parity_smoke.gd` (SPICE_JARS = 4).
8. Generar captura gráfica de la estantería con 4 slots y verificar verde en `tools/verify.sh` y `tools/check_owns.py`.

## Evidence
- Informe detallado: `docs/evidence/PUL-028/README.md`.
- Captura visual de la estantería con 4 slots: `docs/evidence/PUL-028/ac3-spice-shelf-4-slots.png`.
- Tests GUT: 393 tests pasando, 0 fallos (cobertura unitaria e integración de AC1, AC2 y AC3).
- Smoke run: 120 frames sin errores.
- `tools/verify.sh`: ✓ verify OK.
- `tools/check_owns.py`: limpio (todas las rutas dentro de `owns`).

