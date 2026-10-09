---
id: PUL-103
title: Enmendar los contratos con lo que cambió al implementar M3c
status: review
milestone: M3c
role: godot-architect
deps: [PUL-101]
orca_task: null
unity_sources: []
owns: [docs/arch/scene-tree.md, docs/arch/ADR-003-arbol-escenas-composicion.md, docs/design/level-layouts.md, docs/evidence/PUL-103/**, docs/backlog/PUL-103-contratos-tras-m3c.md]
touches_scenes: []
---

## Target
`docs/arch/scene-tree.md`, ADR-003 §9.4 y §9.5, `docs/design/level-layouts.md`. Gate humano: los contratos no cambian sin el visto bueno del responsable.

## Change
Reflejar lo que las revisiones de PUL-097…PUL-101 aceptaron y el código ya hace:
- §9.4: la marca de entrega es `DeliveryFrame` dentro de `Model` (glb de PUL-096), localizada con `find_child`; no hay nodo `%DeliveryMark`. Radio de proximidad 2,0 m medido al borde de la cápsula (~2,21 m al centro).
- §9.5: soltar sin objetivo con el punto delante bloqueado por la capa `world` **no suelta nada** (la mano no cambia): `Holder.can_drop_freely()` + `InteractionComponent`; `drop()` no cambia para transferencias. Sustituye a «se suelta a los pies».
- `scene-tree.md`: 6 `PassSlot` repartidos 3+3 (x −5,3/−4,3/−3,3 y 4,7/5,7/6,7), no 4+2; raíz de dispensadores y cuenco 0,45/0,25 m hacia el pase respecto al arte (anclar al `Model`); antirrebote con reloj de juego.
- `level-layouts.md`: hueco de la barra de 1,4 m (x 2,8…4,2, centro 3,5); el de x 7,7 cerrado.

## Constraints
Solo documentación. No cambia código ni escenas. Si algún punto no debería aceptarse, se abre ficha de código en vez de enmendar.

## Acceptance
- [x] AC1 Los cuatro puntos de Change están en los documentos, con referencia a la ficha que los implementó.
- [x] AC2 Ninguna contradicción restante entre `rediseno-estaciones.md` (R11), ADR-003 §9.5 y `level-layouts.md` (L1) sobre soltar frente a la barra.

## Plan
1. Verificar cada punto de Change contra `godot/` (escenas y scripts de PUL-097, PUL-100 y PUL-101) y anotar en Evidence lo que no coincida; manda el código.
2. ADR-003: §9.4 (`DeliveryFrame` dentro de `Model` con `find_child`, `material_off`/`material_on`, radio al borde de la cápsula), §9.5 (pasaplatos 3+3, soltar bloqueado por `world` no suelta, hueco 2,8…4,2), filas de `Holder` e `InteractionComponent` en §3 (API `can_drop_freely()`), cabecera con la enmienda PUL-103.
3. `scene-tree.md`: cabecera, planta y árbol de `level_01` (PassSlot01–03 al oeste, 04–06 al este, hueco centro 3,5), `kitchen_layout`, `order_stand.tscn` (sin `%DeliveryMark`), estación (colisión 5,2 m, raíz de dispensadores y cuenco desplazada respecto al `Model`, antirrebote con reloj de juego) y tabla de bajas §7.1.
4. `level-layouts.md`: estado, planta, detalle de la barra (pasaplatos este en 4,7/5,7/6,7, hueco 2,8…4,2), L1 y L2.
5. AC2: releer R11 de `rediseno-estaciones.md`, ADR-003 §9.5 y L1; si queda contradicción fuera de `owns`, se avisa al coordinador sin editarla.
6. `tools/verify.sh --quick`, commit.

## Evidence
Gate humano: aprobado por el responsable antes de empezar (commit 30f8a6b). Solo documentación; sin cambios en `godot/`.

**AC1: los cuatro puntos, verificados contra el código y con la ficha que los implementó**
- §9.4 (PUL-100): `order_stand.gd::_setup_delivery_mark()` hace `find_child("DeliveryFrame", true, false)` sobre la malla del `Model` (`order_stand.glb`) y alterna `material_override` entre `@export material_off` y un duplicado de `material_on` con el color de `palette`. `order_stand.tscn` no tiene ningún nodo `DeliveryMark`. `%ProximityArea`: `CylinderShape3D` de radio 2,0 en z 3,4 local (igual que `%DeliveryZone`); la cápsula del jugador tiene radio 0,21 (`player.tscn`), así que el solape enciende con el centro a ≲ 2,21 m (test: 1,9 m enciende, 2,6 m no). Documentado en ADR-003 §9.4 (y alternativa descartada 6), `scene-tree.md` §3 (árbol de `order_stand.tscn`, párrafo del indicador y tabla de equivalencia 2D).
- §9.5 (PUL-101, commit 869949f): `Holder.can_drop_freely()` (base `true`), `HoldComponent.can_drop_freely()` = `not _is_blocked(_drop_position())` (esfera de 0,2 m, máscara `world` = 1, punto 0,6 m delante y 0,6 m arriba), `InteractionComponent.interact_pressed()` llama `drop()` solo si `can_drop_freely()` y devuelve `true` en los dos casos; `drop()` no lo consulta. Documentado en ADR-003 §9.5 (sustituye «a los pies», alternativa descartada 5) y en las filas `Holder`/`InteractionComponent`/`HoldComponent` de ADR-003 §3.
- `scene-tree.md`: `level_01.tscn` tiene `PassSlot01..03` en x −5,3/−4,3/−3,3 y `PassSlot04..06` en x 4,7/5,7/6,7 (3 + 3, PUL-101); `seasoning_dispenser.tscn` con `Model` en z +0,45 y `cachelos_bowl.tscn` con `Model` en z +0,25, raíces en z −0,1 de la estación (PUL-097, commit 96fcbbe); antirrebote con `_game_time` acumulado en `_physics_process` en `seasoning_dispenser.gd` y `cachelos_bowl.gd` (PUL-097, commit d1255b2). Documentado en cabecera, §2 (planta, párrafo M3c, árbol del nivel y `KitchenLayout`), §3 (estación, dispensador, cuenco) y §7.1.
- `level-layouts.md`: `kitchen_layout.tscn` tiene `BarKitchenSide` x −5,8…−1,8 y `BarServiceSide` x 4,2…8,2, `GapThreshold` escalado a 1,4 en x 3,5; la colisión de la estación (5,2 m, centro 0,2) acaba en x 2,8 → hueco libre x 2,8…4,2 (1,4 m, centro 3,5); col. 14 cerrada; `level_walker.gd::GAP_X` = 3,5; `test_level_01.gd` usa `GAP_MIN_X` 2,8 y `GAP_MAX_X` 4,2. Documentado en estado, planta, detalle de la barra, L1 y L2 (PUL-101).

**Discrepancias entre la ficha/documentos y el código (manda el código)**
- La ficha dice «6 `PassSlot` repartidos 3+3 … no 4+2»: correcto, y además cambia la numeración: los del este son `PassSlot04..06` (no `05..06`). `scene-tree.md` lo refleja.
- `scene-tree.md` daba la colisión de la estación como «≈ 4 × 1,1 m»: en el código es 5,2 × 1,1 × 1,12 (PUL-097). Corregido, porque es lo que fija el borde oeste del hueco.
- `level-layouts.md` situaba los pasaplatos del este en 4,2/5,2/6,2 y el hueco en 2,7…3,7: corregido a 4,7/5,7/6,7 y 2,8…4,2. L2 pedía «hueco en x ∈ [2,7; 3,7] con ≥ 1,0 m libre»; el hueco real se sale por el este (4,2), pero su centro (3,5) está en el rango, que es lo que prueba `test_r14_*` (`assert_between(centre, 2.7, 3.7)`). L2 dice ahora «el centro del hueco», sin cambiar el criterio que se prueba.
- La ficha PUL-101 dice en su texto «barra este desde x 4,0»: en `kitchen_layout.tscn` empieza en x 4,2. Se documenta 4,2.

**AC2: R11 / ADR-003 §9.5 / L1**
- `rediseno-estaciones.md` R11: «pulsar con algo en la mano en la barra fuera de ellos y de la estación no suelta nada».
- ADR-003 §9.5: «no se suelta nada y la mano no cambia» si el punto de soltar cae en `world`.
- `level-layouts.md` L1: «no suelta nada (la mano no cambia)», ahora con referencia a `can_drop_freely()`.
- Sin contradicción entre los tres. Se buscó «a los pies» en `docs/`: solo queda en ADR-003 como alternativa descartada y en el texto histórico de la ficha PUL-101 (AC1 previo a la decisión del coordinador).

**Fuera de `owns` (no editado, para el coordinador)**
- `docs/arch/signals.md` líneas 68, 70 y 73 (filas `orders_reset`, `order_completed`, `order_expired`): «M3c: apaga `%DeliveryMark`». Debería decir `DeliveryFrame` (la malla del `Model`). No es contradicción sobre soltar (AC2), pero sí un resto del nombre retirado.

**Verificación**
- `tools/verify.sh --quick`: OK (gdformat 161 sin cambios, gdlint sin problemas, import OK).
