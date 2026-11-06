# Pulpasa

Cooperativo de cocina (pulpo á feira en romerías gallegas) en **Godot 4.7.2** (3D, cámara ortográfica),
camino de una alpha. Desarrollo hecho por agentes coordinados con Orca. La migración desde Unity cerró en M0; fase actual en `docs/design/roadmap.md`.

## Dónde está cada cosa
- `godot/`: proyecto Godot (lo que se desarrolla). GDScript tipado, tests GUT en `godot/tests/`.
- `Assets/`: prototipo Unity. **Solo lectura** y solo referencia (D17): manda el diseño.
- `docs/design/`: `roadmap.md` (hitos), `decisions.md` (decisiones cerradas, mandan sobre el GDD; D25-D28 cambian reglas, UX y estética), `gdd.md` (GDD de trabajo), `features/` (specs con AC).
- `docs/arch/`: ADRs, `signals.md`, `scene-tree.md`. Contratos: no se cambian sin ADR y gate humano.
- `docs/art/`: `art-bible.md` (v3, D28), `pipeline.md`. `art/blender/`: fuentes (D20). `docs/assets/licenses.md`: registro (D16).
- `docs/backlog/PUL-*.md`: fichas de tarea. `docs/evidence/<id>/`: capturas y pruebas.
- GDD original (gallego, solo lectura, fuera del repo): `/home/jeromo/vibedora/dev/pulpasa_docs/main.tex`. Si no está en tu máquina, usa `gdd.md`.

## Comandos
- Toolchain: `mise install` en la raíz. Se trabaja en Linux, macOS y Windows; las versiones solo cambian por commit en `mise.toml`.
- Verificación completa: `tools/verify.sh` (sincronía de AGENTS.md y CLAUDE.md, gdformat, gdlint, import, compilación de scripts, GUT, smoke). `--quick` sin tests ni smoke.
- Merge de una rama de worker (solo el producer): `tools/merge_gate.sh <rama>`.
- Godot: `godot` en el PATH (4.7.2, binario oficial; con el gestor de cada sistema, p. ej. Godots o
  Scoop con `hold`). No lo gestiona mise.
- MCP `godot` (sin diálogos de confirmación, por decisión del responsable): skill `godot-verify`. MCP `blender`: `docs/art/pipeline.md`.
- Orca (único orquestador, T6): `orca-ide` en Linux, nunca `orca` (es el lector de pantalla); `orca` en Windows.

## Reglas no negociables
Los hooks de `.claude/` solo corren en Claude Code: fuera de él, la barrera es `tools/merge_gate.sh`.
1. Una ficha por worker. Escribe su id en `.claude/current-task` antes de editar: un hook solo
   permite tocar `owns` y `touches_scenes` de esa ficha. Bórralo al terminar. El merge gate
   (`tools/check_owns.py`) rechaza la rama si cambia cualquier otra ruta, también desde Bash: si
   necesitas tocar algo más, pregunta al coordinador.
   Arranca la sesión en la raíz del repo: desde una subcarpeta, o en un subagente con worktree
   aislado, el hook no actúa y solo queda el merge gate.
2. No se termina con `tools/verify.sh` en rojo: pásalo antes del commit final. El hook de Stop solo cubre
   cambios sin commitear (lo impide hasta 3 veces; después, escala); la barrera final es el merge gate.
3. Tipado estático en todo GDScript. Datos de balance en `.tres`, no en código.
4. Lógica en núcleos `RefCounted` de `core/`; autoloads como adaptadores finos (ADR-002). Sistemas comunicados por señales de `EventBus`
   (catálogo cerrado en `docs/arch/signals.md`); nada de rutas absolutas de nodos.
   `autoload/`, `core/`, `resources/` y `ui/` de pantalla sin tipos 3D/2D de mundo.
5. Un `.tscn` tiene un solo dueño por oleada. No inventes `uid://`; versiona los `.uid`.
6. No portes los bugs del prototipo (lista en `docs/migration/inventory.md`).
7. No edites `Assets/`, `godot/addons/` ni `main.tex`.

## Agentes y skills
Roles: `.claude/agents/<rol>.md`. Skills: `.claude/skills/<nombre>/SKILL.md`. Un worker de Orca lee su rol como texto: `tools` y `model` del frontmatter solo rigen en subagentes.
