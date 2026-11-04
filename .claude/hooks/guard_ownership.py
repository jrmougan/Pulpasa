#!/usr/bin/env python3
"""PreToolUse (Edit|Write|MultiEdit): solo permite editar rutas declaradas en la ficha activa.

La ficha activa se indica en .claude/current-task (una línea: PUL-xxx). Sin ese fichero
(sesión normal o del producer) no se restringe nada. Siempre se permite editar la propia
ficha y docs/evidence/<id>/.

Claude Code solo trata como bloqueo el código de salida 2: cualquier otro deja pasar la edición.
Por eso toda excepción inesperada sale con 2, igual que una entrada sin `file_path` de texto (las
tres herramientas lo llevan), y todo el texto se lee en UTF-8 de forma explícita (en Windows, la
codificación por defecto es cp1252 y no sirve para las fichas). Se admite BOM (`utf-8-sig`): lo
escriben herramientas de Windows y es invisible en los mensajes.

El parser de fichas es tools/card_frontmatter.py, compartido con tools/check_owns.py. Se importa con
ficha activa y no antes: sin ficha el hook no lo necesita, y si no se puede importar, bloquea.
"""
import json
import os
import sys
from pathlib import Path, PurePosixPath

HOOK_REPO = Path(__file__).resolve().parents[2]


def main() -> int:
    root = Path(os.environ.get("CLAUDE_PROJECT_DIR") or HOOK_REPO).resolve()
    marker = root / ".claude" / "current-task"
    if not marker.exists():
        return 0

    # Después del marcador: sin ficha activa, un stderr cerrado (None) no puede bloquear nada.
    if sys.stderr:
        sys.stderr.reconfigure(encoding="utf-8", errors="backslashreplace")

    task_id = marker.read_text(encoding="utf-8-sig").strip()
    if not task_id:
        return 0

    # Sin .pyc: .gitignore no cubre __pycache__, y merge_gate.sh exige el árbol limpio.
    sys.dont_write_bytecode = True
    sys.path.insert(0, str(HOOK_REPO / "tools"))
    from card_frontmatter import frontmatter_list

    data = json.loads(sys.stdin.buffer.read().decode("utf-8"))
    target = data.get("tool_input", {}).get("file_path")
    if not isinstance(target, str) or not target:
        print("Bloqueado: entrada sin file_path válido.", file=sys.stderr)
        return 2
    resolved = Path(target).resolve()
    try:
        rel = PurePosixPath(resolved.relative_to(root).as_posix())
    except ValueError:
        print(f"Bloqueado: {target} está fuera del repositorio.", file=sys.stderr)
        return 2

    cards = sorted((root / "docs" / "backlog").glob(f"{task_id}-*.md"))
    if not cards:
        print(f"Bloqueado: no encuentro la ficha docs/backlog/{task_id}-*.md.", file=sys.stderr)
        return 2
    card = cards[0]

    text = card.read_text(encoding="utf-8-sig")
    allowed = frontmatter_list(text, "owns") + frontmatter_list(text, "touches_scenes")
    allowed += [card.relative_to(root).as_posix(), f"docs/evidence/{task_id}/**", ".claude/current-task"]

    for pattern in allowed:
        if rel.full_match(pattern) or rel.as_posix() == pattern:
            return 0

    print(
        f"Bloqueado: {rel} no está en `owns` ni `touches_scenes` de {card.name}.\n"
        f"Rutas permitidas: {', '.join(allowed)}\n"
        "Si necesitas tocarlo, pregunta al coordinador (`orchestration ask`, con el binario de Orca "
        "que indica CLAUDE.md) en vez de editarlo.",
        file=sys.stderr,
    )
    return 2


if __name__ == "__main__":
    try:
        status = main()
    except BaseException as exc:  # También SystemExit: el módulo importado no decide la salida.
        status = 2
        try:
            print(
                f"Bloqueado: guard_ownership no ha podido comprobar `owns` ({type(exc).__name__}: {exc}).\n"
                "Revisa la ficha activa, .claude/current-task y la entrada del hook, "
                "o pregunta al coordinador (`orchestration ask`).",
                file=sys.stderr,
            )
        except Exception:
            pass  # Sin stderr no hay mensaje, pero el bloqueo se mantiene.
    sys.exit(status)
