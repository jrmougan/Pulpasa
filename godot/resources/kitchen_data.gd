class_name KitchenData
extends Resource
## Configuración de balance de la olla (`CookingStation`), instanciada en
## `data/config/kitchen.tres` e inyectada por la escena (D9: capacidad en datos).

## Plazas de cocción simultáneas, cada una con su progreso y su anillo.
@export var capacity: int = 2

@export_group("Anillo de cocción y aviso de quemado (D26.6)")
## Parpadeo ámbar ↔ rojo del aviso de quemado (Hz; diseño: 3 ± 0,5).
@export var warn_blink_hz: float = 3.0
## Segundos entre cada repetición del cue `burn_warning` mientras dura el aviso.
@export var warn_repeat_interval: float = 1.0
## Veces que suena `burn_warning` en total (la primera al empezar el aviso) o hasta retirar.
@export_range(1, 10) var warn_repeat_count: int = 3
## Grosor del trazo del anillo, en px a 1080 de alto (diseño: ≥ 8).
@export var ring_thickness_px: float = 8.0
## Diámetro del anillo, en px a 1080 de alto (diseño: ≥ 64).
@export var ring_diameter_px: float = 64.0
