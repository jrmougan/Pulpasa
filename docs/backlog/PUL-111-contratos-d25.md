---
id: PUL-111
title: Enmendar los contratos para D25 (caja única, aliño, cubo de basura)
status: in_progress
milestone: M3d
role: godot-architect
deps: []
orca_task: null
unity_sources: []
owns: [docs/arch/ADR-001-gdscript-convenciones.md, docs/arch/ADR-003-arbol-escenas-composicion.md, docs/arch/ADR-006-audio-feedback.md, docs/arch/scene-tree.md, docs/arch/signals.md, docs/backlog/PUL-111-contratos-d25.md]
touches_scenes: []
---

## Target
Contratos de `docs/arch/` afectados por D25 (aprobada por el responsable el 2026-10-10; la redacta en paralelo PUL-110 en `decisions.md`). Contenido de D25 en `docs/backlog/PUL-110-d25-simplificacion-mecanicas.md`, sección Change: léelo entero.

## Change
Enmienda que fije el contrato que implementarán las fichas de código siguientes (cubo, caja única, aliño):

1. **Caja única** (ADR-003 §9.3 y tablas de `BoxData`, `scene-tree.md` del rack): una sola `BoxData` (`data/boxes/box.tres` o la que decidas), `presses_to_fill` = 6. Decide y documenta: ¿`RecipeData.box` desaparece y `OrderValidator` deja de comparar caja, o queda apuntando a la única caja? Preferencia: quitarlo (menos campos muertos). El rack (`box_shelf`) pasa a un solo spawner. Ticket sin talla (`_show_size` desaparece). ADR-001 si usa `presses_to_fill`/S-M-L como ejemplo.
2. **Aliño** (ADR-003 §8 estación al paso): los `SeasoningData` pasan a ser `sweet_dressing`, `hot_dressing` y `cachelos` (que sigue siendo `SeasoningData` como hoy). Regla: los dos aliños son mutuamente excluyentes (aplicar uno sustituye al otro, generaliza `paprika_swap`); aplicar el que ya está no hace nada; requiere caja llena (`BOX_NOT_FULL`). Dispensador sin toggle de quitar. Decide si `seasoning_station.tres`/`toggle_guard` sigue siendo necesario. Motivos de rechazo que quedan.
3. **Cubo de basura**: escena `entities/stations/trash_bin.tscn` + `trash_bin.gd` (cumple el contrato `interactable` de ADR-003 §4), núcleo `core/trash_rules.gd` (`RefCounted`, `can_trash`), dato `trash_penalty: int = 0` (en qué `.tres`: decide, p. ej. `data/config/trash_bin.tres`). Señal **local** `trashed(item: Node)` con receptor `%Feedback` en `signals.md`; **sin señal nueva en `EventBus`** mientras `trash_penalty` = 0 (si en el futuro > 0, otra enmienda). Dos instancias en `level_01` en `scene-tree.md` (coordenadas aproximadas: cocina x≈−5,8 z≈−3,5; servicio junto al rack; compruébalas contra `docs/design/level-layouts.md` y ajústalas para respetar ≥ 1,5 m a pasaplatos y hueco).
4. **ADR-006**: cue `trash` en el catálogo.
5. **Fases de mecánicas**: cómo expresa la dificultad progresiva qué comandas salen en cada fase (p. ej. catálogo de comandas por fase en el `.tres` de la ronda). Solo el contrato de datos.

## Constraints
- Solo `docs/arch/`. Cada sección enmendada lleva nota «Enmienda D25 (PUL-111, 2026-10-10)».
- No cambies nada fuera de D25. Si D25 deja huecos de contrato, decide lo mínimo y anótalo en Evidence para el gate humano.
- Coherencia con el código actual: cita ficheros reales (`godot/resources/box_data.gd`, `recipe_data.gd`, `order_data.gd`, `core/order_validator.gd`, `core/seasoning_rules.gd`, `entities/stations/seasoning_*.gd`, `ui/tickets/ticket_entry.gd`, `components/interaction_component.gd`).

## Acceptance
- [ ] AC1 ADR-003 describe caja única, aliño y cubo, con tipos y ficheros
- [ ] AC2 `signals.md` tiene `trashed` como señal local y ninguna señal nueva de `EventBus`
- [ ] AC3 `scene-tree.md` refleja rack de una caja, 2 dispensadores de aliño y 2 cubos en `level_01`
- [ ] AC4 ADR-006 tiene el cue `trash`
- [ ] AC5 Contrato de datos de fases de comandas
- [ ] AC6 Lista en Evidence de las decisiones de contrato tomadas, para el gate humano

## Plan

## Evidence
