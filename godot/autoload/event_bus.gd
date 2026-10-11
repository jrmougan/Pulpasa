extends Node
## Bus de eventos global (ADR-002). Solo declara las señales de docs/arch/signals.md §2.
## Sin estado ni lógica: cada señal la emite un único adaptador (columna Emisor del catálogo).
## Cambiar una firma es un cambio de contrato: requiere ADR y gate humano.

# --- Ronda: emisor RoundManager (reenvía RoundState) ---
@warning_ignore("unused_signal")
signal round_started(duration: float)
@warning_ignore("unused_signal")
signal round_time_changed(time_left: float)
@warning_ignore("unused_signal")
signal round_finished(result: RoundResult)
@warning_ignore("unused_signal")
signal score_changed(boxes_delivered: int, revenue: int)
@warning_ignore("unused_signal")
signal phase_changed(phase: int)

# --- Comandas: emisor OrderService (reenvía OrderBoard) ---
@warning_ignore("unused_signal")
signal orders_reset
@warning_ignore("unused_signal")
signal order_generated(order: ActiveOrder)
@warning_ignore("unused_signal")
signal order_completed(order: ActiveOrder, points: int)
@warning_ignore("unused_signal")
signal delivery_rejected(slot_id: int, order_id: int, penalty: int)
@warning_ignore("unused_signal")
signal order_patience_changed(order_id: int, time_left: float, max_time: float)
@warning_ignore("unused_signal")
signal order_expired(order: ActiveOrder, penalty: int)

# --- Interacción (D26): emisor InteractionComponent del personaje que controla `player_index` ---
## `state` es `ActionHint.State` como `int` (0 NONE, 1 OK, 2 BLOCKED).
@warning_ignore("unused_signal")
signal action_hint_changed(player_index: int, verb: StringName, state: int, reason: StringName)
@warning_ignore("unused_signal")
signal interaction_resolved(player_index: int, verb: StringName, state: int, reason: StringName)

# --- Sesión y jugadores: emisores GameState y CharacterSwitcher ---
@warning_ignore("unused_signal")
signal pause_changed(is_paused: bool)
@warning_ignore("unused_signal")
signal character_switched(player_index: int, character_index: int)
@warning_ignore("unused_signal")
signal device_assigned(player_index: int, device: int)
@warning_ignore("unused_signal")
signal device_disconnected(player_index: int)
