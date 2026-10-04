# PUL-030 — Recaudación, estrellas, iconos y paciencia en la UI

## Qué se hizo
- **HUD** (`ui/hud/hud.{gd,tscn}`): nueva sección «Recaudación» con `%RevenueTitle`/`%Revenue`.
  Empieza en `0 €`, se actualiza al recibir `score_changed` (inmediato, ≤ 0,2 s) y nunca baja
  de 0 (`maxi(revenue, 0)`). El panel crece de 132 a 180 px para las tres secciones.
- **Tickets** (`ui/tickets/ticket_entry.{gd,tscn}`): el texto de condimentos se sustituye por
  `%SeasoningIcons`, una fila con un `TextureRect` por condimento usando `SeasoningData.icon`
  (tooltip con el nombre traducido). `%PatienceBar` sigue gobernada solo por
  `order_patience_changed`; se le fija `step = 0.01` para que decrezca de forma lineal con
  valores float (el `step` 1.0 por defecto de `Range` redondeaba a enteros).
- **Game over** (`ui/menus/game_over.{gd,tscn}`): `%Revenue` («Recaudación: %d €») y `%Stars`
  con 3 `TextureRect` (`star_full`/`star_empty` de PUL-031) según `RoundResult.stars` (0–3),
  añadidos como hijos del `Content` del `MenuPanel` instanciado.
- **Datos** (`data/seasonings/*.tres`): asignado `icon` a los cinco condimentos
  (sal→salt, aceite→oil, cachelos→potato, pimentón y pimentón picante→pepper-hot-solid;
  PUL-031 no trajo un icono de pimentón dulce distinto). `owns` de la ficha ampliado con
  `godot/data/seasonings/*.tres`, como prevé la propia ficha.

Sin contadores propios en la UI: todo llega por señales de `EventBus`. Navegación `ui_*` y
`tr()` intactos; textos nuevos con claves `HUD_REVENUE*` y fallback en castellano.

## Capturas (AC2)
Generadas con `godot/ui/hud/capture_pul030.{gd,tscn}`:
`xvfb-run -a godot --path godot res://ui/hud/capture_pul030.tscn`
(ronda real con el catálogo y `RoundManager`, una entrega correcta y `board.advance(15.0)`).

- `partida_hud_y_tickets.png`: vista completa — HUD con «Recaudación 11 €» tras una entrega y
  4 tickets con iconos y barras de paciencia decrecientes.
- `hud_recaudacion.png`: detalle del HUD.
- `ticket_iconos_y_paciencia.png`: detalle de un ticket (iconos de pimentón picante y sal,
  barra al ~75 %).
- `game_over_estrellas.png`: «Recaudación: 65 €» con 2 de 3 estrellas (umbrales 30/60/90).

## Tests (AC1)
- `test_hud.gd`: `test_ac9_revenue_starts_at_zero_euros`,
  `test_ac10_delivery_updates_revenue_on_the_signal`,
  `test_ac11_expiry_subtracts_revenue_but_never_below_zero`.
- `test_order_tickets.gd`: `test_ac4_ticket_shows_one_icon_per_seasoning`,
  `test_ac4_patience_bar_is_visible_and_decreases_linearly` (AC3 de texto rehecho para iconos).
- `test_game_over.gd`: `test_ac2_partida5min_game_over_shows_revenue_and_stars`,
  `test_ac2_partida5min_stars_cover_zero_to_three`.

## Comprobaciones (AC3)
- `tools/verify.sh` en verde (gdformat, gdlint, import, 425 tests GUT, smoke).
- `tools/check_owns.py jrmougan/pul-030 jrmougan/agentica-migracion-godot-alpha` limpio.
