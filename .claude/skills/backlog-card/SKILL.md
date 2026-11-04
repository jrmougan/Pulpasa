---
name: backlog-card
description: Cómo crear y mantener fichas de docs/backlog (PUL-xxx) - frontmatter, owns, criterios de aceptación y ciclo de estados. Úsala al crear fichas desde docs/design/features o al actualizar su estado.
---
# Fichas de backlog

- Copia `docs/backlog/_TEMPLATE.md` a `docs/backlog/PUL-<nnn>-<slug>.md` con el número máximo existente + 1.
- `owns`: lista inline en una línea, sin comentario detrás. Scripts nuevos con `ruta/x.gd*` (incluye el `.uid`); assets con su `.import`. La ficha y `docs/evidence/<id>/**` ya están permitidos. Si la ficha cambia un comportamiento o retira un símbolo, haz `grep -rl <símbolo> godot/tests` e incluye los tests que lo afirman. Dos fichas de la misma oleada no comparten globs.
- `touches_scenes`: solo los `.tscn` que la tarea modifica. `level_01.tscn` lo toca solo la ficha de integración.
- `deps`: solo dependencias reales. Prefiere oleadas paralelas a cadenas largas.
- Cada AC: Given/When/Then con números, y el test o captura que lo prueba.
- Antes de citar un nodo, malla, slot, ruta, señal o script, compruébalo con grep o abriendo el `.tscn` (slots de `.glb`: `docs/evidence/PUL-181/slots_reales.md`). Un script antiguo citado como herramienta se ejecuta antes. Una ficha que genera otras pega esa comprobación en Evidence.
- Una ficha cabe en una sesión de worker. Si tiene más de 5 AC o más de ~400 líneas previstas, pártela.
- Estados: `draft` → `ready` (producer) → `in_progress` (worker) → `review` (worker) → `done` (producer tras merge). `blocked` con motivo. `superseded (→ PUL-xxx)` si otra ficha la sustituye.
- La tabla de `docs/backlog/README.md` y `docs/design/roadmap.md` las actualiza solo el coordinador al mergear; un worker que crea fichas usa el rango de ids que le den.
