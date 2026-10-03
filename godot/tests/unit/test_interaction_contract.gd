extends GutTest
## PUL-014 AC3: el contrato detecta nodos de grupo sin los métodos obligatorios.

const IncompleteInteractable: GDScript = preload("res://tests/helpers/incomplete_interactable.gd")
const IncompletePickable: GDScript = preload("res://tests/helpers/incomplete_pickable.gd")


func _in_group(node: Node, group: StringName) -> Node:
	node.add_to_group(group)
	return add_child_autofree(node)


func test_ac3_complete_interactable_has_no_violations() -> void:
	var node: Node = _in_group(FakeInteractable.new(), &"interactable")
	assert_eq(InteractionContract.violations(node), [])


func test_ac3_interactable_missing_interact_is_reported() -> void:
	var node: Node = _in_group(IncompleteInteractable.new(), &"interactable")
	var found: Array[String] = InteractionContract.violations(node)
	assert_eq(found.size(), 1)
	assert_string_contains(found[0], "interact(")


func test_ac3_complete_pickable_has_no_violations() -> void:
	var node: Node = _in_group(FakePickable.new(), &"pickable")
	assert_eq(InteractionContract.violations(node), [])


func test_ac3_pickable_missing_methods_and_is_held_are_reported() -> void:
	var node: Node = _in_group(IncompletePickable.new(), &"pickable")
	var found: Array[String] = InteractionContract.violations(node)
	assert_eq(found.size(), 2)
	assert_true(found.any(func(s: String) -> bool: return s.contains("on_dropped")))
	assert_true(found.any(func(s: String) -> bool: return s.contains("is_held")))


func test_ac3_node_in_both_groups_accumulates_violations() -> void:
	var node: Node = Node.new()
	node.add_to_group(&"interactable")
	node.add_to_group(&"pickable")
	add_child_autofree(node)
	assert_eq(InteractionContract.violations(node).size(), 5)


func test_ac3_node_outside_groups_has_no_violations() -> void:
	var node: Node = add_child_autofree(Node.new())
	assert_eq(InteractionContract.violations(node), [])


func test_ac3_scan_tree_collects_all_violations_with_node_names() -> void:
	var root: Node = add_child_autofree(Node.new())
	var bad: Node = IncompleteInteractable.new()
	bad.name = "Roto"
	bad.add_to_group(&"interactable")
	root.add_child(bad)
	var good: Node = FakePickable.new()
	good.add_to_group(&"pickable")
	root.add_child(good)
	var found: Array[String] = InteractionContract.scan_tree(root)
	assert_eq(found.size(), 1)
	assert_string_contains(found[0], "Roto")


func test_ac3_pickable_violations_checks_contract_without_group() -> void:
	var complete: Node = add_child_autofree(FakePickable.new())
	assert_eq(InteractionContract.pickable_violations(complete), [])
	var incomplete: Node = add_child_autofree(IncompletePickable.new())
	assert_eq(InteractionContract.pickable_violations(incomplete).size(), 2)
