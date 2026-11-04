# PUL-203 AC1: línea editada contra su fuente

| Línea editada | Qué dice ahora | Fuente que lo respalda |
|---|---|---|
| `docs/design/features/corte-pulpo.md:19` | `presses_to_fill` = 6 deja de ser provisional (G11, 2026-11-04) | `docs/design/decisions.md:29` (D25 (1)); `docs/arch/gate-enmiendas.md:123` (G11); `docs/evidence/PUL-197/ac1-filas.md:17` |
| `docs/design/features/corte-pulpo.md:68` | Pregunta 1 respondida: 6 definitivo; sigue siendo un dato de `box.tres` | `docs/design/decisions.md:29`; `docs/backlog/PUL-197-aplicar-gate-enmiendas.md:19` |
| `docs/design/gdd.md:155` | 6 deja de ser provisional (G11) | `docs/design/decisions.md:29` |
| `docs/design/gdd.md:187` | Solo los precios de las 4 recetas siguen provisionales | `docs/design/decisions.md:29` (los precios no se tocan) |
| `docs/design/gdd.md:185` | Sin cambios: valores de fases siguen provisionales | `docs/backlog/PUL-203-alinear-diseno-gate.md` (Change) |
| `docs/design/features/audio-y-fx.md:12` (AC5) | Sin «entrega errónea» en la lista; ya no suena ni se ve | `docs/arch/signals.md:296`; `docs/arch/ADR-006-audio-feedback.md:176` y `:206` (`deliver_error` sustituido / histórico) |
| `docs/design/features/entrega-y-puntuacion.md:54` (AC5d, Test) | Cita `test_pul198_entry_after_expiry_tick_before_advance_does_not_reject` y `test_pul198_entry_after_the_advance_delivers_replacement`; ya no `_assert_expiry_tick` | `godot/tests/integration/test_order_stand.gd:280` y `:297`; `_assert_expiry_tick` (`:235`) comprueba que la zona no entrega ni rechaza |
| `docs/design/features/cubo-basura.md:37` (T6) y `:56` | Cita `test_t6_level_has_exactly_two_trash_bins_at_contract_positions`, `test_t6_trash_bins_are_far_from_every_target_and_the_gap` y `test_t6_gap_keeps_one_meter_clear_and_bins_not_under_hud` | `godot/tests/integration/test_trash_bin.gd:272`, `:291` (PUL-202 en `:300`), `:330`; `TRASH_MIN_DISTANCE` = 1.5 (`:17`) |
| `docs/backlog/PUL-066-contratos-m3.md` (Evidence, última viñeta) | Respuesta a R2 registrada | `docs/arch/gate-enmiendas.md:11` y `:157`; `docs/backlog/PUL-197-aplicar-gate-enmiendas.md:21`; `docs/arch/signals.md:307-308` |
