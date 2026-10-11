class_name ActionIconSet
extends Resource
## Iconos y medidas del prompt de acción (D26, ADR-003 §11.5). Lo comparten `ActionPrompt` (mundo) y
## el botón de acción táctil (UI): mismo icono en los dos. Capa común: solo `Texture2D`, `Color` y
## números. Las claves son los valores de `ActionVerb.ALL` y `ActionReason.ALL`.

## Icono por verbo (`icon_verb_<id>.svg`).
@export var verb_icons: Dictionary[StringName, Texture2D] = {}
## Icono por motivo de bloqueo (`icon_reason_<id>.svg`).
@export var reason_icons: Dictionary[StringName, Texture2D] = {}
## Placa circular bajo el icono.
@export var plate: Texture2D
## Aspa del estado BLOQUEADO.
@export var cross: Texture2D
## Insignia «sustituye» del prompt de aliño.
@export var replace: Texture2D
## Marcador de jugador en Local 2P: índice 0 = J1, 1 = J2.
@export var player_markers: Array[Texture2D] = []
@export_group("Colores")
@export var ok_color: Color = Color("#FFFFFF")
@export var blocked_color: Color = Color("#FFB020")
## Color de la placa (incluye su 85 % de opacidad).
@export var plate_color: Color = Color(0.105882, 0.105882, 0.121569, 0.85)
## Botón táctil sin objetivo.
@export var idle_color: Color = Color("#6B6B73")
@export_range(0.0, 1.0) var idle_alpha: float = 0.4
@export_group("Medidas")
## Lado del icono de verbo en px a 1080 de alto.
@export var prompt_icon_px_1080: int = 64
@export var prompt_plate_px_1080: int = 80
## Mínimo absoluto del icono de verbo en px.
@export var prompt_min_px: int = 48
@export var reason_icon_px_1080: int = 32
@export var cross_px_1080: int = 24
## Altura del prompt sobre el objetivo, en m.
@export var prompt_offset: float = 0.9
@export_group("Respuesta")
@export var response_duration: float = 0.35
@export var reject_shake_px: int = 6
