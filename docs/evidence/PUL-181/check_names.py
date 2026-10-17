#!/usr/bin/env python3
"""PUL-181: Verificación estricta de nombres de slots, .glb, mallas, texturas y nodos.

Comprueba que cada nombre de slot, modelo .glb, textura, nodo y malla entre comillas
invertidas citado en la biblia de arte (docs/art/art-bible.md) y en las fichas del
backlog (docs/backlog/PUL-18[2-9]-*.md) existe de verdad en docs/evidence/PUL-181/slots_reales.md
o en godot/ (.tscn, .glb).
"""

from __future__ import annotations

import json
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

PALETTE_TOKENS = {
    "ground_sand", "wall_granite", "meadow_green", "surface_top", "brand_navy", "brand_red",
    "ui_cream", "salt", "octopus_raw", "octopus_cooked", "potato_raw", "cachelos_cooked",
    "state_burnt", "paprika_sweet", "paprika_hot", "p1_blue", "p2_amber", "oil", "cachelos"
}

NODE_PREFIXES = (
    "tent_", "ground_", "back_", "props_", "Anchor_", "SizePanel_",
    "octopus_", "cachelos_"
)

SPECIFIC_NODES = {
    "SweetDressing", "HotDressing", "CachelosBowl", "ServiceMat", "ServiceFascia",
    "Steam", "Bulbs", "Vignette", "Sun", "cartons", "labels", "gas_bottle", "pump",
    "props_board", "props_crock", "OrderPlatePaper", "OrderPlateFrame", "StandNumber",
    "WorldEnvironment", "Environment", "Kitchen", "CameraRig", "HUD", "OrderTicketsPanel",
    "paprika_sweet", "paprika_hot", "OutlineHull", "Counter", "Awning"
}


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


def load_nodes_and_meshes() -> set[str]:
    """Carga todos los nodos y mallas de los 40 .glb, todas las .tscn y slots_reales.md §1."""
    valid_nodes: set[str] = set()

    # 1. glb nodes y meshes
    for glb_path in GODOT_DIR.glob("assets/models/**/*.glb"):
        try:
            with open(glb_path, "rb") as f:
                f.seek(12)
                chunk_len = int.from_bytes(f.read(4), "little")
                f.seek(20)
                data = json.loads(f.read(chunk_len))
                for n in data.get("nodes", []):
                    if "name" in n:
                        valid_nodes.add(n["name"])
                for m in data.get("meshes", []):
                    if "name" in m:
                        valid_nodes.add(m["name"])
        except Exception:
            pass

    # 2. tscn nodes
    for tscn_path in GODOT_DIR.glob("**/*.tscn"):
        content = tscn_path.read_text(encoding="utf-8", errors="ignore")
        for m in re.finditer(r'\[node\s+name="([^"]+)"', content):
            valid_nodes.add(m.group(1))

    # 3. slots_reales.md §1 nodes y meshes
    text = SLOTS_REALES_PATH.read_text(encoding="utf-8")
    sec1_match = re.search(r"## 1\. Inventario.*?\n(.*?)(?:\n---|\n## 2|\Z)", text, re.S)
    if sec1_match:
        for line in sec1_match.group(1).splitlines():
            parts = line.split("|")
            if len(parts) >= 5:
                raw_nodes = parts[4]
                for n in raw_nodes.split(","):
                    n_clean = n.strip().rstrip(".")
                    if n_clean and "..." not in n_clean:
                        valid_nodes.add(n_clean)

    return valid_nodes


def find_in_godot(name: str) -> list[Path]:
    """Busca un archivo o recurso en el árbol godot/."""
    return list(GODOT_DIR.rglob(name))


def is_node_candidate(token: str, real_slots: set[str]) -> bool:
    """Determina si un token entre comillas invertidas representa un nodo o malla."""
    if "*" in token or " " in token or any(c in token for c in ["{", "}", "$", "=", "<", ">", "±", "(", ")"]):
        return False
    if token.startswith("#") or token.startswith("mat_") or token.startswith("env_") or token.startswith("atlas_"):
        return False
    if any(token.endswith(ext) for ext in [".glb", ".import", ".tres", ".png", ".tscn", ".gd", ".svg", ".json", ".md", ".blend", ".ctex"]):
        return False
    if token.startswith("docs/") or token.startswith("godot/") or token.startswith("res://") or token.startswith("tools/"):
        return False
    if token.endswith("/") or "/w" in token or "e/w" in token:
        return False
    if token.startswith("PUL-") or token.startswith("AC") or token in {
        "StandardMaterial3D", "DirectionalLight3D", "WorldEnvironment", "OmniLight3D",
        "GPUParticles3D", "TRANSPARENCY_ALPHA", "SPECULAR_DISABLED", "BG_COLOR",
        "RAW", "COOKED", "BURNT", "DISABLED"
    }:
        return False
    if token in real_slots:
        return False
    if token in PALETTE_TOKENS and token not in {
        "octopus_raw", "octopus_cooked", "octopus_burnt",
        "cachelos_raw", "cachelos_cooked", "cachelos_burnt",
        "paprika_sweet", "paprika_hot"
    }:
        return False

    if token.startswith("%"):
        return True
    if "/" in token:
        first = token.split("/")[0]
        if first in {
            "Model", "BackRight", "WallRight", "BackBetweenStoragePot",
            "WallLeftKitchen", "BackCounter", "Walls", "Floor", "Environment"
        }:
            return True
    if any(token.startswith(p) for p in NODE_PREFIXES):
        return True
    if "Layer" in token or "Fill" in token or "counter" in token:
        return True
    if token in SPECIFIC_NODES:
        return True
    return False


def main() -> int:
    real_slots, glb_slots = load_real_slots()
    valid_nodes = load_nodes_and_meshes()
    all_glb_names = {Path(p).name: p for p in glb_slots}

    print("================================================================================")
    print("PUL-181: Verificación estricta de nombres frente a slots_reales.md y godot/")
    print("================================================================================")
    print(f"Total de slots normativos en slots_reales.md §2: {len(real_slots)}")
    print(f"Total de modelos .glb inventariados en slots_reales.md §1: {len(glb_slots)}")
    print(f"Total de nodos y mallas válidos conocidos: {len(valid_nodes)}")
    print(f"Archivos inspeccionados: {len(CHECKED_FILES)}")
    for f in CHECKED_FILES:
        print(f"  - {f.relative_to(REPO_ROOT)}")
    print("--------------------------------------------------------------------------------\n")

    errors: list[str] = []
    slots_found: dict[str, list[str]] = {}
    glbs_found: dict[str, list[str]] = {}
    textures_found: dict[str, list[str]] = {}
    nodes_found: dict[str, list[str]] = {}

    for doc_file in CHECKED_FILES:
        rel_doc = doc_file.relative_to(REPO_ROOT)
        content = doc_file.read_text(encoding="utf-8")

        tokens = re.findall(r"`([^`]+)`", content)

        for token in tokens:
            if "*" in token or " " in token:
                continue
            if token in {".glb", ".glb.import", ".tres", ".png", ".gd", ".tscn", ".import", ".svg"}:
                continue

            # a) Detección de posibles nombres de slot
            is_slot_candidate = False
            if token in real_slots:
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
                    matches = find_in_godot(base_glb)
                    if not matches:
                        errors.append(
                            f"MODELO INEXISTENTE: `{token}` en {rel_doc} (no existe en slots_reales.md ni en godot/)"
                        )

            # c) Detección de archivos de textura .png citados en arte
            if token.endswith(".png") and ("textures" in token or "models" in token or "tent_plate" in token):
                textures_found.setdefault(token, []).append(str(rel_doc))
                clean_path = token.replace("res://", "godot/").replace("godot/godot/", "godot/")
                if not (REPO_ROOT / clean_path).exists() and not (GODOT_DIR / token).exists():
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

            # d) Detección de nombres de nodo y malla
            if is_node_candidate(token, real_slots):
                clean_node = token.split(".")[0]
                nodes_found.setdefault(clean_node, []).append(str(rel_doc))
                base_node = clean_node.lstrip("%").split("/")[-1]
                if clean_node not in valid_nodes and base_node not in valid_nodes:
                    errors.append(
                        f"NODO O MALLA INEXISTENTE: `{clean_node}` en {rel_doc} (no existe en las escenas .tscn de godot/, los .glb ni slots_reales.md)"
                    )

    # Reporte de Slots verificados
    print("## 1. Slots de material encontrados y verificados:")
    for slot, files in sorted(slots_found.items()):
        status = "OK" if slot in real_slots else "FALLO"
        file_summary = ", ".join(sorted(set(Path(f).name for f in files)))
        print(f"  [{status}] `{slot}` -> {file_summary}")

    print(f"\nTotal slots únicos citados y validados: {len(slots_found)}")

    # Reporte de Modelos .glb verificados
    print("\n## 2. Modelos .glb encontrados y verificados:")
    for glb, files in sorted(glbs_found.items()):
        base_name = Path(glb).name
        status = "OK" if base_name in all_glb_names or find_in_godot(base_name) else "FALLO"
        file_summary = ", ".join(sorted(set(Path(f).name for f in files)))
        print(f"  [{status}] `{glb}` -> {file_summary}")

    print(f"\nTotal modelos .glb únicos citados y validados: {len(glbs_found)}")

    # Reporte de Texturas verificadas
    print("\n## 3. Texturas verificadas:")
    for tex, files in sorted(textures_found.items()):
        clean_path = tex.replace("res://", "godot/")
        exists = (REPO_ROOT / clean_path).exists()
        status = "OK" if exists else "FALLO"
        file_summary = ", ".join(sorted(set(Path(f).name for f in files)))
        print(f"  [{status}] `{tex}` -> {file_summary}")

    print(f"\nTotal texturas únicas citadas y validadas: {len(textures_found)}")

    # Reporte de Nodos y mallas verificados
    print("\n## 4. Nodos y mallas encontrados y verificados:")
    for node, files in sorted(nodes_found.items()):
        base_node = node.lstrip("%").split("/")[-1]
        status = "OK" if (node in valid_nodes or base_node in valid_nodes) else "FALLO"
        file_summary = ", ".join(sorted(set(Path(f).name for f in files)))
        print(f"  [{status}] `{node}` -> {file_summary}")

    print(f"\nTotal nodos y mallas únicos citados y validados: {len(nodes_found)}")

    print("\n--------------------------------------------------------------------------------")
    if errors:
        print(f"RESULTADO: SE ENCONTRARON {len(errors)} ERRORES:")
        for err in sorted(set(errors)):
            print(f"  ✗ {err}")
        return 1
    else:
        print("RESULTADO: TODOS LOS NOMBRES, SLOTS, .GLB, TEXTURAS, NODOS Y MALLAS COINCIDEN AL 100% (0 errores).")
        return 0


if __name__ == "__main__":
    sys.exit(main())
