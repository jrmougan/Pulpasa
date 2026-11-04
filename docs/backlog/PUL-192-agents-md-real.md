---
id: PUL-192
title: Convertir AGENTS.md en el fichero real de contexto y CLAUDE.md en su import
status: blocked
milestone: M4
role: godot-architect
deps: []
orca_task: null
unity_sources: []
owns: [AGENTS.md, CLAUDE.md, .claude/skills/orca-dispatch/SKILL.md]
touches_scenes: []
---

## Target
`AGENTS.md`, `CLAUDE.md` y `.claude/skills/orca-dispatch/SKILL.md`.

## Change
`AGENTS.md` es un symlink en git (modo 120000). Con `core.symlinks=false` en Windows se materializa como un texto de
9 bytes que dice «CLAUDE.md», y Codex, que hace las revisiones, puede no recibir las reglas.

- `AGENTS.md` pasa a ser un fichero normal con el contenido actual de `CLAUDE.md`, más una línea que diga que los
  hooks de `.claude/` solo corren en Claude Code: fuera de él, la barrera es `tools/merge_gate.sh`.
- `CLAUDE.md` queda solo con `@AGENTS.md`.
- Retirar de orca-dispatch el aviso de que `AGENTS.md` no contiene el contexto en Windows y la petición de leer
  `CLAUDE.md` en los specs de agentes no Claude y de revisión.

## Constraints
No se pierde ni se relaja ninguna regla no negociable. El contenido no crece salvo esa línea.

## Acceptance
- [x] AC1 Given la rama, When `git ls-files -s AGENTS.md`, Then modo 100644 y en Windows el fichero tiene las reglas completas → salida en docs/evidence/PUL-192/
- [ ] AC2 Given una sesión nueva de Claude Code, When se pregunta por la regla 1, Then la cita desde el contexto cargado → nota en docs/evidence/PUL-192/
- [x] AC3 Given un worker Codex en Windows, When se le pide citar la regla 1 sin indicarle el fichero, Then la cita; si no se puede lanzar, «no verificable» con motivo → nota en docs/evidence/PUL-192/

## Plan
1. Control previo: lanzar Codex en este worktree con el `AGENTS.md` de 9 bytes, para comprobar que hoy no recibe las reglas.
2. `AGENTS.md`: quitar la entrada 120000 del índice (`git rm --cached`) y añadirlo como fichero normal con el contenido de `CLAUDE.md` más una línea sobre los hooks. Con `core.symlinks=false`, un `git add` directo conservaría el modo 120000.
3. `CLAUDE.md`: solo `@AGENTS.md`.
4. orca-dispatch: retirar el aviso de Windows y las peticiones de leer `CLAUDE.md` (agentes no Claude y revisión).
5. Comprobar con un diff contra la base que solo crece esa línea. AC1-AC3 en sesiones nuevas, pidiendo también citar la línea nueva, que solo está en el `AGENTS.md` de la rama: la regla 1 sola no distingue, porque en la base está en el propio `CLAUDE.md`. `tools/verify.sh --quick`.

## Evidence
- **Bloqueo**: `status: blocked` hasta que el coordinador elija entre (a) aceptar por decisión explícita que Claude Code solo se arranca desde la raíz, y (b) enmendar la ficha para que las reglas lleguen también desde subdirectorios. AC2 no se marca antes.
- **AC1** (`docs/evidence/PUL-192/ac1.txt`): `git ls-files -s AGENTS.md` da 100644. Con `core.symlinks=false`, borrado y vuelto a materializar desde git, el fichero tiene 3369 bytes y las 7 reglas. Contra el `CLAUDE.md` de la base, `diff` solo muestra la línea nueva.
- **AC2** (`docs/evidence/PUL-192/ac2.md`): sesión nueva `claude -p` sin herramientas integradas; cita la regla 1 y la línea nueva, que solo existe en el `AGENTS.md` de la rama. Límites: sesión no interactiva y solo desde la raíz. **Desde `godot/`, `@AGENTS.md` no se expande y la sesión no recibe las reglas, sin error**; en la base sí las recibía. Decisión pendiente del coordinador. La segunda línea propuesta en `CLAUDE.md` no cambió el resultado en un clon temporal, así que no se aplica. Corregida la explicación del `CLAUDE.md` padre: no se cargó el del checkout del que cuelga el worktree.
  AC2 queda sin marcar hasta esa decisión: la Constraint «No se pierde ni se relaja ninguna regla no negociable» no se cumple desde subdirectorios. Reproducido de nuevo en la revisión; un import dentro del cwd sí se expande, lo que apoya la causa sin demostrarla (`ac2.md`).
- **AC3** (`docs/evidence/PUL-192/ac3.md`): `codex exec` en solo lectura, sin nombrar el fichero. Antes del cambio responde `NO_DISPONIBLE`, lo que reproduce el fallo; después cita la regla 1 y la línea nueva, sin ejecutar comandos. Límite: lanzado por CLI en un worktree, no como worker de Orca; ese arranque queda no verificable en esta tarea, que no crea runs de Orca. Repetido tras la revisión: también cita ambos textos desde `godot/`.
- **orca-dispatch**: retirados el aviso de Windows y las dos peticiones de leer `CLAUDE.md` (revisión y agentes no Claude). Se mantiene la petición de ejecutar `check_owns.py` y `verify.sh`. Añadido tras la revisión: el spec de antigravity y kimi les pide leer `AGENTS.md`, porque su carga automática no está probada.
- **No comprobado**: antigravity y kimi no se han lanzado (`agy` y `kimi` no están en el PATH), así que no consta que carguen `AGENTS.md`. Tampoco se ha probado una sesión interactiva de Claude Code desde `godot/`.
- **Fuera de owns, sin tocar**: `docs/arch/ADR-003-arbol-escenas-composicion.md:27,243`, `.claude/agents/producer.md:8`, `.claude/agents/game-designer.md:9` y `docs/backlog/PUL-190-guard-ownership-utf8.md:25` siguen citando `CLAUDE.md`. Comprobado; en `docs/design` no hay citas. No bloquea: resuelven a través del import, con un salto más para quien abra el fichero como texto. Decide el coordinador; ADR-003 es contrato y requiere gate.
- **`tools/verify.sh --quick`**: `gdformat` 245 ficheros sin cambios, `gdlint` sin problemas, import correcto, `✓ verify OK`. Sin tests ni smoke: la ficha no toca `godot/`.
