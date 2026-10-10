---
id: PUL-114
title: Aliño de una pulsación y catálogo de 4 comandas
status: in_progress
milestone: M3d
role: gameplay-engineer
deps: [PUL-112, PUL-113]
orca_task: null
unity_sources: []
owns: [godot/core/seasoning_rules.gd, godot/core/order_validator.gd, godot/resources/seasoning_data.gd, godot/resources/seasoning_station_data.gd, godot/resources/box_badge_style.gd, godot/data/seasonings/**, godot/data/recipes/**, godot/data/orders/**, godot/data/config/seasoning_station.tres, godot/data/config/box_badges.tres, godot/data/audio/feedback_map.tres, godot/entities/items/**, godot/entities/stations/seasoning_*, godot/entities/stations/cachelos_bowl.*, godot/entities/stations/sandbox/**, godot/scenes/sandbox/**, godot/ui/tickets/**, godot/tests/**, docs/evidence/PUL-114/**, docs/backlog/PUL-114-alino-una-pulsacion.md]
touches_scenes: [godot/scenes/levels/level_01.tscn, godot/entities/stations/seasoning_station.tscn, godot/entities/stations/seasoning_dispenser.tscn]
---

## Target
Parte «aliño» y «recetas por contenido» de D25 con el contrato de ADR-003 §10.2 y §10.4 (PUL-111), `signals.md` y ADR-006 §4. Features: `condimentacion.md`, `estacion-condimentos.md`, `comandas.md`, `audio-y-fx.md` AC7.

## Change
- `sweet_dressing.tres` / `hot_dressing.tres` (`SWEET_DRESSING`/`HOT_DRESSING` al final de `SeasoningType`, grupo `dressing`), bajas de `salt/oil/paprika/hot_paprika.tres`.
- `SeasoningRules.apply` + `Box.apply_seasoning`; `ALREADY_APPLIED` silencioso; `BOX_NOT_FULL`; sustitución con `seasoning_removed` antes que `seasoned` (cues `unseason` + `season`); `paprika_swap` fuera; `toggle_guard` solo cuenco.
- Estación: 2 dispensadores de aliño + cuenco en x local −1/0/1, mostrador 5,2 m sin cambios; gesto visual `%Gesture` al aplicar.
- Catálogo: 4 recetas/comandas (`a_feira`, `picante`, `con_cachelos`, `bravo_cachelos`; precios y `max_time` de `comandas.md`), `order_catalog.tres` rehecho, bajas de `individual/combo_duo/familiar.tres`, `order_1..6.tres`, `order_catalog_basic.tres`; `kitchen_sandbox` y `test_data_integrity` a `order_catalog.tres`.
- Pegatinas e iconos del ticket para los 2 aliños + cachelos.

## Constraints
- Contrato tal cual; si no encaja, para y pregunta. Datos en `.tres`, `.uid` versionados, sin inventar `uid://`. Las fases (`PhaseData.orders`) son de PUL-115.
- `tools/verify.sh` en verde.

## Acceptance
- [ ] AC1 Los AC de `condimentacion.md` y `estacion-condimentos.md` marcados como D25 → tests
- [ ] AC2 Catálogo de 4 comandas con nombres ≤ 14 caracteres que no se recortan en el ticket → test + captura
- [ ] AC3 `audio-y-fx.md` AC7 → test
- [ ] AC4 Captura de la estación con los 2 dispensadores en `docs/evidence/PUL-114/`
- [ ] AC5 `tools/verify.sh` en verde

## Plan

## Evidence
