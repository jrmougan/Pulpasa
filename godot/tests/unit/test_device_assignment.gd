extends GutTest
## PUL-034 AC1: reparto de mandos y hot-plug de DeviceAssignment (ADR-004 §2), sin árbol.

const ANY: int = DeviceAssignment.ANY
const NONE: int = DeviceAssignment.NONE
const SINGLE: GameMode.Mode = GameMode.Mode.SINGLE
const COOP: GameMode.Mode = GameMode.Mode.COOP_2P


func _pads(ids: Array) -> Array[int]:
	var out: Array[int] = []
	out.assign(ids)
	return out


func test_ac1_constants_are_distinct_and_any_is_godot_wildcard() -> void:
	assert_eq(ANY, -1)
	assert_eq(NONE, -2)


func test_ac1_single_gives_any_to_p1_and_none_to_p2() -> void:
	for pads: Array in [[], [0], [0, 1]]:
		assert_eq(DeviceAssignment.initial(SINGLE, _pads(pads)), _pads([ANY, NONE]), str(pads))


func test_ac1_coop_without_pads_is_keyboard_only() -> void:
	assert_eq(DeviceAssignment.initial(COOP, _pads([])), _pads([NONE, NONE]))


func test_ac1_coop_with_one_pad_gives_it_to_p2() -> void:
	assert_eq(DeviceAssignment.initial(COOP, _pads([3])), _pads([NONE, 3]))


func test_ac1_coop_with_two_or_more_pads_in_order() -> void:
	assert_eq(DeviceAssignment.initial(COOP, _pads([4, 2])), _pads([4, 2]))
	assert_eq(DeviceAssignment.initial(COOP, _pads([0, 1, 2])), _pads([0, 1]))


func test_ac1_coop_never_uses_any_nor_repeats_a_pad() -> void:
	for pads: Array in [[], [0], [0, 1], [5, 6, 7]]:
		var devices: Array[int] = DeviceAssignment.initial(COOP, _pads(pads))
		assert_false(devices.has(ANY), str(pads))
		if devices[0] >= 0:
			assert_ne(devices[0], devices[1], str(pads))


func test_ac1_player_with_finds_exact_pad_only() -> void:
	var devices: Array[int] = _pads([NONE, 3])
	assert_eq(DeviceAssignment.player_with(devices, 3), 2)
	assert_eq(DeviceAssignment.player_with(devices, 0), 0)
	assert_eq(DeviceAssignment.player_with(devices, NONE), 0)
	assert_eq(DeviceAssignment.player_with(_pads([ANY, NONE]), ANY), 0)


func test_ac1_disconnecting_p2_pad_affects_p2_only() -> void:
	var devices: Array[int] = _pads([NONE, 3])
	assert_eq(DeviceAssignment.on_disconnected(devices, 3, _pads([])), 2)


func test_ac1_disconnecting_unassigned_pad_affects_nobody() -> void:
	assert_eq(DeviceAssignment.on_disconnected(_pads([0, 1]), 2, _pads([0, 1])), 0)
	assert_eq(DeviceAssignment.on_disconnected(_pads([NONE, NONE]), 0, _pads([])), 0)


func test_ac1_single_pad_loss_affects_p1_only_when_no_pad_remains() -> void:
	var devices: Array[int] = _pads([ANY, NONE])
	assert_eq(DeviceAssignment.on_disconnected(devices, 0, _pads([1])), 0)
	assert_eq(DeviceAssignment.on_disconnected(devices, 1, _pads([])), 1)


func test_ac1_reconnection_returns_pad_to_p2_not_p1() -> void:
	# Teclado + 1 mando: J2 lo pierde (pasa a NONE) y J1 ya estaba en NONE.
	var devices: Array[int] = _pads([NONE, NONE])
	var lost_by: Dictionary = {3: 2}
	assert_eq(DeviceAssignment.on_connected(devices, COOP, 3, lost_by), 2)


func test_ac1_new_pad_goes_to_first_player_in_none() -> void:
	assert_eq(DeviceAssignment.on_connected(_pads([NONE, NONE]), COOP, 7, {}), 1)
	assert_eq(DeviceAssignment.on_connected(_pads([0, NONE]), COOP, 7, {}), 2)


func test_ac1_lost_pad_goes_to_first_none_if_owner_has_another() -> void:
	# J2 perdió el 3 pero ya tiene el 5: el 3 va a J1, que sigue en NONE.
	assert_eq(DeviceAssignment.on_connected(_pads([NONE, 5]), COOP, 3, {3: 2}), 1)


func test_ac1_connection_is_ignored_when_full_assigned_or_single() -> void:
	assert_eq(DeviceAssignment.on_connected(_pads([0, 1]), COOP, 2, {}), 0)
	assert_eq(DeviceAssignment.on_connected(_pads([NONE, 1]), COOP, 1, {}), 0, "ya asignado")
	assert_eq(DeviceAssignment.on_connected(_pads([ANY, NONE]), SINGLE, 0, {}), 0)
