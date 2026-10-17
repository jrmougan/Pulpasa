#!/usr/bin/env python3
"""Genera las tablas de contraste WCAG (§3.4, paletas y estados) y la comprobación visual anotada para PUL-180."""

from __future__ import annotations

import json
import math
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

EVIDENCE_DIR = Path(__file__).resolve().parent


def srgb_to_linear(c: float) -> float:
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def rel_luminance(hex_color: str) -> float:
    h = hex_color.lstrip("#")
    r, g, b = (int(h[i : i + 2], 16) / 255.0 for i in (0, 2, 4))
    return 0.2126 * srgb_to_linear(r) + 0.7152 * srgb_to_linear(g) + 0.0722 * srgb_to_linear(b)


def contrast_ratio(hex1: str, hex2: str) -> float:
    l1, l2 = rel_luminance(hex1), rel_luminance(hex2)
    bright, dark = max(l1, l2), min(l1, l2)
    return (bright + 0.05) / (dark + 0.05)


SEC34_COLORS = [
    ("paprika_sweet", "Pimentón dulce", "#D6361F", "Círculo"),
    ("paprika_hot", "Pimentón picante", "#8F1A14", "Octógono"),
    ("salt", "Sal gruesa", "#F7F4EC", "Cuadrado"),
    ("oil", "Aceite de oliva", "#F2C230", "Gota"),
    ("cachelos", "Cachelos", "#F2D56B", "Óvalo"),
]

DIRECTION_SURFACES = {
    "Dirección A · «Feira Clara» (`direccion-a-color-plano.md`)": {
        "pairs": [
            ("paprika_sweet", "Encimera / interior de caja (`surface_top`)", "#EDE8DF", True),
            ("paprika_hot", "Encimera / interior de caja (`surface_top`)", "#EDE8DF", True),
            ("salt", "Cuenco / pastilla HUD / zócalo (`brand_navy`)", "#1D3557", True),
            ("salt", "Anillo `StickerInk` / pozo oscuro (`state_burnt`)", "#2A2320", False),
            ("salt", "Pulpo cocido en caja (`octopus_cooked`)", "#B8283D", False),
            ("oil", "Cuenco / pastilla HUD / zócalo (`brand_navy`)", "#1D3557", True),
            ("oil", "Anillo `StickerInk` / pozo oscuro (`state_burnt`)", "#2A2320", False),
            ("oil", "Pulpo cocido en caja (`octopus_cooked`)", "#B8283D", False),
            ("cachelos", "Cuenco / pastilla HUD / zócalo (`brand_navy`)", "#1D3557", True),
            ("cachelos", "Cuenco de barro (`potato_raw`)", "#8E6B47", False),
            ("cachelos", "Pulpo cocido en caja (`octopus_cooked`)", "#B8283D", False),
        ],
    },
    "Dirección B · «Bloques de Romería» (`direccion-b-geometrica.md`)": {
        "pairs": [
            ("paprika_sweet", "Losa de piedra / interior de caja (`surf_stone_block`)", "#EFECE6", True),
            ("paprika_hot", "Losa de piedra / interior de caja (`surf_stone_block`)", "#EFECE6", True),
            ("salt", "Cuenco / pastilla HUD (`play_box_navy`)", "#1D3557", True),
            ("salt", "Vacío / soporte oscuro (`bg_void_navy`)", "#18222C", True),
            ("salt", "Pulpo cocido en caja (`state_octopus_cooked`)", "#B8283D", False),
            ("oil", "Cuenco / pastilla HUD (`play_box_navy`)", "#1D3557", True),
            ("oil", "Vacío / soporte oscuro (`bg_void_navy`)", "#18222C", True),
            ("oil", "Pulpo cocido en caja (`state_octopus_cooked`)", "#B8283D", False),
            ("cachelos", "Cuenco / pastilla HUD (`play_box_navy`)", "#1D3557", True),
            ("cachelos", "Vacío / soporte oscuro (`bg_void_navy`)", "#18222C", True),
            ("cachelos", "Pulpo cocido en caja (`state_octopus_cooked`)", "#B8283D", False),
        ],
    },
    "Dirección C · «Maqueta de Papel» (`direccion-c-maqueta-papel.md`)": {
        "pairs": [
            ("paprika_sweet", "Encimera de papel blanco / interior caja (`paper_counter_white`)", "#F7F4EC", True),
            ("paprika_hot", "Encimera de papel blanco / interior caja (`paper_counter_white`)", "#F7F4EC", True),
            ("salt", "Bandeja de grafito (`ink_graphite_dark`)", "#2A2320", True),
            ("salt", "Pastilla HUD / cabecera (`brand_navy`)", "#1D3557", True),
            ("salt", "Pulpo cocido en caja (`state_octopus_cooked`)", "#B8283D", False),
            ("oil", "Bandeja de grafito (`ink_graphite_dark`)", "#2A2320", True),
            ("oil", "Pastilla HUD / cabecera (`brand_navy`)", "#1D3557", True),
            ("oil", "Pulpo cocido en caja (`state_octopus_cooked`)", "#B8283D", False),
            ("cachelos", "Bandeja de grafito (`ink_graphite_dark`)", "#2A2320", True),
            ("cachelos", "Pastilla HUD / cabecera (`brand_navy`)", "#1D3557", True),
            ("cachelos", "Pulpo cocido en caja (`state_octopus_cooked`)", "#B8283D", False),
        ],
    },
}

STATE_AND_UI_PAIRS = [
    ("Dir. A: Pulpo crudo vs. cocido", "#E0AFB2", "#B8283D"),
    ("Dir. A: Pulpo crudo vs. quemado", "#E0AFB2", "#2A2320"),
    ("Dir. A: Pulpo cocido vs. quemado", "#B8283D", "#2A2320"),
    ("Dir. A: Pulpo cocido vs. encimera `#EDE8DF`", "#B8283D", "#EDE8DF"),
    ("Dir. A: Pulpo quemado vs. encimera `#EDE8DF`", "#2A2320", "#EDE8DF"),
    ("Dir. A: Patata cruda vs. cachelo cocido", "#8E6B47", "#F2D56B"),
    ("Dir. A: Cachelo cocido vs. quemado", "#F2D56B", "#2A2320"),
    ("Dir. A: Patata cruda vs. quemado", "#8E6B47", "#2A2320"),
    ("Dir. A: Caja roja `#C8402F` vs. interior `#EDE8DF`", "#C8402F", "#EDE8DF"),
    ("Dir. B: Pulpo cocido `#B8283D` vs. losa `#EFECE6`", "#B8283D", "#EFECE6"),
    ("Dir. C: Pulpo crudo `#E0AFB2` (prototipo) vs. encimera `#F7F4EC`", "#E0AFB2", "#F7F4EC"),
    ("Dir. C: Pulpo crudo `#9E7B9B` (variante conceptual) vs. encimera `#F7F4EC`", "#9E7B9B", "#F7F4EC"),
    ("Dir. C: Pulpo cocido `#B8283D` vs. encimera `#F7F4EC`", "#B8283D", "#F7F4EC"),
    ("Dir. C: Pulpo quemado `#2A2320` vs. encimera `#F7F4EC`", "#2A2320", "#F7F4EC"),
    ("Dir. C: Pastilla `#1D3557` vs. suelo/fondo `#E4DFD5` (prototipo)", "#1D3557", "#E4DFD5"),
    ("Dir. C: Pastilla `#1D3557` vs. cartulina `#E6DFD3` (variante conceptual)", "#1D3557", "#E6DFD3"),
]


def build_contrast_markdown() -> str:
    sec34_map = {cid: (name, hx, shape) for cid, name, hx, shape in SEC34_COLORS}
    lines = [
        "# Verificación de contrastes WCAG 2.1 para §3.4 (AC2 — PUL-180)",
        "",
        "Cálculo reproducible de luminancia relativa ($L$) y razón de contraste WCAG 2.1",
        "$(L_{\\max} + 0.05) / (L_{\\min} + 0.05)$ generado por `docs/evidence/PUL-180/build_evidence.py`",
        "para los 5 colores normativos de condimentos (§3.4 de `docs/art/art-bible.md` y D26) frente a",
        "las superficies donde aparecen en las 3 direcciones minimalistas propuestas.",
        "",
        "## 1. Colores normativos de §3.4 y redundancia forma + color (D26)",
        "",
        "| ID (`OrderItem`) | Condimento | Hex (§3.4) | Luminancia ($L$) | Polaridad | Forma de pegatina (D26) |",
        "|---|---|---|---:|---|---|",
    ]
    for cid, name, hx, shape in SEC34_COLORS:
        lum = rel_luminance(hx)
        polarity = "Oscuro (sobre soporte claro)" if lum < 0.25 else "Claro (sobre soporte oscuro / pulpo)"
        lines.append(f"| `{cid}` | {name} | `{hx}` | {lum:.4f} | {polarity} | {shape} |")

    lines.extend(
        [
            "",
            "## 2. Contraste frente a la superficie donde aparecen (requisito AC2: ≥ 3.0000 : 1)",
            "",
        ]
    )

    for dir_title, cfg in DIRECTION_SURFACES.items():
        lines.append(f"### {dir_title}")
        lines.append("")
        lines.append(
            "| Condimento (§3.4) | Hex | $L$ cond. | Superficie donde aparece | Hex sup. | $L$ sup. | Contraste exacto | Contraste (2 dec.) | ≥ 3:1 |"
        )
        lines.append("|---|---|---:|---|---|---:|---:|---:|:---:|")

        all_ratios: list[tuple[float, str, str]] = []
        primary_ratios: list[tuple[float, str, str]] = []
        food_ratios: list[tuple[float, str, str]] = []

        for cid, s_name, s_hex, is_primary in cfg["pairs"]:
            name, hx, _shape = sec34_map[cid]
            lum_c = rel_luminance(hx)
            lum_s = rel_luminance(s_hex)
            cr = contrast_ratio(hx, s_hex)
            ok = "SÍ" if cr >= 3.0 else "NO"
            all_ratios.append((cr, cid, s_hex))
            if is_primary:
                primary_ratios.append((cr, cid, s_hex))
            if s_hex == "#B8283D":
                food_ratios.append((cr, cid, s_hex))
            lines.append(
                f"| **{name}** (`{cid}`) | `{hx}` | {lum_c:.4f} | {s_name} | `{s_hex}` | {lum_s:.4f} | **{cr:.4f} : 1** | {cr:.2f} : 1 | {ok} |"
            )

        min_all = min(all_ratios, key=lambda x: x[0])
        min_prim = min(primary_ratios, key=lambda x: x[0])
        min_food = min(food_ratios, key=lambda x: x[0])
        lines.append("")
        lines.append(
            f"- **Mínimo en soportes primarios de estación/UI:** **{min_prim[0]:.4f} : 1** ({min_prim[0]:.2f} : 1, `{min_prim[1]}` sobre `{min_prim[2]}`)."
        )
        lines.append(
            f"- **Mínimo sobre cama de pulpo cocido (`#B8283D`):** **{min_food[0]:.4f} : 1** ({min_food[0]:.2f} : 1, `{min_food[1]}` sobre `{min_food[2]}`)."
        )
        lines.append(
            f"- **Mínimo absoluto de todas las combinaciones de la tabla:** **{min_all[0]:.4f} : 1** ({min_all[0]:.2f} : 1, `{min_all[1]}` sobre `{min_all[2]}`)."
        )
        lines.append("")

    lines.extend(
        [
            "## 3. Distinción entre los 5 condimentos de §3.4 (par a par: color + soporte + forma D26)",
            "",
            "| Par de condimentos | Contraste exacto | Contraste (2 dec.) | Mecanismo de distinción en las 3 direcciones |",
            "|---|---:|---:|---|",
        ]
    )
    for i in range(len(SEC34_COLORS)):
        for j in range(i + 1, len(SEC34_COLORS)):
            c1, _n1, h1, s1 = SEC34_COLORS[i]
            c2, _n2, h2, s2 = SEC34_COLORS[j]
            cr = contrast_ratio(h1, h2)
            if cr >= 3.0:
                mech = f"Contraste cromático directo ≥ 3:1 ({cr:.4f}:1 / {cr:.2f}:1) + formas distintas ({s1} vs. {s2})"
            else:
                mech = (
                    f"Doble codificación obligatoria D26: forma distinta ({s1} vs. {s2}), "
                    f"contorno interior oscuro/claro de ≥ 3.9052:1 y posición fija en puesto/HUD"
                )
            lines.append(f"| `{c1}` (`{h1}`) vs. `{c2}` (`{h2}`) | **{cr:.4f} : 1** | {cr:.2f} : 1 | {mech} |")

    lines.extend(
        [
            "",
            "## 4. Pares adicionales de estado y UI citados en los documentos de dirección",
            "",
            "| Par evaluado | Hex 1 ($L_1$) | Hex 2 ($L_2$) | Contraste exacto | Contraste (2 dec.) |",
            "|---|---|---|---:|---:|",
        ]
    )
    for label, h1, h2 in STATE_AND_UI_PAIRS:
        l1, l2 = rel_luminance(h1), rel_luminance(h2)
        cr = contrast_ratio(h1, h2)
        lines.append(f"| {label} | `{h1}` ({l1:.4f}) | `{h2}` ({l2:.4f}) | **{cr:.4f} : 1** | {cr:.2f} : 1 |")

    lines.append("")
    return "\n".join(lines)


ELEMENT_STYLES = {
    "OrderStand1": ("#00E5FF", "Puesto #1 (OrderStand1)"),
    "OrderStand2": ("#00E5FF", "Puesto #2 (OrderStand2)"),
    "OrderStand3": ("#00E5FF", "Puesto #3 (OrderStand3)"),
    "OrderStand4": ("#00E5FF", "Puesto #4 (OrderStand4)"),
    "Kitchen": ("#FF9100", "Olla 1 (Kitchen)"),
    "Kitchen2": ("#FF9100", "Olla 2 (Kitchen2)"),
    "Bar_SeasoningStation": ("#D500F9", "Barra (SeasoningStation)"),
    "Player1": ("#00E676", "Cocinero 1 (Player1)"),
    "Player2": ("#00E676", "Cocinero 2 (Player2)"),
}


def compute_max_deviation(base_elements: dict, target_elements: dict) -> tuple[float, float]:
    """Calcula la desviación máxima por eje y euclídea (en px) respecto al estado de partida."""
    max_axis = 0.0
    max_euclid = 0.0
    for node_name, base_coords in base_elements.items():
        bx, by = base_coords["screen_xy_px"]
        tx, ty = target_elements[node_name]["screen_xy_px"]
        dx = abs(tx - bx)
        dy = abs(ty - by)
        max_axis = max(max_axis, dx, dy)
        max_euclid = max(max_euclid, math.hypot(dx, dy))
    return max_axis, max_euclid


def build_annotated_verification() -> None:
    pos_data = json.loads((EVIDENCE_DIR / "posiciones_verificadas.json").read_text(encoding="utf-8"))
    base_1080p = pos_data["partida_1080p"]["elements"]
    base_mob = pos_data["partida_800x370"]["elements"]

    panels = [
        ("partida_1080p", "partida_800x370", "Estado de partida (v2 actual)", EVIDENCE_DIR / "partida" / "1920x1080_con_hud.png"),
        ("dir_a_1080p", "dir_a_800x370", "Dirección A · «Feira Clara» (Prototipo motor)", EVIDENCE_DIR / "direccion_a" / "1920x1080_con_hud.png"),
        ("dir_b_1080p", "dir_b_800x370", "Dirección B · «Bloques de Romería» (Prototipo motor)", EVIDENCE_DIR / "direccion_b" / "1920x1080_con_hud.png"),
        ("dir_c_1080p", "dir_c_800x370", "Dirección C · «Maqueta de Papel» (Prototipo motor)", EVIDENCE_DIR / "direccion_c" / "1920x1080_con_hud.png"),
    ]

    font = ImageFont.load_default()
    annotated_imgs = []

    for key_1080, key_mob, title, img_path in panels:
        im = Image.open(img_path).convert("RGBA")
        overlay = Image.new("RGBA", im.size, (0, 0, 0, 0))
        draw = ImageDraw.Draw(overlay)

        entry = pos_data[key_1080]
        dev_1080_axis, _dev_1080_euc = compute_max_deviation(base_1080p, entry["elements"])
        dev_mob_axis, dev_mob_euc = compute_max_deviation(base_mob, pos_data[key_mob]["elements"])

        draw.rectangle([1345, 16, 1904, 152], fill=(15, 22, 32, 235), outline=(255, 255, 255, 210), width=2)
        draw.text((1358, 26), title, fill=(247, 244, 236, 255), font=font)
        draw.text(
            (1358, 48),
            f"Cam ortho size={entry['camera_ortho_size']} pos={entry['camera_pos']} rot={entry['camera_rot_deg']}",
            fill=(200, 220, 240, 255),
            font=font,
        )
        draw.text(
            (1358, 70),
            f"Desv. max vs partida: 1080p={dev_1080_axis:.1f} px | 800x370={dev_mob_axis:.1f} px/eje ({dev_mob_euc:.2f} px)",
            fill=(0, 230, 118, 255),
            font=font,
        )
        draw.text((1358, 94), "[Cian] 4 Puestos (OrderStand1..4)  [Naranja] 2 Ollas (Kitchen1..2)", fill=(220, 230, 242, 255), font=font)
        draw.text((1358, 116), "[Violeta] Barra (SeasoningStation) [Verde] 2 Cocineros (Player1..2)", fill=(220, 230, 242, 255), font=font)

        elements = entry["elements"]
        for node_name, (color_hex, short_label) in ELEMENT_STYLES.items():
            coords = elements[node_name]
            sx, sy = coords["screen_xy_px"]
            r = 18
            draw.ellipse([sx - r, sy - r, sx + r, sy + r], outline=color_hex, width=4)
            draw.line([sx - r - 8, sy, sx + r + 8, sy], fill=color_hex, width=2)
            draw.line([sx, sy - r - 8, sx, sy + r + 8], fill=color_hex, width=2)

            label = f"{short_label} ({sx:.1f},{sy:.1f})"
            tw = len(label) * 6 + 12
            lx = max(12, min(1920 - tw - 12, int(sx - tw // 2)))
            ly = int(sy - r - 26) if not node_name.startswith("Player") else int(sy + r + 8)
            draw.rectangle([lx, ly, lx + tw, ly + 18], fill=(15, 22, 32, 230), outline=color_hex, width=1)
            draw.text((lx + 5, ly + 3), label, fill=(255, 255, 255, 255), font=font)

        merged = Image.alpha_composite(im, overlay).convert("RGB")
        merged_small = merged.resize((960, 540), Image.Resampling.LANCZOS)
        annotated_imgs.append(merged_small)

    grid = Image.new("RGB", (1920, 1080), (15, 22, 32))
    grid.paste(annotated_imgs[0], (0, 0))
    grid.paste(annotated_imgs[1], (960, 0))
    grid.paste(annotated_imgs[2], (0, 540))
    grid.paste(annotated_imgs[3], (960, 540))

    draw_grid = ImageDraw.Draw(grid)
    draw_grid.line([960, 0, 960, 1080], fill=(255, 255, 255), width=2)
    draw_grid.line([0, 540, 1920, 540], fill=(255, 255, 255), width=2)
    grid.save(EVIDENCE_DIR / "comprobacion_posiciones_anotada.png", optimize=True)

    # Mosaico 2x2 móvil 800x370 sin anotaciones encima para comparar legibilidad pura
    mob_panels = [
        EVIDENCE_DIR / "partida" / "800x370_movil.png",
        EVIDENCE_DIR / "direccion_a" / "800x370_movil.png",
        EVIDENCE_DIR / "direccion_b" / "800x370_movil.png",
        EVIDENCE_DIR / "direccion_c" / "800x370_movil.png",
    ]
    mob_imgs = [Image.open(p).convert("RGB") for p in mob_panels]
    mob_grid = Image.new("RGB", (1600, 740), (15, 22, 32))
    mob_grid.paste(mob_imgs[0], (0, 0))
    mob_grid.paste(mob_imgs[1], (800, 0))
    mob_grid.paste(mob_imgs[2], (0, 370))
    mob_grid.paste(mob_imgs[3], (800, 370))
    draw_mob = ImageDraw.Draw(mob_grid)
    draw_mob.line([800, 0, 800, 740], fill=(255, 255, 255), width=2)
    draw_mob.line([0, 370, 1600, 370], fill=(255, 255, 255), width=2)
    mob_grid.save(EVIDENCE_DIR / "comparativa_movil_800x370.png", optimize=True)


def main() -> None:
    md = build_contrast_markdown()
    (EVIDENCE_DIR / "contrastes_sec34.md").write_text(md, encoding="utf-8")
    build_annotated_verification()
    print("Evidencia generada correctamente en", EVIDENCE_DIR)


if __name__ == "__main__":
    main()
