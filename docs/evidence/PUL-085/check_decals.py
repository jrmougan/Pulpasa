"""Contraste de los decals de suelo (Z0) contra `ground_dirt` (art-bible v2 §5: ≤ 1,3:1 salvo rejillas).

Compone `decals_albedo.png` sobre #A18668, promedia a bloques de 4 px de textura (lo que se ve a 1080p
con mipmaps, ≈ 3 texels por píxel) y da el peor contraste WCAG de cada región. Uso, desde la raíz:
    python3 docs/evidence/PUL-085/check_decals.py
"""

from PIL import Image


def lum(c):
    c = [x / 255 for x in c[:3]]
    c = [x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4 for x in c]
    return 0.2126 * c[0] + 0.7152 * c[1] + 0.0722 * c[2]


DIRT = (0xA1, 0x86, 0x68)
im = Image.open("art/blender/textures/environment_v2/decals_albedo.png").convert("RGBA")
bg = Image.new("RGBA", im.size, DIRT + (255,))
bg.alpha_composite(im)
d = lum(DIRT)
worst_all = 1.0
for name, box in (("rodada", (0, 0, 1024, 128)), ("charcos", (0, 128, 1024, 448)),
                  ("manchas", (0, 448, 1024, 768)), ("hojas y piedrecitas", (0, 768, 1024, 1024))):
    reg = bg.crop(box).convert("RGB").resize(((box[2] - box[0]) // 4, (box[3] - box[1]) // 4), Image.BOX)
    worst = max((max(lum(p), d) + 0.05) / (min(lum(p), d) + 0.05) for p in reg.get_flattened_data())
    worst_all = max(worst_all, worst)
    print(f"{name:20s} {worst:.3f}:1")
print("OK" if worst_all <= 1.3 else "FALLA", f"(máximo {worst_all:.3f}:1, límite 1,3:1)")
