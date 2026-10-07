---
id: PUL-093
title: Enmendar los contratos para la estación sin bandeja y los pasaplatos marcados
status: ready
milestone: M3c
role: godot-architect
deps: []
orca_task: null
unity_sources: []
owns: [docs/arch/scene-tree.md, docs/arch/ADR-003-arbol-escenas-composicion.md, docs/arch/signals.md, docs/arch/README.md, docs/evidence/PUL-093/**, docs/backlog/PUL-093-contratos-estacion-al-paso.md]
touches_scenes: []
---

## Target
Contratos afectados por D23: `scene-tree.md` (`seasoning_station.tscn` sin `Tray`; dispensadores y cuenco actúan sobre la caja **en la mano** del actor; 6 `PassSlot` en el nivel con su marca visual; zona de entrega con indicador en `order_stand.tscn`; hueco de la barra a x≈3,2), ADR-003 §8 y, si hace falta, `signals.md`. Pendiente del QA de M3b: `Bulbs` y `Vignette` no aparecen en `scene-tree.md`.

## Change
Enmienda ADR-003 (sección nueva fechada) y `scene-tree.md` para D23: nodos que desaparecen o se añaden, quién es objetivo con qué en la mano (dispensador: caja llena en mano y lado de servicio; cuenco: cachelos cocidos para reponer y caja en mano para alternar), nuevos campos de `BoxData` (`short_label: String`, `icon: Texture2D`), recurso de colores de puesto (`StandPalette`, `data/config/stand_palette.tres`, `slot_id` 1–4 → color) y el indicador de la zona de entrega. Confirma que **no hace falta ninguna señal nueva** (`seasoned`/`seasoning_removed`/`order_*` existentes) o justifícala. Añade `Bulbs` y `Vignette` al árbol del nivel.

## Constraints
Solo documentación. El responsable aprobó el diseño (D23); el producer revisa la enmienda antes de la oleada 2. InputMap sin cambios (tecla única).

## Acceptance
- [ ] AC1 ADR-003 y `scene-tree.md` describen la estación sin `Tray`, los 6 `PassSlot`, el indicador de entrega y el hueco nuevo
- [ ] AC2 Contratos de datos `BoxData.short_label/icon` y `StandPalette` definidos con tipos
- [ ] AC3 `signals.md` sin cambios o con la señal justificada; `Bulbs`/`Vignette` añadidos

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
