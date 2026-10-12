---
id: PUL-137
title: Enmendar ADR-005 E4 para los botones en fila y la zona de botones con safe area
status: in_progress
milestone: M3e
role: godot-architect
deps: [PUL-136]
orca_task: null
unity_sources: []
owns: [docs/arch/ADR-005-dimension-3d-2d.md, docs/arch/scene-tree.md, docs/evidence/PUL-137/**, docs/backlog/PUL-137-adr-005-e4-botones-en-fila.md]
touches_scenes: []
---

## Target
Decisión D27 (`docs/design/decisions.md`, gate de PUL-136): botones táctiles en fila y zona de botones
más baja. Diseño y medidas: `docs/design/features/controles-tactiles.md` «Contadores del pasaplatos bajo
los botones» y `docs/evidence/PUL-136/README.md`. Contrato afectado: ADR-005 Enmienda D26 E4 (zona
reservada de botones) y la nota «Zonas tapadas de la flecha y de los botones» de E5.

## Change
Enmienda a E4 (y referencia en E5) que fije:
1. Colocación: botón de cambiar a la izquierda del de acción, borde inferior alineado y hueco horizontal
   de 24 px a 1080 (sustituye «sobre el de acción»).
2. Zona de botones: y ≥ alto − 240 px a 1080 (`UiProfile.button_zone_top_px` 600 → 840 en el perfil
   móvil, o expresado desde abajo si es más robusto) y su relación con la safe area derecha (la duda de
   PUL-135): con safe area derecha los botones en fila llegan a ancho − 516 px, así que la zona debe
   descontarla o ensancharse. Decide la forma y deja escrito qué lee la cámara (`GameState.ui_profile`
   y safe area) sin que conozca `TouchControls`.
3. La limitación del caso 09 de E5 pasa a resuelta, con el residuo aceptado (≤ 8 px a 800×370 con el
   activo en z −3,4).
4. Qué ficheros y campos cambian para la ficha de implementación PUL-138 (datos en `.tres`).

## Constraints
- Solo documentación de arquitectura (tus owns). Sin código ni datos.
- Escritorio y Local 2P sin cambios. Sin señales nuevas salvo que sea imprescindible (`signals.md` es
  catálogo cerrado: si hiciera falta, avisa al coordinador).
- Gate humano: el coordinador presenta la enmienda al responsable antes del merge.

## Acceptance
- [ ] AC1 ADR-005 E4/E5 recogen los puntos 1-4 con valores numéricos a 1080 y su escala.
- [ ] AC2 Lista exacta de ficheros/campos a cambiar en PUL-138 en la Evidence de esta ficha.
- [ ] AC3 `tools/verify.sh` en verde y `check_owns` limpio.

## Plan

## Evidence
