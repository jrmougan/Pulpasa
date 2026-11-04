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
print("Excluye tests y sandboxes de desarrollo (ver la sección G05 y G24).")
print("Solo mira la columna de la fila y solo nombres .gd: una nota aparte o un receptor citado por su")
print("nombre de clase salen como falsos positivos (camera_rig.gd, signals.md:101; audio_director.gd,")
print("AudioDirector en la fila de pause_changed).")
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

print("\n== G05 y G24, señales de EventBus usadas desde sandboxes (excluidos arriba)")
sandbox = [p for p in CACHE if p.suffix == ".gd" and "tests" not in p.parts and "sandbox" in str(p)]
for path in sandbox:
    for number, line in enumerate(CACHE[path].splitlines(), 1):
        if re.search(r"EventBus\.[a-z_]+\.(?:emit|connect)", line):
            print(f"{path.as_posix()}:{number}: {line.strip()}")
loaders = sorted(
    p.as_posix()
    for p, content in CACHE.items()
    if "touch_sandbox" in content and "ui/touch/sandbox" not in p.as_posix()
)
print(f"ficheros fuera de ui/touch/sandbox que citan touch_sandbox: {loaders}")

print("\n== G12, G15, G50 y G57, motivos de `rejected` del dispensador: código frente a texto")
dispenser = CACHE[GODOT / "entities/stations/seasoning_dispenser.gd"]
for number, line in enumerate(dispenser.splitlines(), 1):
    if re.search(r"rejected\.emit|Rejection\.(?:ALREADY_APPLIED|BOX_NOT_FULL)", line):
        print(f"seasoning_dispenser.gd:{number}: {line.strip()}")
for path in sorted(Path("docs/arch").glob("*.md")):
    if path.name == "gate-enmiendas.md":
        continue
    for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if re.search(r"ALREADY_APPLIED|solo `?BOX_NOT_FULL|único motivo es `BOX_NOT_FULL", line):
            print(f"{path.as_posix()}:{number}: {line.strip()[:110]}")

print("\n== G16, cuenco con caja vacía o a medias: el fixture por stock")
matrix = (GODOT / "tests/fixtures/action_matrix.csv").read_text(encoding="utf-8").splitlines()
for number, line in enumerate(matrix, 1):
    if re.match(r"E[123]s\d-M[56],", line):
        print(f"action_matrix.csv:{number}: {line}")

print("\n== G17 y G18, interactables de entities/ sin get_action_hint en sus scripts directos")
for path in sorted(p for p in CACHE if p.suffix == ".tscn" and "entities" in p.parts):
    match = re.search(r'\[node [^\n]*groups=\[[^\]]*"interactable"', CACHE[path])
    scripts_of = re.findall(r'path="(res://[^"]+\.gd)"', CACHE[path])
    if match:
        has_hint = any(
            "get_action_hint" in CACHE.get(GODOT / s.removeprefix("res://"), "") for s in scripts_of
        )
        if not has_hint:
            print(f"{path.as_posix()}: {scripts_of}")
users = sorted(p.as_posix() for p, content in CACHE.items() if "sandbox_item" in content)
print(f"ficheros que citan sandbox_item: {users}")

print("\n== G19, cues de las pulsaciones dobles y de dónde sale el hint de _press")
for rel, pattern in [
    ("components/hold_component.gd", r"item_dropped\.emit"),
    ("entities/player/player.gd", r"item_dropped\.connect|play_cue\(&\"drop\"\)"),
    ("entities/stations/trash_bin.gd", r"holder\.drop\(\)|trashed\.emit|play_cue\(CUE_TRASH\)"),
    ("entities/stations/cooking_station.gd", r"holder\.drop\(\)|cooking_started\.emit|&\"cook_start\""),
    ("entities/items/box.gd", r"seasoning_removed\.emit\(result|seasoned\.emit\(result"),
    ("components/interaction_component.gd", r"\.get_hint\(\)|hint_of\(|= _floor_hint\(\)"),
]:
    for number, line in enumerate(CACHE[GODOT / rel].splitlines(), 1):
        if re.search(pattern, line):
            print(f"{rel}:{number}: {line.strip()}")

print("\n== G20, Tween en action_prompt.gd y tipos de action_icon_set.gd")
prompt = CACHE[GODOT / "components/action_prompt.gd"]
print(f"apariciones de tween, sin distinguir mayúsculas: {len(re.findall(r'(?i)tween', prompt))}")
icons = CACHE[GODOT / "resources/action_icon_set.gd"]
types = re.findall(r"@export[^\n]*? var \w+: ([^\s=]+)", icons)
print(f"tipos exportados: {sorted(set(types))}")

print("\n== G14, quién usa el catálogo de paridad de tests/helpers/m0_data")
for path in sorted(p for p in CACHE if p.suffix == ".gd" and "m0_data" in CACHE[p]):
    for number, line in enumerate(CACHE[path].splitlines(), 1):
        if "m0_data" in line:
            print(f"{path.as_posix()}:{number}: {line.strip()}")

print("\n== G25, quién lee PlayerInput, _unhandled_input o _input")
for rel in [
    "entities/player/player.gd",
    "components/interaction_component.gd",
    "entities/player/character_switcher.gd",
    "ui/menus/pause_menu.gd",
]:
    content = CACHE[GODOT / rel]
    print(
        f"{rel}: PlayerInput={len(re.findall(r'\bPlayerInput\b', content))} "
        f"_unhandled_input={len(re.findall(r'func _unhandled_input', content))} "
        f"_input={len(re.findall(r'func _input', content))} "
        f"Input.get_vector={len(re.findall(r'Input\.get_vector\(', content))}"
    )

print("\n== G37, zona de la flecha en el código y en sus tests")
for rel, pattern in [
    ("entities/camera/camera_rig.gd", r"var avoid: Rect2|func _button_zone"),
    ("tests/integration/test_camera_follow.gd", r"func test_arrow_keeps_16px|var zone: Rect2"),
    ("tests/unit/test_camera_follow_math.gd", r"func test_edge_point_avoids|var avoid: Rect2 = Rect2\(1950"),
]:
    for number, line in enumerate(CACHE[GODOT / rel].splitlines(), 1):
        if re.search(pattern, line):
            print(f"{rel}:{number}: {line.strip()}")

print("\n== Residuos: nombres dados de baja en docs/arch (sin el gate); revisar una a una")
RESIDUE = (
    r"toggle_seasoning|swap_exclusive|paprika_swap|toggle_guard|ErrorAudio|season_error|deliver_error"
    r"|%Portions"
)
for path in sorted(Path("docs/arch").glob("*.md")):
    if path.name == "gate-enmiendas.md":
        continue
    for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if re.search(RESIDUE, line):
            print(f"{path.as_posix()}:{number}: {line.strip()[:110]}")
