#!/usr/bin/env python3
"""Comprueba que una rama de worker solo cambia rutas de `owns`/`touches_scenes` de su ficha.

Uso: tools/check_owns.py <rama> [<base>]
La ficha se deduce del nombre de la rama (…pul-0xx…) y se lee en la versión de la rama.
Sale con 1 y lista las rutas fuera de owns. Complementa al hook guard_ownership.py, que solo
intercepta Edit/Write: esto cubre también cambios hechos desde Bash. Ambos leen la ficha con
tools/card_frontmatter.py. Git se ejecuta en la raíz del repo: vale cualquier directorio de trabajo.
"""
import re
import subprocess
import sys
from pathlib import Path, PurePosixPath

branch = sys.argv[1]
base = sys.argv[2] if len(sys.argv) > 2 else "HEAD"
m = re.search(r"pul-(\d+)", branch, re.I)
if not m:
    print(f"check_owns: {branch} no es una rama de ficha; no se comprueba.")
    sys.exit(0)
task_id = f"PUL-{int(m.group(1)):03d}"

# Tras la salida anterior: una rama sin ficha no depende del módulo. Sin .pyc porque .gitignore no
# cubre __pycache__ y merge_gate.sh exige el árbol limpio.
TOOLS = Path(__file__).resolve().parent
sys.dont_write_bytecode = True
sys.path.insert(0, str(TOOLS))
from card_frontmatter import frontmatter_list  # noqa: E402


def git(*args: str) -> str:
    return subprocess.run(["git", *args], check=True, capture_output=True, text=True,
                          encoding="utf-8", cwd=TOOLS.parent).stdout


cards = [p for p in git("ls-tree", "-r", "--name-only", branch, "docs/backlog/").splitlines()
         if PurePosixPath(p).name.startswith(f"{task_id}-")]
if not cards:
    print(f"check_owns: no encuentro la ficha de {task_id} en {branch}.", file=sys.stderr)
    sys.exit(1)
card = cards[0]
text = git("show", f"{branch}:{card}")

allowed = (frontmatter_list(text, "owns") + frontmatter_list(text, "touches_scenes")
           + [card, f"docs/evidence/{task_id}/**"])
changed = git("diff", "--name-only", f"{base}...{branch}").splitlines()
outside = [f for f in changed
           if not any(PurePosixPath(f).full_match(p) or f == p for p in allowed)]
if outside:
    print(f"check_owns: {branch} cambia rutas fuera de owns de {card}:", file=sys.stderr)
    for f in outside:
        print(f"  - {f}", file=sys.stderr)
    print(f"Rutas permitidas: {', '.join(allowed)}", file=sys.stderr)
    sys.exit(1)
print(f"check_owns: {len(changed)} rutas dentro de owns de {task_id}.")
