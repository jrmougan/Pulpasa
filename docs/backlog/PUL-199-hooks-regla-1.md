---
id: PUL-199
title: Hacer que el hook de ownership falle cerrado y actúe desde subcarpetas
status: ready
milestone: M4
role: godot-architect
deps: []
orca_task: null
unity_sources: []
owns: [.claude/settings.json, .claude/hooks/guard_ownership.py, .claude/hooks/run_guard.sh]
touches_scenes: []
---

## Target
Entradas de hooks de `.claude/settings.json` y `guard_ownership.py`.

## Change
La regla 1 tiene dos huecos, medidos en PUL-190 y en la revisión de PUL-192:
- **Fallo abierto antes del `try`:** intérprete ausente (rc=127), hook que no compila (rc=1), `PYTHONIOENCODING` inválida (rc=1) y `PYTHONUTF8=9` (rc=1) dejan pasar la edición. Un envoltorio convierte todo rc distinto de 0 y 2 en 2, y falla cerrado sin intérprete. `except Exception` tampoco cubre `BaseException`.
- **Sesión arrancada en `godot/`:** una sola prueba indica que los hooks no actuaron. Hay que confirmarlo y averiguar la causa; si es `$CLAUDE_PROJECT_DIR` o la resolución de `settings.json`, corregirlo. Si no se puede corregir desde el repo, documentar el límite y qué lo cubre.

## Constraints
Funciona en Windows (Git Bash), Linux y macOS. No toca `permissions`. No relaja el bloqueo actual. Si el entorno impide editar los hooks de `settings.json`, status=blocked y explícalo.

## Acceptance
- [ ] AC1 Given esos cuatro casos, When se ejecuta el comando real del hook, Then rc=2 y la edición se bloquea → docs/evidence/PUL-199/
- [ ] AC2 Given una ruta dentro de owns y otra fuera, When se ejecuta el comando real, Then rc=0 y rc=2 → docs/evidence/PUL-199/
- [ ] AC3 Given una sesión `claude -p` real arrancada en la raíz y en `godot/` con `current-task`, When intenta editar fuera de owns, Then se bloquea, o queda documentado por qué no y qué lo cubre → docs/evidence/PUL-199/

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker: salida de verify.sh, capturas, notas.)
