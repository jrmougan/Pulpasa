"""Atlas propio del cocinero v2 (PUL-075, art-bible v2 §3.3 y §7): 512² RGBA.

    python3 docs/evidence/PUL-075/gen_cook_atlas.py <salida.png>

Mitad superior izquierda: insignia compacta de PulpaSA (gorra). Mitad superior derecha: símbolo
sobre el logotipo «PulpaSA», apilados y en `brand_paper` (peto del delantal). Fondo transparente:
el material del atlas recorta por alfa (modo MASK del glTF). La mitad inferior queda libre.
Fuentes: los PNG propios de PUL-088 en godot/assets/textures/brand/. Determinista.
"""

import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[3]
BRAND = ROOT / "godot" / "assets" / "textures" / "brand"
PAPER = (0xF4, 0xEF, 0xE6)
SIZE = 512


def tint(im: Image.Image, rgb: tuple) -> Image.Image:
    alpha = im.getchannel("A")
    out = Image.new("RGBA", im.size, (*rgb, 0))
    out.putalpha(alpha)
    return out


def fit(im: Image.Image, w: int, h: int) -> Image.Image:
    im = im.crop(im.getchannel("A").getbbox())
    s = min(w / im.width, h / im.height)
    return im.resize((max(1, round(im.width * s)), max(1, round(im.height * s))), Image.LANCZOS)


def main() -> None:
    out = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    badge = fit(Image.open(BRAND / "pulpasa_compacta.png").convert("RGBA"), 248, 248)
    out.alpha_composite(badge, (4 + (248 - badge.width) // 2, 4 + (248 - badge.height) // 2))
    symbol = fit(tint(Image.open(BRAND / "pulpasa_simbolo.png").convert("RGBA"), PAPER), 150, 140)
    # Logotipo sin lema: franja «Pulpa SA» de la versión monocroma blanca (y 55..215 de 347).
    mono = Image.open(BRAND / "pulpasa_mono_blanco.png").convert("RGBA").crop((330, 50, 1000, 215))
    word = fit(tint(mono, PAPER), 236, 80)
    out.alpha_composite(symbol, (256 + (256 - symbol.width) // 2, 14))
    out.alpha_composite(word, (256 + (256 - word.width) // 2, 14 + 140 + 12))
    # Alfa binaria (recorte a 0,5): el atlas se usa con alfa MASK.
    a = out.getchannel("A").point(lambda v: 255 if v >= 128 else 0)
    out.putalpha(a)
    out.save(sys.argv[1])


if __name__ == "__main__":
    main()
