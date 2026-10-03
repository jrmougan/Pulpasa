---
id: PUL-025
title: Pasar el smoke checklist de paridad M0 en builds Linux y Windows
status: done
milestone: M0
role: qa-tester
deps: [PUL-024, PUL-023, PUL-026]
orca_task: task_ef1e616e0937
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
- [x] AC1 `test_parity_smoke.gd` cubre AC1–AC6 de paridad-unity y pasa.
- [x] AC2 Tabla AC7 completa con enlaces a tests o capturas.
- [x] AC3 Builds generados; resultado por plataforma en `docs/evidence/PUL-025/report.md`.
- [x] AC4 `m0-gate.md` listo para la sesión humana. `tools/verify.sh` en verde.

## Plan
1. Smoke AC1–AC6 sobre el proyecto real (menú → `ui_accept` → `level_01`) con el patrón de pulsaciones
   de `test_kitchen_flow.gd` y el detector congelado.
2. AC7: mapear B1–B18 a los tests existentes (más comprobaciones estáticas) en el informe.
3. AC8: `tools/export.sh linux|windows`; build Linux en headless y en ventana bajo `xvfb-run`,
   movido con `xdotool` y capturado con `import`. Windows: solo export.
4. `docs/design/m0-gate.md` para la sesión humana.

## Evidence
Informe completo: `docs/evidence/PUL-025/report.md`.
- `tools/verify.sh`: ✓ verify OK (383 tests; `test_parity_smoke.gd` 6/6).
- AC1–AC6 pasan en el proyecto; AC1, AC2, AC5 (a ojo) y AC6 (partida real de 180 s → Reintentar)
  también en el build de Linux con capturas.
- AC7: B1–B18 con test o comprobación estática; ninguno se reproduce.
- AC8: Linux exporta y pasa; Windows exporta (106 MB) pero es **no verificable** (sin Windows/Wine).
- Sin fallos en código de otras fichas: nada escalado.
