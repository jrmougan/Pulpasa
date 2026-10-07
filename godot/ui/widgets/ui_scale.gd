class_name UiScale
extends RefCounted
## Escala de HUD y tickets (PUL-086). El proyecto no estira el lienzo y la cámara ortográfica
## conserva la altura del mundo: sin escalar, a 1080p la UI se vería un tercio más pequeña que a
## 720p. Con esto ocupa la misma proporción de pantalla en ambas (AC2).

const REFERENCE_HEIGHT_PX: float = 720.0
const MAX_FACTOR: float = 2.0


static func factor(viewport_height: float) -> float:
	return clampf(viewport_height / REFERENCE_HEIGHT_PX, 1.0, MAX_FACTOR)
