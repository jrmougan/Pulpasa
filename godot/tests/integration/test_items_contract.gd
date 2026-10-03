extends GutTest
## PUL-016 AC4: pulpo, caja y condimento cumplen el contrato `pickable`/`interactable`
## (ADR-003 §4) y están en la capa de física `interactable`.

const INTERACTABLE_LAYER: int = 1 << 2
const SCENES: Array[String] = [
	"res://entities/items/octopus.tscn",
	"res://entities/items/box.tscn",
	"res://entities/items/seasoning.tscn",
]


func _instance(path: String) -> Node:
	var node: Node = (load(path) as PackedScene).instantiate()
	add_child_autofree(node)
	return node


func test_ac4_items_meet_interaction_contract() -> void:
	for path: String in SCENES:
		var root: Node = _instance(path)
		assert_true(root.is_in_group(InteractionContract.GROUP_PICKABLE), path)
		assert_true(root.is_in_group(InteractionContract.GROUP_INTERACTABLE), path)
		assert_eq(InteractionContract.scan_tree(root), [] as Array[String], path)
		assert_true(PickableContract.is_valid_pickable(root), path)


func test_ac4_items_are_bodies_on_interactable_layer_with_highlight() -> void:
	for path: String in SCENES:
		var root: Node = _instance(path)
		assert_true(root is RigidBody3D, path)
		assert_true((root as RigidBody3D).collision_layer & INTERACTABLE_LAYER != 0, path)
		assert_true(root.get_node("%Highlightable") is Highlightable, path)
		assert_true(root.get_node("%AnchorPoint") is Marker3D, path)


func test_ac4_box_and_octopus_have_world_progress_bars() -> void:
	assert_true(_instance(SCENES[0]).get_node("%AmountBar") is WorldProgressBar)
	assert_true(_instance(SCENES[1]).get_node("%FillBar") is WorldProgressBar)
