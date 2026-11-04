---
id: PUL-193
title: Compartir el parser de fichas entre hook y merge gate y limpiar la plantilla
status: ready
milestone: M4
role: godot-architect
deps: [PUL-190]
orca_task: null
unity_sources: []
owns: [.claude/hooks/guard_ownership.py, tools/check_owns.py, tools/card_frontmatter.py, docs/backlog/_TEMPLATE.md, docs/backlog/README.md]
touches_scenes: []
---

## Target
`guard_ownership.py`, `check_owns.py`, módulo nuevo `tools/card_frontmatter.py`, `_TEMPLATE.md` y la cabecera de `docs/backlog/README.md`.

## Change
- Hoy hay dos parsers: el hook entiende listas inline y en bloque, y `check_owns.py` solo inline. Una ficha con `owns` en bloque pasa el hook y la rechaza el merge gate. Ambos pasan a usar un único parser.
- `owns: []   # comentario` no casa con la regex: la lista queda vacía, el hook bloquea todo y `check_owns` rechaza la rama. El parser tolera el comentario y lo que viene tras él no cuenta como glob.
- `_TEMPLATE.md`: sin comentarios tras `owns` y `touches_scenes`; `unity_sources` opcional, ya no «de especificación» (D17); estados con `superseded`; hito remitiendo a `docs/design/roadmap.md`.
- `docs/backlog/README.md` (líneas de cabecera): quitar «tal cual», «Ownership» y `worker-start --spec`, que contradicen orca-dispatch. La tabla de fichas no se toca.

## Constraints
El hook mantiene lo de PUL-190: lee UTF-8 y bloquea ante fallo, también si no puede importar el módulo. Debe funcionar desde cualquier directorio de trabajo. Las 180+ fichas existentes dan el mismo resultado que hoy. `check_owns` sigue saliendo con 0 en ramas sin `pul-<n>`.

## Acceptance
- [ ] AC1 Given una ficha con `owns` inline, en bloque y con comentario final, When hook y `check_owns` la leen, Then obtienen la misma lista → salida en docs/evidence/PUL-193/
- [ ] AC2 Given todas las fichas de docs/backlog, When se comparan los `owns` del parser nuevo con los del anterior, Then no hay diferencias → salida en docs/evidence/PUL-193/
- [ ] AC3 Given una copia de `_TEMPLATE.md` con `owns` relleno, When se ejecuta el hook sobre una ruta incluida, Then rc=0 → salida en docs/evidence/PUL-193/
- [ ] AC4 Given el módulo ausente, When se ejecuta el hook con `current-task`, Then rc=2 → salida en docs/evidence/PUL-193/

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker: salida de verify.sh, capturas, notas.)
