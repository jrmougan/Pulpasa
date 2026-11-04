---
name: gdscript-conventions
description: Convenciones de código GDScript, escenas y tests de Pulpasa en Godot 4.7. Úsala al escribir o revisar cualquier .gd, .tscn o .tres.
---
# Convenciones GDScript de Pulpasa

La norma completa es `docs/arch/ADR-001-gdscript-convenciones.md` (manda sobre esta skill).
Arquitectura de núcleos y autoloads: `docs/arch/ADR-002-eventbus-autoloads.md`.

Mapa de carpetas: ADR-001; lo no listado, mira `godot/`.

## Código
- Tipado estático siempre: `var speed: float = 4.0`, `func f(x: int) -> void:`. El proyecto trata
  `untyped_declaration` como error.
- `class_name` en scripts reutilizables y Resources, salvo autoloads (los tests los cargan con `preload(...).new()`). Archivos en `snake_case`; nodos y clases en `PascalCase`.
- Orden de declaraciones: lo impone `gdlint` (ADR-001). Funciones: built-in, públicas, privadas (gdlint no lo comprueba).
- Señales en participio (`order_completed`). `is_instance_valid()` antes de usar nodos que puedan haberse liberado.
- Referencias a nodos hijos con `%UniqueName` o `@export var x: Node3D`. Nunca rutas absolutas
  ni `get_tree().get_first_node_in_group` para sistemas.
- Comunicación entre sistemas: señales de `EventBus` (catálogo en `docs/arch/signals.md`). Hechos por señal, órdenes por método del autoload dueño.
- Tests de reglas: instancia los núcleos de `core/` con dependencias inyectadas. Para un adaptador, `preload("res://autoload/x.gd").new()`; nunca el singleton global.
- Números de balance en Resources `.tres` dentro de `godot/data/`, no en código.
- Aleatoriedad con `RandomNumberGenerator` inyectable (semilla fija en tests).
- Formato lo decide `gdformat`; el hook lo aplica solo.

## Escenas
- Una escena por entidad o pieza de UI, junto a su script: `entities/stations/cachelos_bowl.{tscn,gd}`.
- `level_*.tscn` solo instancia escenas; no lleva lógica ni overrides grandes.
- `.tscn` y `.tres` se editan con el editor o el MCP si funcionan. Un worker headless no tiene editor, y las
  operaciones headless del MCP (`add_node`, `set_node_properties`, `get_scene_tree`, `validate`...) fallan hoy con
  `untyped_declaration=2` (godot-mcp-runtime#73); el runtime (`run_project`, `take_screenshot`, `simulate_input`) sí
  funciona. Entonces edita el texto, según ADR-001 Enmienda 1:
  - Conserva `uid` y `unique_id`. Nunca inventes `uid://`: cópialo del `.uid` o `.import` del recurso, u omítelo.
  - No reutilices ni hagas colisionar ids de `ExtResource` y `SubResource`.
  - Comprueba que la escena carga en un test, en el smoke o con `run_project` y `scene`.
- Se versionan los `.uid`.

## Tests (GUT 9.7)
- `godot/tests/unit/test_<sistema>.gd` para lógica pura; `tests/integration/` para escenas.
- `extends GutTest`; un `func test_<comportamiento>() -> void:` por caso; `add_child_autofree`.
- El nombre del test cita el AC: `test_ac1_order_completed_once_per_delivery`.
- Un test con `level_01` real fija `rng_seed` en su `RoundConfig` (con 0 hay `randomize()`) y no compara tiempos de reloj con tolerancia ajustada. Un rojo que desaparece al repetir se anota en Evidence con test y valor, y se abre ficha.
- El esperado es el literal del AC o de los datos, nunca la constante del código que se prueba.
