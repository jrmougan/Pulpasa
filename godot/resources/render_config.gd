class_name RenderConfig
extends Resource
## Luz ambiental y post-proceso del nivel (biblia de arte v2 §1.3, PUL-073). Lo aplica
## `LevelEnvironment` al `WorldEnvironment` de `environment.tscn`.

## Cielo, ambiente, tonemapping, SSAO, glow y gradación.
@export var environment: Environment
## Exposición y profundidad de campo. Solo se usa el desenfoque lejano: con la cámara ortográfica
## inclinada el cercano emborronaría los carteles de los kioscos, que están más cerca de la cámara.
@export var camera_attributes: CameraAttributesPractical
## Tilt-shift: desenfoca el fondo por detrás del perímetro de encimeras. Apagado por defecto (D22).
@export var tilt_shift_enabled: bool = false


## Copia de `camera_attributes` con el tilt-shift según `tilt_shift_enabled`.
func make_camera_attributes() -> CameraAttributesPractical:
	if camera_attributes == null:
		return null
	var attrs: CameraAttributesPractical = (
		camera_attributes.duplicate() as CameraAttributesPractical
	)
	attrs.dof_blur_far_enabled = tilt_shift_enabled
	attrs.dof_blur_near_enabled = false
	return attrs
