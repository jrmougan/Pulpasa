#!/usr/bin/env python3
"""PUL-205: comprueba que cada `ruta:línea` de ac1-frases.md contiene lo que esa frase afirma.

Uso, desde la raíz del repo: python3 docs/evidence/PUL-205/comprobar_citas.py
Solo prueba que la línea citada es la correcta; el comportamiento se lee en el código o en los tests.
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
CITES = [
    ("godot/components/interaction_component.gd", 79, 'target.call(&"interact", self)'),
    ("godot/components/interaction_component.gd", 88, "Objetivo heredado (sin verbo)"),
    ("godot/components/interaction_component.gd", 93, "elif target != null:"),
    ("godot/components/interaction_component.gd", 99, "else:"),
    ("godot/core/action_rules.gd", 34, "Held.OCTOPUS_RAW:"),
    ("godot/core/action_rules.gd", 38, "Held.OCTOPUS_COOKED:"),
    ("godot/core/action_rules.gd", 42, "return ActionHint.none()"),
    ("godot/core/action_rules.gd", 68, "static func for_spawner"),
    ("godot/core/action_rules.gd", 88, "return ActionHint.none()"),
    ("godot/core/action_rules.gd", 110, "return ActionHint.none()"),
    ("godot/core/action_rules.gd", 124, "if can_drop:"),
    ("godot/components/interaction_detector.gd", 104, "entity is Slot and"),
    ("godot/components/interaction_detector.gd", 110, "if not hint.is_target():"),
    ("godot/entities/stations/seasoning_dispenser.gd", 42, "func is_reachable_from(floor_position: Vector2, _holder: Holder)"),
    ("godot/entities/stations/seasoning_dispenser.gd", 56, "func can_interact"),
    ("godot/entities/stations/cachelos_bowl.gd", 67, "func can_interact"),
    ("godot/entities/stations/slot.gd", 118, "return ActionRules.for_pass_slot("),
    ("godot/tests/integration/test_slot.gd", 248, "test_pul058_accepted_group_rejects_other_items_without_being_a_target"),
    ("godot/entities/items/box.gd", 121, "if hint.state != ActionHint.State.OK:"),
    ("godot/entities/items/box.gd", 122, "return hint.state == ActionHint.State.BLOCKED"),
    ("godot/tests/integration/test_trash_bin.gd", 291, "test_t6_trash_bins_are_far_from_every_target_and_the_gap"),
    ("godot/tests/integration/test_trash_bin.gd", 303, 'level.find_children("*", "OrderStand", true, false)'),
    ("godot/tests/integration/test_trash_bin.gd", 324, "assert_gte(gap, TRASH_MIN_DISTANCE"),
    ("godot/tests/integration/test_trash_bin.gd", 327, "al hueco"),
    ("godot/tests/integration/test_trash_bin.gd", 330, "test_t6_gap_keeps_one_meter_clear_and_bins_not_under_hud"),
    ("godot/tests/integration/test_level_01.gd", 33, '"Stations/TrashBinKitchen"'),
    ("godot/entities/stations/order_stand.gd", 65, "order_patience_changed.connect(_on_order_patience_changed)"),
    ("godot/entities/stations/order_stand.gd", 154, "_service.try_deliver(slot_id, box.get_contents())"),
    ("godot/entities/stations/order_stand.gd", 156, "holder.drop()"),
    ("godot/entities/stations/order_stand.gd", 161, "_blocked_by_expiry()"),
    ("godot/entities/stations/order_stand.gd", 167, "func _blocked_by_expiry()"),
    ("godot/entities/stations/order_stand.gd", 170, "_order.max_time > 0.0"),
    ("godot/entities/stations/order_stand.gd", 221, "func _on_order_patience_changed"),
    ("godot/core/order_board.gd", 122, "_expired_this_tick.clear()"),
    ("godot/core/order_board.gd", 133, "order_patience_changed.emit"),
    ("godot/core/order_board.gd", 138, "order_expired.emit"),
    ("godot/core/order_board.gd", 150, "delivery_rejected.emit"),
    ("godot/core/order_board.gd", 154, "delivery_rejected.emit"),
    ("godot/core/order_board.gd", 157, "delivery_rejected.emit"),
    ("godot/core/order_board.gd", 160, "delivery_rejected.emit"),
    ("godot/autoload/order_service.gd", 96, "delivery_rejected.emit"),
    ("godot/autoload/round_manager.gd", 77, "func _physics_process"),
]

failed = 0
for rel, line, token in CITES:
    text = (ROOT / rel).read_text(encoding="utf-8").splitlines()[line - 1]
    ok = token in text
    failed += not ok
    print(f"{'ok ' if ok else 'MAL'} {rel}:{line}  {text.strip()[:90]}")
print(f"{len(CITES) - failed}/{len(CITES)} citas correctas")
sys.exit(1 if failed else 0)
