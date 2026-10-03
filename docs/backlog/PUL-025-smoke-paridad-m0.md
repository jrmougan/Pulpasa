---
id: PUL-025
title: Pasar el smoke checklist de paridad M0 en builds Linux y Windows
status: ready
milestone: M0
role: qa-tester
deps: [PUL-024, PUL-023]
orca_task: null
unity_sources: [Assets/Scenes/**]
owns: [godot/tests/integration/test_parity_smoke.gd, godot/tests/integration/test_parity_smoke.gd.uid, docs/evidence/PUL-025/**, docs/design/m0-gate.md]
touches_scenes: []
---

## Target
Feature `docs/design/features/paridad-unity.md` (AC1–AC8) y fase 8 de M0. Builds con `tools/export.sh`.

## Change
1. `test_parity_smoke.gd`: AC1–AC6 automatizados sobre el proyecto (menú → nivel → flujo completo →
   20 entregas seguidas → pausa ±0,05 s → fin y Reintentar).
2. AC7: tabla bug del inventario (B1–B18) → test o captura que demuestra que no se reproduce.
3. AC8: `tools/export.sh linux` y `windows`; el build de Linux se ejecuta en headless (y con `xvfb-run`
   y el MCP o capturas si es posible); el de Windows solo se exporta (sin Windows/Wine): márcalo «no
   verificable» con el motivo.
4. `docs/design/m0-gate.md`: guía para la **partida lado a lado con Unity** (puerta humana de M0):
   cómo abrir cada versión, qué comparar (flujo, tiempos, controles, cámara, comandas, fin de partida) y una
   tabla para que el responsable marque cada punto.

## Constraints
- Rol QA: no corrijas código de otras fichas; documenta y escala con `orca ask`.

## Acceptance
- [ ] AC1 `test_parity_smoke.gd` cubre AC1–AC6 de paridad-unity y pasa.
- [ ] AC2 Tabla AC7 completa con enlaces a tests o capturas.
- [ ] AC3 Builds generados; resultado por plataforma en `docs/evidence/PUL-025/report.md`.
- [ ] AC4 `m0-gate.md` listo para la sesión humana. `tools/verify.sh` en verde.

## Plan

## Evidence
