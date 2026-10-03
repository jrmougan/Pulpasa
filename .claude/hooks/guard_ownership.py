#!/usr/bin/env python3
"""PreToolUse (Edit|Write|MultiEdit): solo permite editar rutas declaradas en la ficha activa.

La ficha activa se indica en .claude/current-task (una línea: PUL-xxx). Sin ese fichero
(sesión normal o del producer) no se restringe nada. Siempre se permite editar la propia
ficha y docs/evidence/<id>/.
"""
import json
import os
import re
import sys
from pathlib import Path, PurePosixPath

root = Path(os.environ.get("CLAUDE_PROJECT_DIR", ".")).resolve()
marker = root / ".claude" / "current-task"
if not marker.exists():
    sys.exit(0)

task_id = marker.read_text().strip()
if not task_id:
    sys.exit(0)

data = json.load(sys.stdin)
target = data.get("tool_input", {}).get("file_path")
if not target:
    sys.exit(0)
try:
    rel = PurePosixPath(Path(target).resolve().relative_to(root).as_posix())
except ValueError:
    print(f"Bloqueado: {target} está fuera del repositorio.", file=sys.stderr)
    sys.exit(2)

cards = sorted((root / "docs" / "backlog").glob(f"{task_id}-*.md"))
if not cards:
    print(f"Bloqueado: no encuentro la ficha docs/backlog/{task_id}-*.md.", file=sys.stderr)
    sys.exit(2)
card = cards[0]


def frontmatter_list(text: str, key: str) -> list[str]:
    m = re.match(r"^---\n(.*?)\n---", text, re.S)
    if not m:
        return []
    fm = m.group(1)
    inline = re.search(rf"^{key}:\s*\[(.*?)\]\s*$", fm, re.M)
    if inline:
        return [v.strip().strip("'\"") for v in inline.group(1).split(",") if v.strip()]
    block = re.search(rf"^{key}:\s*\n((?:\s+-\s+.*\n?)+)", fm, re.M)
    if block:
        return [l.split("-", 1)[1].strip().strip("'\"") for l in block.group(1).splitlines() if l.strip()]
    return []


text = card.read_text()
allowed = frontmatter_list(text, "owns") + frontmatter_list(text, "touches_scenes")
allowed += [card.relative_to(root).as_posix(), f"docs/evidence/{task_id}/**", ".claude/current-task"]

for pattern in allowed:
    if rel.full_match(pattern) or rel.as_posix() == pattern:
        sys.exit(0)

print(
    f"Bloqueado: {rel} no está en `owns` ni `touches_scenes` de {card.name}.\n"
    f"Rutas permitidas: {', '.join(allowed)}\n"
    "Si necesitas tocarlo, pregunta al coordinador (orca ask) en vez de editarlo.",
    file=sys.stderr,
)
sys.exit(2)
