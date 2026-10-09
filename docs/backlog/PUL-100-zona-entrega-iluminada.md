---
id: PUL-100
title: Encender la zona de entrega del kiosco con la caja correcta
status: done
milestone: M3c
role: gameplay-engineer
deps: [PUL-093, PUL-096, PUL-099]
orca_task: null
unity_sources: []
owns: [godot/entities/stations/order_stand.gd, godot/entities/stations/order_stand.tscn, godot/entities/stations/order_stand_model.gd, godot/tests/integration/test_order_stand.gd, godot/tests/unit/test_order_stand_model.gd, godot/tests/integration/test_delivery_e2e.gd, docs/evidence/PUL-100/**, docs/backlog/PUL-100-zona-entrega-iluminada.md]
touches_scenes: [godot/entities/stations/order_stand.tscn]
---

## Target
Kiosco de entrega (D23, E-A).

## Change
Integra el modelo de PUL-096 (placa del `#id`, `delivery_zone`). La zona se enciende (material encendido, color de `StandPalette` en `albedo_color` y `emission` de `delivery_zone_on.tres`) cuando un portador a ≤ 2,0 m lleva una caja que coincide con la comanda viva del puesto; si no coincide, apagada. **Alinea el `Area3D` de entrega con la marca `delivery_zone` de PUL-096**, que se desplazó hacia la cocina (centro Z local ≈ 2,5) para que se vea desde la cámara; el centro final es Z local **3,40** (no 2,5; tamaño en `docs/evidence/PUL-096/README.md`). Mueve también `OrderLabel` a `Anchor_OrderLabel` sobre la placa nueva. Revisión de PUL-096: el chevron apunta hacia la cocina; valida con diseño si debe apuntar al kiosco.

## Constraints
- `tools/verify.sh` en verde; GDScript tipado; datos en `.tres`. Godot con `--audio-driver Dummy`; con el MCP, silencia los buses.
- Diseño: D23 en `docs/design/decisions.md` y `docs/design/rediseno-estaciones.md` (R1–R17). Las features reescritas (PUL-092) y los contratos (PUL-093) mandan.

## Acceptance
- [x] AC1 R12: caja que coincide → zona encendida en ≤ 0,1 s; que no coincide → apagada → test
- [x] AC2 Captura de un kiosco encendido y otro apagado

## Plan
Ficheros: `order_stand.gd`, `order_stand.tscn`, `test_order_stand.gd` (integración); `order_stand_model.gd` y su test no cambian.
- Escena: `%DeliveryZone` (Area3D) se mueve a Z local 3,40 (el nodo, no solo la forma: `global_position` es el centro de la marca) con forma 1,45 x 0,975 x 1,05 (huella de `delivery_zone`). Nuevo `%ProximityArea` (Area3D, capa 0, máscara 2 `player`, cilindro de radio 2,0 centrado en la zona; ADR-003 §9.4). `OrderLabel` pasa a (0, 1,905, -0,23) = `Anchor_OrderLabel`. `@export palette` apunta a `stand_palette.tres`; `@export` de los materiales `delivery_zone_off/on.tres`.
- Código: `_physics_process` evalúa si algún cuerpo de `%ProximityArea` lleva (por `%InteractionComponent`) una `Box` que pasa `_zone_accepts`; cambia el material de `DeliveryFrame` (hallado en `Model`, sin ruta absoluta) entre el compartido apagado y un duplicado por instancia del encendido con `albedo_color` y `emission` = `palette.color_for(slot_id)`. Se apaga además con `orders_reset`, `order_completed`, `order_expired` propios. `is_zone_lit() -> bool`. No entrega nada. Sin señales nuevas del catálogo.
- Tests (integración): AC1 caja que coincide a 1,5 m de la zona (fuera de ella) -> encendida en 3 ticks (50 ms < 0,1 s); caja que no coincide / sin caja / otro objeto -> apagada; a 2,5 m -> apagada; se apaga al entregar, al expirar, al reset; color de albedo y emission = paleta y cada puesto con material propio, el `.tres` compartido intacto; geometría: centro de la zona en Z 3,40, radio 2,0, capa/máscara, `OrderLabel` en `Anchor_OrderLabel`. AC2: captura `capture_level.gd` en `level_01` (un kiosco encendido, otro apagado) y sonda de alcanzabilidad/colisiones de la zona nueva.

## Evidence
- Tests nuevos en `godot/tests/integration/test_order_stand.gd` (12 `test_pul100_*`; el fichero pasa 37/37): encendida a 1,5 m con la caja que coincide en 6 ticks (0,1 s a 60 Hz; el área evalúa cada tick de física), apagada con caja que no coincide / de otro puesto / sin caja / con pulpo / a más de 2 m, apagada al irse, al caducar, con reset y al entregar; color en `albedo_color` y `emission` desde `StandPalette`, material por instancia y `.tres` compartido intacto; geometría (zona en Z 3,40 de 1,45 x 1,05, `%ProximityArea` cilindro r=2,0, capa 0, máscara player) y `OrderLabel` sobre `Anchor_OrderLabel`.
- Captura AC2 (`level_zone_lit_1080.png`, `capture_level.gd`): kiosco 1 encendido en rojo, 2-4 apagados, en `level_01` con la cámara real. La sonda de la misma ejecución da que las cuatro zonas (centros Z 2,35 mundo, x -3,3 / -1,3 / 1,7 / 3,7) solo solapan `KitchenLayout/Floor`: no chocan con nada y son alcanzables caminando; entre sí no se solapan (1,45 m de ancho, separación >= 2 m).
- `verify.log`: `tools/verify.sh` en verde, 769 tests, todos OK.
- `test_delivery_e2e.gd` adaptado a la zona nueva: la aproximación rodea las cuatro zonas por fuera (X -4,8 para los puestos 1-2 y 5,1 para el 3-4, baja desde Z 1,2 y recorre Z 3,5, a 0,4 m de las zonas) y se coloca delante del kiosco, fuera de la zona. (a) E delante del kiosco entrega. (b) Caminando: antes de entrar no ha entregado y la zona está encendida; al entrar entrega. (c) `test_pul039_wrong_box...`: cruza las zonas a su altura (Z 2,35), termina dentro de la del puesto (`overlaps_body`), no hay señales; luego sale delante del kiosco y E rechaza (E exige estar junto al kiosco: desde el centro de la zona el detector no lo elige). (d) Nuevo `test_pul100_every_stand_lights_and_delivers_on_entry`: determinista para los 4 puestos con una caja que coincide inyectada en la mano. Cruzar la zona con la caja correcta entrega: es lo deseado.
- `order_stand.gd`: `_apply_lit` solo reasigna el material al cambiar de estado (primera aplicación forzada) y `_physics_process` no evalúa con el área vacía y la zona apagada.
- Desviación de ADR-003 §9.4 / scene-tree.md:212: no hay nodo `%DeliveryMark`; la malla `DeliveryFrame` vive dentro de `Model` (.glb) y se localiza con `find_child`. Además el radio de 2,0 m de `%ProximityArea` se mide al borde de la cápsula del jugador (el cuerpo debe solapar el cilindro; ~2,21 m al centro). Pendiente de enmienda de docs/arch por el coordinador.
- Hallazgos para PUL-101 (`level_01.tscn`): (1) los kioscos están en y=-0,04 y la marca queda a y -0,02..0,004, bajo el suelo (y=0): no se ve nada; hay que poner los kioscos en y=0 (la captura lo simula). (2) Nada más que mover: la zona libre es Z 1,8-2,9 entre la barra y los kioscos; solo `BoxShelf` (x=-6,3) queda lejos.
- Nota de diseño: el chevron de la marca apunta hacia la cocina (arriba en pantalla), como pide la lámina; validar con diseño si debería apuntar al kiosco.
- Decisión: `%DeliveryMark` del ADR no existe como nodo propio (la malla está dentro del `.glb`); se localiza `DeliveryFrame` con `find_child` y se alterna `material_override`. `%DeliveryZone` y `%ProximityArea` se desplazan como nodo a Z 3,40 (la forma queda en su origen) para que `global_position` sea el centro de la marca.
