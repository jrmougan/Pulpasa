"""Parser único del frontmatter de las fichas: lo usan guard_ownership.py y check_owns.py.

Lee listas de una clave en sus dos formas, inline (`owns: [a, b]`) y en bloque (`owns:` seguido de
`- a`), con comentario final o sin él. Lo que no reconoce devuelve una lista vacía: para quien
comprueba `owns` eso significa bloquear, nunca permitir de más.
"""


def _strip_comment(line: str) -> str:
    """Quita el comentario final: un `#` a principio de línea o tras un espacio, fuera de comillas."""
    quote = ""
    prev = " "
    for index, char in enumerate(line):
        if quote:
            if char == quote:
                quote = ""
        elif char in "'\"" and (prev.isspace() or prev in "[,"):
            quote = char
        elif char == "#" and prev.isspace():
            return line[:index]
        prev = char
    return line


def _frontmatter_lines(text: str) -> list[str]:
    # git show no quita el BOM ni todas las lecturas normalizan CRLF: da igual cómo llegue el texto.
    lines = text.removeprefix("\ufeff").replace("\r\n", "\n").replace("\r", "\n").split("\n")
    if lines[0].rstrip() != "---":
        return []
    for index, line in enumerate(lines[1:], start=1):
        if line.rstrip() == "---":
            return lines[1:index]
    return []


def _clean(items: list[str]) -> list[str]:
    values = (item.strip().strip("'\"") for item in items)
    return [value for value in values if value]


def frontmatter_list(text: str, key: str) -> list[str]:
    """Devuelve la lista de `key` en el frontmatter de `text`, o [] si falta o no es una lista."""
    lines = _frontmatter_lines(text)
    prefix = f"{key}:"
    for index, line in enumerate(lines):
        if not line.startswith(prefix):
            continue
        value = _strip_comment(line[len(prefix):]).strip()
        if value:
            is_inline = value.startswith("[") and value.endswith("]")
            return _clean(value[1:-1].split(",")) if is_inline else []
        items: list[str] = []
        for following in lines[index + 1:]:
            entry = _strip_comment(following).strip()
            if not entry:
                continue  # Línea en blanco o solo comentario entre elementos.
            if entry != "-" and not entry.startswith(("- ", "-\t")):
                break
            items.append(entry[1:])
        return _clean(items)
    return []
