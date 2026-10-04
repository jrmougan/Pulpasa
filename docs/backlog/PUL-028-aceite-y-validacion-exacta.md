---
id: PUL-028
title: Añadir el aceite, la exclusividad de pimentones y la validación exacta
status: done
milestone: M1
role: gameplay-engineer
agent: antigravity · gemini-3.8-flash-high (media)
deps: []
orca_task: task_7e1c51f4721f
unity_sources: []
owns: [godot/resources/seasoning_data.gd, godot/data/seasonings/**, godot/core/order_validator.gd, godot/core/box_contents.gd, godot/entities/items/box.gd, godot/entities/stations/spice_shelf.tscn, godot/tests/unit/test_order_validator.gd, godot/tests/unit/test_data_*.gd, godot/tests/integration/test_box.gd, godot/tests/integration/test_shelves.gd, docs/evidence/PUL-028/**]
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
- [ ] AC1 `condimentacion` AC1–AC4 con tests (exclusividad, idempotencia, caja sin llenar).
- [ ] AC2 Validación exacta: condimento de más → inválida; de menos → inválida; exacta → válida.
- [ ] AC3 La estantería ofrece 4 condimentos y se pueden devolver a su slot.
- [ ] AC4 `tools/verify.sh` en verde, `check_owns` limpio.

## Plan

## Evidence
