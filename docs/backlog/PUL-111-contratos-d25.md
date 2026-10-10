---
id: PUL-111
title: Enmendar los contratos para D25 (caja única, aliño, cubo de basura)
status: in_progress
milestone: M3d
role: godot-architect
deps: []
orca_task: null
unity_sources: []
owns: [docs/arch/ADR-001-gdscript-convenciones.md, docs/arch/ADR-003-arbol-escenas-composicion.md, docs/arch/ADR-006-audio-feedback.md, docs/arch/scene-tree.md, docs/arch/signals.md, docs/backlog/PUL-111-contratos-d25.md]
touches_scenes: []
---

## Target
Contratos de `docs/arch/` afectados por D25 (aprobada por el responsable el 2026-10-10; la redacta en paralelo PUL-110 en `decisions.md`). Contenido de D25 en `docs/backlog/PUL-110-d25-simplificacion-mecanicas.md`, sección Change: léelo entero.

## Change
Enmienda que fije el contrato que implementarán las fichas de código siguientes (cubo, caja única, aliño):

1. **Caja única** (ADR-003 §9.3 y tablas de `BoxData`, `scene-tree.md` del rack): una sola `BoxData` (`data/boxes/box.tres` o la que decidas), `presses_to_fill` = 6. Decide y documenta: ¿`RecipeData.box` desaparece y `OrderValidator` deja de comparar caja, o queda apuntando a la única caja? Preferencia: quitarlo (menos campos muertos). El rack (`box_shelf`) pasa a un solo spawner. Ticket sin talla (`_show_size` desaparece). ADR-001 si usa `presses_to_fill`/S-M-L como ejemplo.
2. **Aliño** (ADR-003 §8 estación al paso): los `SeasoningData` pasan a ser `sweet_dressing`, `hot_dressing` y `cachelos` (que sigue siendo `SeasoningData` como hoy). Regla: los dos aliños son mutuamente excluyentes (aplicar uno sustituye al otro, generaliza `paprika_swap`); aplicar el que ya está no hace nada; requiere caja llena (`BOX_NOT_FULL`). Dispensador sin toggle de quitar. Decide si `seasoning_station.tres`/`toggle_guard` sigue siendo necesario. Motivos de rechazo que quedan.
3. **Cubo de basura**: escena `entities/stations/trash_bin.tscn` + `trash_bin.gd` (cumple el contrato `interactable` de ADR-003 §4), núcleo `core/trash_rules.gd` (`RefCounted`, `can_trash`), dato `trash_penalty: int = 0` (en qué `.tres`: decide, p. ej. `data/config/trash_bin.tres`). Señal **local** `trashed(item: Node)` con receptor `%Feedback` en `signals.md`; **sin señal nueva en `EventBus`** mientras `trash_penalty` = 0 (si en el futuro > 0, otra enmienda). Dos instancias en `level_01` en `scene-tree.md` (coordenadas aproximadas: cocina x≈−5,8 z≈−3,5; servicio junto al rack; compruébalas contra `docs/design/level-layouts.md` y ajústalas para respetar ≥ 1,5 m a pasaplatos y hueco).
4. **ADR-006**: cue `trash` en el catálogo.
5. **Fases de mecánicas**: cómo expresa la dificultad progresiva qué comandas salen en cada fase (p. ej. catálogo de comandas por fase en el `.tres` de la ronda). Solo el contrato de datos.

## Constraints
- Solo `docs/arch/`. Cada sección enmendada lleva nota «Enmienda D25 (PUL-111, 2026-10-10)».
- No cambies nada fuera de D25. Si D25 deja huecos de contrato, decide lo mínimo y anótalo en Evidence para el gate humano.
- Coherencia con el código actual: cita ficheros reales (`godot/resources/box_data.gd`, `recipe_data.gd`, `order_data.gd`, `core/order_validator.gd`, `core/seasoning_rules.gd`, `entities/stations/seasoning_*.gd`, `ui/tickets/ticket_entry.gd`, `components/interaction_component.gd`).

## Acceptance
- [x] AC1 ADR-003 describe caja única, aliño y cubo, con tipos y ficheros
- [x] AC2 `signals.md` tiene `trashed` como señal local y ninguna señal nueva de `EventBus`
- [x] AC3 `scene-tree.md` refleja rack de una caja, 2 dispensadores de aliño y 2 cubos en `level_01`
- [x] AC4 ADR-006 tiene el cue `trash`
- [x] AC5 Contrato de datos de fases de comandas
- [x] AC6 Lista en Evidence de las decisiones de contrato tomadas, para el gate humano

## Plan
1. Leer D25 (PUL-110), los contratos vigentes (ADR-003 §8–§9, ADR-006 §4–§6, `signals.md`,
   `scene-tree.md`, ADR-001) y el código real: `resources/{box_data,recipe_data,order_data,
   seasoning_data,seasoning_station_data,phase_data,round_config}.gd`, `core/{order_validator,
   seasoning_rules,order_board,round_state,box_contents}.gd`, `entities/items/box.gd`,
   `entities/stations/{seasoning_dispenser,cachelos_bowl,seasoning_station,item_spawner}.gd`,
   `box_shelf.tscn`, `ui/tickets/ticket_entry.gd`, `components/{interaction_component,
   hold_component,highlightable}.gd`, `kitchen_layout.tscn` y `level_01.tscn` (posiciones).
2. ADR-003: nueva §10 (caja única, aliño, cubo, comandas por fase, señales, alternativas) y notas
   «Enmienda D25» en estado, §1, §4, §8, §9.3 y §9.6; consecuencias.
3. ADR-006: cue `trash` en §4, nota en §5 (el quemado sigue en la olla) y contrato de comandas por
   fase en §6.
4. `signals.md`: `trashed` local con receptor `%Feedback`; cambios de `seasoned` /
   `seasoning_removed` / `rejected`; `ALREADY_APPLIED`; `PhaseData.orders`; sin señales de bus.
5. `scene-tree.md`: planta con 2 cubos (posiciones comprobadas contra la colisión del layout), rack
   de un spawner, estación con 2 dispensadores + cuenco, `trash_bin.tscn`, ticket sin talla, datos
   D25 y bajas §7.2.
6. `tools/verify.sh --quick`.

## Evidence
- Ficheros: `docs/arch/ADR-003-arbol-escenas-composicion.md` (§10 nueva + notas),
  `docs/arch/ADR-006-audio-feedback.md` (§4 cue `trash`, §5, §6 comandas por fase),
  `docs/arch/signals.md`, `docs/arch/scene-tree.md`. ADR-001 **sin cambios**: solo usa
  `presses_to_fill` como ejemplo genérico de dato en `.tres` (sigue siendo válido con 6) y no
  menciona S/M/L.
- `tools/verify.sh --quick`: verde (gdformat, gdlint, import).

### Decisiones de contrato tomadas (para el gate humano)
1. **`RecipeData.box` se quita** y `OrderValidator.matches` deja de comparar caja (preferencia de la
   ficha). La caja errónea de D8 es solo de contenido. El llenado sigue sin compararse: toda comanda
   lleva aliño y el aliño exige caja llena.
2. **`BoxContents.box` se conserva** (informativo, sin validar) para no reescribir las llamadas
   posicionales al constructor.
3. **Caja única en `data/boxes/box.tres`** (`presses_to_fill` 6); bajas `small/medium/large.tres`,
   `BoxData.short_label` e `icon`. Rack con un `BoxSpawner` cuyo `%Highlightable` resalta el mueble
   entero (`OutlineHull`); el `.glb` puede seguir mostrando tres huecos hasta que cambie el arte.
4. **Tipos de aliño nuevos** `SWEET_DRESSING`, `HOT_DRESSING` **al final** de `SeasoningType` (5 y 6),
   en `data/seasonings/{sweet_dressing,hot_dressing}.tres`, grupo `&"dressing"`, `sort_order` 0;
   `SALT/PAPRIKA/HOT_PAPRIKA/OIL` en desuso sin renumerar (`cachelos.tres` guarda `type = 4`). La
   llama de la pegatina pasa a `HOT_DRESSING`.
5. **Regla nueva `SeasoningRules.apply(current, seasoning, is_full) -> Toggle`** y
   `Box.apply_seasoning(seasoning)`: sustituye al del mismo grupo (generaliza `paprika_swap`),
   `ALREADY_APPLIED` si ya lo lleva, `BOX_NOT_FULL` sin llenar. Al sustituir, `seasoning_removed`
   antes que `seasoned` (orden de AC4).
6. **`Rejection.ALREADY_APPLIED`** (al final, valor 8). El dispensador lo **consume en silencio**
   (sin `rejected` ni `season_error`), por «pulsar el mismo no hace nada». Si el playtest pide
   feedback, basta con emitirlo en `rejected` (señal local). `EXCLUSIVE_TAKEN` en desuso.
7. **`toggle()` / `Box.toggle_seasoning()` pierden `swap_exclusive`**; solo los usa el cuenco.
8. **`SeasoningStationData` se mantiene sin `paprika_swap`**; `toggle_guard` queda **solo para el
   cuenco**. El dispensador **pierde el antirrebote** (aplicar es idempotente).
9. Motivos de `rejected` que quedan: dispensador `BOX_NOT_FULL`; cuenco `BOWL_EMPTY`, `BOWL_FULL`.
10. **Gesto visual** de aliño: nodo `%Gesture` interno de `seasoning_dispenser.tscn`, lanzado por el
    dispensador al aplicar, sin señal; el sonido sigue siendo `season` de la caja.
11. **Estación**: 2 dispensadores + cuenco en bloque centrado (x −1 / 0 / 1 local, ±0,5 m según R8);
    el mostrador de 5,2 m y el hueco **no cambian**. Pregunta abierta: ¿acortar el mostrador ahora
    que tiene 3 objetivos? D25 no lo pide; cambiarlo movería hueco y pasaplatos (R11, R14).
12. **Cubo**: `core/trash_rules.gd::can_trash(item: Node)` = objeto válido, no en cola de borrado y en
    el grupo `pickable` (común, solo `Node` + grupo). `TrashBin` vacía la mano con `Holder.drop()`
    (sin API nueva de `Holder`), emite `trashed(item)` y hace `queue_free()`. Consecuencia: suenan
    `drop` + `trash` (como al dejar algo en una estación). Sin regla de lado.
13. **`trash_penalty` en `data/config/trash_bin.tres`** (`TrashBinData`, `resources/trash_bin_data.gd`),
    valor 0. El cubo no lo aplica; `push_warning` si ≠ 0. **Hueco con T5 de PUL-110** («cambiarlo no
    exige código»): subirlo exige una enmienda (señal de bus o método de `RoundManager`), como pide
    esta ficha. El gate decide si T5 se lee como «el valor vive en datos».
14. **Posiciones de los cubos** (revisión del coordinador): regla de contrato, exigida en
    `test_level_01.gd`: ≥ 1,5 m de todo objetivo con la mano llena (nevera, saco de cachelos,
    `BoxSpawner`, ollas, pasaplatos, dispensadores, cuenco, puestos) y del hueco, sin solapar la
    colisión de `kitchen_layout.tscn`. `TrashBinKitchen` **x 2,6, z −3,1** (al este de `Kitchen2`,
    2,10 m de ella: «junto a las ollas» sin competir) y `TrashBinService` **x −5,4, z 4,3** (al sur
    del rack, 1,80 m del `BoxSpawner` en (−5,52; 2,5), 2,55 m de `OrderStand1`). ±0,2 m.
15. **Comandas por fase**: `PhaseData.orders: Array[OrderData]` (lista explícita por fase, vacía =
    todo el catálogo) + `OrderBoard.set_order_pool(orders)` aplicado en `RoundState._enter_phase`;
    un `randi_range` por comanda (semilla determinista); invariante de datos: el pool es subconjunto
    del catálogo. Descartado `OrderData.min_phase`. El tutorial (solo fase 1) lo resuelve su ficha
    con datos, sin contrato nuevo.
16. **Recetas** (nombres de `comandas.md`): Á feira 8 €, Picante 9 €, Con cachelos 12 €, Bravo
    cachelos 13 €; `max_time` 60/60/80/80. Una `RecipeData` por comanda (1:1), ficheros
    `data/{recipes,orders}/{a_feira,picante,con_cachelos,bravo_cachelos}.tres`; `order_catalog.tres`
    rehecho con las 4. Bajas: `individual/combo_duo/familiar.tres`, `order_1..6.tres`,
    `order_catalog_basic.tres` (sus usuarios, `kitchen_sandbox.tscn` y `test_data_integrity.gd`, pasan
    a `order_catalog.tres`). `tests/helpers/m0_data/` se rehace o se da de baja en la ficha dueña.
17. **Señales**: ninguna nueva ni cambio de firma en `EventBus`; una local nueva (`trashed`).
18. Confirmado en revisión: al sustituir un aliño suenan `unseason` y luego `season`; el mostrador se
    queda en 5,2 m (PUL-110 alinea el diseño).
