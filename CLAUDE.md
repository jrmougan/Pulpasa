# Pulpasa

Cooperativo de cocina (pulpo á feira en romerías gallegas) en migración de Unity 6 a
**Godot 4.7.2** (3D, cámara ortográfica) y camino de una alpha. Desarrollo hecho por agentes coordinados con Orca.

## Dónde está cada cosa
- `godot/`: proyecto Godot (lo que se desarrolla). GDScript tipado, tests GUT en `godot/tests/`.
- `Assets/`: prototipo Unity. **Solo lectura**: es la especificación de la migración.
- `docs/design/roadmap.md`: hitos y fases de M0. `docs/design/decisions.md`: decisiones cerradas (mandan sobre el GDD). `docs/design/gdd.md`: GDD de trabajo.
- `docs/arch/`: ADRs, `signals.md`, `scene-tree.md`. Contratos: no se cambian sin ADR y gate humano.
- `docs/migration/inventory.md`: mapa Unity → Godot y bugs que no se portan.
- `docs/backlog/PUL-*.md`: fichas de tarea. `docs/evidence/<id>/`: capturas y pruebas.
- GDD original (gallego, solo lectura): `/home/jeromo/vibedora/dev/pulpasa_docs/main.tex`.

## Comandos
- Verificación completa: `tools/verify.sh` (gdformat, gdlint, import, GUT, smoke). `--quick` sin tests.
- Merge de una rama de worker (solo el producer): `tools/merge_gate.sh <rama>`.
- Godot: `godot` en el PATH (4.7.2, binario oficial instalado con Godots).
- MCP `godot` (`.mcp.json`, godot-mcp-runtime 3.8.1): ejecutar, capturar, simular input, leer errores.
  Proyecto: `<raíz>/godot`. Sin pantalla, lanzar Claude con `xvfb-run -a`.
- Orca: usa siempre `orca-ide`, nunca `orca` (en Linux es el lector de pantalla).

## Reglas no negociables
1. Una ficha por worker. Escribe su id en `.claude/current-task` antes de editar: un hook solo
   permite tocar `owns` y `touches_scenes` de esa ficha. Bórralo al terminar. El merge gate
   (`tools/check_owns.py`) rechaza la rama si cambia cualquier otra ruta, también desde Bash: si
   necesitas tocar algo más, pregunta al coordinador.
2. No se termina con `tools/verify.sh` en rojo (un hook de Stop lo impide hasta 3 veces; después, escala).
3. Tipado estático en todo GDScript. Datos de balance en `.tres`, no en código.
4. Lógica en núcleos `RefCounted` de `core/`; autoloads `EventBus`, `GameState`, `OrderService`,
   `RoundManager` como adaptadores finos (ADR-002). Sistemas comunicados por señales de `EventBus`
   (catálogo cerrado en `docs/arch/signals.md`); nada de rutas absolutas de nodos.
   `autoload/`, `core/`, `resources/` y `ui/` sin tipos 3D/2D de mundo.
5. Un `.tscn` tiene un solo dueño por oleada. No inventes `uid://`; versiona los `.uid`.
6. No portes los bugs del prototipo (lista en `docs/migration/inventory.md`).
7. No edites `Assets/`, `godot/addons/` ni `main.tex`.

## Agentes y skills
Roles en `.claude/agents/` (producer, migration-analyst, game-designer, godot-architect,
gameplay-engineer, ui-engineer, asset-pipeline, qa-tester, reviewer).
Skills: `orca-dispatch`, `godot-verify`, `gdscript-conventions`, `unity-to-godot`, `backlog-card`.
