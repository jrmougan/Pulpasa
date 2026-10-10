class_name SeasoningStationData
extends Resource
## Balance de la estación de condimentos (D18; feature estacion-condimentos, Datos).

## Segundos en que el cuenco al alternar cachelos ignora otra pulsación (D25: solo el cuenco).
@export var toggle_guard: float = 0.25
## Raciones máximas en el cuenco de cachelos.
@export var cachelos_stock_max: int = 4
## Raciones con las que empieza el cuenco.
@export var cachelos_initial_stock: int = 0
## Raciones que suma cada cachelos cocido echado al cuenco (D23: 2; se recorta al máximo).
@export var cachelos_portions_per_item: int = 2
## Dispensadores (y alternar cachelos) solo desde el lado de condimentar; false = los dos lados.
@export var operator_side_only: bool = true
