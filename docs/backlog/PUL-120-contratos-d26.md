---
id: PUL-120
title: Enmendar los contratos para D26 (verbo de acción, prompt, táctil, cámara móvil)
status: in_progress
milestone: M3e
role: godot-architect
deps: []
orca_task: null
unity_sources: []
owns: [docs/arch/**, docs/backlog/PUL-120-contratos-d26.md]
touches_scenes: []
---

## Target
Contratos de `docs/arch/` afectados por D26 (decidida 2026-10-11 con autorización del responsable; la redacta en
paralelo PUL-119 en `decisions.md`). Contenido de D26: `docs/backlog/PUL-119-d26-lenguaje-acciones-movil.md`,
sección Change. Léela entera.

## Change
Enmendar los ADR, `signals.md` y `scene-tree.md` para que la implementación de D26 tenga contrato:

1. **Verbo de acción (ADR-003 §4, `interaction_contract`).** Método opcional en interactuables
   `get_action_hint(actor: InteractionComponent) -> ActionHint` (o equivalente), con `ActionHint` RefCounted en
   `core/` (verbo `StringName`, estado OK/BLOCKED, motivo `StringName`, progreso opcional). Regla: `interact`
   y `get_action_hint` comparten la misma resolución de rama (helper puro en `core/`), para que no diverjan.
   `can_interact` pasa a ser honesto: true solo si la pulsación tiene efecto o un BLOCKED con motivo útil.
   Decide el conjunto cerrado de verbos y motivos (`core/action_verb.gd` o similar).
2. **Histéresis del detector** (`InteractionScoring`, `player_config.tres`: `hysteresis_margin`).
3. **Señales.** La UI (prompt del botón táctil) solo escucha EventBus: añade al catálogo cerrado la señal del
   hint del objetivo activo por jugador, con primitivos (p. ej. `action_hint_changed(player_index: int, verb:
   StringName, state: int, reason: StringName)`), un único emisor, y una señal de resultado si hace falta
   (`interaction_resolved(player_index, verb, result)`). Decide si el icono sobre el objetivo vive en el mundo
   (componente en `components/`, regla 4: `ui/` sin tipos 3D) y cómo obtiene el hint (local, sin bus).
4. **Entrega solo por zona** (D26.5): `OrderStand` deja de ser objetivo de pulsación; actualizar ADR/árbol.
   Cuenco sin toggle. Cues nuevos y distintos en ADR-006 (`cook_ready`, `burn_warning`, `box_full`,
   `switch`, `rejected` único, `trash` con sonido propio, `already_applied`).
5. **Input táctil (ADR-004).** Solo Individual en táctil; el stick virtual y los botones alimentan las acciones
   existentes `p1_*` por código (`Input.parse_input_event`/`action_press` con fuerza), sin añadir eventos
   táctiles al InputMap; visibles si hay pantalla táctil, ocultos al usar teclado/mando; botón de pausa;
   corte con mantener (`is_action_pressed` + temporizador en núcleo).
6. **Escala y cámara (ADR-005).** `window/stretch` (canvas_items/expand), orientación apaisada, safe area,
   escala de UI por alto y DPI con mínimos en datos; perfil de cámara móvil (zoom ≥ 120 px/m a 1080 de alto,
   seguimiento suave del jugador activo) seleccionable por datos/plataforma sin romper la cámara de PC.
7. **Partición.** Al final de la ficha, propón la partición en fichas de implementación con `owns` disjuntos
   (un `.tscn` y `project.godot` con un solo dueño por oleada), dependencias y orden. El producer la usará.

## Constraints
- Solo `docs/arch/` y esta ficha. Sin código.
- Coherente con ADR-002 (núcleos RefCounted, autoloads finos), reglas de `signals.md` (primitivos, emisor
  único) y la regla 4 de CLAUDE.md.

## Acceptance
- [ ] AC1 ADR-003 enmendado (§ D26): `get_action_hint`, `ActionHint`, verbos/motivos cerrados, `can_interact` honesto
- [ ] AC2 `signals.md` con las señales nuevas (firma, emisor, oyentes) y `event_bus.gd` descrito
- [ ] AC3 ADR-004 (táctil) y ADR-005 (escala, cámara móvil) enmendados; ADR-006 con los cues nuevos
- [ ] AC4 `scene-tree.md` con los nodos nuevos (prompt en mundo, controles táctiles, perfil de cámara)
- [ ] AC5 Partición en fichas con owns disjuntos

## Plan

## Evidence
