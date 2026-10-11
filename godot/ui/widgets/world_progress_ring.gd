class_name WorldProgressRing
extends Sprite3D
## Anillo de estado en el mundo, siempre de cara a la cámara (billboard; D26.6, ADR-003 §11.8).
## Capa específica como `WorldProgressBar`: pinta un `TextureProgressBar` radial de un `SubViewport`
## propio. Estados: cociendo (arco blanco 0 a 100 %), listo (verde con ✓), aviso de quemado
## (parpadeo ámbar y rojo con la llama, el arco muestra el tiempo que queda) y quemado (rojo fijo).
## Mide `diameter_px` y su trazo `thickness_px` a `screen_height` de alto con la cámara ortográfica
## de `camera_size` m (los de juego); el tamaño en el mundo sale de ahí (`configure`).

enum State { HIDDEN, COOKING, READY, WARNING, BURNT }

## Lado del `SubViewport` (px) y margen de antialiasing alrededor del círculo.
const TEXTURE_PX: int = 128
const MARGIN_PX: int = 2
## Lado de la marca del centro (px del `SubViewport`).
const MARK_PX: float = 56.0
const COLOR_COOKING: Color = Color("#FFFFFF")
const COLOR_READY: Color = Color("#5CC754")
const COLOR_AMBER: Color = Color("#FFB020")
const COLOR_RED: Color = Color("#E03A2F")
const COLOR_TRACK: Color = Color(0.1, 0.1, 0.1, 0.75)
const MARK_READY: Texture2D = preload("res://assets/textures/ui/actions/icon_mark_ready.svg")
const MARK_WARNING: Texture2D = preload(
	"res://assets/textures/ui/actions/icon_mark_burn_warning.svg"
)

## Textura del anillo ya generada, por grosor (px del `SubViewport`): las plazas la comparten.
static var _texture_cache: Dictionary[float, Texture2D] = {}

## Diámetro y trazo del anillo en px de pantalla a `screen_height` (diseño: >= 64 y >= 8).
@export var diameter_px: float = 64.0
@export var thickness_px: float = 8.0
## Alto de ventana de referencia y alto (m) de la cámara ortográfica de juego (`camera_rig.tscn`).
@export var screen_height: float = 1080.0
@export var camera_size: float = 12.74
## Frecuencia del parpadeo ámbar y rojo del aviso (Hz).
@export var blink_hz: float = 3.0

var _state: State = State.HIDDEN
var _progress: float = 0.0
var _warn_time: float = 0.0

@onready var _viewport: SubViewport = %Viewport
@onready var _ring: TextureProgressBar = %Ring
@onready var _mark: TextureRect = %Mark


func _ready() -> void:
	texture = _viewport.get_texture()
	_viewport.size = Vector2i(TEXTURE_PX, TEXTURE_PX)
	_mark.size = Vector2(MARK_PX, MARK_PX)
	_mark.position = (Vector2(TEXTURE_PX, TEXTURE_PX) - _mark.size) / 2.0
	_ring.tint_under = COLOR_TRACK
	configure(diameter_px, thickness_px, blink_hz)
	_refresh()


## Fija las medidas (px a `screen_height`) y el parpadeo, y rehace el tamaño en el mundo.
func configure(new_diameter_px: float, new_thickness_px: float, new_blink_hz: float) -> void:
	diameter_px = new_diameter_px
	thickness_px = new_thickness_px
	blink_hz = new_blink_hz
	var drawn_px: float = float(TEXTURE_PX - 2 * MARGIN_PX)
	var texture_thickness: float = thickness_px * drawn_px / diameter_px
	var ring_texture: Texture2D = _make_ring_texture(texture_thickness)
	_ring.texture_under = ring_texture
	_ring.texture_progress = ring_texture
	# El círculo dibujado mide `diameter_px` en pantalla: el sprite entero, un poco más.
	var meters_per_px: float = camera_size / screen_height
	pixel_size = diameter_px * meters_per_px / drawn_px


func get_state() -> State:
	return _state


func set_state(new_state: State) -> void:
	_state = new_state
	_refresh()


## Progreso 0–1 del arco (cociendo: lo cocido; aviso: lo que queda hasta quemarse).
func set_progress(value: float) -> void:
	_progress = clampf(value, 0.0, 1.0)
	_refresh()


func get_progress() -> float:
	return _progress


## Segundos de aviso transcurridos: fija la fase del parpadeo (empieza en ámbar).
func set_warning_time(seconds: float) -> void:
	_warn_time = maxf(seconds, 0.0)
	_refresh()


## Color con que se pinta ahora el trazo.
func get_ring_color() -> Color:
	return _ring.tint_progress


## Marca del centro visible (✓ listo, llama del aviso) o `null`.
func get_mark() -> Texture2D:
	return _mark.texture if _mark.visible else null


## Diámetro del círculo en px de pantalla con una cámara de `size_m` m y una ventana de `height` px.
func get_diameter_px(size_m: float, height: float = 1080.0) -> float:
	return float(TEXTURE_PX - 2 * MARGIN_PX) * pixel_size * height / size_m


## Grosor del trazo en px de pantalla (mismas condiciones).
func get_thickness_px(size_m: float, height: float = 1080.0) -> float:
	var texture_thickness: float = thickness_px * float(TEXTURE_PX - 2 * MARGIN_PX) / diameter_px
	return texture_thickness * pixel_size * height / size_m


## Color del parpadeo `seconds` después de empezar el aviso: ámbar y rojo alternan a `hz` ciclos/s.
static func blink_color(seconds: float, hz: float) -> Color:
	var phase: int = int(maxf(seconds, 0.0) * hz * 2.0)
	return COLOR_AMBER if phase % 2 == 0 else COLOR_RED


func _refresh() -> void:
	if _ring == null:
		return
	visible = _state != State.HIDDEN
	var color: Color = COLOR_COOKING
	var value: float = _progress
	var mark: Texture2D = null
	match _state:
		State.READY:
			color = COLOR_READY
			value = 1.0
			mark = MARK_READY
		State.WARNING:
			color = blink_color(_warn_time, blink_hz)
			mark = MARK_WARNING
		State.BURNT:
			color = COLOR_RED
			value = 1.0
	_ring.tint_progress = color
	_ring.value = value * _ring.max_value
	_mark.texture = mark
	_mark.visible = mark != null


## Anillo blanco con borde suave, `thickness` px de grosor, a todo el `SubViewport`.
func _make_ring_texture(thickness: float) -> Texture2D:
	if _texture_cache.has(thickness):
		return _texture_cache[thickness]
	var image: Image = Image.create_empty(TEXTURE_PX, TEXTURE_PX, false, Image.FORMAT_RGBA8)
	var center: float = (TEXTURE_PX - 1) / 2.0
	var outer: float = float(TEXTURE_PX - 2 * MARGIN_PX) / 2.0
	var inner: float = outer - thickness
	for y: int in TEXTURE_PX:
		for x: int in TEXTURE_PX:
			var distance: float = Vector2(x - center, y - center).length()
			var alpha: float = clampf(outer - distance + 0.5, 0.0, 1.0)
			alpha *= clampf(distance - inner + 0.5, 0.0, 1.0)
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
	var made: ImageTexture = ImageTexture.create_from_image(image)
	_texture_cache[thickness] = made
	return made
