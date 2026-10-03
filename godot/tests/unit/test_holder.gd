extends GutTest
## PUL-011 AC3: Holder base falla con push_error; un Holder de prueba cumple el contrato.


func test_ac3_base_get_held_item_pushes_error() -> void:
	var holder: Holder = add_child_autofree(Holder.new())
	assert_null(holder.get_held_item())
	assert_push_error("abstracto")


func test_ac3_base_can_hold_pushes_error() -> void:
	var holder: Holder = add_child_autofree(Holder.new())
	assert_false(holder.can_hold(null))
	assert_push_error("abstracto")


func test_ac3_base_pick_up_pushes_error() -> void:
	var holder: Holder = add_child_autofree(Holder.new())
	assert_false(holder.pick_up(null))
	assert_push_error("abstracto")


func test_ac3_base_drop_pushes_error() -> void:
	var holder: Holder = add_child_autofree(Holder.new())
	assert_null(holder.drop())
	assert_push_error("abstracto")


func test_ac3_fake_holder_pick_up_emits_and_notifies_item() -> void:
	var holder: FakeHolder = add_child_autofree(FakeHolder.new())
	var item: FakePickable = add_child_autofree(FakePickable.new())
	watch_signals(holder)
	assert_true(holder.pick_up(item))
	assert_signal_emit_count(holder, "item_picked_up", 1)
	assert_signal_emitted_with_parameters(holder, "item_picked_up", [item])
	assert_eq(holder.get_held_item(), item)
	assert_true(item.is_held)


func test_ac3_fake_holder_drop_emits_and_notifies_item() -> void:
	var holder: FakeHolder = add_child_autofree(FakeHolder.new())
	var item: FakePickable = add_child_autofree(FakePickable.new())
	holder.pick_up(item)
	watch_signals(holder)
	assert_eq(holder.drop(), item)
	assert_signal_emit_count(holder, "item_dropped", 1)
	assert_null(holder.get_held_item())
	assert_false(item.is_held)


func test_ac3_validates_before_mutating() -> void:
	var holder: FakeHolder = add_child_autofree(FakeHolder.new())
	var first: FakePickable = add_child_autofree(FakePickable.new())
	var second: FakePickable = add_child_autofree(FakePickable.new())
	holder.pick_up(first)
	holder.log.clear()
	watch_signals(holder)
	assert_false(holder.pick_up(second))
	assert_eq(holder.log, ["validate"] as Array[String], "rechazado: no muta")
	assert_eq(holder.get_held_item(), first)
	assert_false(second.is_held)
	assert_signal_not_emitted(holder, "item_picked_up")


func test_ac3_pick_up_order_is_validate_then_mutate() -> void:
	var holder: FakeHolder = add_child_autofree(FakeHolder.new())
	holder.pick_up(add_child_autofree(FakePickable.new()))
	assert_eq(holder.log, ["validate", "mutate"] as Array[String])
