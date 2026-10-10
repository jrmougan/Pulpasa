extends GutTest
## PUL-112: regla del cubo de basura (D25, ADR-003 §10.3; cubo-basura T2, T5). Núcleo y datos.

const DATA: TrashBinData = preload("res://data/config/trash_bin.tres")


func _node(pickable: bool) -> Node:
	var node: Node = autofree(Node.new())
	if pickable:
		node.add_to_group(&"pickable")
	return node


func test_null_cannot_be_trashed() -> void:
	assert_false(TrashRules.can_trash(null))


func test_pickable_can_be_trashed() -> void:
	assert_true(TrashRules.can_trash(_node(true)))


func test_non_pickable_cannot_be_trashed() -> void:
	assert_false(TrashRules.can_trash(_node(false)))


func test_queued_for_deletion_cannot_be_trashed() -> void:
	var node: Node = Node.new()
	node.add_to_group(&"pickable")
	add_child(node)
	node.queue_free()
	assert_false(TrashRules.can_trash(node))


func test_t5_trash_penalty_is_zero_in_data() -> void:
	assert_not_null(DATA)
	assert_eq(DATA.trash_penalty, 0)
