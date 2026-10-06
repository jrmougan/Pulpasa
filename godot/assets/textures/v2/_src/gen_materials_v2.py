"""Genera la biblioteca de materiales v2 (PUL-074, art-bible v2 §3).

Texturas tileables pintadas proceduralmente (numpy) y horneadas a PNG pequeños, más los
`StandardMaterial3D` de Godot y un manifiesto que lee el script de Blender. Es determinista
(semillas fijas): volver a ejecutarlo reproduce los mismos ficheros.

  python3 godot/assets/textures/v2/_src/gen_materials_v2.py          # desde la raíz del repo
  blender -b --factory-startup --python godot/assets/textures/v2/_src/build_materials_v2_blend.py

Convención de UV (materials-v2.md §2): 1 unidad de UV = 2 m; una textura de 512² da 256 px/m.
Mapas por textura: `_albedo` (sRGB), `_orm` (R oclusión = 1, G roughness, B metallic; lineal) y,
si procede, `_normal` (OpenGL, +Y arriba, como glTF y Godot). Las texturas «neutras» son grises y
el material les da el color con un factor (baseColorFactor / albedo_color); las «propias» ya
llevan el color y su factor es blanco.
"""

import json
import math
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[5]
TEX_DIR = ROOT / "godot" / "assets" / "textures" / "v2"
MAT_DIR = ROOT / "godot" / "assets" / "materials" / "v2"
MANIFEST = TEX_DIR / "_src" / "materials_v2.json"
N = 512
GREY_MEAN = 0.8  # media lineal de las texturas neutras (deja sitio a ±25 % sin saturar)


# --- color ---------------------------------------------------------------------------------------
def hex_rgb(h: str) -> np.ndarray:
    h = h.lstrip("#")
    return np.array([int(h[i : i + 2], 16) / 255.0 for i in (0, 2, 4)])


def to_lin(c):
    c = np.asarray(c, dtype=np.float64)
    return np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)


def to_srgb(c):
    c = np.clip(np.asarray(c, dtype=np.float64), 0.0, 1.0)
    return np.where(c <= 0.0031308, c * 12.92, 1.055 * c ** (1 / 2.4) - 0.055)


def lum(lin_rgb) -> float:
    r, g, b = lin_rgb
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


# --- ruido tileable ------------------------------------------------------------------------------
def gnoise(n: int, sx: float, sy: float, seed: int) -> np.ndarray:
    """Ruido gaussiano filtrado en frecuencia (periódico): sigma sx/sy px en u/v. Media 0, std 1."""
    rng = np.random.default_rng(seed)
    f = np.fft.fft2(rng.standard_normal((n, n)))
    ky = np.fft.fftfreq(n)[:, None]
    kx = np.fft.fftfreq(n)[None, :]
    f *= np.exp(-2.0 * math.pi**2 * ((kx * sx) ** 2 + (ky * sy) ** 2))
    a = np.real(np.fft.ifft2(f))
    return (a - a.mean()) / (a.std() + 1e-9)


def smooth(a: np.ndarray, s: float) -> np.ndarray:
    n = a.shape[0]
    ky = np.fft.fftfreq(n)[:, None]
    kx = np.fft.fftfreq(n)[None, :]
    return np.real(np.fft.ifft2(np.fft.fft2(a) * np.exp(-2.0 * math.pi**2 * s * s * (kx**2 + ky**2))))


def sstep(e0: float, e1: float, x):
    t = np.clip((x - e0) / (e1 - e0), 0.0, 1.0)
    return t * t * (3 - 2 * t)


def blobs(n: int, count: int, rmin: float, rmax: float, seed: int, aspect: float = 1.0) -> np.ndarray:
    """Máscara 0..1 de manchas elípticas suaves que envuelven en los bordes (tileable)."""
    rng = np.random.default_rng(seed)
    yy, xx = np.mgrid[0:n, 0:n].astype(np.float64)
    m = np.zeros((n, n))
    for _ in range(count):
        cx, cy = rng.uniform(0, n, 2)
        r = rng.uniform(rmin, rmax)
        ang = rng.uniform(0, math.pi)
        dx = (xx - cx + n / 2) % n - n / 2
        dy = (yy - cy + n / 2) % n - n / 2
        u = dx * math.cos(ang) + dy * math.sin(ang)
        v = -dx * math.sin(ang) + dy * math.cos(ang)
        d = np.sqrt((u / (r * aspect)) ** 2 + (v / r) ** 2)
        m = np.maximum(m, 1.0 - sstep(0.75, 1.0, d))
    return m


def segments(n: int, count: int, lmin: float, lmax: float, width: float, seed: int, ang_range=None):
    """Trazos rectos (arañazos, cortes de cuchillo) de `width` px, tileables. Máscara 0..1."""
    rng = np.random.default_rng(seed)
    yy, xx = np.mgrid[0:n, 0:n].astype(np.float64)
    m = np.zeros((n, n))
    for _ in range(count):
        cx, cy = rng.uniform(0, n, 2)
        length = rng.uniform(lmin, lmax)
        ang = rng.uniform(*(ang_range or (0, math.pi)))
        dx = (xx - cx + n / 2) % n - n / 2
        dy = (yy - cy + n / 2) % n - n / 2
        u = dx * math.cos(ang) + dy * math.sin(ang)
        v = -dx * math.sin(ang) + dy * math.cos(ang)
        along = 1.0 - sstep(length / 2 - 4, length / 2, np.abs(u))
        across = 1.0 - sstep(width / 2 - 0.5, width / 2 + 0.75, np.abs(v))
        m = np.maximum(m, along * across)
    return m


def normal_from_height(h: np.ndarray, strength: float) -> np.ndarray:
    """Normal tangente OpenGL (+Y = v hacia arriba de la imagen) desde una altura en px."""
    dx = (np.roll(h, -1, axis=1) - np.roll(h, 1, axis=1)) * 0.5
    dy = (np.roll(h, -1, axis=0) - np.roll(h, 1, axis=0)) * 0.5
    nx, ny, nz = -dx * strength, dy * strength, np.ones_like(h)
    ln = np.sqrt(nx * nx + ny * ny + nz * nz)
    return np.stack([nx / ln, ny / ln, nz / ln], axis=-1) * 0.5 + 0.5


# --- escritura -----------------------------------------------------------------------------------
def save_rgb(path: Path, rgb01: np.ndarray, alpha=None) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    a = np.clip(np.round(rgb01 * 255.0), 0, 255).astype(np.uint8)
    if alpha is not None:
        al = np.clip(np.round(alpha * 255.0), 0, 255).astype(np.uint8)[..., None]
        Image.fromarray(np.concatenate([a, al], axis=-1), "RGBA").save(path, optimize=True)
    else:
        Image.fromarray(a, "RGB").save(path, optimize=True)


TEXTURES: dict = {}


def put_texture(name: str, albedo_lin: np.ndarray, rough: np.ndarray, metal, normal=None, alpha=None):
    """albedo en lineal (n,n,3) o (n,n); rough/metal relativos 0..1 (se multiplican por el factor)."""
    if albedo_lin.ndim == 2:
        albedo_lin = np.repeat(albedo_lin[..., None], 3, axis=-1)
    albedo_lin = np.clip(albedo_lin, 0.0, 1.0)
    n = albedo_lin.shape[0]
    d = TEX_DIR / name
    files = {"albedo": f"{name}/{name}_albedo.png"}
    save_rgb(d / f"{name}_albedo.png", to_srgb(albedo_lin), alpha)
    metal_a = np.broadcast_to(np.asarray(metal, dtype=np.float64), (n, n))
    orm = np.stack([np.ones((n, n)), np.clip(rough, 0, 1), np.clip(metal_a, 0, 1)], axis=-1)
    save_rgb(d / f"{name}_orm.png", orm)
    files["orm"] = f"{name}/{name}_orm.png"
    if normal is not None:
        save_rgb(d / f"{name}_normal.png", normal)
        files["normal"] = f"{name}/{name}_normal.png"
    # Media lineal tal como la ve la cámara (con mipmaps, la media es el color a distancia).
    if alpha is not None:
        w = alpha[..., None]
        mean = (albedo_lin * w).sum(axis=(0, 1)) / w.sum()
    else:
        mean = albedo_lin.mean(axis=(0, 1))
    TEXTURES[name] = {"files": files, "size": n, "mean_lin": mean.tolist(), "alpha": alpha is not None}


def grey_norm(mod: np.ndarray) -> np.ndarray:
    """Textura neutra: modulación (media 0) → gris lineal de media GREY_MEAN, sin saturar."""
    g = GREY_MEAN * (1.0 + mod)
    g = np.clip(g, 0.0, 1.0)
    return g * (GREY_MEAN / g.mean())


def colorize(target_hex: str, mod: np.ndarray, overlays=()) -> np.ndarray:
    """Textura con color propio: base × (1+mod) + capas (máscara, color hex), media ajustada al hex."""
    t = to_lin(hex_rgb(target_hex))
    img = t[None, None, :] * (1.0 + mod[..., None])
    for mask, hexc in overlays:
        c = to_lin(hex_rgb(hexc))
        img = img * (1 - mask[..., None]) + c[None, None, :] * mask[..., None]
    img = np.clip(img, 0.0, 1.0)
    # Reescala por canal para que la media quede en el hex (§2: ≤ 10 % a distancia de cámara).
    img = np.clip(img * (t / img.mean(axis=(0, 1)))[None, None, :], 0.0, 1.0)
    return img


# --- texturas ------------------------------------------------------------------------------------
def tex_steel() -> None:
    # Cepillado direccional suave en u (vetas de ≥ 10 px de ancho, contraste bajo) y manchas de agua.
    streak = gnoise(N, 90, 3.5, 11)
    stain = blobs(N, 7, 28, 60, 12) * (0.5 + 0.5 * gnoise(N, 6, 6, 13).clip(-1, 1))
    mod = 0.05 * streak - 0.06 * stain + 0.03 * gnoise(N, 40, 40, 14)
    h = streak * 0.6
    rough = 0.9 + 0.06 * streak + 0.05 * stain
    put_texture("steel_brushed", grey_norm(mod), rough.clip(0.75, 1.0), 1.0, normal_from_height(h, 0.35))
    # Tablero: lo mismo con arañazos finos y claros (3 px, contraste ≤ 1,1:1), solo en tableros.
    scr = segments(N, 46, 30, 120, 3.0, 15)
    mod2 = mod + 0.07 * scr
    rough2 = rough - 0.15 * scr
    put_texture(
        "steel_brushed_top", grey_norm(mod2), rough2.clip(0.7, 1.0), 1.0, normal_from_height(h - 1.2 * scr, 0.35)
    )


def tex_plastic() -> None:
    # Liso; roces claros alargados y escasos, más mates.
    scuff = blobs(N, 14, 8, 18, 21, aspect=3.5) * sstep(-0.2, 0.6, gnoise(N, 5, 5, 22))
    mod = 0.12 * scuff + 0.025 * gnoise(N, 60, 60, 23)
    rough = 0.9 + 0.1 * scuff
    put_texture("plastic", grey_norm(mod), rough.clip(0, 1), 0.0)


def wood_height(seed: int, period: float) -> np.ndarray:
    yy, xx = np.mgrid[0:N, 0:N].astype(np.float64)
    warp = 14.0 * gnoise(N, 70, 30, seed)
    k = 2 * math.pi * round(N / period) / N
    rings = np.sin(k * (yy + warp))
    return 0.6 * rings + 0.4 * gnoise(N, 120, 6, seed + 1)


def tex_wood() -> None:
    # Veta pintada ancha (periodo ≈ 0,15 m) a lo largo de u; cortes de cuchillo en la usada.
    g = wood_height(31, 38)
    cuts = segments(N, 26, 40, 110, 3.0, 33)
    mod = 0.16 * g - 0.18 * cuts + 0.04 * gnoise(N, 50, 50, 34)
    rough = 0.95 + 0.05 * g * 0.5
    put_texture("wood_used", grey_norm(mod), rough.clip(0, 1), 0.0, normal_from_height(1.5 * g - 2.0 * cuts, 0.25))
    g2 = wood_height(41, 46)
    mod2 = 0.2 * g2 + 0.05 * gnoise(N, 50, 50, 44)
    put_texture("wood_dark", grey_norm(mod2), np.full((N, N), 0.97), 0.0, normal_from_height(1.5 * g2, 0.25))


def weave(thread: int, seed: int, slub: float):
    """Trama de tafetán: hilos de `thread` px que pasan por encima/debajo; devuelve la altura."""
    yy, xx = np.mgrid[0:N, 0:N].astype(np.float64)
    cu = np.cos(math.pi * (xx % thread) / thread - math.pi / 2)  # perfil del hilo vertical
    cv = np.cos(math.pi * (yy % thread) / thread - math.pi / 2)
    over = ((xx // thread + yy // thread) % 2).astype(np.float64)
    h = over * cu + (1 - over) * cv
    return h + slub * gnoise(N, 40, 40, seed)


def tex_burlap() -> None:
    # Trama gruesa: hilo de 16 px ≈ 6 cm ≥ 4 px a 1080p.
    h = weave(16, 51, 0.35)
    mod = 0.14 * h + 0.06 * gnoise(N, 60, 60, 52)
    put_texture(
        "burlap",
        colorize("#9C7D59", mod, [(0.6 * blobs(N, 5, 20, 40, 53) * 0.3, "#7E6446")]),
        np.full((N, N), 1.0),
        0.0,
        normal_from_height(2.5 * h, 0.5),
    )


def tex_canvas() -> None:
    # Lona: trama fina y suave (8 px), costura horizontal con puntadas, neutra (se tiñe por material).
    h = weave(8, 61, 0.2) * 0.5
    yy, xx = np.mgrid[0:N, 0:N].astype(np.float64)
    seam_band = 1.0 - sstep(5, 8, np.abs(yy - N / 2))
    stitch = seam_band * (((xx // 12) % 2) == 0) * (1.0 - sstep(1.0, 2.5, np.abs(yy - N / 2 + 3)))
    mod = 0.05 * h - 0.10 * seam_band + 0.12 * stitch + 0.04 * gnoise(N, 70, 70, 62)
    put_texture("canvas", grey_norm(mod), np.full((N, N), 1.0), 0.0, normal_from_height(1.2 * h - 3 * seam_band, 0.5))


def tex_cardboard() -> None:
    # Cartón: manchas grandes, cinta adhesiva en banda y garabatos de rotulador sin texto.
    yy, xx = np.mgrid[0:N, 0:N].astype(np.float64)
    tape = 1.0 - sstep(18, 22, np.abs(yy - 150))
    marks = segments(N, 9, 30, 70, 5.0, 71)
    mod = 0.08 * gnoise(N, 50, 50, 72) + 0.04 * gnoise(N, 120, 8, 73)
    img = colorize("#B8935F", mod, [(tape * 0.55, "#D4B88A"), (marks * 0.8, "#3A3430")])
    rough = 1.0 - 0.45 * tape
    put_texture("cardboard", img, rough, 0.0)


def tex_clay() -> None:
    # Barro: moteado grande; zonas de vidriado parcial más claras y menos rugosas.
    glaze = sstep(0.3, 0.9, gnoise(N, 45, 45, 81))
    mod = 0.07 * gnoise(N, 25, 25, 82) + 0.12 * glaze
    rough = 1.0 - 0.45 * glaze
    put_texture("clay", colorize("#A85A3A", mod), rough, 0.0, normal_from_height(1.0 * gnoise(N, 10, 10, 83), 0.4))


def tex_paint(name: str, hexc: str, seed: int) -> None:
    # Pintura con desconchado que deja ver steel_mid (metallic 1). El desconchado fino de aristas va
    # en el atlas de cada asset (máscara de curvatura horneada); aquí solo saltados sueltos.
    chip_n = gnoise(N, 9, 9, seed) + 0.8 * gnoise(N, 40, 40, seed + 1)
    chip = sstep(2.0, 2.25, chip_n)
    rim = np.clip(sstep(1.7, 2.0, chip_n) - chip, 0, 1)
    mod = 0.06 * gnoise(N, 60, 60, seed + 2) - 0.25 * rim
    img = colorize(hexc, mod, [(chip, "#7D868D")])
    rough = 1.0 - 0.35 * chip
    put_texture(name, img, rough, chip, normal_from_height(-2.0 * chip, 0.6))


def tex_granite() -> None:
    # Sillares irregulares: 4 hiladas de 0,5 m, anchos variables, juntas oscuras, mica ≥ 4 px y musgo
    # en las juntas bajas de algunas piezas (Z3).
    rng = np.random.default_rng(91)
    yy, xx = np.mgrid[0:N, 0:N].astype(np.float64)
    row_h = N // 4
    block_id = np.zeros((N, N), dtype=np.int64)
    edge_d = np.full((N, N), 1e9)
    for r in range(4):
        y0, y1 = r * row_h, (r + 1) * row_h
        widths = []
        while sum(widths) < N - 120:
            widths.append(int(rng.integers(130, 220)))
        widths.append(N - sum(widths))
        off = int(rng.integers(0, N))
        cuts = (np.cumsum([0] + widths[:-1]) + off) % N
        rows = slice(y0, y1)
        xr = xx[rows]
        dvert = np.min(np.stack([np.abs((xr - c + N / 2) % N - N / 2) for c in cuts]), axis=0)
        dhor = np.minimum(yy[rows] - y0, y1 - 1 - yy[rows])
        edge_d[rows] = np.minimum(dvert, dhor)
        # id por pieza: índice del corte a la izquierda
        rel = (xr - cuts[0]) % N
        bounds = np.cumsum(widths)
        bid = np.searchsorted(bounds, rel, side="right") + r * 100
        block_id[rows] = bid
    jitter = 1.5 * gnoise(N, 6, 6, 92)
    joint = 1.0 - sstep(2.5, 4.5, edge_d + jitter)
    tone = np.zeros((N, N))
    for b in np.unique(block_id):
        tone[block_id == b] = rng.uniform(-0.07, 0.07)
    mica_n = gnoise(N, 2.2, 2.2, 93)
    mica_l = sstep(1.7, 2.0, mica_n)
    mica_d = sstep(1.7, 2.0, -mica_n)
    moss = joint * sstep(0.2, 0.8, gnoise(N, 25, 25, 94)) * (((yy % row_h) > row_h * 0.6))
    mod = tone + 0.05 * gnoise(N, 30, 30, 95)
    img = colorize(
        "#8C8A84",
        mod,
        [(mica_l * 0.8, "#B5B2AA"), (mica_d * 0.8, "#4F4D49"), (joint, "#5E5C57"), (moss * 0.8, "#5E6B3A")],
    )
    bevel = sstep(2.0, 12.0, edge_d)
    rough = np.full((N, N), 1.0)
    put_texture("granite", img, rough, 0.0, normal_from_height(6.0 * bevel + 0.6 * gnoise(N, 4, 4, 96), 0.5))


def tex_ground() -> None:
    # Tierra apisonada 1024² (4 m): moteado, zonas pisadas (ground_track ≤ 1,3:1), piedrecitas con
    # relieve ≤ 2 cm y alguna hoja seca. Rodadas y charcos (ground_puddle, roughness 0,1) van como
    # decal (art-bible §5, Z0): un charco dentro de la textura se repite cada 4 m y se nota.
    n = 1024
    def gn(sx, sy, seed):
        return gnoise(n, sx, sy, seed)

    trod = sstep(0.4, 1.2, gn(90, 90, 101))
    pebbles_n = gn(4, 4, 102) + 0.5 * gn(30, 30, 103)
    peb_l = sstep(2.3, 2.6, pebbles_n)
    peb_d = sstep(2.3, 2.6, -pebbles_n)
    leaves = segments(n, 10, 14, 22, 9.0, 104) * sstep(0.0, 0.5, gn(3, 3, 105))
    mod = 0.07 * gn(25, 25, 107) + 0.05 * gn(6, 6, 108)
    img = colorize(
        "#A18668",
        mod,
        [
            (trod * 0.55, "#8A735A"),
            (peb_l * 0.7, "#B9AC98"),
            (peb_d * 0.6, "#6F6252"),
            (leaves * 0.7, "#8F6A3E"),
        ],
    )
    rough = np.full((n, n), 1.0)
    h = 4.0 * (peb_l + peb_d) + 0.8 * gn(5, 5, 109)
    put_texture("ground_dirt", img, rough, 0.0, normal_from_height(h, 0.4))


def tex_grass() -> None:
    # Hierba pintada a pinceladas alargadas (fuera de la zona jugable).
    strokes = gnoise(N, 4, 14, 111)
    mod = 0.12 * strokes + 0.10 * gnoise(N, 50, 50, 112)
    img = colorize("#66713C", mod, [(sstep(1.6, 2.2, strokes) * 0.6, "#879050")])
    put_texture("grass", img, np.full((N, N), 1.0), 0.0)


def tex_foliage() -> None:
    # Tarjeta de hojas con alfa (scissor): racimos de hojas grandes para helechos y copas (Z3).
    rng = np.random.default_rng(121)
    yy, xx = np.mgrid[0:N, 0:N].astype(np.float64)
    alpha = np.zeros((N, N))
    shade = np.zeros((N, N))
    for _ in range(70):
        cx, cy = rng.uniform(40, N - 40, 2)
        r = rng.uniform(18, 34)
        ang = rng.uniform(0, math.pi)
        u = (xx - cx) * math.cos(ang) + (yy - cy) * math.sin(ang)
        v = -(xx - cx) * math.sin(ang) + (yy - cy) * math.cos(ang)
        leaf = 1.0 - sstep(0.85, 1.0, np.sqrt((u / (r * 2.2)) ** 2 + (v / r) ** 2))
        shade = np.where(leaf > alpha, rng.uniform(0, 1) * (0.5 + 0.5 * np.clip(-v / r, 0, 1)), shade)
        alpha = np.maximum(alpha, leaf)
    # Borde suave del racimo: la tarjeta acaba antes del límite de la imagen (no es tileable).
    cut = (alpha > 0.5).astype(np.float64)
    img = colorize("#3E5A2E", 0.15 * (shade - 0.5) + 0.05 * gnoise(N, 20, 20, 122), [(shade * 0.5 * cut, "#2C4324")])
    TEXTURES.pop("foliage", None)
    put_texture("foliage", img, np.full((N, N), 1.0), 0.0, alpha=cut)


def tex_cloth() -> None:
    # Tela de personaje: pliegues pintados grandes (verticales) y trama casi invisible; neutra.
    folds = gnoise(N, 40, 140, 131)
    mod = 0.14 * folds + 0.03 * gnoise(N, 10, 10, 132)
    put_texture("cloth", grey_norm(mod), np.full((N, N), 1.0), 0.0, normal_from_height(3.0 * folds, 0.5))


def tex_burnt(name: str, hexc: str, seed: int) -> None:
    # Quemado: carbón con grietas grandes (celdas ≈ 0,12 m) de brasa #5A2A1E; sin ruido fino.
    n = 512
    rng = np.random.default_rng(seed)
    pts = rng.uniform(0, n, (40, 2))
    yy, xx = np.mgrid[0:n, 0:n].astype(np.float64)
    d1 = np.full((n, n), 1e9)
    d2 = np.full((n, n), 1e9)
    for px, py in pts:
        dx = (xx - px + n / 2) % n - n / 2
        dy = (yy - py + n / 2) % n - n / 2
        d = np.sqrt(dx * dx + dy * dy)
        d2 = np.minimum(d2, np.maximum(d1, d))
        d1 = np.minimum(d1, d)
    crack = 1.0 - sstep(3.0, 7.0, d2 - d1)
    mod = 0.15 * gnoise(n, 30, 30, seed + 1)
    img = colorize(hexc, mod, [(crack * 0.9, "#5A2A1E")])
    put_texture(name, img, np.full((n, n), 1.0), 0.0, normal_from_height(-4.0 * crack, 0.5))


# --- materiales ----------------------------------------------------------------------------------
# (nombre, textura o None, color hex objetivo, roughness, metallic, extras)
# Con textura neutra el color sale del factor; con textura propia (colorize) el factor es blanco.
NEUTRAL = {"steel_brushed", "steel_brushed_top", "plastic", "wood_used", "wood_dark", "canvas", "cloth"}
MATERIALS = [
    ("mat_steel_brushed", "steel_brushed", "#B9BEC2", 0.40, 1.0, {}),
    ("mat_steel_brushed_top", "steel_brushed_top", "#9EA5AA", 0.42, 1.0, {}),
    ("mat_steel_brushed_mid", "steel_brushed", "#7D868D", 0.45, 1.0, {}),
    ("mat_steel_dark", "steel_brushed", "#4E5458", 0.50, 0.8, {}),
    ("mat_copper", "steel_brushed", "#C8672E", 0.40, 1.0, {"note": "solo atrezo de fondo (§3.1)"}),
    ("mat_paint_worn_grey", "paint_grey", "#5F6A6E", 0.60, 1.0, {}),
    ("mat_paint_worn_beige", "paint_beige", "#B29770", 0.60, 1.0, {}),
    ("mat_plastic_red", "plastic", "#C8402F", 0.45, 0.0, {}),
    ("mat_plastic_blue", "plastic", "#3E78B0", 0.45, 0.0, {}),
    ("mat_wood_used", "wood_used", "#B58A5C", 0.70, 0.0, {}),
    ("mat_wood_dark", "wood_dark", "#553E30", 0.70, 0.0, {}),
    ("mat_burlap", "burlap", "#9C7D59", 0.90, 0.0, {}),
    ("mat_cardboard", "cardboard", "#B8935F", 0.85, 0.0, {}),
    ("mat_clay", "clay", "#A85A3A", 0.75, 0.0, {}),
    ("mat_canvas_red", "canvas", "#C8402F", 0.85, 0.0, {}),
    ("mat_canvas_paper", "canvas", "#F4EFE6", 0.85, 0.0, {}),
    ("mat_canvas_stand_1", "canvas", "#D2473F", 0.85, 0.0, {}),
    ("mat_canvas_stand_2", "canvas", "#3F7CC8", 0.85, 0.0, {}),
    ("mat_canvas_stand_3", "canvas", "#E8C23A", 0.85, 0.0, {}),
    ("mat_canvas_stand_4", "canvas", "#4FA05A", 0.85, 0.0, {}),
    ("mat_granite", "granite", "#8C8A84", 0.85, 0.0, {}),
    ("mat_rubber", None, "#24272A", 0.70, 0.0, {}),
    ("mat_rubber_hose_red", None, "#8E2F2A", 0.70, 0.0, {}),
    ("mat_rubber_hose_green", None, "#3F6B45", 0.70, 0.0, {}),
    ("mat_ground_dirt", "ground_dirt", "#A18668", 0.95, 0.0, {"uv_m": 4.0}),
    ("mat_grass", "grass", "#66713C", 0.90, 0.0, {}),
    ("mat_foliage", "foliage", "#3E5A2E", 0.90, 0.0, {"alpha": "scissor", "cull": "disabled"}),
    ("mat_glass_water", None, "#8FC6D8", 0.05, 0.0, {"alpha": "blend", "alpha_value": 0.55}),
    ("mat_emissive_bulb", None, "#FFD58A", 0.50, 0.0, {"emission": 2.0}),
    ("mat_emissive_screen", None, "#8FD3F0", 0.50, 0.0, {"emission": 0.6}),
    ("mat_emissive_neon", None, "#FF6B57", 0.50, 0.0, {"emission": 2.5}),
    ("mat_cloth_shirt", "cloth", "#F2F0EC", 0.90, 0.0, {}),
    ("mat_cloth_pants", "cloth", "#1D3557", 0.90, 0.0, {}),
    ("mat_cloth_player_1", "cloth", "#2F6FB5", 0.90, 0.0, {}),
    ("mat_cloth_player_2", "cloth", "#E0A02E", 0.90, 0.0, {}),
    ("mat_skin_light", None, "#EBC49A", 0.70, 0.0, {}),
    ("mat_skin_dark", None, "#A8734D", 0.70, 0.0, {}),
    ("mat_food_octopus_raw", None, "#E0AFB2", 0.40, 0.0, {}),
    ("mat_food_octopus_cooked", None, "#B8283D", 0.50, 0.0, {}),
    ("mat_food_octopus_pieces", None, "#D4506A", 0.50, 0.0, {}),
    ("mat_food_octopus_burnt", "burnt_octopus", "#2A2320", 0.95, 0.0, {}),
    ("mat_food_potato_raw", None, "#8E6B47", 0.80, 0.0, {}),
    ("mat_food_potato_cooked", None, "#F2D56B", 0.60, 0.0, {}),
    ("mat_food_potato_burnt", "burnt_potato", "#2E2620", 0.95, 0.0, {}),
    ("mat_food_tray_liner", None, "#F4EFE6", 0.80, 0.0, {}),
]


def tres_text(m: dict) -> str:
    ext, lines = [], []
    tex = m["texture"]
    if tex:
        files = TEXTURES[tex]["files"]
        for i, key in enumerate(("albedo", "orm", "normal"), start=1):
            if key in files:
                ext.append(f'[ext_resource type="Texture2D" path="res://assets/textures/v2/{files[key]}" id="{i}_{key}"]')
    c = m["factor_srgb"]
    alpha = m["extras"].get("alpha_value", 1.0)
    lines.append(f'resource_name = "{m["name"]}"')
    if m["extras"].get("alpha") == "blend":
        lines.append("transparency = 1")
    elif m["extras"].get("alpha") == "scissor":
        lines.append("transparency = 2")
        lines.append("alpha_scissor_threshold = 0.5")
    if m["extras"].get("cull") == "disabled":
        lines.append("cull_mode = 2")
    lines.append(f"albedo_color = Color({c[0]:.4f}, {c[1]:.4f}, {c[2]:.4f}, {alpha:.2f})")
    if tex:
        lines.append('albedo_texture = ExtResource("1_albedo")')
    lines.append(f"metallic = {m['metallic']:.2f}")
    if tex:
        lines.append('metallic_texture = ExtResource("2_orm")')
        lines.append("metallic_texture_channel = 2")
    lines.append(f"roughness = {m['roughness']:.2f}")
    if tex:
        lines.append('roughness_texture = ExtResource("2_orm")')
        lines.append("roughness_texture_channel = 1")
    if tex and "normal" in TEXTURES[tex]["files"]:
        lines.append("normal_enabled = true")
        lines.append(f"normal_scale = {m['normal_strength']:.2f}")
        lines.append('normal_texture = ExtResource("3_normal")')
    em = m["extras"].get("emission")
    if em:
        lines.append("emission_enabled = true")
        lines.append(f"emission = Color({c[0]:.4f}, {c[1]:.4f}, {c[2]:.4f}, 1)")
        lines.append(f"emission_energy_multiplier = {em:.2f}")
    if tex:
        lines.append(f"uv1_scale = Vector3({1.0:.1f}, {1.0:.1f}, {1.0:.1f})")
        lines.append("texture_filter = 5")
    head = f'[gd_resource type="StandardMaterial3D" load_steps={len(ext) + 1} format=3]'
    return "\n".join([head, ""] + ext + ([""] if ext else []) + ["[resource]"] + lines) + "\n"


def main() -> None:
    tex_steel()
    tex_plastic()
    tex_wood()
    tex_burlap()
    tex_canvas()
    tex_cardboard()
    tex_clay()
    tex_paint("paint_grey", "#5F6A6E", 151)
    tex_paint("paint_beige", "#B29770", 161)
    tex_granite()
    tex_ground()
    tex_grass()
    tex_foliage()
    tex_cloth()
    tex_burnt("burnt_octopus", "#2A2320", 141)
    tex_burnt("burnt_potato", "#2E2620", 171)
    MAT_DIR.mkdir(parents=True, exist_ok=True)
    mats = []
    for name, tex, hexc, rough, metal, extras in MATERIALS:
        target = to_lin(hex_rgb(hexc))
        if tex is None:
            factor = target
            mean = target
        elif tex in NEUTRAL:
            tmean = np.array(TEXTURES[tex]["mean_lin"])
            factor = np.clip(target / tmean, 0.0, 1.0)
            mean = factor * tmean
        else:
            factor = np.ones(3)
            mean = np.array(TEXTURES[tex]["mean_lin"])
        mean_srgb = to_srgb(mean)
        tgt_srgb = hex_rgb(hexc)
        dl = abs(lum(mean) - lum(target)) / max(lum(target), 1e-6)
        m = {
            "name": name,
            "texture": tex,
            "hex": hexc,
            "factor_lin": [float(x) for x in factor],
            "factor_srgb": [float(x) for x in to_srgb(factor)],
            "roughness": rough,
            "metallic": metal,
            "normal_strength": 1.0,
            "extras": extras,
            "mean_srgb": "#" + "".join(f"{round(float(v) * 255):02X}" for v in mean_srgb),
            "max_channel_diff": float(np.max(np.abs(mean_srgb - tgt_srgb))),
            "lum_diff": float(dl),
        }
        mats.append(m)
        (MAT_DIR / f"{name}.tres").write_text(tres_text(m), encoding="utf-8")
    MANIFEST.write_text(
        json.dumps({"uv_meters_per_unit": 2.0, "textures": TEXTURES, "materials": mats}, indent=1) + "\n",
        encoding="utf-8",
    )
    for m in mats:
        flag = "OK" if m["max_channel_diff"] <= 0.10 and m["lum_diff"] <= 0.10 else "FUERA"
        print(f"{m['name']:28s} {m['hex']} media {m['mean_srgb']} Δcanal {m['max_channel_diff']:.3f} "
              f"ΔL {m['lum_diff'] * 100:4.1f}% {flag}")


if __name__ == "__main__":
    main()
