#!/usr/bin/env python3
"""Comprueba que AGENTS.md y CLAUDE.md son ficheros normales con el mismo texto.

Uso: tools/check_agents_sync.py
Son dos copias a propósito: un `@AGENTS.md` en CLAUDE.md no se expande en una sesión de Claude Code
arrancada en un subdirectorio, y esta se queda sin las reglas y sin ningún error (docs/evidence/PUL-192/).
Solo se normalizan los finales de línea. Sale con 1 y dice qué falla. Vale cualquier directorio de trabajo.
Los mensajes van sin acentos: en Windows la consola puede no poder codificarlos.
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
FIRST, SECOND = "AGENTS.md", "CLAUDE.md"


def read_normalized(name: str) -> tuple[bytes | None, str]:
    """Devuelve (texto con LF, ""), o (None, motivo) si no es un fichero normal legible."""
    path = ROOT / name
    if path.is_symlink():
        return None, f"{name} es un symlink: debe ser un fichero normal"
    if not path.is_file():
        return None, f"falta {name}"
    try:
        return path.read_bytes().replace(b"\r\n", b"\n").replace(b"\r", b"\n"), ""
    except OSError as error:
        return None, f"no puedo leer {name}: {error.strerror}"


def first_difference(first: bytes, second: bytes) -> int:
    """Número de línea, desde 1, de la primera diferencia entre dos textos distintos."""
    first_lines, second_lines = first.split(b"\n"), second.split(b"\n")
    for number, (line_a, line_b) in enumerate(zip(first_lines, second_lines), start=1):
        if line_a != line_b:
            return number
    return min(len(first_lines), len(second_lines)) + 1


def main() -> int:
    first, first_error = read_normalized(FIRST)
    second, second_error = read_normalized(SECOND)
    errors = [error for error in (first_error, second_error) if error]
    if errors:
        for error in errors:
            print(f"check_agents_sync: {error}.", file=sys.stderr)
        return 1
    if first != second:
        print(f"check_agents_sync: {FIRST} y {SECOND} difieren, primera diferencia en L"
              f"{first_difference(first, second)}. Deben ser identicos: copia el cambio al otro.",
              file=sys.stderr)
        return 1
    print(f"check_agents_sync: {FIRST} y {SECOND} coinciden.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
