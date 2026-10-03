# Dificultad progresiva (Should)

**Slug:** dificultad-progresiva · **Original:** mecánica «Variación de dificultad».

## Descripción
La cadencia de comandas sube con el tiempo de partida: el intervalo entre comandas baja de
`order_interval_start` a `order_interval_end` linealmente a lo largo de `match_duration`.

## Criterios de aceptación
- **AC1** Given el inicio de partida, Then el intervalo de generación es 20 s.
- **AC2** Given 150 s de partida (mitad), Then el intervalo es 12,5 s (±0,1).
- **AC3** Given 300 s, Then el intervalo es 5 s y nunca se supera `max_active_orders`.
- **AC4** Given dos partidas con la misma semilla, Then la secuencia de comandas generadas es idéntica.

## Datos (`.tres`)
`order_interval_start` (20 s), `order_interval_end` (5 s). Sustituye a `order_interval` fijo de `comandas.md`.
