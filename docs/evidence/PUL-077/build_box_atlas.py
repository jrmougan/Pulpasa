"""Atlas propio de las bandejas v2 (PUL-077): albedo sRGB + ORM lineal de 512² (art-bible v2 §3.3, §4.2).

    python3 docs/evidence/PUL-077/build_box_atlas.py <out_dir>

Escribe <out_dir>/box_atlas_albedo.png y box_atlas_orm.png; build_box_v2.py los empaqueta en el .blend.
Distribución (píxeles, origen arriba a la izquierda):
- (0..256, 0..256): papel salvamanteles `tray_liner` #F4EFE6 con el símbolo de la marca repetido en
  `brand_support` #5B8DB8 **al 15 %** (§6.4). Símbolos de ≈ 0,06 m con la proyección de la malla.
- (256..384, 0..128): símbolo en `brand_paper` sobre `plastic_red` para el canto frontal-inferior (§7).
- (0..512, 256..512): celdas lisas de 64 px (CELLS), sin ruido (§3.2).
El símbolo sale del alfa de godot/assets/textures/brand/pulpasa_simbolo.png (PUL-088, sin modificarlo).
"""

import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[3]
SYMBOL = ROOT / "godot/assets/textures/brand/pulpasa_simbolo.png"
PX = 512
CELL = 64
# (hex sRGB, roughness). El orden fija la celda: i → columna i % 8, fila 4 + i // 8.
CELLS = {
    "foot": ("#7E271D", 0.55),  # pie de contacto (AO horneado sobre plastic_red)
    "rim": ("#D65845", 0.40),  # canto superior con roce claro (§3.1 mat_plastic_red)
    "inner": ("#B5392A", 0.45),  # pared interior, algo más oscura: da hondura vista desde arriba
    "band_small": ("#3E78B0", 0.45),  # aro de talla (§6.4): pequeña azul
    "band_medium": ("#4FA05A", 0.45),  # mediana verde
    "band_large": ("#F4EFE6", 0.45),  # grande: papel (el rojo no se ve sobre la bandeja roja)
    "liner_edge": ("#E2D9C9", 0.80),  # borde del papel (sombra del pliegue)
    "red": ("#C8402F", 0.45),  # plastic_red liso (asas, decal)
}
PAPER = (0xF4, 0xEF, 0xE6)
SUPPORT = (0x5B, 0x8D, 0xB8)
RED = (0xC8, 0x40, 0x2F)
PATTERN_ALPHA = 0.15
PAPER_ROUGH = 0.80
PLASTIC_ROUGH = 0.45


def hex_rgb(h: str) -> tuple:
    return tuple(int(h[i : i + 2], 16) for i in (1, 3, 5))


def mix(a: tuple, b: tuple, t: float) -> tuple:
    return tuple(round(x * (1 - t) + y * t) for x, y in zip(a, b))


def symbol_mask(size: int, angle: float = 0.0) -> Image.Image:
    mask = Image.open(SYMBOL).getchannel("A")
    mask = mask.crop(mask.getbbox())
    w, h = mask.size
    k = size / max(w, h)
    mask = mask.resize((max(1, round(w * k)), max(1, round(h * k))), Image.LANCZOS)
    return mask.rotate(angle, resample=Image.BICUBIC, expand=True) if angle else mask


def build(out_dir: Path) -> None:
    albedo = Image.new("RGB", (PX, PX), PAPER)
    orm = Image.new("RGB", (PX, PX), (255, round(PAPER_ROUGH * 255), 0))

    # Papel: símbolos en rejilla al tresbolillo, alternando ±12°, que encajan al repetir 256 px.
    tint = mix(PAPER, SUPPORT, PATTERN_ALPHA)
    paper = Image.new("RGB", (256, 256), PAPER)
    step = 64
    for row in range(4):
        for col in range(4):
            m = symbol_mask(34, 12.0 if (row + col) % 2 else -12.0)
            cx = col * step + (step // 2 if row % 2 else 0) + step // 4
            cy = row * step + step // 2
            for dx in (-256, 0, 256):
                paper.paste(tint, (cx - m.width // 2 + dx, cy - m.height // 2), m)
    albedo.paste(paper, (0, 0))

    # Canto: símbolo en papel sobre rojo, con margen (área de respeto, brand.md).
    logo = Image.new("RGB", (128, 128), RED)
    m = symbol_mask(96)
    logo.paste(PAPER, ((128 - m.width) // 2, (128 - m.height) // 2), m)
    albedo.paste(logo, (256, 0))
    orm.paste((255, round(PLASTIC_ROUGH * 255), 0), (256, 0, 384, 128))
    # Resto de la franja superior: rojo liso (nadie la usa; evita sangrado claro en mips).
    albedo.paste(RED, (384, 0, 512, 256))
    albedo.paste(RED, (256, 128, 384, 256))
    orm.paste((255, round(PLASTIC_ROUGH * 255), 0), (256, 0, 512, 256))

    for i, (hex_color, rough) in enumerate(CELLS.values()):
        x, y = (i % 8) * CELL, 256 + (i // 8) * CELL
        albedo.paste(hex_rgb(hex_color), (x, y, x + CELL, y + CELL))
        orm.paste((255, round(rough * 255), 0), (x, y, x + CELL, y + CELL))
    # Filas sin celdas: rojo liso.
    used_rows = (len(CELLS) + 7) // 8
    albedo.paste(RED, (0, 256 + used_rows * CELL, PX, PX))
    orm.paste((255, round(PLASTIC_ROUGH * 255), 0), (0, 256 + used_rows * CELL, PX, PX))

    out_dir.mkdir(parents=True, exist_ok=True)
    albedo.save(out_dir / "box_atlas_albedo.png")
    orm.save(out_dir / "box_atlas_orm.png")


if __name__ == "__main__":
    build(Path(sys.argv[1]))
