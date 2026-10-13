---
id: PUL-176
title: Exportar los builds finales de la alpha y pasar el smoke en Windows y Linux
status: draft
milestone: M4
role: qa-tester
deps: [PUL-166, PUL-170, PUL-173, PUL-175, PUL-177]
orca_task: null
unity_sources: []
owns: [docs/evidence/PUL-176/**, docs/backlog/PUL-176-builds-finales-y-smoke.md]
touches_scenes: []
---

## Target
Must 1 y Must 2 de la alpha sobre los **builds candidatos exactos** que irán al playtest (G4) y a la publicación
(PUL-179): checklist de `features/paridad-unity.md` AC1–AC6 sin la comparación con Unity (D17), con las reglas
vigentes (D25, D26), y rendimiento de D22 (60 fps a 1080p en la RTX 3090). Tubería y versión de PUL-170.

## Change
1. Sobre el commit de la rama de integración tras mergear todo M4 (incluidos los arreglos de PUL-177), con el
   árbol limpio, exportar Linux y Windows con `tools/export.sh` y guardar `MANIFEST.txt` (commit, versión, SHA-256).
2. Ejecutar el checklist sobre esos `.zip` en Linux y en Windows (máquina que decida el responsable, P3) y medir
   fps y arranque.
3. Si después cambia cualquier fichero de `godot/` o `tools/export.sh` (p. ej. arreglos del playtest), esta ficha
   **se repite entera** con un manifiesto nuevo antes de PUL-179.

## Constraints
- Solo evidencia: no se arregla nada aquí; los fallos se describen con pasos para reproducir. Los `.zip` no se
  versionan (`build/` está en `.gitignore`); se conservan para G4 y PUL-179 y su identidad es el SHA-256.
- Si no hay máquina Windows, Windows queda `blocked` con el motivo y Linux se cierra igual.

## Acceptance
- [ ] AC1 Given el commit final con el árbol limpio, When se ejecuta `tools/export.sh all`, Then `MANIFEST.txt` registra ese commit, la versión
  de G0 y el SHA-256 de cada `.zip`, y `git log <commit>..HEAD -- godot tools/export.sh` está vacío al cerrar la ficha → manifiesto y salida en `docs/evidence/PUL-176/`.
- [ ] AC2 Given el `.zip` de Linux del manifiesto, When se arranca y se juega una partida de 300 s en Individual y otra en Local 2P con pausa,
  reanudar y reintentar, Then llega al menú en ≤ 5 s, completa ambas hasta resultados y hay 0 líneas `ERROR` → log + ≥ 6 capturas.
- [ ] AC3 Given el mismo build Linux, When se hacen 20 entregas seguidas (bot o a mano), Then 0 puestos vacíos y +1 comanda exacta por entrega (Must 2) → log o vídeo en la evidencia.
- [ ] AC4 Given el `.zip` de Windows del manifiesto, When se repite AC2, Then se cumplen los mismos umbrales (o la ficha queda `blocked` con motivo) → log + capturas.
- [ ] AC5 Given cada plataforma probada, When se juega la fase 3 con 4 tickets a 1920×1080 durante 60 s, Then se registran fps medio y p1 y el medio es ≥ 60 en la RTX 3090; Given la rama, When se ejecutan `tools/verify.sh --quick` y `python3 tools/check_owns.py <rama>`, Then salen con 0 → tabla y salida en la evidencia.

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
