# PUL-032 — Informe de QA de M1

Rama `jrmougan/pul-032`. Nivel: `level_01.tscn` con los datos reales (`round_config.tres`, `order_catalog.tres`, `kitchen.tres`).

## Resultado por AC

| AC | Resultado | Evidencia |
|----|-----------|-----------|
| AC1 Cachelera en el nivel y alcanzable | Pasa | `Stations/CachelosStorage` en (−5,7; −2,45), yaw 180°. `test_level_01.gd::test_ac4_player_reaches_and_interacts_with_every_station_and_slot` la alcanza, coge cachelos y los mete en la olla junto al pulpo. Estantería de 4 botes (`SPICE_SLOTS` con `OilSlot`) y olla de 2 plazas, alcanzables. Captura 01. |
| AC2 `test_m1_flow.gd` | Pasa | Comanda con aceite + cachelos, cocción conjunta, FIFO, bonus por tiempo, caducidad −3, caja errónea −2, recaudación y estrellas en el game over (72 asserts). |
| AC3 FIFO discriminante | Pasa | `test_cooking_station.gd::test_ac3_fifo_discriminates_finish_order_from_slot_index` (A plaza 0, B plaza 1 a t=2,5, recoger A, C en plaza 0 → sale B). |
| AC4 Partida manual + verify | Pasa | Capturas 01–08 (abajo). `tools/verify.sh` y `check_owns`: ver cierre de la ficha. |

## Decisiones de colocación
- La cachelera NO puede ir pegada a la nevera: el hueco izquierdo lo ocupa `LeftTable6` y el derecho el fogón. Primera prueba en (−6,3; −4,08): pasaba el test pero quedaba oculta tras la esquina (la caja de colisión es la de la nevera, 1,61×2,33×0,91). Queda en el suelo, a la izquierda y delante de la nevera, visible y alcanzable.
- Su collider (copia del de la nevera) es mayor que el modelo (0,5×0,42): es un ajuste de `cachelos_storage.tscn` (PUL-029), fuera de mi `owns`.

## Partida manual (MCP, `run_project` en background; input por `run_script` porque `simulate_input` no genera `_unhandled_input`)
1. `01` Nivel con la cachelera (cajita a la izquierda) y 4 comandas tras `first_order_delay`.
2. `02` Pulpo y cachelos crudos en la olla (2 plazas).
3. `03` Ambos cocidos tras 5 s.
4. `04` Caja de la comanda #3 llena (10 cortes) y con aceite.
5. `05` Entrega en el puesto 3: 0 € → 16 € (base 14 + bonus 2; `time_left` 43,8/90 s ⇒ floor(0,487·5)=2).
6. `06` Cachelos cocidos recogidos en mano; caja vacía entregada en el puesto 1: 16 → 14 (−2).
7. `07` Caducidad de comandas: 14 → 11 (−3).
8. `08` Dos entregas directas por `OrderService` (atajo, no jugadas) hasta 42 €; al acabar la ronda caducan 4 comandas (−12) → 30 €, 1 estrella, «Pulpeiro ineficiente», 0,60 cajas/min.

## Hallazgos (no corregidos: son de otras fichas)
1. **El catálogo real no tiene ninguna comanda con cachelos** (`order_1..4`: aceite+pimentón, aceite, pimentón picante+sal). Los cachelos como condimento solo se prueban con una comanda sintética en `test_m1_flow.gd` (con las `.tres` reales). En la partida manual no se pudo entregar una caja con cachelos. Decisión de diseño pendiente.
2. El icono de cachelos en el ticket #1/#2 y el cachelo crudo/cocido en la olla apenas se distinguen (captura 02/03): en la olla solo se ve el pulpo. Ya anotado en el roadmap para PUL-029.
3. El cierre de ronda caduca las comandas vivas de golpe y resta `expire_penalty` por cada una (−12 en 08) justo antes del resultado final. Es coherente con el código (`RoundState.advance` con salto grande), pero conviene decidir si al terminar la ronda deben restar.
4. `OrderService` no expone `get_order_for_slot` (solo `board`); menor.
