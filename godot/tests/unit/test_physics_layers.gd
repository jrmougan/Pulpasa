extends GutTest
## PUL-011 AC4: nombres de capa de física 3D (ADR-003 §5).
## PUL-011 AC5: la capa común no referencia tipos 3D/2D ni clases específicas (ADR-003 §0).

const LAYERS: Dictionary = {
	1: "world",
	2: "player",
	3: "interactable",
	4: "held",
	5: "delivery_zone",
}

const SCRIPTS: Array[String] = [
	"res://components/control_component.gd",
	"res://components/holder.gd",
	"res://core/player_input.gd",
	"res://resources/player_config.gd",
	"res://resources/input_config.gd",
]
const FORBIDDEN: String = (
	"\\b(Node3D|Node2D|Vector3|Transform3D|Transform2D|Area3D|Area2D|Marker3D|Marker2D"
	+ "|CharacterBody3D|CharacterBody2D|RigidBody3D|RigidBody2D|StaticBody3D|StaticBody2D"
	+ "|Player|HoldComponent|Box)\\b"
)


func test_ac4_layer_names_exist_with_their_number() -> void:
	for number: int in LAYERS:
		var setting: String = "layer_names/3d_physics/layer_%d" % number
		assert_true(ProjectSettings.has_setting(setting), setting)
		assert_eq(ProjectSettings.get_setting(setting), LAYERS[number], setting)


func test_ac5_scripts_load_without_scenes() -> void:
	for path: String in SCRIPTS:
		assert_not_null(load(path) as GDScript, path)


func test_ac5_no_world_types_in_sources() -> void:
	var regex: RegEx = RegEx.create_from_string(FORBIDDEN)
	for path: String in SCRIPTS:
		var text: String = FileAccess.get_file_as_string(path)
		assert_ne(text, "", path)
		var found: RegExMatch = regex.search(text)
		assert_null(found, "%s referencia %s" % [path, found.get_string() if found else ""])
