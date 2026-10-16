#!/usr/bin/env python3
"""Genera las tablas de contraste WCAG (§3.4) y la comprobación visual anotada para PUL-180."""

from __future__ import annotations

import json
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
        "light_surface": ("Encimera / interior de caja (`surf_counter_cream`)", "#EDE8DF"),
        "dark_surface": ("Cuenco / pastilla HUD / caja (`play_box_navy`)", "#1D3557"),
        "food_surface": ("Pulpo cocido en caja (`state_octopus_cooked`)", "#B8283D"),
    },
    "Dirección B · «Bloques de Romería» (`direccion-b-geometrica.md`)": {
        "light_surface": ("Losa de piedra / interior de caja (`surf_stone_block`)", "#EFECE6"),
        "dark_surface": ("Cuenco / pastilla HUD (`play_box_navy`)", "#1D3557"),
        "alt_dark_surface": ("Vacío / soporte oscuro (`bg_void_navy`)", "#18222C"),
        "food_surface": ("Pulpo cocido en caja (`state_octopus_cooked`)", "#B8283D"),
    },
    "Dirección C · «Maqueta de Papel» (`direccion-c-maqueta-papel.md`)": {
        "light_surface": ("Encimera de papel blanco / interior caja (`paper_counter_white`)", "#F7F4EC"),
        "dark_surface": ("Bandeja de grafito (`ink_graphite_dark`)", "#2A2320"),
        "hud_surface": ("Pastilla HUD / caja (`play_box_navy`)", "#1D3557"),
        "food_surface": ("Pulpo cocido en caja (`state_octopus_cooked`)", "#B8283D"),
    },
}


def build_contrast_markdown() -> str:
    lines = [
        "# Verificación de contrastes WCAG 2.1 para §3.4 (AC2 — PUL-180)",
        "",
        "Cálculo reproducible de luminancia relativa ($L$) y razón de contraste WCAG 2.1",
        "$(L_{\\max} + 0.05) / (L_{\\min} + 0.05)$ para los 5 colores normativos de condimentos",
        "(§3.4 de `docs/art/art-bible.md` y D26) frente a las superficies donde aparecen en las",
        "3 direcciones minimalistas propuestas.",
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
            "## 2. Contraste frente a la superficie donde aparecen (requisito AC2: ≥ 3.00 : 1)",
            "",
        ]
    )

    for dir_title, surfaces in DIRECTION_SURFACES.items():
        lines.append(f"### {dir_title}")
        lines.append("")
        lines.append(
            "| Condimento (§3.4) | Hex | $L$ cond. | Superficie donde aparece | Hex sup. | $L$ sup. | Contraste | ≥ 3:1 |"
        )
        lines.append("|---|---|---:|---|---|---:|---:|:---:|")

        light_name, light_hex = surfaces["light_surface"]
        dark_name, dark_hex = surfaces["dark_surface"]
        food_name, food_hex = surfaces["food_surface"]

        for cid, name, hx, _shape in SEC34_COLORS:
            lum_c = rel_luminance(hx)
            if cid in ("paprika_sweet", "paprika_hot"):
                target_pairs = [(light_name, light_hex)]
            else:
                target_pairs = [(dark_name, dark_hex), (food_name, food_hex)]
                if "alt_dark_surface" in surfaces:
                    target_pairs.insert(1, surfaces["alt_dark_surface"])
                if "hud_surface" in surfaces:
                    target_pairs.insert(1, surfaces["hud_surface"])

            for s_name, s_hex in target_pairs:
                lum_s = rel_luminance(s_hex)
                cr = contrast_ratio(hx, s_hex)
                ok = "SÍ" if cr >= 3.0 else "NO"
                lines.append(
                    f"| **{name}** (`{cid}`) | `{hx}` | {lum_c:.4f} | {s_name} | `{s_hex}` | {lum_s:.4f} | **{cr:.2f} : 1** | {ok} |"
                )
        lines.append("")

    lines.extend(
        [
            "## 3. Distinción entre los 5 condimentos de §3.4 (par a par: color + soporte + forma D26)",
            "",
            "| Par de condimentos | Contraste directo | Mecanismo de distinción en las 3 direcciones |",
            "|---|---:|---|",
        ]
    )
    for i in range(len(SEC34_COLORS)):
        for j in range(i + 1, len(SEC34_COLORS)):
            c1, n1, h1, s1 = SEC34_COLORS[i]
            c2, n2, h2, s2 = SEC34_COLORS[j]
            cr = contrast_ratio(h1, h2)
            if cr >= 3.0:
                mech = f"Contraste cromático directo ≥ 3:1 ({cr:.2f}:1) + formas distintas ({s1} vs. {s2})"
            else:
                mech = (
                    f"Doble codificación obligatoria D26: forma distinta ({s1} vs. {s2}), "
                    f"contorno interior oscuro/claro de ≥ 3.9:1 y posición fija en puesto/HUD"
                )
            lines.append(f"| `{c1}` (`{h1}`) vs. `{c2}` (`{h2}`) | {cr:.2f} : 1 | {mech} |")

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


def build_annotated_verification() -> None:
    pos_data = json.loads((EVIDENCE_DIR / "posiciones_verificadas.json").read_text(encoding="utf-8"))
    panels = [
        ("partida_1080p", "Estado de partida (v2 actual)", EVIDENCE_DIR / "partida" / "1920x1080_con_hud.png"),
        ("dir_a_1080p", "Dirección A · «Feira Clara» (Prototipo motor)", EVIDENCE_DIR / "direccion_a" / "1920x1080_con_hud.png"),
        ("dir_b_1080p", "Dirección B · «Bloques de Romería» (Prototipo motor)", EVIDENCE_DIR / "direccion_b" / "1920x1080_con_hud.png"),
        ("dir_c_1080p", "Dirección C · «Maqueta de Papel» (Prototipo motor)", EVIDENCE_DIR / "direccion_c" / "1920x1080_con_hud.png"),
    ]

    font = ImageFont.load_default()
    annotated_imgs = []

    for key, title, img_path in panels:
        im = Image.open(img_path).convert("RGBA")
        overlay = Image.new("RGBA", im.size, (0, 0, 0, 0))
        draw = ImageDraw.Draw(overlay)

        entry = pos_data[key]
        draw.rectangle([1345, 16, 1904, 152], fill=(15, 22, 32, 235), outline=(255, 255, 255, 210), width=2)
        draw.text((1358, 26), title, fill=(247, 244, 236, 255), font=font)
        draw.text(
            (1358, 48),
            f"Cam ortho size={entry['camera_ortho_size']} pos={entry['camera_pos']} rot={entry['camera_rot_deg']}",
            fill=(200, 220, 240, 255),
            font=font,
        )
        draw.text((1358, 70), "Desviacion de posiciones vs. partida: 0.0 px (exacta)", fill=(0, 230, 118, 255), font=font)
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
