---
id: PUL-107
title: Poner al día el GDD §9 (reglas vigentes) con decisions.md y el código
status: done
milestone: M3c
role: game-designer
deps: []
orca_task: null
unity_sources: []
owns: [docs/design/gdd.md, docs/evidence/PUL-107/**, docs/backlog/PUL-107-gdd-reglas-vigentes.md]
touches_scenes: []
---

## Target
`docs/design/gdd.md` §9 «Reglas vigentes de paridad con Unity» (hallazgo de PUL-106).

## Change
§9 describe defaults del prototipo que ya no rigen: la caja errónea «no penaliza» (D8: se penaliza), «Cocción: sin quemado» (el quemado existe, ADR-006 §5, `set_burnt`). Revisar cada punto de §9 contra `decisions.md` (manda sobre el GDD) y el código de `godot/` (p. ej. capacidad de la olla, asignación por puesto, reposición), corregir lo superado citando la decisión o ficha, y renombrar la sección si ya no trata de paridad (D17).

## Constraints
Solo `gdd.md`. Si un punto contradice `decisions.md` y el código hace otra cosa distinta a ambos, no se decide aquí: se anota en Evidence para el coordinador. Sin tocar `docs/arch/` ni código.

## Acceptance
- [x] AC1 Cada punto de §9 coincide con `decisions.md` y con el código, con referencia (D-xx, PUL-xxx o ADR)
- [x] AC2 Las discrepancias que no se pueden resolver solo en el GDD quedan listadas en Evidence

## Plan
1. Leer §9 de `gdd.md`, `decisions.md` y contrastar con `godot/` (`order_board.gd`, `cooking_station.gd`, `data/config/*.tres`, `data/boxes/*.tres`).
2. Reescribir los puntos superados citando D8, D9/D10, D12, ADR-006 §5/§6 y los valores en `.tres`.
3. Renombrar §9 (ya no es de paridad, D17) y ajustar §10, que listaba como «no rigen» cambios ya decididos.
4. Anotar en Evidence lo que no se resuelve solo en el GDD.

## Evidence
Cambios en `docs/design/gdd.md`:
- §9 renombrada «Reglas vigentes de las comandas, la olla y el corte» (D17).
- Caja errónea: ahora penaliza (D8; `wrong_delivery_penalty = 2` en `round_config.tres`; `OrderBoard.try_deliver`). Sin comanda o comanda caducada: penalización 0 (código).
- Olla: capacidad por datos (D9, D10; `kitchen.tres` `capacity = 2`; `CookingStation`).
- Asignación por puesto: D12, sin cambios, referencia a `OrderBoard`.
- Reposición: `OrderBoard.request_order`, `max_active_orders = 4`; añadido el límite por fases (ADR-006 §6, `active_slots` 2/3/4).
- Cocción: el quemado existe (ADR-006 §5, `set_burnt`, `burn_time` = 10 s en pulpo y cachelos).
- Corte: sin cambios (ya citaba PUL-104 y D23; `presses_to_fill` 4/6/10 verificado en `data/boxes/*.tres`).
- §10: quitados los puntos 1 (penalizar) y 2 (olla > 1), ya decididos; los restantes citan D12 y D13 como rechazados.

Discrepancias que no se resuelven solo en el GDD (para el coordinador):
1. Otras secciones de `gdd.md` desactualizadas, fuera del alcance de la ficha pero relacionadas: §6 Must 1 «Paridad con Unity» (D17) y `features/paridad-unity.md`; §6 Should «olla que se pasa» (ya implementada, ADR-006); §11 pregunta 2 (cachelos, respondida por D10) y pregunta 3 (cambio de personaje, respondida por D11).
2. `docs/design/features/olla-que-se-pasa.md` AC1 sigue diciendo `octopus_burnt`; la señal real es `burnt(ingredient)` (PUL-066 R10, `signals.md`). Lo corrige un game-designer en otra ficha (fuera de las owns).
3. `OrderService` documenta «sin config, 0 (paridad M0)»: valor por defecto de código, no contradice D8 porque el juego carga `round_config.tres` con las penalizaciones.
4. §4 «Máx. 4 comandas activas» es correcto como tope, pero con las fases el número efectivo empieza en 2 puestos activos; no se tocó.
5. Penalización 0 al entregar con la comanda ya caducada en el mismo tick: comportamiento del código (`try_deliver`) no recogido en `decisions.md` ni en `entrega-y-puntuacion.md`; se documenta en §9, pero conviene confirmarlo.

Verificación: solo cambios de documentación; `tools/verify.sh` lo pasa el coordinador.
