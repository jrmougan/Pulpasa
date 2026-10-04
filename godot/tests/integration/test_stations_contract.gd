extends GutTest

const STATIONS: Array[String] = [
	"res://entities/stations/octopus_storage.tscn", "res://entities/stations/cachelos_storage.tscn"
]


func test_ac1_stations_are_interactable() -> void:
	for path: String in STATIONS:
		var scene: PackedScene = load(path)
		assert_not_null(scene, "scene loaded: " + path)
		var instance: Node = scene.instantiate()
		assert_true(instance.is_in_group("interactable"), path + " is in interactable group")
		instance.free()
