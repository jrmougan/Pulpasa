"""Atlas de pegatinas de la caja (PUL-047, art-bible §3.4): 256×128, celdas de 64 px en 4×2.

Celdas: 0 pimentón dulce, 1 pimentón picante (+ llama), 2 sal, 3 aceite, 4 cachelos. Disco del
color del condimento (borde oscuro en sal y cachelos) e icono en blanco o negro. Iconos SVG de
godot/assets/textures/icons (los del ticket y de %BadgeRow), rasterizados con ImageMagick.
Uso, desde la raíz del repo:  python3 docs/evidence/PUL-047/build_sticker_atlas.py <salida.png>
"""

import subprocess
import sys
import tempfile
from pathlib import Path

from PIL import Image, ImageDraw

ICONS = Path("godot/assets/textures/icons")
CELL = 64
SS = 4  # supermuestreo del disco
WHITE = "#FFFFFF"
INK = "#34302E"  # iron_black
# (disco, borde o None, icono, color del icono, marca de llama)
CELLS = [
    ("#D6361F", None, "pepper-hot-solid.svg", WHITE, False),
    ("#8F1A14", None, "pepper-hot-solid.svg", WHITE, True),
    ("#F7F4EC", "#6E4A2B", "salt.svg", INK, False),
    ("#F2C230", None, "oil.svg", INK, False),
    ("#F2D56B", "#8E6B47", "potato.svg", INK, False),
]


def icon(name: str, color: str, px: int, tmp: Path) -> Image.Image:
    out = tmp / f"{name}_{px}.png"
    subprocess.run(
        ["magick", "-background", "none", "-density", "600", str(ICONS / name), "-resize", f"{px}x{px}", str(out)],
        check=True,
    )
    alpha = Image.open(out).convert("RGBA").getchannel("A")
    solid = Image.new("RGBA", alpha.size, color)
    solid.putalpha(alpha)
    return solid


def main(dest: str) -> None:
    atlas = Image.new("RGBA", (CELL * 4, CELL * 2), (0, 0, 0, 0))
    with tempfile.TemporaryDirectory() as t:
        tmp = Path(t)
        for i, (disc, rim, ico, ink, hot) in enumerate(CELLS):
            big = Image.new("RGBA", (CELL * SS, CELL * SS), (0, 0, 0, 0))
            d = ImageDraw.Draw(big)
            m = 1 * SS
            if rim:
                d.ellipse([m, m, CELL * SS - m, CELL * SS - m], fill=rim)
                m += 4 * SS
            d.ellipse([m, m, CELL * SS - m, CELL * SS - m], fill=disc)
            cell = big.resize((CELL, CELL), Image.LANCZOS)
            glyph = icon(ico, ink, 36, tmp)
            cell.alpha_composite(glyph, ((CELL - glyph.width) // 2, (CELL - glyph.height) // 2))
            if hot:
                spark = icon("small-fire.svg", "#F2C230", 20, tmp)
                cell.alpha_composite(spark, (CELL - spark.width - 6, 5))
            atlas.alpha_composite(cell, ((i % 4) * CELL, (i // 4) * CELL))
    atlas.save(dest)


if __name__ == "__main__":
    main(sys.argv[1])
