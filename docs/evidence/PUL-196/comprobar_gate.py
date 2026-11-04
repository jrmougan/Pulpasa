#!/usr/bin/env python3
"""Evidencia de PUL-196. Ejecutar desde la raíz del repo.

AC1: toda aparición de `propuest|pendiente` en docs/arch (salvo el propio gate) está clasificada.
AC2: toda cita `ruta:línea` de docs/arch/gate-enmiendas.md existe; imprime la línea citada.
Forma: cada fila de la tabla tiene 7 columnas, recomendación válida y, si dice «Sí», alguna cita.
Sale con 1 si algo falla.
"""
import glob
import re
import sys
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8", newline="\n")
GATE = Path("docs/arch/gate-enmiendas.md")
text = GATE.read_text(encoding="utf-8")
fail = 0

print("== AC1: apariciones de propuest|pendiente en docs/arch (sin gate-enmiendas.md)")
table_ac1 = text[text.index("## Apariciones de"):text.index("## Qué no se ha comprobado")]
classified = dict(re.findall(r"^\| `(docs/arch/[^`:]+:\d+)` \| (.+?) \|$", table_ac1, re.M))
hits = []
for name in sorted(glob.glob("docs/arch/*.md")):
    path = Path(name)
    if path == GATE:
        continue
    lines = path.read_text(encoding="utf-8").splitlines()
    for number, line in enumerate(lines, 1):
        if re.search(r"propuest|pendiente", line, re.I):
            hits.append(f"{path.as_posix()}:{number}")
            where = classified.get(hits[-1], "SIN CLASIFICAR")
            if where == "SIN CLASIFICAR":
                fail = 1
            print(f"{hits[-1]} -> {where}")
stale = sorted(set(classified) - set(hits))
for item in stale:
    print(f"SOBRA EN LA TABLA (ya no es una aparición): {item}")
    fail = 1
print(f"apariciones: {len(hits)}; clasificadas: {len(classified)}; sobran: {len(stale)}")

print("\n== Forma de la tabla")
table = text[text.index("## Tabla"):text.index("## Propuesta sobre T3")]
rows = [line for line in table.splitlines() if re.match(r"^\| G\d+ \|", line)]
count = {"aceptar": 0, "aceptar con cambios": 0, "rechazar": 0}
for row in rows:
    cells = [cell.strip() for cell in row.strip("|").split(" | ")]
    if len(cells) != 7:
        print(f"{cells[0]}: {len(cells)} columnas")
        fail = 1
        continue
    verdict = cells[6]
    if verdict.startswith("aceptar con cambios"):
        key = "aceptar con cambios"
    else:
        key = verdict.split(",")[0].split(":")[0]
    if key not in count:
        print(f"{cells[0]}: recomendación no válida: {verdict}")
        fail = 1
    else:
        count[key] += 1
    if cells[4].startswith(("Sí", "Parcial", "Los nodos")) and not re.search(
        r"`godot/[^`]+:\d+`", cells[4]
    ):
        print(f"{cells[0]}: dice implementada sin ruta:línea")
        fail = 1
print(f"filas: {len(rows)}; {count}")

print("\n== AC2: cada cita ruta:línea de la tabla y de la propuesta sobre T3, con su línea")
scope = text[:text.index("## Apariciones de")]
for current in scope.splitlines():
    row = re.match(r"^\| (G\d+) \|", current)
    label = row.group(1) if row else "--"
    for path_text, number_text in re.findall(r"`((?:godot|docs)/[^`:]+):(\d+)`", current):
        path = Path(path_text)
        number = int(number_text)
        if not path.is_file():
            print(f"{label} {path_text}:{number}: NO EXISTE")
            fail = 1
            continue
        lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
        if number > len(lines):
            print(f"{label} {path_text}:{number}: FUERA DE RANGO")
            fail = 1
            continue
        print(f"{label} {path_text}:{number}: {lines[number - 1].strip()[:150]}")
print("\nRESULTADO:", "FALLO" if fail else "OK")
sys.exit(fail)
