extends Node
## Bus de eventos global (ADR-002). Solo declara las señales de docs/arch/signals.md §2.
## Sin estado ni lógica: cada señal la emite un único adaptador (columna Emisor del catálogo).
## Cambiar una firma es un cambio de contrato: requiere ADR y gate humano.

# --- Ronda: emisor RoundManager (reenvía RoundState) ---
@warning_ignore("unused_signal")
signal round_started(duration: float)
@warning_ignore("unused_signal")
signal round_time_changed(time_left: float)
# TODO(PUL-006): RoundResult
@warning_ignore("unused_signal")
signal round_finished(result: RefCounted)
@warning_ignore("unused_signal")
signal score_changed(boxes_delivered: int, revenue: int)

# --- Comandas: emisor OrderService (reenvía OrderBoard) ---
@warning_ignore("unused_signal")
signal orders_reset
# TODO(PUL-006): ActiveOrder
@warning_ignore("unused_signal")
signal order_generated(order: RefCounted)
# TODO(PUL-006): ActiveOrder
@warning_ignore("unused_signal")
signal order_completed(order: RefCounted, points: int)
@warning_ignore("unused_signal")
signal delivery_rejected(slot_id: int, order_id: int, penalty: int)
@warning_ignore("unused_signal")
signal order_patience_changed(order_id: int, time_left: float, max_time: float)
# TODO(PUL-006): ActiveOrder
@warning_ignore("unused_signal")
signal order_expired(order: RefCounted, penalty: int)

# --- Sesión y jugadores: emisores GameState y CharacterSwitcher ---
@warning_ignore("unused_signal")
signal pause_changed(is_paused: bool)
@warning_ignore("unused_signal")
signal character_switched(player_index: int, character_index: int)
@warning_ignore("unused_signal")
signal device_assigned(player_index: int, device: int)
@warning_ignore("unused_signal")
signal device_disconnected(player_index: int)
