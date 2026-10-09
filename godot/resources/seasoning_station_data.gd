class_name SeasoningStationData
extends Resource
## Balance de la estación de condimentos (D18; feature estacion-condimentos, Datos).

## Segundos en que un mismo dispensador (o el cuenco al alternar) ignora otra pulsación.
@export var toggle_guard: float = 0.25
## Raciones máximas en el cuenco de cachelos.
@export var cachelos_stock_max: int = 4
## Raciones con las que empieza el cuenco.
@export var cachelos_initial_stock: int = 0
## Raciones que suma cada cachelos cocido echado al cuenco (D23: 2; se recorta al máximo).
@export var cachelos_portions_per_item: int = 2
## Pulsar el otro pimentón intercambia (true) o se rechaza con `EXCLUSIVE_TAKEN` (false).
@export var paprika_swap: bool = true
## Dispensadores (y alternar cachelos) solo desde el lado de condimentar; false = los dos lados.
@export var operator_side_only: bool = true
