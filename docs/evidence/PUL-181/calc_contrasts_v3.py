#!/usr/bin/env python3
"""PUL-181: Cálculo reproducible de luminancia relativa y contrastes WCAG 2.1 para la biblia v3 «Feira Clara».

Verifica AC2: los 5 colores normativos de §3.4 frente a cada superficie donde aparecen
tienen contraste >= 3.0000 : 1, además de los pares de estado de cocción, números de puesto y UI/HUD.
Genera `docs/evidence/PUL-181/contrastes_v3.md`.
"""

from __future__ import annotations

from pathlib import Path

EVIDENCE_DIR = Path(__file__).resolve().parent
OUT_MD = EVIDENCE_DIR / "contrastes_v3.md"

# Paleta cerrada v3 «Feira Clara» (16 colores en hex)
PALETTE_V3: list[tuple[int, str, str, str, float, str]] = [
    (
        1,
        "ground_sand",
        "#C4A882",
        "mat_ground_sand.tres",
        0.95,
        "Suelo interior de cocina, arena exterior y sacos de arpillera",
    ),
    (
        2,
        "wall_granite",
        "#9A948C",
        "mat_wall_granite.tres",
        0.92,
        "Muro perimetral de granito, postes exteriores, acero estructural de olla y arcón",
    ),
    (
        3,
        "meadow_green",
        "#4FA05A",
        "mat_meadow_green.tres",
        0.95,
        "Prado exterior, fondo de cámara, vegetación lejana, toldo del puesto 4 y barra de paciencia (>60 %)",
    ),
    (
        4,
        "surface_top",
        "#EDE8DF",
        "mat_surface_top.tres",
        0.85,
        "Tableros de encimera, tabla de corte, interior de caja (`box_inside`), alfombrilla `ServiceMat`, collar de botes y borde de paneles UI",
    ),
    (
        5,
        "brand_navy",
        "#1D3557",
        "mat_brand_navy.tres",
        0.90,
        "Faldones de encimera y puestos, rayas pares del toldo, marco `OrderPlateFrame`, glifo `#1..#4`, zócalo `ServiceFascia`, cuenco de cachelos, pantalones y paneles UI (`UiPanel`)",
    ),
    (
        6,
        "brand_red",
        "#C8402F",
        "mat_brand_red.tres",
        0.80,
        "Exterior de caja de reparto (`box_outside`), toldo del puesto 1, acento de marca PulpaSA y barra de paciencia (<30 %)",
    ),
    (
        7,
        "ui_cream",
        "#F7F4EC",
        "mat_ui_cream.tres",
        0.90,
        "Sal gruesa (§3.4), placa `OrderPlatePaper`, dígito frontal `StandNumber` (`1..4`), rayas impares del toldo, camisa/gorro de cocinero, papel de ticket y texto principal HUD",
    ),
    (
        8,
        "octopus_raw",
        "#E0AFB2",
        "mat_octopus_raw.tres",
        0.88,
        "Pulpo crudo (cuerpo y tentáculos en arcón, mano, encimera y olla) y piel de personajes",
    ),
    (
        9,
        "octopus_cooked",
        "#B8283D",
        "mat_octopus_cooked.tres",
        0.65,
        "Pulpo cocido entero y rodajas (`FillHalf`, `FillFull`) dentro de la caja",
    ),
    (
        10,
        "potato_raw",
        "#8E6B47",
        "mat_potato_raw.tres",
        0.92,
        "Patata cruda con piel, madera cálida secundaria y borde histórico de cachelos (§3.4)",
    ),
    (
        11,
        "cachelos_cooked",
        "#F2D56B",
        "mat_cachelos_cooked.tres",
        0.80,
        "Cachelos cocidos (§3.4), icono/pegatina de cachelos y flecha/etiqueta `potato` en la estación de condimentos",
    ),
    (
        12,
        "state_burnt",
        "#2A2320",
        "mat_state_burnt.tres",
        0.95,
        "Ingrediente quemado (pulpo o cachelos), boca interior de olla y cubo de basura, tinta `StickerInk` (`#2A2320`) y pozos oscuros HUD (`UiHeader`, `DisplayWell`)",
    ),
    (
        13,
        "paprika_sweet",
        "#D6361F",
        "mat_paprika_sweet.tres",
        0.75,
        "Pimentón dulce (§3.4): cuerpo del dispensador `SweetDressing`, pegatina circular D26, flecha/etiqueta `sweet` y partículas",
    ),
    (
        14,
        "paprika_hot",
        "#8F1A14",
        "mat_paprika_hot.tres",
        0.75,
        "Pimentón picante (§3.4): cuerpo del dispensador `HotDressing`, pegatina octogonal D26, flecha/etiqueta `hot` y partículas",
    ),
    (
        15,
        "p1_blue",
        "#2F6FB5",
        "mat_p1_blue.tres",
        0.75,
        "Delantal y aro de suelo de J1, toldo del puesto 2 y agua del tanque de pulpo",
    ),
    (
        16,
        "p2_amber",
        "#F2C230",
        "mat_p2_amber.tres",
        0.75,
        "Aceite de oliva (§3.4), delantal y aro de suelo de J2, toldo del puesto 3, cifras/reloj del HUD y barra de paciencia (30–60 %)",
    ),
]

# Los 5 colores normativos de §3.4 (art-bible-v1.md §3.4 / D26)
SEC34_COLORS: list[tuple[str, str, str, str, str]] = [
    ("paprika_sweet", "Pimentón dulce", "#D6361F", "Oscuro (sobre soporte claro)", "Círculo (activo D25)"),
    ("paprika_hot", "Pimentón picante", "#8F1A14", "Oscuro (sobre soporte claro)", "Octógono (activo D25)"),
    ("salt", "Sal gruesa", "#F7F4EC", "Claro (sobre soporte oscuro / pulpo)", "Cuadrado (reserva §3.4; integrado en aliño D25)"),
    ("oil", "Aceite de oliva", "#F2C230", "Claro (sobre soporte oscuro / pulpo)", "Gota (reserva §3.4; integrado en aliño D25)"),
    ("cachelos", "Cachelos", "#F2D56B", "Claro (sobre soporte oscuro / pulpo)", "Óvalo (activo D25)"),
]

# Todas las superficies donde aparece cada uno de los 5 colores de §3.4 en la v3 «Feira Clara»
SEC34_SURFACES: list[tuple[str, str, str, str, str]] = [
    # Pimentón dulce (#D6361F)
    (
        "paprika_sweet",
        "Pimentón dulce",
        "#D6361F",
        "Encimera (`ServiceMat`), interior de caja (`box_inside`) y collar del dispensador (`mat_surface_top`)",
        "#EDE8DF",
    ),
    (
        "paprika_sweet",
        "Pimentón dulce",
        "#D6361F",
        "Tarjeta/soporte crema claro (`mat_ui_cream`)",
        "#F7F4EC",
    ),
    (
        "paprika_sweet",
        "Pimentón dulce",
        "#D6361F",
        "Anillo e icono interior `StickerInk` en pegatina D26 y ticket (`mat_state_burnt`)",
        "#2A2320",
    ),
    # Pimentón picante (#8F1A14)
    (
        "paprika_hot",
        "Pimentón picante",
        "#8F1A14",
        "Encimera (`ServiceMat`), interior de caja (`box_inside`) y collar del dispensador (`mat_surface_top`)",
        "#EDE8DF",
    ),
    (
        "paprika_hot",
        "Pimentón picante",
        "#8F1A14",
        "Icono interior / chispa crema (`mat_ui_cream`)",
        "#F7F4EC",
    ),
    # Sal gruesa (#F7F4EC)
    (
        "salt",
        "Sal gruesa",
        "#F7F4EC",
        "Zócalo de estación (`ServiceFascia`), pastilla de ticket HUD y faldón (`mat_brand_navy`)",
        "#1D3557",
    ),
    (
        "salt",
        "Sal gruesa",
        "#F7F4EC",
        "Anillo `StickerInk` / pozo oscuro (`mat_state_burnt`)",
        "#2A2320",
    ),
    (
        "salt",
        "Sal gruesa",
        "#F7F4EC",
        "Cama de pulpo cocido en la caja y partículas de aliño sobre pulpo (`mat_octopus_cooked`)",
        "#B8283D",
    ),
    (
        "salt",
        "Sal gruesa",
        "#F7F4EC",
        "Borde exterior rojo de la caja (`mat_brand_red`)",
        "#C8402F",
    ),
    # Aceite de oliva (#F2C230)
    (
        "oil",
        "Aceite de oliva",
        "#F2C230",
        "Zócalo de estación (`ServiceFascia`), pastilla de ticket HUD y faldón (`mat_brand_navy`)",
        "#1D3557",
    ),
    (
        "oil",
        "Aceite de oliva",
        "#F2C230",
        "Anillo `StickerInk` / pozo oscuro (`mat_state_burnt`)",
        "#2A2320",
    ),
    (
        "oil",
        "Aceite de oliva",
        "#F2C230",
        "Cama de pulpo cocido en la caja y partículas de aliño sobre pulpo (`mat_octopus_cooked`)",
        "#B8283D",
    ),
    # Cachelos (#F2D56B)
    (
        "cachelos",
        "Cachelos",
        "#F2D56B",
        "Cuenco de cachelos (`CachelosBowl`), zócalo `ServiceFascia` y pastilla HUD (`mat_brand_navy`)",
        "#1D3557",
    ),
    (
        "cachelos",
        "Cachelos",
        "#F2D56B",
        "Anillo e icono interior `StickerInk` en pegatina D26 y ticket (`mat_state_burnt`)",
        "#2A2320",
    ),
    (
        "cachelos",
        "Cachelos",
        "#F2D56B",
        "Cama de pulpo cocido en la caja (`mat_octopus_cooked`)",
        "#B8283D",
    ),
    (
        "cachelos",
        "Cachelos",
        "#F2D56B",
        "Borde exterior rojo de la caja (`mat_brand_red`)",
        "#C8402F",
    ),
    (
        "cachelos",
        "Cachelos",
        "#F2D56B",
        "Piel de patata cruda / madera secundaria (`mat_potato_raw`)",
        "#8E6B47",
    ),
]

# Pares de estados, números de puestos (AC3) y UI/HUD
EXTRA_PAIRS: list[tuple[str, str, str, str, str]] = [
    ("Pulpo crudo vs. pulpo cocido", "octopus_raw", "#E0AFB2", "octopus_cooked", "#B8283D"),
    ("Pulpo crudo vs. pulpo quemado", "octopus_raw", "#E0AFB2", "state_burnt", "#2A2320"),
    ("Pulpo cocido vs. tablero de encimera", "octopus_cooked", "#B8283D", "surface_top", "#EDE8DF"),
    ("Pulpo cocido vs. boca oscura de la olla", "octopus_cooked", "#B8283D", "state_burnt", "#2A2320"),
    ("Cachelo crudo vs. cachelo cocido", "potato_raw", "#8E6B47", "cachelos_cooked", "#F2D56B"),
    ("Cachelo crudo vs. tablero de encimera", "potato_raw", "#8E6B47", "surface_top", "#EDE8DF"),
    ("Cachelo cocido vs. cama de pulpo cocido", "cachelos_cooked", "#F2D56B", "octopus_cooked", "#B8283D"),
    ("Cachelo cocido vs. cuenco azul marino", "cachelos_cooked", "#F2D56B", "brand_navy", "#1D3557"),
    ("Ingrediente quemado vs. tablero de encimera", "state_burnt", "#2A2320", "surface_top", "#EDE8DF"),
    (
        "Puesto de entrega (AC3): `%OrderLabel` (`#1..#4`) sólido sobre `OrderPlatePaper`",
        "brand_navy",
        "#1D3557",
        "ui_cream",
        "#F7F4EC",
    ),
    (
        "Puesto de entrega (AC3): `StandNumber` (`1..4`) sólido sobre faldón frontal",
        "ui_cream",
        "#F7F4EC",
        "brand_navy",
        "#1D3557",
    ),
    ("HUD: texto principal crema sobre panel `UiPanel`", "ui_cream", "#F7F4EC", "brand_navy", "#1D3557"),
    ("HUD: texto principal crema sobre cabecera/pozo `UiHeader`", "ui_cream", "#F7F4EC", "state_burnt", "#2A2320"),
    ("HUD: cifras y reloj ámbar sobre panel `UiPanel`", "p2_amber", "#F2C230", "brand_navy", "#1D3557"),
    ("HUD: cifras y reloj ámbar sobre pozo `DisplayWell`", "p2_amber", "#F2C230", "state_burnt", "#2A2320"),
    ("J1 azul vs. suelo de arena", "p1_blue", "#2F6FB5", "ground_sand", "#C4A882"),
    ("J2 ámbar vs. faldón azul marino", "p2_amber", "#F2C230", "brand_navy", "#1D3557"),
]

# Pegatinas de condimentos en soportes de juego reales (caja roja y suelo) y regla del anillo StickerInk (Finding 4)
STICKER_BACKGROUND_PAIRS: list[tuple[str, str, str, str, str, str]] = [
    (
        "Pegatina dulce directa sobre caja roja (sin anillo)",
        "paprika_sweet",
        "#D6361F",
        "brand_red",
        "#C8402F",
        "INSUFICIENTE (1.04:1) sin anillo delimitador",
    ),
    (
        "Pegatina dulce directa sobre suelo de cocina (sin anillo)",
        "paprika_sweet",
        "#D6361F",
        "ground_sand",
        "#C4A882",
        "INSUFICIENTE (2.10:1) sin anillo delimitador",
    ),
    (
        "Pegatina cachelos directa sobre suelo de cocina (sin anillo)",
        "cachelos",
        "#F2D56B",
        "ground_sand",
        "#C4A882",
        "INSUFICIENTE (1.56:1) sin anillo delimitador",
    ),
    (
        "Anillo `StickerInk.INK` sobre caja roja (frontera exterior)",
        "state_burnt",
        "#2A2320",
        "brand_red",
        "#C8402F",
        "CUMPLE (≥ 3:1) — el anillo separa la pegatina de la caja",
    ),
    (
        "Anillo `StickerInk.INK` sobre suelo de cocina (frontera exterior)",
        "state_burnt",
        "#2A2320",
        "ground_sand",
        "#C4A882",
        "CUMPLE (≥ 3:1) — el anillo separa la pegatina del suelo",
    ),
    (
        "Disco dulce interior contra anillo `StickerInk.INK`",
        "paprika_sweet",
        "#D6361F",
        "state_burnt",
        "#2A2320",
        "CUMPLE (≥ 3:1) — contraste interno disco/anillo",
    ),
    (
        "Disco cachelos interior contra anillo `StickerInk.INK`",
        "cachelos",
        "#F2D56B",
        "state_burnt",
        "#2A2320",
        "CUMPLE (≥ 3:1) — contraste interno disco/anillo",
    ),
    (
        "Disco picante interior contra anillo `StickerInk.INK`",
        "paprika_hot",
        "#8F1A14",
        "state_burnt",
        "#2A2320",
        "1.71:1 (doble codificación: octógono D26 + icono interior crema a 8.21:1; el anillo exterior separa del fondo a 3.11:1 y 6.82:1)",
    ),
    (
        "Icono chispa crema interior sobre disco picante",
        "ui_cream",
        "#F7F4EC",
        "paprika_hot",
        "#8F1A14",
        "CUMPLE (≥ 3:1) — icono interior crema sobre disco picante (8.21:1)",
    ),
]


def srgb_to_linear(channel_hex: int) -> float:
    c = channel_hex / 255.0
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def relative_luminance(hex_color: str) -> float:
    h = hex_color.lstrip("#")
    r = srgb_to_linear(int(h[0:2], 16))
    g = srgb_to_linear(int(h[2:4], 16))
    b = srgb_to_linear(int(h[4:6], 16))
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def contrast_ratio(hex1: str, hex2: str) -> float:
    l1 = relative_luminance(hex1)
    l2 = relative_luminance(hex2)
    l_max, l_min = (l1, l2) if l1 >= l2 else (l2, l1)
    return (l_max + 0.05) / (l_min + 0.05)


def main() -> None:
    lines: list[str] = [
        "# Verificación de contrastes WCAG 2.1 — Biblia de arte v3 «Feira Clara» (AC2 — PUL-181)",
        "",
        "Cálculo reproducible de luminancia relativa ($L$) y razón de contraste WCAG 2.1",
        "$(L_{\\max} + 0.05) / (L_{\\min} + 0.05)$ generado por `docs/evidence/PUL-181/calc_contrasts_v3.py`",
        "para la paleta cerrada de 16 colores de la v3 (`docs/art/art-bible.md`) y los 5 colores",
        "normativos de §3.4 frente a cada superficie donde aparecen.",
        "",
        "## 1. Paleta cerrada v3 «Feira Clara» (16 colores) y luminancia relativa ($L$)",
        "",
        "| # | ID de paleta | Hex | $L$ (WCAG 2.1) | Material compartido (`.tres`) | Roughness | Uso principal |",
        "|---:|---|---|---:|---|---:|---|",
    ]

    for idx, token, hx, tres, rough, usage in PALETTE_V3:
        lum = relative_luminance(hx)
        lines.append(
            f"| {idx} | `{token}` | `{hx}` | {lum:.4f} | `{tres}` | {rough:.2f} | {usage} |"
        )

    lines.extend(
        [
            "",
            "## 2. Los 5 colores normativos de §3.4 y redundancia forma + color (D26)",
            "",
            "| ID (`OrderItem`) | Condimento | Hex (§3.4) | Luminancia ($L$) | Polaridad | Forma de pegatina D26 y estado en D25 |",
            "|---|---|---|---:|---|---|",
        ]
    )
    for item_id, label, hx, polarity, shape in SEC34_COLORS:
        lines.append(
            f"| `{item_id}` | {label} | `{hx}` | {relative_luminance(hx):.4f} | {polarity} | {shape} |"
        )

    lines.extend(
        [
            "",
            "## 3. Contraste de los 5 colores de §3.4 frente a cada superficie donde aparecen (AC2: todos ≥ 3:1)",
            "",
            "| Condimento (§3.4) | Hex cond. | $L$ cond. | Superficie donde aparece en v3 | Hex sup. | $L$ sup. | Contraste exacto | Contraste (2 dec.) | ≥ 3:1 |",
            "|---|---|---:|---|---|---:|---:|---:|:---:|",
        ]
    )

    min_ratio = 999.0
    min_desc = ""
    for item_id, label, c_hex, surf_desc, s_hex in SEC34_SURFACES:
        lc = relative_luminance(c_hex)
        ls = relative_luminance(s_hex)
        cr = contrast_ratio(c_hex, s_hex)
        assert cr >= 3.0, f"Fallo AC2: {item_id} ({c_hex}) sobre {surf_desc} ({s_hex}) da {cr:.4f} < 3.0"
        if cr < min_ratio:
            min_ratio = cr
            min_desc = f"`{item_id}` (`{c_hex}`) sobre {surf_desc} (`{s_hex}`)"
        lines.append(
            f"| **{label}** (`{item_id}`) | `{c_hex}` | {lc:.4f} | {surf_desc} | `{s_hex}` | {ls:.4f} | **{cr:.4f} : 1** | {cr:.2f} : 1 | SÍ |"
        )

    lines.extend(
        [
            "",
            f"- **Contraste mínimo en toda la tabla de §3.4:** **{min_ratio:.4f} : 1** ({min_ratio:.2f} : 1, {min_desc}).",
            "- **Resultado AC2:** **17/17 combinaciones cumplen ≥ 3.0000 : 1**.",
            "",
            "## 4. Estados de cocción, números de puestos de entrega (AC3) y UI/HUD",
            "",
            "| Par evaluado | Color 1 (`hex`, $L_1$) | Color 2 (`hex`, $L_2$) | Contraste exacto | Contraste (2 dec.) |",
            "|---|---|---|---:|---:|",
        ]
    )

    for desc, t1, h1, t2, h2 in EXTRA_PAIRS:
        l1 = relative_luminance(h1)
        l2 = relative_luminance(h2)
        cr = contrast_ratio(h1, h2)
        lines.append(
            f"| {desc} | `{t1}` (`{h1}`, {l1:.4f}) | `{t2}` (`{h2}`, {l2:.4f}) | **{cr:.4f} : 1** | {cr:.2f} : 1 |"
        )

    lines.extend(
        [
            "",
            "## 5. Pegatinas en soportes de juego reales y regla del anillo `StickerInk.INK` (Finding 4)",
            "",
            "En el juego las pegatinas se ven como billboards 3D sobre el exterior de la caja roja (`#C8402F`) y sobre el suelo de cocina/arena (`#C4A882`).",
            "Sin anillo delimitador, el dulce sobre la caja roja da 1.04:1 y sobre el suelo 2.10:1, y los cachelos sobre el suelo dan 1.56:1.",
            "Para garantizar WCAG 2.1 ≥ 3:1 en cualquier superficie, en la v3 (`PUL-185`) **todos los discos de pegatina llevan obligatoriamente el anillo exterior oscuro `StickerInk.INK` (`#2A2320`)**.",
            "",
            "| Caso evaluado | Color 1 (`hex`, $L_1$) | Color 2 (`hex`, $L_2$) | Contraste exacto | Contraste (2 dec.) | Evaluación WCAG 2.1 |",
            "|---|---|---|---:|---:|---|",
        ]
    )

    for desc, t1, h1, t2, h2, note in STICKER_BACKGROUND_PAIRS:
        l1 = relative_luminance(h1)
        l2 = relative_luminance(h2)
        cr = contrast_ratio(h1, h2)
        lines.append(
            f"| {desc} | `{t1}` (`{h1}`, {l1:.4f}) | `{t2}` (`{h2}`, {l2:.4f}) | **{cr:.4f} : 1** | {cr:.2f} : 1 | {note} |"
        )

    lines.extend(
        [
            "",
            "## 6. Matriz par a par entre los 5 colores de §3.4 y doble codificación D26",
            "",
            "| Par de condimentos | Contraste exacto | Contraste (2 dec.) | Mecanismo de distinción en v3 |",
            "|---|---:|---:|---|",
        ]
    )
    for i in range(len(SEC34_COLORS)):
        for j in range(i + 1, len(SEC34_COLORS)):
            id1, _, h1, _, sh1 = SEC34_COLORS[i]
            id2, _, h2, _, sh2 = SEC34_COLORS[j]
            cr = contrast_ratio(h1, h2)
            s1 = sh1.split(" (")[0]
            s2 = sh2.split(" (")[0]
            if cr >= 3.0:
                mech = f"Contraste directo ≥ 3:1 ({cr:.2f}:1) + formas distintas ({s1} vs. {s2})"
            else:
                mech = (
                    f"Doble codificación obligatoria D26: forma distinta ({s1} vs. {s2}), "
                    "anillo interior `StickerInk` (#2A2320 / #F7F4EC con contraste ≥ 3.24:1) y posición fija en estación/HUD"
                )
            lines.append(f"| `{id1}` (`{h1}`) vs. `{id2}` (`{h2}`) | **{cr:.4f} : 1** | {cr:.2f} : 1 | {mech} |")

    OUT_MD.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"OK: {OUT_MD} generado. Contraste mínimo §3.4 = {min_ratio:.4f}:1 (>= 3.0:1).")


if __name__ == "__main__":
    main()
