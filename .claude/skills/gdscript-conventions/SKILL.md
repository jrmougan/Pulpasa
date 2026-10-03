---
name: gdscript-conventions
description: Convenciones de código GDScript, escenas y tests de Pulpasa en Godot 4.7. Úsala al escribir o revisar cualquier .gd, .tscn o .tres.
---
# Convenciones GDScript de Pulpasa

## Código
- Tipado estático siempre: `var speed: float = 4.0`, `func f(x: int) -> void:`. El proyecto trata
  `untyped_declaration` como error.
- `class_name` en scripts reutilizables y Resources. Archivos y nodos en `snake_case`; clases en `PascalCase`.
- Orden: `class_name`, `extends`, docstring `##`, señales, enums, constantes, `@export`, vars
  públicas, vars `_privadas`, `@onready`, funciones built-in, públicas, privadas.
- Referencias a nodos hijos con `%UniqueName` o `@export var x: Node3D`. Nunca rutas absolutas
  ni `get_tree().get_first_node_in_group` para sistemas.
- Comunicación entre sistemas: señales de `EventBus` (catálogo en `docs/arch/signals.md`).
- Números de balance en Resources `.tres` dentro de `godot/data/`, no en código.
- Aleatoriedad con `RandomNumberGenerator` inyectable (semilla fija en tests).
- Formato lo decide `gdformat`; el hook lo aplica solo.

## Escenas
- Una escena por entidad o pieza de UI, junto a su script: `entities/stations/kitchen_station.{tscn,gd}`.
- `level_*.tscn` solo instancia escenas; no lleva lógica ni overrides grandes.
- `.tscn` y `.tres` se editan con herramientas del MCP o del editor; a mano solo cambios triviales
  de texto. Nunca inventes `uid://` ni ids de ExtResource.
- Se versionan los `.uid`.

## Tests (GUT 9.7)
- `godot/tests/unit/test_<sistema>.gd` para lógica pura; `tests/integration/` para escenas.
- `extends GutTest`; un `func test_<comportamiento>() -> void:` por caso; `add_child_autofree`.
- El nombre del test cita el AC: `test_ac1_order_completed_once_per_delivery`.
