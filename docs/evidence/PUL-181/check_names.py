#!/usr/bin/env python3
"""PUL-181: Verificación estricta de nombres de slots, .glb, mallas, texturas y rutas.

Comprueba que cada nombre de slot entre comillas invertidas citado en la biblia de arte
(docs/art/art-bible.md) y en las fichas del backlog (docs/backlog/PUL-18[2-9]-*.md)
existe de verdad en docs/evidence/PUL-181/slots_reales.md o en godot/.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[3]
SLOTS_REALES_PATH = REPO_ROOT / "docs/evidence/PUL-181/slots_reales.md"
DOCS_ART_BIBLE = REPO_ROOT / "docs/art/art-bible.md"
BACKLOG_DIR = REPO_ROOT / "docs/backlog"
GODOT_DIR = REPO_ROOT / "godot"

CHECKED_FILES = [
    DOCS_ART_BIBLE,
    *sorted(BACKLOG_DIR.glob("PUL-18[2-9]-*.md")),
]


def load_real_slots() -> tuple[set[str], dict[str, list[str]]]:
    """Carga los 68 slots reales y el inventario por .glb desde slots_reales.md."""
    if not SLOTS_REALES_PATH.exists():
        print(f"ERROR: No existe {SLOTS_REALES_PATH}", file=sys.stderr)
        sys.exit(1)

    text = SLOTS_REALES_PATH.read_text(encoding="utf-8")

    # Extraer slots de la sección 2 (normativa de 68 slots)
    sec2_match = re.search(r"## 2\. Los 68 slots.*?\n(.*?)(?:\n---|\n## 3|\Z)", text, re.S)
    if not sec2_match:
        print("ERROR: No se encontró la sección 2 en slots_reales.md", file=sys.stderr)
        sys.exit(1)

    sec2_text = sec2_match.group(1)
    slots_sec2 = set(re.findall(r"\|\s*\d+\s*\|\s*`([^`]+)`", sec2_text))

    # Extraer inventario por .glb de la sección 1
    sec1_match = re.search(r"## 1\. Inventario.*?\n(.*?)(?:\n---|\n## 2|\Z)", text, re.S)
    glb_slots: dict[str, list[str]] = {}
    if sec1_match:
        for line in sec1_match.group(1).splitlines():
            m = re.match(r"\|\s*\d+\s*\|\s*`([^`]+\.glb)`\s*\|\s*(.*?)\s*\|", line)
            if m:
                glb_path, raw_slots = m.group(1), m.group(2)
                slots_in_glb = re.findall(r"`([^`]+)`", raw_slots)
                glb_slots[glb_path] = slots_in_glb

    return slots_sec2, glb_slots


def find_in_godot(name: str) -> list[Path]:
    """Busca un archivo o recurso en el árbol godot/."""
    return list(GODOT_DIR.rglob(name))


def main() -> int:
    real_slots, glb_slots = load_real_slots()
    all_glb_names = {Path(p).name: p for p in glb_slots}

    print("================================================================================")
    print("PUL-181: Verificación estricta de nombres frente a slots_reales.md y godot/")
    print("================================================================================")
    print(f"Total de slots normativos en slots_reales.md §2: {len(real_slots)}")
    print(f"Total de modelos .glb inventariados en slots_reales.md §1: {len(glb_slots)}")
    print(f"Archivos inspeccionados: {len(CHECKED_FILES)}")
    for f in CHECKED_FILES:
        print(f"  - {f.relative_to(REPO_ROOT)}")
    print("--------------------------------------------------------------------------------\n")

    # Tokens que representan slots aunque no lleven prefijo
    known_slots = set(real_slots) | {
        "counters_atlas",
        "counter_pass_signs",
        "delivery_zone_off",
        "kiosk_delivery_signs",
        "order_stand_atlas",
        "pot_water",
        "seasoning_signs",
        "seasoning_station_atlas",
    }

    errors: list[str] = []
    slots_found: dict[str, list[str]] = {}
    glbs_found: dict[str, list[str]] = {}
    textures_found: dict[str, list[str]] = {}

    for doc_file in CHECKED_FILES:
        rel_doc = doc_file.relative_to(REPO_ROOT)
        content = doc_file.read_text(encoding="utf-8")

        # 1. Buscar todos los tokens en comillas invertidas
        tokens = re.findall(r"`([^`]+)`", content)

        for token in tokens:
            # Descartar comodines, expresiones regulares o extensiones genéricas
            if "*" in token or " " in token:
                continue
            if token in {".glb", ".glb.import", ".tres", ".png", ".gd", ".tscn", ".import", ".svg"}:
                continue

            # a) Detección de posibles nombres de slot
            is_slot_candidate = False
            if token in known_slots:
                is_slot_candidate = True
            elif (
                (token.startswith("mat_") or token.startswith("env_") or token.startswith("atlas_"))
                and not token.endswith(".tres")
                and not token.endswith(".gd")
                and not token.endswith(".png")
                and not token.endswith(".tscn")
                and "/" not in token
            ):
                is_slot_candidate = True

            if is_slot_candidate:
                slots_found.setdefault(token, []).append(str(rel_doc))
                if token not in real_slots:
                    errors.append(
                        f"SLOT INEXISTENTE: `{token}` en {rel_doc} (no existe en slots_reales.md §2)"
                    )

            # b) Detección de archivos .glb
            if token.endswith(".glb") or token.endswith(".glb.import"):
                clean_glb = token.replace(".import", "")
                base_glb = Path(clean_glb).name
                glbs_found.setdefault(clean_glb, []).append(str(rel_doc))
                if base_glb not in all_glb_names:
                    # Comprobar si existe físicamente en godot/
                    matches = find_in_godot(base_glb)
                    if not matches:
                        errors.append(
                            f"MODELO INEXISTENTE: `{token}` en {rel_doc} (no existe en slots_reales.md ni en godot/)"
                        )

            # c) Detección de archivos de textura .png citados en arte
            if token.endswith(".png") and ("textures" in token or "models" in token or "tent_plate" in token):
                textures_found.setdefault(token, []).append(str(rel_doc))
                # Verificar ruta real
                clean_path = token.replace("res://", "godot/").replace("godot/godot/", "godot/")
                if not (REPO_ROOT / clean_path).exists() and not (GODOT_DIR / token).exists():
                    # Buscar por nombre base
                    base_name = Path(token).name
                    matches = find_in_godot(base_name)
                    if not matches:
                        errors.append(
                            f"TEXTURA INEXISTENTE: `{token}` en {rel_doc} (no existe en el disco)"
                        )
                    else:
                        real_p = matches[0].relative_to(REPO_ROOT)
                        errors.append(
                            f"RUTA DE TEXTURA ERRÓNEA: `{token}` en {rel_doc} (la ruta real en disco es {real_p})"
                        )

    # Reporte de Slots verificados
    print("## 1. Slots de material encontrados y verificados:")
    for slot, files in sorted(slots_found.items()):
        status = "OK" if slot in real_slots else "FALLO"
        file_summary = ", ".join(Path(f).name for f in set(files))
        print(f"  [{status}] `{slot}` -> {file_summary}")

    print(f"\nTotal slots únicos citados y validados: {len(slots_found)}")

    # Reporte de Modelos .glb verificados
    print("\n## 2. Modelos .glb encontrados y verificados:")
    for glb, files in sorted(glbs_found.items()):
        base_name = Path(glb).name
        status = "OK" if base_name in all_glb_names or find_in_godot(base_name) else "FALLO"
        file_summary = ", ".join(Path(f).name for f in set(files))
        print(f"  [{status}] `{glb}` -> {file_summary}")

    # Reporte de Texturas verificadas
    print("\n## 3. Texturas verificadas:")
    for tex, files in sorted(textures_found.items()):
        clean_path = tex.replace("res://", "godot/")
        exists = (REPO_ROOT / clean_path).exists()
        status = "OK" if exists else "FALLO"
        file_summary = ", ".join(Path(f).name for f in set(files))
        print(f"  [{status}] `{tex}` -> {file_summary}")

    print("\n--------------------------------------------------------------------------------")
    if errors:
        print(f"RESULTADO: SE ENCONTRARON {len(errors)} ERRORES:")
        for err in errors:
            print(f"  ✗ {err}")
        return 1
    else:
        print("RESULTADO: TODOS LOS NOMBRES, SLOTS, .GLB Y RUTAS COINCIDEN AL 100% (0 errores).")
        return 0


if __name__ == "__main__":
    sys.exit(main())
