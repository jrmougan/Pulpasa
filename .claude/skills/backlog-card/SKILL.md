---
name: backlog-card
description: Cómo crear y mantener fichas de docs/backlog (PUL-xxx) - frontmatter, owns, criterios de aceptación y ciclo de estados. Úsala al crear fichas desde docs/design/features o al actualizar su estado.
---
# Fichas de backlog

- Copia `docs/backlog/_TEMPLATE.md` a `docs/backlog/PUL-<nnn>-<slug>.md` con el siguiente número libre.
- `owns`: globs mínimos que la tarea necesita. Dos fichas de la misma oleada no comparten globs.
- `touches_scenes`: solo los `.tscn` que la tarea modifica. `level_01.tscn` lo toca solo la ficha de integración.
- `deps`: solo dependencias reales. Prefiere oleadas paralelas a cadenas largas.
- Cada AC: Given/When/Then con números, y el test o captura que lo prueba.
- Una ficha cabe en una sesión de worker. Si tiene más de 5 AC o más de ~400 líneas previstas, pártela.
- Estados: `draft` → `ready` (producer) → `in_progress` (worker) → `review` (worker) → `done` (producer tras merge). `blocked` con motivo.
- Actualiza la tabla de `docs/backlog/README.md` al crear o cerrar fichas.
