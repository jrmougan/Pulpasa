# PUL-092 · Evidencia: features de estaciones según D23

Solo documentación (sin cambios en `godot/` ni `docs/arch/`). Fuente: `docs/design/rediseno-estaciones.md`
§4 y §7, decisión D23 (`docs/design/decisions.md`).

## Reparto de R1–R17 (AC2)
| R | Feature | AC | Test previsto |
|---|---|---|---|
| R1 | estacion-condimentos | AC1 | `test_seasoning_station.gd` |
| R2 | estacion-condimentos | AC2 (+AC3 pausa) | `test_seasoning_station.gd`, reloj de juego |
| R3 | estacion-condimentos / condimentacion | AC5 / AC4 | `test_seasoning_station.gd` / `test_seasoning_rules.gd` |
| R4 | estacion-condimentos | AC6 | `test_seasoning_station.gd` |
| R5 | estacion-condimentos | AC8 (concretado, ver abajo) | `test_seasoning_station.gd` + `target_map.gd` |
| R6 | estacion-condimentos / condimentacion | AC9 / AC8 | `test_cachelos.gd` |
| R7 | estacion-condimentos | AC11 | `test_station_level.gd` + `target_map.gd` |
| R8 | estacion-condimentos | AC12 | `test_station_level.gd` |
| R9 | corte-pulpo | AC2 | `test_box.gd`, `test_data_boxes.gd` |
| R10 | comandas | AC9 | `test_order_tickets.gd` + captura |
| R11 | level-layouts | L1 | `test_level_01.gd` + captura |
| R12 | entrega-y-puntuacion | AC14 | `test_order_stand.gd` + captura |
| R13 | comandas / entrega-y-puntuacion | AC10 / AC16 | `test_order_tickets.gd`, `test_order_stand_model.gd` |
| R14 | level-layouts | L2 | `test_level_01.gd` (Dijkstra) |
| R15 | level-layouts | L3 | `measure_flow.gd` adaptado |
| R16 | estacion-condimentos / level-layouts | AC16 / L4 | `test_station_level.gd` |
| R17 | level-layouts | L5 | `measure_flow.gd` adaptado |

Comprobación: `grep -o "(R[0-9]*)" docs/design/features/*.md docs/design/level-layouts.md` cubre R1–R17.

## Preguntas abiertas de PUL-090 §7 (recogidas)
1. Precio de la L → lo decide el playtest (`corte-pulpo.md` y `entrega-y-puntuacion.md`, preguntas abiertas).
2. Varias cajas en la mano → fuera de alcance (`estacion-condimentos.md`, descripción).
3. `operator_side_only` → se mantiene en true (`estacion-condimentos.md` AC7, Datos).
4. Antirrebote → reloj de juego (`estacion-condimentos.md` AC3).

## Coherencia con `decisions.md` (AC1)
- **D3/D11:** una tecla de acción y cambio de personaje; Individual nunca exige dos personajes a la vez (AC16–AC17).
- **D4:** sí/no, pimentón exclusivo (`paprika_swap`).
- **D13:** pulsación repetida; solo cambian las cantidades 5/10/20 → 4/6/10.
- **D18 modificada por D23:** marcado «Sustituido por D23» en cada feature (bandeja, cortes, ticket, zona muda, hueco x 7,7, 9 pasaplatos).
- **D8:** `entrega-y-puntuacion.md` AC13 decía «caja errónea sin penalización» (paridad M0) y contradecía D8; corregido a −2 € (`wrong_delivery_penalty`, ya en `round_config.tres`).
- **Concreción de D23/R5** (acordada con el coordinador el 2026-10-07, que corrige la redacción de D23 en `decisions.md`): el cuenco es objetivo (a) con cachelos cocidos, desde cualquier lado, para reponer, y (b) con una caja llena, solo desde el lado de condimentar, para alternar; con cualquier otra cosa no.

## Boceto (AC3)
`docs/design/level-layouts.md` § «Planta B vigente (D23)»: planta de 1 m y detalle de la barra a 0,5 m con el hueco en x 2,7–3,7 (≈ 3,2), 3 + 3 pasaplatos marcados y la línea d p s a c. Boceto de la línea en `estacion-condimentos.md`.
