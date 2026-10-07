class_name StickerInk
extends RefCounted
## Tinta de las pegatinas de condimento (biblia §2.5, PUL-086). Sobre un disco claro (la sal,
## `#F7F4EC`) el icono blanco no se ve: el icono pasa a `INK` y el disco lleva un anillo de `INK`.
## Lo comparten el ticket (UI) y la fila de pegatinas de la caja (3D).

## Borde y tinta de la sal en la biblia (§2.5).
const INK: Color = Color(0.43137255, 0.2901961, 0.16862746, 1.0)
## Por encima de esta luminancia relativa el disco cuenta como claro: solo los casi blancos; los
## amarillos (aceite, cachelos) mantienen el icono blanco de PUL-060.
const LIGHT_LUMINANCE: float = 0.9
## Grosor del anillo como fracción del lado de la pegatina.
const RING_FRACTION: float = 0.09


static func is_light(disc: Color) -> bool:
	return disc.get_luminance() > LIGHT_LUMINANCE


## Color del icono sobre `disc`: blanco salvo en discos claros.
static func icon_color(disc: Color) -> Color:
	return INK if is_light(disc) else Color.WHITE
