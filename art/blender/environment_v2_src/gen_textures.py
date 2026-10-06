"""Texturas propias del entorno v2 (PUL-085): atlas de atrezo, decals de suelo, malla de valla y marca.

Determinista (semillas fijas), sin imágenes de terceros: todo se pinta aquí o sale de los PNG de marca
de PUL-088 (`godot/assets/textures/brand/`). Escribe en `art/blender/textures/environment_v2/`; el
`.blend` las enlaza por ruta relativa y el export las embebe en cada `.glb` (pipeline.md §8).
Uso, desde la raíz del repo:
    python3 art/blender/environment_v2_src/gen_textures.py
"""

import math
import random
from pathlib import Path

try:  # Blender importa este fichero solo por las constantes de UV (sin PIL).
    from PIL import Image, ImageChops, ImageDraw, ImageFilter
except ImportError:
    Image = ImageChops = ImageDraw = ImageFilter = None

ROOT = Path(__file__).resolve().parents[3]
OUT = ROOT / "art/blender/textures/environment_v2"
BRAND = ROOT / "godot/assets/textures/brand"

NAVY = (0x1D, 0x35, 0x57)
RED = (0xC8, 0x40, 0x2F)
PAPER = (0xF4, 0xEF, 0xE6)
NIGHT = (0x13, 0x20, 0x2F)
NEON = (0xFF, 0x6B, 0x57)

# Atlas de atrezo (512², celdas de 64 px en la mitad superior). Índice → (nombre, hex).
# Ropa de romería en tonos apagados (art-bible §1.4): nada de player_*, stand_* ni brand_navy como color
# principal de un comensal.
SWATCHES = [
    ("beret", "#2F2C2B"), ("scarf", "#7E3F38"), ("vest", "#5E4A3A"), ("cardigan", "#69705A"),
    ("mustard", "#9C8650"), ("plum", "#5D4652"), ("shirt", "#D9D2C3"), ("trousers", "#4F4A44"),
    ("skirt", "#3E3A3F"), ("tablecloth", "#E9E4DA"), ("cup", "#F4EFE6"), ("cup_band", "#C8402F"),
    ("cup_lid", "#1D3557"), ("camera", "#D3D5D1"), ("lens", "#1A1C1E"), ("leaf_dark", "#2C4324"),
    ("leaf_mid", "#3E5A2E"), ("leaf_light", "#536E3D"), ("flag_red", "#A9534A"), ("flag_ochre", "#B39550"),
    ("flag_teal", "#4F7F7A"), ("flag_cream", "#D8CDB4"), ("hair_grey", "#8A8580"), ("hair_brown", "#4A3828"),
    ("panel", "#2E3236"), ("label", "#C9B98A"), ("drum_green", "#3F5747"), ("drum_blue", "#3D5670"),
    ("pebble", "#8F8B83"), ("frame_navy", "#1D3557"), ("sign_night", "#13202F"), ("bulb_socket", "#2A2622"),
]


def hex_rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def swatch_uv(name):
    """Centro UV (Blender, v hacia arriba) de la celda `name` del atlas."""
    i = [s[0] for s in SWATCHES].index(name)
    cx, cy = (i % 8) * 64 + 32, (i // 8) * 64 + 32
    return cx / 512, 1 - cy / 512


def classify(px):
    """Color de marca más cercano de un píxel del logotipo horizontal (o None si es fondo)."""
    r, g, b, a = px
    if a < 96:
        return None
    best, dist = None, 1e9
    for name, c in (("navy", NAVY), ("red", RED), ("paper", PAPER)):
        d = sum((x - y) ** 2 for x, y in zip((r, g, b), c))
        if d < dist:
            best, dist = name, d
    return best


def logo_crop(with_tagline):
    logo = Image.open(BRAND / "pulpasa_horizontal.png").convert("RGBA")
    bbox = logo.getbbox()
    if not with_tagline:
        # El lema (rojo, a la derecha del símbolo y bajo «Pulpa») se borra; los tentáculos se quedan.
        px = logo.load()
        for y in range(int(logo.height * 0.62), logo.height):
            for x in range(int(logo.width * 0.33), logo.width):
                px[x, y] = (0, 0, 0, 0)
        bbox = logo.getbbox()
    return logo.crop(bbox)


def sign_textures():
    """Cartel luminoso: caja `brand_night`, «Pulpa» y símbolo en neón, placa «SA» roja con letras blancas."""
    w, h = 1024, 384
    logo = logo_crop(False)
    scale = min(900 / logo.width, 300 / logo.height)
    logo = logo.resize((int(logo.width * scale), int(logo.height * scale)), Image.LANCZOS)
    albedo = Image.new("RGB", (w, h), NIGHT)
    emit = Image.new("RGB", (w, h), (0, 0, 0))
    ox, oy = (w - logo.width) // 2, (h - logo.height) // 2
    pa, pe = albedo.load(), emit.load()
    src = logo.load()
    for y in range(logo.height):
        for x in range(logo.width):
            kind = classify(src[x, y])
            if kind is None:
                continue
            p = (ox + x, oy + y)
            if kind == "navy":
                pa[p], pe[p] = NEON, NEON
            elif kind == "red":
                pa[p], pe[p] = RED, (60, 14, 10)
            else:
                pa[p], pe[p] = (255, 255, 255), (255, 244, 236)
    albedo.save(OUT / "sign_albedo.png")
    emit.save(OUT / "sign_emission.png")


def plate_texture():
    """Placa del toldo: logotipo horizontal con lema sobre `brand_paper`, borde marino."""
    w, h = 1024, 352
    img = Image.new("RGB", (w, h), PAPER)
    d = ImageDraw.Draw(img)
    d.rectangle((0, 0, w - 1, h - 1), outline=NAVY, width=18)
    logo = logo_crop(True)
    scale = min(900 / logo.width, 290 / logo.height)
    logo = logo.resize((int(logo.width * scale), int(logo.height * scale)), Image.LANCZOS)
    img.paste(logo, ((w - logo.width) // 2, (h - logo.height) // 2), logo)
    img.save(OUT / "plate_albedo.png")


def soft_blob(size, rng, lobes=7, jitter=0.25):
    """Máscara L de una mancha orgánica (polígono de radios aleatorios suavizado)."""
    w, h = size
    m = Image.new("L", size, 0)
    pts = []
    n = 28
    radii = [1 + rng.uniform(-jitter, jitter) for _ in range(lobes)]
    for i in range(n):
        t = 2 * math.pi * i / n
        k = t / (2 * math.pi) * lobes
        r0, r1 = radii[int(k) % lobes], radii[(int(k) + 1) % lobes]
        f = k - int(k)
        r = r0 + (r1 - r0) * (3 * f * f - 2 * f ** 3)
        pts.append((w / 2 + math.cos(t) * r * w * 0.3, h / 2 + math.sin(t) * r * h * 0.3))
    ImageDraw.Draw(m).polygon(pts, fill=255)
    return m.filter(ImageFilter.GaussianBlur(min(w, h) * 0.04))


def decal_texture():
    """Decals de suelo (1024², 256 px/m): rodada tileable, charcos, manchas, hojas y piedrecitas.

    Filas (px): 0–127 rodada (una rueda de 0,24 m, tileable en horizontal, 4 m); 128–447 tres charcos;
    448–767 tres manchas pisadas; 768–1023 hojas secas y piedrecitas dispersas. Colores de art-bible §2.3:
    rodada y manchas `ground_track`, charco `ground_puddle` (aclarado, §5), contraste ≤ 1,3:1.
    """
    rng = random.Random(85)
    track = hex_rgb("#8A735A")
    puddle = hex_rgb("#6E6A60")
    # Fondo transparente con el color de la rodada (no negro): con alfa sin premultiplicar, el filtrado
    # y los mipmaps mezclan el RGB de los píxeles transparentes y oscurecerían los bordes.
    img = Image.new("RGBA", (1024, 1024), track + (0,))
    # Rodada: banda compactada con tacos del neumático cada 0,09 m (≥ 4 px a 1080p).
    band = Image.new("L", (1024, 128), 0)
    bd = ImageDraw.Draw(band)
    bd.rectangle((0, 34, 1023, 94), fill=120)
    for x in range(0, 1024, 23):
        bd.polygon([(x, 38), (x + 10, 38), (x + 16, 64), (x + 10, 90), (x, 90), (x + 6, 64)], fill=200)
    band = band.filter(ImageFilter.GaussianBlur(2.2))
    # Bordes irregulares (tierra levantada), sin romper la tileabilidad en x.
    edge = Image.new("L", (1024, 128), 255)
    ed = ImageDraw.Draw(edge)
    for x in range(0, 1024, 32):
        ed.ellipse((x - 10, 26 + rng.randint(-3, 3), x + 10, 40), fill=170)
        ed.ellipse((x + 6, 88, x + 26, 102 + rng.randint(-3, 3)), fill=170)
    band = Image.composite(band, Image.new("L", band.size, 0), edge.filter(ImageFilter.GaussianBlur(3)))
    img.paste(Image.new("RGBA", (1024, 128), track + (255,)), (0, 0), band)
    # Charcos: ground_puddle con borde de barro algo más oscuro.
    for i in range(3):
        m = soft_blob((320, 320), rng, lobes=6, jitter=0.3)
        # Borde de barro solo en el anillo exterior; el agua, al 55 % (≤ 1,3:1 contra la tierra, §5 Z0).
        rim = ImageChops.subtract(m.filter(ImageFilter.GaussianBlur(14)), m).point(lambda v: min(255, int(v * 1.2)))
        rim_layer = Image.new("RGBA", (320, 320), track + (255,))
        tile = Image.new("RGBA", (320, 320), track + (0,))
        tile.paste(rim_layer, (0, 0), rim)
        tile.paste(Image.new("RGBA", (320, 320), puddle + (255,)), (0, 0), m.point(lambda v: int(v * 0.55)))
        img.alpha_composite(tile, (i * 341, 128))
    # Manchas pisadas (ground_track a media opacidad).
    for i in range(3):
        m = soft_blob((320, 320), rng, lobes=9, jitter=0.35).filter(ImageFilter.GaussianBlur(10))
        tile = Image.new("RGBA", (320, 320), track + (0,))
        tile.paste(Image.new("RGBA", (320, 320), track + (255,)), (0, 0), m.point(lambda v: int(v * 0.55)))
        img.alpha_composite(tile, (i * 341, 448))
    # Hojas secas (≥ 0,05 m) y piedrecitas, de luminancia parecida a la tierra.
    leaf_cols = [hex_rgb(c) for c in ("#9A7A50", "#A3875A", "#977650")]
    stone_cols = [hex_rgb(c) for c in ("#A89A86", "#8F8576")]
    d = ImageDraw.Draw(img)
    for _ in range(46):
        x, y = rng.randint(20, 1004), rng.randint(788, 1004)
        if rng.random() < 0.55:
            a = rng.uniform(0, math.pi)
            L, W = rng.randint(14, 22), rng.randint(6, 9)
            pts = [(x + math.cos(a) * L, y + math.sin(a) * L), (x + math.cos(a + 1.57) * W, y + math.sin(a + 1.57) * W),
                   (x - math.cos(a) * L, y - math.sin(a) * L), (x - math.cos(a + 1.57) * W, y - math.sin(a + 1.57) * W)]
            d.polygon(pts, fill=rng.choice(leaf_cols) + (225,))
        else:
            r = rng.randint(6, 10)
            d.ellipse((x - r, y - r * 0.8, x + r, y + r * 0.8), fill=rng.choice(stone_cols) + (240,))
    img.save(OUT / "decals_albedo.png")


def fence_texture():
    """Malla romboidal de valla (256² = 1 m): alambre de 6 px, rombo de 0,125 m; alfa recortado."""
    s = 256
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    col = hex_rgb("#6A7676") + (255,)
    for k in range(-s, 2 * s, 32):
        d.line((k, 0, k + s, s), fill=col, width=6)
        d.line((k + s, 0, k, s), fill=col, width=6)
    img.save(OUT / "fence_albedo.png")


def fern_frond(img, box):
    """Fronda de helecho (fento) con alfa: tallo central y pinnas decrecientes hacia la punta."""
    x0, y0, x1, y1 = box
    d = ImageDraw.Draw(img)
    w, h = x1 - x0, y1 - y0
    cx = x0 + w / 2
    dark, mid, light = hex_rgb("#2C4324"), hex_rgb("#3E5A2E"), hex_rgb("#567340")
    n = 13
    for i in range(n):
        t = i / (n - 1)  # 0 base → 1 punta (arriba en la imagen)
        y = y1 - 10 - t * (h - 24)
        span = (w * 0.46) * (1 - t) ** 0.8 + 6
        for side in (-1, 1):
            tip = (cx + side * span, y - span * 0.35)
            pts = [(cx, y + 6), (cx + side * span * 0.5, y - span * 0.12 + 7), tip,
                   (cx + side * span * 0.55, y - span * 0.2 - 7), (cx, y - 8)]
            d.polygon(pts, fill=(mid if i % 2 else light) + (255,))
            d.line([(cx, y), tip], fill=dark + (255,), width=2)
    d.line([(cx, y1 - 2), (cx, y0 + 8)], fill=dark + (255,), width=5)


def board_texture(img, box):
    """Pizarra de menú: fondo noche, logotipo blanco pequeño y líneas de tiza ilegibles (§3.2)."""
    x0, y0, x1, y1 = box
    d = ImageDraw.Draw(img)
    d.rectangle(box, fill=hex_rgb("#1E2A2E") + (255,))
    logo = Image.open(BRAND / "pulpasa_mono_blanco.png").convert("RGBA")
    logo = logo.crop(logo.getbbox())
    logo = logo.crop((0, 0, logo.width, int(logo.height * 0.62)))
    lw = int((x1 - x0) * 0.62)
    logo = logo.resize((lw, int(logo.height * lw / logo.width)), Image.LANCZOS)
    img.alpha_composite(logo, (x0 + (x1 - x0 - lw) // 2, y0 + 10))
    rng = random.Random(7)
    chalk = (226, 222, 210, 230)
    y = y0 + 22 + logo.height
    while y < y1 - 12:
        x = x0 + 18
        end = x1 - 60
        while x < end:
            seg = rng.randint(10, 34)
            d.line((x, y, min(x + seg, end), y + rng.randint(-1, 1)), fill=chalk, width=4)
            x += seg + rng.randint(6, 12)
        d.ellipse((x1 - 40, y - 4, x1 - 30, y + 4), fill=hex_rgb("#FF6B57") + (255,))
        y += 18


def atlas_texture():
    img = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for i, (_, h) in enumerate(SWATCHES):
        x, y = (i % 8) * 64, (i // 8) * 64
        d.rectangle((x, y, x + 63, y + 63), fill=hex_rgb(h) + (255,))
    fern_frond(img, (0, 256, 256, 512))
    board_texture(img, (256, 256, 512, 384))
    img.save(OUT / "atlas_albedo.png")


# Regiones del atlas en UV de Blender (u0, v0, u1, v1) para las mallas.
FERN_UV = (0.0, 0.0, 0.5, 0.5)
BOARD_UV = (0.5, 0.25, 1.0, 0.5)
# Regiones de los decals (u0, v0, u1, v1).
DECAL_TRACK_UV = (0.0, 1 - 128 / 1024, 1.0, 1.0)
DECAL_PUDDLE_UV = [(i * 341 / 1024, 1 - 448 / 1024, (i * 341 + 320) / 1024, 1 - 128 / 1024) for i in range(3)]
DECAL_STAIN_UV = [(i * 341 / 1024, 1 - 768 / 1024, (i * 341 + 320) / 1024, 1 - 448 / 1024) for i in range(3)]
DECAL_LITTER_UV = (0.0, 0.0, 1.0, 256 / 1024)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    sign_textures()
    plate_texture()
    decal_texture()
    fence_texture()
    atlas_texture()
    print("gen_textures: OK", sorted(p.name for p in OUT.glob("*.png")))


if __name__ == "__main__":
    main()
