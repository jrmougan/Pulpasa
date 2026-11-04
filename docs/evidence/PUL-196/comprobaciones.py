#!/usr/bin/env python3
"""Comprobaciones negativas y de receptores que cita docs/arch/gate-enmiendas.md (PUL-196).

Ejecutar desde la raíz del repo. Solo lee ficheros; no escribe nada.
"""
import re
import sys
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8", newline="\n")
GODOT = Path("godot")
TEXT = {".gd", ".tscn", ".tres", ".godot", ".cfg"}
FILES = [
    p
    for p in GODOT.rglob("*")
    if p.is_file()
    and p.suffix in TEXT
    and "addons" not in p.parts
    and ".godot" not in p.parts
    and ".mcp" not in p.parts
]
CACHE = {p: p.read_text(encoding="utf-8", errors="replace") for p in FILES}


def count(pattern: str, only_tests: bool | None = None) -> int:
    total = 0
    for path, text in CACHE.items():
        if only_tests is not None and ("tests" in path.parts) != only_tests:
            continue
        total += len(re.findall(pattern, text))
    return total


print("== G10, bajas de ADR-003 §8.4: rutas que no deben existir")
for name in [
    "entities/stations/spice_shelf.tscn",
    "entities/items/seasoning.tscn",
    "entities/items/seasoning_item.gd",
    "assets/models/placeholders/condiment_jar.tscn",
]:
    print(f"{name}: {'EXISTE' if (GODOT / name).exists() else 'no existe'}")
print(f"Tray o get_box fuera de tests: {count(r'\bTray\b|get_box\(|get_tray\(', False)}")
print(f"initial_item_data fuera de tests: {count(r'initial_item_data', False)}")

print("\n== Apariciones fuera de tests de nombres que los contratos dan de baja")
for name in [
    "set_new_order_max_time",
    "toggle_seasoning",
    "swap_exclusive",
    "paprika_swap",
    "toggle_guard",
    "button_zone_top_px",
    "cook_done",
    "season_error",
    "deliver_error",
    "short_label",
    "UiScale.factor",
]:
    print(f"{name}: {count(re.escape(name), False)}")

print("\n== G25, eventos táctiles en project.godot")
project = (GODOT / "project.godot").read_text(encoding="utf-8")
print(f"InputEventScreenTouch o InputEventScreenDrag: {len(re.findall(r'InputEventScreen', project))}")

print("\n== G31, factor en ui_scale.gd")
scale = (GODOT / "ui/widgets/ui_scale.gd").read_text(encoding="utf-8")
print(f"factor o MAX_FACTOR: {len(re.findall(r'factor|MAX_FACTOR', scale))}")

print("\n== G35, tipos de mundo en la capa común de E6")
for name in [
    "core/platform_profile.gd",
    "resources/ui_profile.gd",
    "ui/widgets/ui_scale.gd",
    "ui/widgets/safe_area_margin.gd",
    "resources/camera_profile.gd",
    "core/camera_follow.gd",
]:
    lines = (GODOT / name).read_text(encoding="utf-8").splitlines()
    found = [
        f"{number}: {line.strip()}"
        for number, line in enumerate(lines, 1)
        if re.search(r"Node3D|Node2D|Vector3|Camera3D|Camera2D", line)
    ]
    print(f"{name}: {found if found else 'ninguno'}")

print("\n== G46, señales de EventBus: catálogo de signals.md §2 frente a connect/emit en el código")
signals = Path("docs/arch/signals.md").read_text(encoding="utf-8")
section = signals[signals.index("## 2. Señales de `EventBus`"):signals.index("## 3.")]
rows: dict[str, str] = {}
for line in section.splitlines():
    match = re.match(r"\| `([a-z_]+)(?:\(|`)", line)
    if match:
        rows[match.group(1)] = line.split("|")[3]
bus = (GODOT / "autoload/event_bus.gd").read_text(encoding="utf-8")
declared = re.findall(r"^signal ([a-z_]+)", bus, re.M)
print(f"en el catálogo y no en el código: {sorted(set(rows) - set(declared))}")
print(f"en el código y no en el catálogo: {sorted(set(declared) - set(rows))}")
scripts = [
    p
    for p in CACHE
    if p.suffix == ".gd" and "tests" not in p.parts and "sandbox" not in str(p)
]
for signal in declared:
    pattern = r"(?:EventBus|_bus|_get_bus\(\)|bus)\.%s\.%s"
    connected = {p.name for p in scripts if re.search(pattern % (signal, "connect"), CACHE[p])}
    emitted = sorted(p.name for p in scripts if re.search(pattern % (signal, "emit"), CACHE[p]))
    listed = set(re.findall(r"[a-z_]+\.gd", rows.get(signal, "")))
    print(
        f"{signal}: emite={emitted} "
        f"conecta_sin_estar_en_la_fila={sorted(connected - listed)} "
        f"en_la_fila_sin_conectar={sorted(listed - connected)}"
    )
