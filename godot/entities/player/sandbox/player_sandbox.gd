extends Node3D
## Raíz del sandbox del jugador: arranca una ronda como lo hará `level.gd`, para que el
## jugador reciba `round_started` y se mueva. Coger, soltar y dejar en slots lo hacen
## `InteractionDetector` + `InteractionComponent` del jugador.
## PUL-035: añade un segundo personaje y un `CharacterSwitcher` (modo de `GameState`) antes de
## la ronda, para probar `p1_switch` y `%ActiveIndicator` con dos personajes.

const PLAYER_SCENE: PackedScene = preload("res://entities/player/player.tscn")
const SWITCHER_SCENE: PackedScene = preload("res://entities/player/character_switcher.tscn")
const SECOND_POSITION: Vector3 = Vector3(-1.5, 0.0, -0.5)

@export var round_config: RoundConfig
@export var order_catalog: OrderCatalog

@onready var _player: Player = $Player


func _ready() -> void:
	_add_second_character()
	OrderService.setup(order_catalog)
	var slot_ids: Array[int] = []
	RoundManager.start_round(round_config, slot_ids)


func _add_second_character() -> void:
	var second: Player = PLAYER_SCENE.instantiate()
	second.name = &"Player2"
	second.camera = _player.camera
	second.items_root = _player.items_root
	second.position = SECOND_POSITION
	add_child(second)
	var second_control: ControlComponent = second.get_node(^"%Control") as ControlComponent
	second_control.player_index = 2
	var switcher: CharacterSwitcher = SWITCHER_SCENE.instantiate()
	switcher.characters = [_player.get_node(^"%Control") as ControlComponent, second_control]
	add_child(switcher)
