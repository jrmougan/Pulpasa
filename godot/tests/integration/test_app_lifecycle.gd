extends GutTest
## PUL-122 AC7 (controles-tactiles AC19): perder el foco o la tecla Atrás pausan la ronda en el
## perfil MOBILE; al volver no se reanuda sola (ADR-004 §6.5).

const BusScript: GDScript = preload("res://autoload/event_bus.gd")
const GameStateScript: GDScript = preload("res://autoload/game_state.gd")

var _bus: Node
var _state: Node


func before_each() -> void:
	_bus = add_child_autofree(BusScript.new())
	_state = GameStateScript.new()
	_state.set_bus(_bus)
	add_child_autofree(_state)
	watch_signals(_bus)


func after_each() -> void:
	get_tree().paused = false
	_state.reset_input()


func _start_round(kind: PlatformProfile.Kind) -> void:
	_state.set_platform(kind)
	_bus.round_started.emit(60.0)


func test_focus_out_pauses_immediately_and_focus_in_does_not_resume() -> void:
	_start_round(PlatformProfile.Kind.MOBILE)
	_state.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert_true(get_tree().paused, "en el mismo frame")
	assert_signal_emitted_with_parameters(_bus, "pause_changed", [true])
	_state.notification(NOTIFICATION_APPLICATION_FOCUS_IN)
	await wait_process_frames(2)
	assert_true(get_tree().paused, "no se reanuda sola")


func test_application_paused_pauses_the_round() -> void:
	_start_round(PlatformProfile.Kind.MOBILE)
	_state.notification(NOTIFICATION_APPLICATION_PAUSED)
	assert_true(get_tree().paused)
	_state.notification(NOTIFICATION_APPLICATION_RESUMED)
	assert_true(get_tree().paused)


func test_back_request_pauses_the_round_and_a_second_one_does_not_resume() -> void:
	_start_round(PlatformProfile.Kind.MOBILE)
	_state.notification(NOTIFICATION_WM_GO_BACK_REQUEST)
	assert_true(get_tree().paused)
	_state.notification(NOTIFICATION_WM_GO_BACK_REQUEST)
	assert_true(get_tree().paused)
	assert_signal_emit_count(_bus, "pause_changed", 1)


func test_desktop_profile_ignores_focus_loss_and_back() -> void:
	_start_round(PlatformProfile.Kind.DESKTOP)
	for what: int in [
		NOTIFICATION_APPLICATION_FOCUS_OUT,
		NOTIFICATION_APPLICATION_PAUSED,
		NOTIFICATION_WM_GO_BACK_REQUEST
	]:
		_state.notification(what)
		assert_false(get_tree().paused, "notificación %d" % what)


func test_no_round_in_progress_does_not_pause() -> void:
	_state.set_platform(PlatformProfile.Kind.MOBILE)
	_state.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert_false(get_tree().paused, "en el menú no hay nada que pausar")


func test_finished_round_does_not_pause() -> void:
	_start_round(PlatformProfile.Kind.MOBILE)
	_bus.round_finished.emit(RoundResult.new())
	_state.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert_false(get_tree().paused)
