---
id: PUL-206
title: Corregir ADR-003 §9.1 (cuenco) y las secuencias de entrega de signals.md §3
status: review
milestone: M4
role: godot-architect
deps: []
orca_task: null
unity_sources: []
owns: [docs/arch/ADR-003-arbol-escenas-composicion.md, docs/arch/signals.md]
touches_scenes: []
---

## Target
Dos frases de contrato que no coinciden con el código, vistas al cerrar PUL-205 y fuera de su alcance.

## Change
- **ADR-003 §9.1:** la tabla dice que el cuenco «no es objetivo» con la caja a medio cortar, y la nota que «las dos son de `is_reachable_from`». Hoy `ActionRules.for_bowl` da `BLOCKED` `BOX_NOT_FULL` con esa caja (`godot/core/action_rules.gd:101`), y lo decide `get_action_hint`, no `is_reachable_from`. Reescribir la fila y la nota según el código.
- **`signals.md` §3, «Entrega errónea» y «Entrega en el tick de caducidad»:** describen el núcleo (`OrderBoard.try_deliver`) sin decirlo, y en el juego no se alcanzan desde D26 (§2, `delivery_rejected`). Decir que son secuencias del núcleo, con la precondición `OrderData.max_time > 0` igual que §2.

## Constraints
**Requiere gate humano antes del merge**: es contrato. Solo cambia esas frases; no cambia código ni otras secciones. Cada frase nueva cita `ruta:línea`. Si el código contradice lo que pide el diseño (no solo el texto del contrato), status=blocked y pregúntalo.

## Acceptance
- [x] AC1 Given cada frase, When se abre la ruta citada, Then el código coincide → tabla en docs/evidence/PUL-206/
- [x] AC2 Given el cuenco con una caja a medio cortar en `level_01`, When se pide el hint, Then es el que dice la frase nueva → salida de un test o sonda en docs/evidence/PUL-206/

## Plan
1. Abrir el código en `81a450c` y comprobar cada afirmación de la ficha: `ActionRules.for_bowl`
   (`godot/core/action_rules.gd:101`-`:102`; la ficha citaba `:101`, que es el `case`), `CachelosBowl`
   (`get_action_hint`, `interact`, `is_reachable_from`), `SeasoningDispenser`, `OrderBoard.try_deliver`,
   `OrderBoard.advance`, `RoundState._on_delivery_rejected` y la zona de `order_stand.gd`.
2. Comprobar contra el diseño que no hay contradicción código/diseño: tabla E de
   `docs/design/features/lenguaje-acciones.md:218`-`:223` (M5/M6 = `B:caja a medias` desde el lado de aliñar,
   `—` desde el pase) y ADR-003 §11.7 ya lo decían; solo el texto de §9.1 estaba desfasado. No hay bloqueo.
3. ADR-003 §9.1: reescribir la celda del cuenco en la fila «Caja a medio cortar» y tachar y sustituir la
   nota de la asimetría (marcadas *Enmienda PUL-206*), citando `ruta:línea`.
4. `signals.md` §3: marcar «Entrega errónea» y «Entrega en el tick de caducidad» como secuencias del
   núcleo (`OrderBoard.try_deliver`) no alcanzables en el juego desde D26, con la precondición
   `OrderData.max_time > 0` de §2, citando `ruta:línea`.
5. AC1: tabla de citas. AC2: tests GUT existentes (sin añadir ninguno): el caso `E1s0-M6@bowl` sobre
   `level_01.tscn` real de `test_d26_no_mute_press.gd`, más dos de apoyo. `tools/verify.sh --quick`.

## Evidence
- AC1: `docs/evidence/PUL-206/ac1-citas.md` (cada cita contra la línea de código, todas coinciden).
- AC2: `docs/evidence/PUL-206/ac2-gut.txt`. `test_ac1_cachelos_bowl_on_level_01`
  (`godot/tests/integration/test_d26_no_mute_press.gd:626`) sobre `level_01.tscn` real con el detector real:
  caso `E1s0-M6@bowl`, caja con fill 0,5 desde el lado de servicio, exige objetivo = cuenco y hint
  `cachelos` `BLOCKED` `box_not_full` (fila `godot/tests/fixtures/action_matrix.csv:228`), y una sola
  respuesta `BLOCKED` con un solo cue `rejected` sin cambiar el mundo: pasa. Apoyo:
  `test_pul126_ac2_box_not_full_blocks_with_box_not_full` (fill 0,0 y 0,6, `rejected(BOX_NOT_FULL)`, `stock`
  igual) y `test_r5_box_in_hand_bowl_is_not_target_from_pass_side_within_1_5_m` (desde el pase no es
  objetivo): pasan.
- `tools/verify.sh --quick`: verde, `docs/evidence/PUL-206/verify-quick.txt`.
- Notas: el código cumple el diseño (D26, tabla E); el texto literal de D23 en `decisions.md` («con
  cualquier otra cosa no es objetivo») no se reescribió en la línea de D26, pero D26 remite a
  `lenguaje-acciones.md`, que manda. Sin cambios en código ni en otras secciones. Requiere gate humano.
