class_name SeasoningStationData
extends Resource
## Balance de la estación de condimentos (D18; feature estacion-condimentos, Datos).

## Raciones máximas en el cuenco de cachelos.
@export var cachelos_stock_max: int = 4
## Raciones con las que empieza el cuenco.
@export var cachelos_initial_stock: int = 0
## Raciones que suma cada cachelos cocido echado al cuenco (D23: 2; se recorta al máximo).
@export var cachelos_portions_per_item: int = 2
## Dispensadores (y poner cachelos con una caja) solo desde el lado de condimentar; false = ambos.
@export var operator_side_only: bool = true

## %StockMeter del cuenco (D26.6, ADR-003 §11.8): muescas por ración, medidas en px a 1080 de alto.
## Lado de cada muesca (el mínimo legible es 24).
@export var stock_notch_px: int = 24
## Separación entre muescas y margen de la placa.
@export var stock_notch_gap_px: int = 6
## Grosor del contorno de una muesca hueca.
@export var stock_notch_outline_px: int = 3
## Muesca con ración.
@export var stock_fill_color: Color = Color("F2D56B")
## Interior de una muesca hueca y placa (contraste >= 3:1 con `stock_fill_color`).
@export var stock_empty_color: Color = Color("1B1B1F")
## Contorno de una muesca hueca.
@export var stock_outline_color: Color = Color("FFF4D6")
## Opacidad de la placa del medidor.
@export_range(0.0, 1.0) var stock_plate_alpha: float = 0.85
