---
id: PUL-192
title: Duplicar el contexto en AGENTS.md y CLAUDE.md con comprobación de sincronía
status: done
milestone: M4
role: godot-architect
deps: []
orca_task: null
unity_sources: []
owns: [AGENTS.md, CLAUDE.md, .claude/skills/orca-dispatch/SKILL.md, tools/verify.sh, tools/check_agents_sync.py]
touches_scenes: []
---

## Target
`AGENTS.md`, `CLAUDE.md`, `.claude/skills/orca-dispatch/SKILL.md`, `tools/check_agents_sync.py` y `tools/verify.sh`.

## Change
`AGENTS.md` es un symlink en git (modo 120000). Con `core.symlinks=false` en Windows se materializa como un texto de
9 bytes que dice «CLAUDE.md», y Codex, que hace las revisiones, puede no recibir las reglas.

Enmendado por decisión del responsable (opción «duplicar», ver `## Evidence`): un `CLAUDE.md` con solo `@AGENTS.md` deja
sin reglas, y sin error, a una sesión de `claude -p` arrancada en `godot/`.

- `AGENTS.md` y `CLAUDE.md` son ficheros normales (modo 100644), idénticos, con el contenido vigente de `CLAUDE.md`, más
  una línea que diga que los hooks de `.claude/` solo corren en Claude Code: fuera de él, la barrera es
  `tools/merge_gate.sh`.
- `tools/check_agents_sync.py` compara ambos normalizando solo los finales de línea, y sale con rc≠0 y un mensaje claro
  si difieren o falta alguno. `tools/verify.sh` lo ejecuta, también con `--quick`.
- Retirar de orca-dispatch el aviso de que `AGENTS.md` no contiene el contexto en Windows y la petición de leer
  `CLAUDE.md` en los specs de agentes no Claude y de revisión.

## Constraints
No se pierde ni se relaja ninguna regla no negociable. El contenido no crece salvo esa línea.

## Acceptance
- [x] AC1 Given la rama, When `git ls-files -s AGENTS.md CLAUDE.md` y `tools/check_agents_sync.py`, Then modo 100644 en ambos y rc=0; con una divergencia inyectada, el script da rc≠0 y `tools/verify.sh --quick` falla, y sin ella pasa → salida en docs/evidence/PUL-192/
- [x] AC2 Given una sesión nueva de Claude Code, desde la raíz y desde `godot/`, When se pregunta por la regla 1 y la línea de los hooks, Then cita ambas desde el contexto cargado → nota en docs/evidence/PUL-192/
- [x] AC3 Given un worker Codex en Windows, desde la raíz y desde `godot/`, When se le pide citar la regla 1 y la línea de los hooks sin indicarle el fichero, Then las cita; si no se puede lanzar, «no verificable» con motivo → nota en docs/evidence/PUL-192/
- [x] AC4 Given el `owns` enmendado, When `tools/check_owns.py pul-192 <merge-base con integración>`, Then rc=0 → salida en docs/evidence/PUL-192/

## Plan
1. Control previo: lanzar Codex en este worktree con el `AGENTS.md` de 9 bytes, para comprobar que hoy no recibe las reglas.
2. `AGENTS.md`: quitar la entrada 120000 del índice (`git rm --cached`) y añadirlo como fichero normal con el contenido de `CLAUDE.md` más una línea sobre los hooks. Con `core.symlinks=false`, un `git add` directo conservaría el modo 120000.
3. `CLAUDE.md`: copia exacta de `AGENTS.md`.
4. `tools/check_agents_sync.py` y su paso en `tools/verify.sh`, de modo que corra también con `--quick`.
5. orca-dispatch: retirar el aviso de Windows y las peticiones de leer `CLAUDE.md` (agentes no Claude y revisión).
6. Comprobar con un diff contra la base que solo crece esa línea. AC1-AC4 en sesiones nuevas, pidiendo también citar la línea nueva, que solo existe en esta rama: la regla 1 sola no distingue, porque en la base está en el propio `CLAUDE.md`.

## Evidence
- **Decisión del responsable, opción «duplicar»**: `AGENTS.md` y `CLAUDE.md` son ficheros normales (100644), idénticos, y una comprobación impide que diverjan. Cierra el bloqueo: `claude -p` arrancado en `godot/` no expandía `@AGENTS.md` y se quedaba sin las 7 reglas, sin error (prueba en la parte histórica de `ac2.md`), y `AGENTS.md` como fichero real sí funcionaba para Codex. El responsable autoriza además `tools/verify.sh` y `tools/check_agents_sync.py` en `owns`.
- **Merge de integración**: `jrmougan/improve-agent-context-docs` en `pul-192` sin conflictos, antes de los cambios de esta enmienda.
- **AC1** (`ac1.txt`): `git ls-files -s` da 100644 en ambos, con el mismo blob, y `check_agents_sync.py` da rc=0. Con una línea inyectada en `CLAUDE.md` sin commitear, el script da rc=1 y `tools/verify.sh --quick` falla; revertida, ambos pasan. También: CRLF contra LF da rc=0 y otro cwd no afecta; un salto final distinto, un fichero ausente y un symlink dan rc=1. Contra el `CLAUDE.md` de integración solo crece la línea de los hooks.
- **AC2** (`ac2.md`): `claude -p` sin herramientas cita la regla 1 y la línea de los hooks desde la raíz y desde `godot/`, en el worktree y en un clon limpio con `core.symlinks=false`. Límite: sesión no interactiva, en Windows.
- **AC3** (`ac3.md`): `codex exec` en solo lectura cita ambos textos desde los mismos cuatro arranques, sin llamadas a comandos. Límite: por CLI, no como worker de Orca, en Windows.
- **AC4** (`ac4.txt`): `tools/check_owns.py pul-192 <merge-base>` da rc=0 con el `owns` nuevo.
- **`tools/verify.sh`** (`verify.txt`): completo en verde, 1378 tests. El paso de sincronía va antes de los de Godot.
- **orca-dispatch**: revisado, sin cambios en esta enmienda. Coherente con ambos ficheros: el spec de revisión no pide leer ninguno porque Codex carga `AGENTS.md`, los workers Claude cargan `CLAUDE.md`, y a antigravity y kimi se les pide leer `AGENTS.md`, que existe como fichero real.
- **No verificable aquí**: sesión interactiva de Claude Code; Linux y macOS (la instrucción de esta tarea excluye WSL); arranque como worker de Orca (no se crean runs); antigravity y kimi (`agy` y `kimi` no están en el PATH).
- **Citas fuera de owns, sin tocar**: `docs/arch/ADR-003-arbol-escenas-composicion.md:27,243`, `.claude/agents/producer.md:8`, `.claude/agents/game-designer.md:9` y `.claude/hooks/guard_ownership.py:74` citan `CLAUDE.md`. Siguen siendo correctas: ahora tiene el texto completo.
