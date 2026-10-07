"""Láminas de comparación de PUL-087 (referencia / antes / progreso / después). Uso:
python3 docs/evidence/PUL-087/make_comparativa.py  (desde la raíz del repo)."""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

REFS = Path("docs/art/style-refs")
EV = Path("docs/evidence/PUL-087")
W = 960
FONT = ImageFont.truetype("godot/assets/fonts/LiberationSans.ttf", 26)


def tile(path: Path, label: str, crop=None) -> Image.Image:
    img = Image.open(path).convert("RGB")
    if crop is not None:
        w, h = img.size
        img = img.crop((int(w * crop[0]), int(h * crop[1]), int(w * crop[2]), int(h * crop[3])))
    img = img.resize((W, int(img.height * W / img.width)))
    canvas = Image.new("RGB", (W, img.height), (20, 20, 20))
    canvas.paste(img, (0, 0))
    d = ImageDraw.Draw(canvas)
    d.rectangle((0, 0, 16 + int(d.textlength(label, font=FONT)), 40), fill=(0, 0, 0))
    d.text((8, 4), label, fill=(255, 255, 255), font=FONT)
    return canvas


def sheet(tiles: list[Image.Image], out: Path, cols: int = 2) -> None:
    th = max(t.height for t in tiles)
    rows = (len(tiles) + cols - 1) // cols
    s = Image.new("RGB", (W * cols, th * rows), (20, 20, 20))
    for i, t in enumerate(tiles):
        s.paste(t, ((i % cols) * W, (i // cols) * th))
    s.save(out, optimize=True)


sheet(
    [
        tile(REFS / "referencia-elegida-2026-10-06.png", "Referencia (2026-10-06)"),
        tile(REFS / "actual-2026-10-06/00_nivel_sin_hud.png", "Antes: v1 (2026-10-06)"),
        tile(REFS / "progreso-2026-10-07/00_nivel_sin_hud.png", "Progreso (2026-10-07)"),
        tile(EV / "despues/00_nivel_sin_hud.png", "Después: v2 cerrada (PUL-087)"),
    ],
    EV / "ac1_comparativa_nivel.png",
)
sheet(
    [
        tile(REFS / "referencia-elegida-2026-10-06.png", "Referencia con HUD"),
        tile(EV / "despues/01_nivel_completo.png", "Después con HUD"),
    ],
    EV / "ac1_comparativa_hud.png",
)
# Mismas zonas en la referencia (encuadre aproximado) y en la captura del juego.
ZONAS = {
    "cocina": ((0.22, 0.28, 0.78, 0.58), (0.2, 0.22, 0.8, 0.55)),
    "puestos": ((0.25, 0.72, 0.75, 1.0), (0.25, 0.75, 0.75, 1.0)),
    "carpa": ((0.0, 0.0, 1.0, 0.45), (0.0, 0.0, 1.0, 0.4)),
}
for zona, (crop_game, crop_ref) in ZONAS.items():
    sheet(
        [
            tile(REFS / "referencia-elegida-2026-10-06.png", f"Referencia: {zona}", crop_ref),
            tile(REFS / "actual-2026-10-06/00_nivel_sin_hud.png", f"Antes: {zona}", crop_game),
            tile(EV / "despues/00_nivel_sin_hud.png", f"Después: {zona}", crop_game),
        ],
        EV / f"ac1_zona_{zona}.png",
        cols=1,
    )
