class_name StickerInk
extends RefCounted
## Tinta de las pegatinas de condimento (biblia v3 §6.2.1, PUL-185). Todos los discos llevan un
## anillo exterior de `INK` que los separa de cualquier fondo (caja roja 3.11 : 1, suelo
## 6.82 : 1). El icono va en `INK` salvo que no llegue a 3 : 1 sobre el disco (picante): entonces
## va en crema. El picante se distingue además por su silueta octogonal (D26).
## Lo comparten el ticket (UI) y la fila de pegatinas de la caja (3D).

## `state_burnt` de la paleta v3 (`#2A2320`, L = 0.0180).
const INK: Color = Color("#2A2320")
## Icono interior cuando `INK` no contrasta con el disco (`#F7F4EC`, 8.21 : 1 sobre el picante).
const CREAM: Color = Color("#F7F4EC")
## Anillo del picante. Con `INK` el disco/anillo da 1.71 : 1 (P4 abierta en la biblia §10): si el
## responsable decide otro tratamiento, se cambia solo aquí.
const HOT_RING: Color = INK
## Contraste mínimo icono/disco para usar `INK` como tinta del icono (WCAG 2.1, no texto).
const MIN_ICON_CONTRAST: float = 3.0
## Grosor del anillo como fracción del lado de la pegatina.
const RING_FRACTION: float = 0.09
## Chaflán de cada esquina del octógono regular como fracción del lado: 1 / (2 + √2).
const OCTAGON_CHAMFER: float = 0.29289322


## Luminancia relativa WCAG 2.1 (sRGB linealizado).
static func luminance(color: Color) -> float:
	var linear: Color = color.srgb_to_linear()
	return 0.2126 * linear.r + 0.7152 * linear.g + 0.0722 * linear.b


## Razón de contraste WCAG 2.1 entre dos colores (1..21).
static func contrast(a: Color, b: Color) -> float:
	var la: float = luminance(a)
	var lb: float = luminance(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)


## Si la pegatina de `seasoning` es la del picante (silueta octogonal y `HOT_RING`).
static func is_hot(seasoning: SeasoningData) -> bool:
	return seasoning != null and seasoning.type == SeasoningData.SeasoningType.HOT_DRESSING


## Color del anillo exterior de la pegatina de `seasoning`.
static func ring_color(seasoning: SeasoningData) -> Color:
	return HOT_RING if is_hot(seasoning) else INK


## Color del icono sobre `disc`: `INK` si contrasta al menos `MIN_ICON_CONTRAST`; si no, crema.
static func icon_color(disc: Color) -> Color:
	return INK if contrast(INK, disc) >= MIN_ICON_CONTRAST else CREAM
