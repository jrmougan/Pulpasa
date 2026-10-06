class_name PhaselessConfig
extends RefCounted
## Suites de paridad (flujos M1/M2/M2b, `level_01`, smoke): quitan las fases del
## `round_config.tres` real mientras dura cada test, para que los niveles (también los cargados por
## cambio de escena o reintento, que comparten el recurso de la caché) arranquen como antes de las
## fases (PUL-070): todos los puestos y el `max_time` de la receta. `test_phases.gd` cubre las
## fases reales. Llamar a `disable()` en `before_each` y a `restore()` en `after_each`.

const CONFIG_PATH: String = "res://data/config/round_config.tres"

## Recurso de la caché mientras está desactivado (mantenerlo vivo lo mantiene en la caché).
static var _config: RoundConfig
static var _saved: Array[PhaseData] = []


static func disable() -> void:
	if _config != null:
		return
	_config = load(CONFIG_PATH) as RoundConfig
	_saved = _config.phases
	_config.phases = [] as Array[PhaseData]


static func restore() -> void:
	if _config == null:
		return
	_config.phases = _saved
	_config = null
	_saved = [] as Array[PhaseData]
