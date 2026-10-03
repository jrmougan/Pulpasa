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
