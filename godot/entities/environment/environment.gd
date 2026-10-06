class_name LevelEnvironment
extends Node3D
## Entorno del nivel (scene-tree.md, Environment): aplica `RenderConfig` al `WorldEnvironment`
## hijo para que la luz y el post-proceso se ajusten desde `data/config/render_config.tres`.

const DEFAULT_CONFIG: RenderConfig = preload("res://data/config/render_config.tres")

@export var config: RenderConfig = DEFAULT_CONFIG

@onready var _world: WorldEnvironment = $WorldEnvironment


func _ready() -> void:
	apply(config)


## Aplica `render_config` al `WorldEnvironment` (también en caliente, p. ej. para capturas).
## Antes de `_ready` solo lo guarda; se aplica al entrar en el árbol.
func apply(render_config: RenderConfig) -> void:
	config = render_config
	if config == null or not is_node_ready():
		return
	_world.environment = config.environment
	_world.camera_attributes = config.make_camera_attributes()
