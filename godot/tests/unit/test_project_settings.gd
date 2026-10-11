extends GutTest
## PUL-122 AC2: escalado del lienzo y orientación (ADR-005 E2).


func test_stretch_mode_is_canvas_items() -> void:
	assert_eq(ProjectSettings.get_setting("display/window/stretch/mode"), "canvas_items")


func test_stretch_aspect_is_expand() -> void:
	assert_eq(ProjectSettings.get_setting("display/window/stretch/aspect"), "expand")


func test_handheld_orientation_is_sensor_landscape() -> void:
	assert_eq(int(ProjectSettings.get_setting("display/window/handheld/orientation")), 4)


func test_design_units_stay_1280_by_720() -> void:
	assert_eq(int(ProjectSettings.get_setting("display/window/size/viewport_width")), 1280)
	assert_eq(int(ProjectSettings.get_setting("display/window/size/viewport_height")), 720)


func test_back_button_does_not_quit() -> void:
	assert_false(bool(ProjectSettings.get_setting("application/config/quit_on_go_back")))
