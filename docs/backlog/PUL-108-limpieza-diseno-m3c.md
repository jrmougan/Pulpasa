---
id: PUL-108
title: Limpiar el diseño superado y registrar D24 (entrega en el tick de caducidad)
status: review
milestone: M3c
role: game-designer
deps: [PUL-107]
orca_task: null
unity_sources: []
owns: [docs/design/decisions.md, docs/design/gdd.md, docs/design/features/paridad-unity.md, docs/design/features/olla-que-se-pasa.md, docs/design/features/coccion-pulpo.md, docs/design/features/entrega-y-puntuacion.md, docs/evidence/PUL-108/**, docs/backlog/PUL-108-limpieza-diseno-m3c.md]
touches_scenes: []
---

## Target
Restos de diseño superados que encontró PUL-107, y una decisión del responsable sin registrar.

## Change
- **D24** (decidido por el responsable el 2026-10-10): entregar en un puesto cuya comanda caduca en el mismo tick se rechaza **sin penalizar** (0), como hace hoy `OrderBoard.try_deliver`. Añadir la fila D24 a `decisions.md` y la regla a `entrega-y-puntuacion.md` y al GDD §9 (caja errónea).
- `gdd.md`: §6 Must 1 «Paridad con Unity» (D17: la paridad ya no es requisito); §6 Should «olla que se pasa» (implementada, ADR-006 §5); §11 pregunta 2 (respondida por D10) y 3 (respondida por D11).
- `features/paridad-unity.md`: marcarla como superada por D17 (cabecera de estado), sin borrar su contenido histórico.
- `features/olla-que-se-pasa.md` AC1: la señal es `burnt(ingredient)` (local, `signals.md`), no `octopus_burnt`; estado implementada.

## Constraints
Solo documentación de diseño; sin `docs/arch/` ni código. Citar decisión, ficha o ADR en cada cambio. Si aparece otra contradicción que requiera decisión, anotarla en Evidence.

## Acceptance
- [x] AC1 D24 en `decisions.md` y reflejada en `entrega-y-puntuacion.md` y `gdd.md` §9
- [x] AC2 Los cuatro restos de Change corregidos, con referencia
- [x] AC3 `grep -n octopus_burnt docs/design` sin resultados fuera de menciones históricas

## Plan
1. Verificar en `order_board.gd`, `signals.md` y `cooking_station.gd` lo que se va a documentar.
2. Añadir D24 tras D23 en `decisions.md`; regla y AC5d en `entrega-y-puntuacion.md`; frase en `gdd.md` §9.
3. (Ampliación pedida por el coordinador) `coccion-pulpo.md`: variante de paridad superada por D17 y ADR-006 §5; `gdd.md` §4 con quemado; cabecera y §3 de `gdd.md` remiten a `decisions.md` (D1–D24). `m0-gate.md` no se toca (histórico).
4. Corregir `gdd.md` §6 (Must 1, Should olla) y §11 (preguntas 2 y 3); cabecera de estado en `paridad-unity.md`; AC1 y estado en `olla-que-se-pasa.md`.

## Evidence
Verificado contra el código:
- `OrderBoard.try_deliver` (`core/order_board.gd:130-150`): si el puesto está en `_expired_this_tick` emite `delivery_rejected(slot, id_caducada, 0)` antes de validar la caja; sin comanda o con `time_left <= 0` también 0. Solo la caja errónea usa `_reject_penalty`. Con el tablero parado devuelve `null` sin señal.
- `signals.md:125` y `:192`: `burnt(ingredient)` es señal local de `cooking_station.gd` (línea 28, emitida en `_burn`, línea 301), tras `Ingredient.set_burnt()`; no hay `octopus_burnt` en el código.
- Quemado (`_tick_burn`): `burn_warned` a `warn_time`, `burnt` a `burn_time`; test `test_burn.gd`.
- `grep -n octopus_burnt docs/design`: solo queda la mención histórica en `olla-que-se-pasa.md` AC1 («antes `octopus_burnt`»).

Discrepancias nuevas (sin resolver, fuera de owns):
1. En el tick de caducidad la repuesta ya existe en el puesto, pero la entrega se rechaza contra la caducada (`id_caducada`). D24 lo cubre; los tests existentes son `test_order_board.gd` (`test_ac5b_delivery_on_expiry_tick_rejected_not_redirected`) y `test_order_stand.gd` (`_assert_expiry_tick`), con caja válida; falta el caso con caja errónea (el AC5d lo anota).
2. Resueltas en la ampliación: `coccion-pulpo.md` (AC2 y AC6 tachados como histórico de M0; rigen AC2' y AC6', cabecera «Quemado vigente»), `gdd.md` §4 (cocción con quemado) y cabecera/§3 de `gdd.md` (remiten a `decisions.md`, D1–D24). `m0-gate.md` cita `paridad-unity.md` y se deja intacto por histórico.
3. Pendiente (fuera de esta ficha): añadir a `test_order_board.gd` el caso de caja errónea en el tick de caducidad (penalización 0; AC5d de `entrega-y-puntuacion.md`).
