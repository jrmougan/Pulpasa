---
id: PUL-176
title: Pasar el smoke de la alpha en los builds de Windows y Linux
status: draft
milestone: M4
role: qa-tester
deps: [PUL-166, PUL-170, PUL-173, PUL-175]
orca_task: null
unity_sources: []
owns: [docs/evidence/PUL-176/**, docs/backlog/PUL-176-smoke-de-builds-y-rendimiento.md]
touches_scenes: []
---

## Target
Must 1 y Must 2 de la alpha sobre **builds exportados** (no el editor): checklist de
`features/paridad-unity.md` AC1–AC6 sin la comparación con Unity (D17), con las reglas vigentes (D25, D26),
y objetivo de rendimiento de D22 (60 fps a 1080p en la RTX 3090). Builds de `tools/export.sh` (PUL-170).

## Change
Ejecutar el checklist en Linux y en Windows (en la máquina que decida el responsable, pregunta P3), medir
fps y tiempo de arranque, y registrar cualquier fallo como ficha nueva o escalado.

## Constraints
- Solo evidencia: no se arregla nada aquí. Los fallos se describen con pasos para reproducir.
- Si no hay máquina Windows, Windows queda `blocked` con el motivo y Linux se cierra igual.

## Acceptance
- [ ] AC1 Linux: arranque al menú ≤ 5 s, 0 `ERROR`, partida completa Individual y Local 2P hasta resultados,
  pausa/reanudar y reintentar (log + capturas).
- [ ] AC2 Linux: 20 entregas seguidas sin puestos vacíos y +1 comanda exacta por entrega (Must 2), con el bot o a mano.
- [ ] AC3 Windows: los mismos puntos de AC1 en el build `.zip` de PUL-170.
- [ ] AC4 Rendimiento: fps medio y p1 a 1920×1080 en fase 3 con 4 tickets en cada plataforma probada (≥ 60 medio en la RTX 3090).
- [ ] AC5 `docs/evidence/PUL-176/README.md` con la tabla checklist × plataforma; `tools/verify.sh --quick` en verde; `check_owns` limpio.

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
