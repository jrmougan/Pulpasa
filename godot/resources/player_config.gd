class_name PlayerConfig
extends Resource
## Números del personaje (PlayerController, PlayerHoldSystem). Valores de Unity.

## Velocidad de movimiento (m/s).
@export var speed: float = 5.0
## Velocidad de giro hacia la dirección de movimiento.
@export var rotation_speed: float = 20.0
## Radio del detector de interacción (valor efectivo en Level_01; 1,5 en el prefab).
@export var detector_radius: float = 2.2
## Al soltar: desplazamiento hacia delante del portador.
@export var drop_forward_offset: float = 0.6
## Al soltar: desplazamiento hacia arriba.
@export var drop_up_offset: float = 0.6
## Detector: semiángulo del cono de selección (grados).
@export var detector_cone_half_angle: float = 30.0
## Detector: por debajo de esta distancia se ignora el cono.
@export var detector_near_distance: float = 0.7
## Detector: bonus de puntuación de la cocina con la mano vacía.
@export var detector_kitchen_bonus: float = 1.0
## Detector: altura sobre el jugador desde la que se mide la distancia 3D.
@export var detector_origin_height: float = 0.8
