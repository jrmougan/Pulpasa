class_name KitchenData
extends Resource
## Configuración de balance de la olla (`CookingStation`), instanciada en
## `data/config/kitchen.tres` e inyectada por la escena (D9: capacidad en datos).

## Plazas de cocción simultáneas, cada una con su progreso y su barra.
@export var capacity: int = 2
