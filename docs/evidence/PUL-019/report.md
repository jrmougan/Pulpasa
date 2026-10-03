# PUL-019 — Informe QA: sandbox de cocina y flujo completo

Rama `jrmougan/pul-019`. Godot 4.7.2, MCP godot-mcp-runtime 3.8.1 (background, Vulkan).

## AC → resultado → evidencia

| AC | Resultado | Evidencia |
|---|---|---|
| AC1 Flujo completo → exactamente 1 `order_completed` y el puesto recibe comanda nueva | **Pasa** | `test_kitchen_flow.gd::test_ac1_full_flow_completes_exactly_one_order_and_stand_gets_new_one` (nevera → olla → `cooking_finished` real → caja S/M/L de la receta en el slot libre → cortes hasta llenar → condimentos de la comanda → entrega; 1 `order_completed` con id/slot correctos, 0 `delivery_rejected`, caja liberada, label `#nuevo`, el otro puesto no cambia, sigue en 1 tras 5 ticks). MCP sesión 2: log del bus `order_completed(#1, slot 1, 0)` → `order_generated(#3, slot 1)`, `OkAudio` sonando, label `#1` → `#3` (`s2-02-…png`) |
| AC2 Condimentos de menos se rechazan; de más se aceptan (B15) | **Pasa** | `test_ac2_missing_seasoning_rejected_extra_seasoning_accepted`: sin el último condimento → `delivery_rejected(1, id, 0)`, caja en la mano, comanda viva; añadiendo el que falta + todos los no pedidos → `order_completed` de esa comanda. MCP sesión 2: caja con solo sal para la comanda #1 (sal + pimentón) → `delivery_rejected(slot 1, #1, 0)`, `ErrorAudio` sonando, caja en la mano (`s2-01-…png`). La parte «de más se acepta» **solo** está verificada por el test, no en la partida manual (ver notas) |
| AC3 Partida manual vía MCP con capturas + informe; `verify.sh` en verde | **Pasa** | Capturas `s1-*` y `s2-*` de esta carpeta; `tools/verify.sh` → `✓ verify OK` (328/328 tests GUT, gdformat, gdlint, import, smoke). `get_debug_output` de las dos sesiones: 0 `ERROR`/`SCRIPT ERROR` |

## Qué se montó

- `godot/scenes/sandbox/kitchen_sandbox.tscn`: jugador, `CameraRig`, nevera, olla, estantería de
  cajas, estantería de especias, `FreeSlot` (slot sin objeto) y `OrderStand1/2` (`slot_id` 1 y 2).
  El script del sandbox va **embebido en la escena** (sub_resource `GDScript`, tipado), porque
  `owns` no incluye ningún `.gd` para él: `OrderService.setup(catalog, rng)` +
  `RoundManager.start_round(round_config, slot_ids de stands)`. `rng_seed = 2` deja las comandas
  fijas (puesto 1: Pulpo Individual, caja pequeña, sal + pimentón; puesto 2: Familiar, caja grande,
  sal + pimentón picante); `rng_seed = 0` las hace aleatorias. `mcp_bridge` (apagado por defecto)
  sondea `p1_interact` para el MCP, como el sandbox de PUL-017.
- `godot/tests/integration/test_kitchen_flow.gd`: instancia el sandbox con los autoloads reales;
  aparta al jugador para que su detector no cambie de objetivo y cada pulsación pasa por
  `InteractionComponent.interact_pressed()` con el objetivo que publicaría el detector.

## Partida manual (MCP)

Input solo con `simulate_input` (acciones `p1_move_*` / `p1_interact`); `run_script` solo para
encender `mcp_bridge`, leer estado y montar un nodo que registra señales del bus (no modifica el
juego).

- **Sesión 1** (`s1-00` … `s1-07`): inicio con `#1`/`#2` → pulpo de la nevera → olla cociendo →
  caja pequeña de la estantería (y pulpo ya cocido en la olla) → caja en el slot libre → cortes
  (40 %) → caja llena con sal. La ronda (180 s, `round_config.tres`) terminó antes de entregar:
  con el tablero parado el puesto no hace nada (sin señales), que es lo especificado
  (`OrderBoard.try_deliver` con `_stopped`). `s1-07` es ese estado.
- **Sesión 2** (`s2-01`, `s2-02`): la misma partida de un tirón. Entrega con solo sal → rechazo;
  vuelta al slot, pimentón, entrega → aceptada y comanda nueva `#3` en el puesto 1.

## Observaciones (no son fallos de código de otras fichas; para triage del coordinador)

1. **Detector y especias**: con un bote en la mano, el detector prefiere el bote de otra especia
   (o un objeto suelto) al slot vacío de la estantería; pulsar ahí suelta el bote al suelo en vez de
   devolverlo. Y mirando hacia la nevera con un bote en la mano, la nevera consume la pulsación
   (paridad `OctopusSpawner`) y no se suelta. En la partida manual no logré apuntar al bote de
   pimentón picante con otro bote caído delante, por eso la parte «de más» del AC2 no se jugó a
   mano. Afecta a la colocación del nivel (fase 8) y quizá a `InteractionScoring`; no lo reproduzco
   como bug de contrato.
2. **Duración de ronda**: `round_config.tres` tiene `duration = 180`, mientras que
   `scene-tree.md` §2 cita «300 s, D5». Uno de los dos está desactualizado.
3. **Colores de caja**: la caja pequeña que da `SmallSpawner` se ve amarilla en el slot, pero el
   cajón más cercano de la estantería se ve verde. Solo es visual.
4. **`tools/verify.sh` analiza `godot/.mcp/`**: los scripts temporales que deja `run_script` del
   MCP (ignorados por git) hacen fallar gdformat/gdlint. Los borré para que pasara; convendría
   excluir `./.mcp/*` en el `find` de `verify.sh`.
