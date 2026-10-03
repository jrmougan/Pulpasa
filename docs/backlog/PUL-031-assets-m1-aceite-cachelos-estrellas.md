---
id: PUL-031
title: Incorporar iconos y placeholders de aceite, cachelos y estrellas
status: ready
milestone: M1
role: asset-pipeline
agent: kimi (fácil)
deps: []
orca_task: null
unity_sources: []
owns: [godot/assets/textures/icons/**, godot/assets/models/placeholders/**, godot/assets/materials/**, godot/assets/CREDITS.md, docs/assets/licenses-pul-031.md, godot/tests/unit/test_assets_m1.gd, docs/evidence/PUL-031/**]
touches_scenes: []
---

## Target
Assets que necesitan PUL-028/029/030, con la regla D16 (solo licencias confirmadas: CC0, CC BY, OFL, MIT).

## Change
1. Iconos SVG: aceite (botella), cachelos (patata), estrella llena y vacía. Preferible game-icons.net (CC BY 3.0,
   con autor) o CC0.
2. Placeholders 3D con primitivas: botella de aceite, cachelos crudos y cocidos (color distinto), cachelera
   (caja o saco), con frente en −Z y dimensiones razonables junto a la olla de PUL-008.
3. Atribuciones en `godot/assets/CREDITS.md` y tabla en `docs/assets/licenses-pul-031.md` (el producer la consolida).

## Constraints
- Desde M1 manda el diseño (`docs/design/gdd.md`, `features/`, `decisions.md`), no Unity (D17). Donde una feature cite «paridad», prevalecen D8–D10 y D17.
- Capa común (ADR-003 §0) y núcleos `RefCounted` con dependencias inyectadas (ADR-002). Datos de balance en `.tres`.
- Cambios de firma de señales: solo si la ficha lo dice; actualiza `docs/arch/signals.md` en ese caso.
- Antes de cerrar: `tools/verify.sh` en verde y `tools/check_owns.py <tu-rama> jrmougan/agentica-migracion-godot-alpha` limpio (los hooks de Claude Code no corren en tu agente: el merge gate sí).
- Nada de assets de la tabla «Pendientes» de `licenses.md` ni de Pandazole.

## Acceptance
- [ ] AC1 Los 4 iconos y los 4 placeholders cargan sin errores → `test_assets_m1.gd`.
- [ ] AC2 Cada asset nuevo con URL, licencia y autor en `licenses-pul-031.md` y `CREDITS.md`.
- [ ] AC3 Captura de los placeholders en `docs/evidence/PUL-031/`. `tools/verify.sh` verde, `check_owns` limpio.

## Plan

## Evidence
