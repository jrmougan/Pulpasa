#!/usr/bin/env python3
"""Genera la identidad de PulpaSA (PUL-088): SVG fuente, PNG para Godot y láminas.

Uso (desde la raíz del repo):
    uv run --with fonttools --with uharfbuzz python art/brand/build_brand.py

El texto se convierte a trazados con fontTools + HarfBuzz, así que los SVG generados no
dependen de las fuentes instaladas. Las fuentes (SIL OFL 1.1) se leen de las rutas del sistema
de FONTS; ver docs/art/brand.md. Los PNG se rasterizan con ImageMagick (delegado librsvg).
"""

from __future__ import annotations

import subprocess
from dataclasses import dataclass
from pathlib import Path

import uharfbuzz as hb
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen
from fontTools.ttLib import TTFont

ROOT = Path(__file__).resolve().parents[2]
SRC_DIR = ROOT / "art" / "brand"
TEX_DIR = ROOT / "godot" / "assets" / "textures" / "brand"
EVI_DIR = ROOT / "docs" / "evidence" / "PUL-088"

FONTS = {
    "montserrat_black": "/usr/share/fonts/julietaula-montserrat-fonts/Montserrat-Black.otf",
    "montserrat_bold": "/usr/share/fonts/julietaula-montserrat-fonts/Montserrat-Bold.otf",
    "comfortaa_bold": "/usr/share/fonts/aajohan-comfortaa-fonts/Comfortaa-Bold.otf",
    "inter_black": "/usr/share/fonts/rsms-inter-fonts/InterDisplay-Black.ttf",
    "inter_bold": "/usr/share/fonts/rsms-inter-fonts/Inter-Bold.ttf",
}


# --------------------------------------------------------------------------- texto


class Face:
    _cache: dict[str, "Face"] = {}

    def __init__(self, path: str) -> None:
        self.tt = TTFont(path)
        self.glyphs = self.tt.getGlyphSet()
        self.order = self.tt.getGlyphOrder()
        self.upem = self.tt["head"].unitsPerEm
        os2 = self.tt["OS/2"]
        self.cap = getattr(os2, "sCapHeight", 0) or int(self.upem * 0.7)
        blob = hb.Blob.from_file_path(path)
        self.hb_font = hb.Font(hb.Face(blob))

    @classmethod
    def get(cls, key: str) -> "Face":
        if key not in cls._cache:
            cls._cache[key] = Face(FONTS[key])
        return cls._cache[key]


def text_path(font: str, text: str, size: float, x: float, y: float, track: float = 0.0):
    """Devuelve (d, ancho, alto_mayúsculas) del texto con la línea base en (x, y)."""
    face = Face.get(font)
    buf = hb.Buffer()
    buf.add_str(text)
    buf.guess_segment_properties()
    hb.shape(face.hb_font, buf, {"kern": True, "liga": True})
    s = size / face.upem
    pen = SVGPathPen(face.glyphs)
    cx = 0.0
    for info, pos in zip(buf.glyph_infos, buf.glyph_positions):
        name = face.order[info.codepoint]
        tp = TransformPen(pen, (s, 0, 0, -s, x + (cx + pos.x_offset) * s, y - pos.y_offset * s))
        face.glyphs[name].draw(tp)
        cx += pos.x_advance + track * face.upem
    width = (cx - track * face.upem) * s
    return pen.getCommands(), width, face.cap * s


# --------------------------------------------------------------------------- propuestas


@dataclass
class Brand:
    key: str
    name: str
    tagline: str
    word_font: str
    tag_font: str
    main: str  # color del símbolo y de «Pulpa»
    accent: str  # placa de «SA»
    paper: str  # fondo claro
    dark: str  # fondo oscuro (cartel, HUD)
    extra: str  # color de apoyo
    neon: str  # tubo del cartel luminoso
    stripe: str  # rayas del toldo (con paper)
    symbol: str  # "redondo" | "romaria" | "caldeiro"
    track: float = 0.0


BRANDS = [
    Brand(
        "a",
        "Mariña",
        "FRANQUICIA GALEGA DE POLBO",
        "montserrat_black",
        "montserrat_bold",
        main="#1D3557",
        accent="#C8402F",
        paper="#F4EFE6",
        dark="#13202F",
        extra="#5B8DB8",
        neon="#FF6B57",
        stripe="#C8402F",
        symbol="redondo",
        track=-0.01,
    ),
    Brand(
        "b",
        "Romaría",
        "POLBO DE FESTA",
        "comfortaa_bold",
        "comfortaa_bold",
        main="#5E2A6E",
        accent="#1C9C8F",
        paper="#FFF4E2",
        dark="#24132B",
        extra="#F28C9B",
        neon="#FF8FB1",
        stripe="#5E2A6E",
        symbol="romaria",
        track=-0.02,
    ),
    Brand(
        "c",
        "Caldeiro",
        "SOCIEDADE ANÓNIMA DO POLBO",
        "inter_black",
        "inter_bold",
        main="#12403C",
        accent="#C1722F",
        paper="#F3E6CC",
        dark="#0D2523",
        extra="#7FA89A",
        neon="#FFB27A",
        stripe="#12403C",
        symbol="caldeiro",
        track=-0.02,
    ),
]

_uid = [0]


def uid(prefix: str) -> str:
    _uid[0] += 1
    return f"{prefix}{_uid[0]}"


# --------------------------------------------------------------------------- símbolo
# Todos los símbolos se dibujan en una caja de 100 × 100 y se cortan los ojos con una máscara,
# así funcionan sobre cualquier fondo y en monocromo.


def symbol(b: Brand, x: float, y: float, size: float, col: str, col2: str | None = None) -> str:
    col2 = col2 or col
    m = uid("eyes")
    k = size / 100.0
    t = f'transform="translate({x:.2f},{y:.2f}) scale({k:.4f})"'
    st = 'fill="none" stroke-linecap="round" stroke-linejoin="round"'
    if b.symbol == "redondo":
        mask = (
            f'<mask id="{m}" maskUnits="userSpaceOnUse" x="0" y="0" width="100" height="100">'
            '<rect width="100" height="100" fill="#fff"/>'
            '<circle cx="40" cy="40" r="5.5" fill="#000"/><circle cx="60" cy="40" r="5.5" fill="#000"/>'
            "</mask>"
        )
        head = "M21,50 C21,22 35,8 50,8 C65,8 79,22 79,50 C79,60 70,64 50,64 C30,64 21,60 21,50 Z"
        arms = (
            "M30,59 C22,70 12,72 9,64",
            "M41,62 C38,78 28,88 20,83",
            "M59,62 C62,78 72,88 80,83",
            "M70,59 C78,70 88,72 91,64",
        )
        body = f'<path d="{head}" fill="{col}" mask="url(#{m})"/>'
        body += "".join(f'<path d="{a}" stroke="{col}" stroke-width="9" {st}/>' for a in arms)
    elif b.symbol == "romaria":
        mask = (
            f'<mask id="{m}" maskUnits="userSpaceOnUse" x="0" y="0" width="100" height="100">'
            '<rect width="100" height="100" fill="#fff"/>'
            '<ellipse cx="39" cy="38" rx="5" ry="6.5" fill="#000"/>'
            '<ellipse cx="61" cy="38" rx="5" ry="6.5" fill="#000"/>'
            '<path d="M42,50 Q50,57 58,50" stroke="#000" stroke-width="4" fill="none" '
            'stroke-linecap="round"/>'
            # hueco alrededor del lazo para que se lea en monocromo
            '<path d="M50,10 L38,2 L38,18 Z M50,10 L62,2 L62,18 Z" fill="#000" stroke="#000" '
            'stroke-width="9" stroke-linejoin="round"/>'
            "</mask>"
        )
        head = "M16,46 C16,20 32,6 50,6 C68,6 84,20 84,46 C84,58 72,62 50,62 C28,62 16,58 16,46 Z"
        arms = (
            "M24,56 C12,64 10,80 20,82 C27,83 28,74 22,73",
            "M40,61 C36,74 38,90 48,90",
            "M60,61 C66,72 72,86 81,84 C88,82 86,73 79,74",
            "M76,56 C88,62 94,74 92,80",
        )
        body = f'<path d="{head}" fill="{col}" mask="url(#{m})"/>'
        body += "".join(f'<path d="{a}" stroke="{col}" stroke-width="8" {st}/>' for a in arms)
        # Lazo de romaría sobre la cabeza
        body += (
            f'<path d="M50,10 L38,2 L38,18 Z M50,10 L62,2 L62,18 Z" fill="{col2}" '
            f'stroke="{col2}" stroke-width="3" stroke-linejoin="round"/>'
            f'<circle cx="50" cy="10" r="4.5" fill="{col2}"/>'
        )
    else:  # caldeiro
        mask = (
            f'<mask id="{m}" maskUnits="userSpaceOnUse" x="-10" y="-10" width="120" height="120">'
            '<rect x="-10" y="-10" width="120" height="120" fill="#fff"/>'
            '<circle cx="42" cy="36" r="4.5" fill="#000"/><circle cx="58" cy="36" r="4.5" fill="#000"/>'
            # hueco alrededor del caldero para que se lea también en monocromo
            '<rect x="10" y="43" width="80" height="17" rx="8" fill="#000"/>'
            "</mask>"
        )
        head = "M31,50 C31,26 40,16 50,16 C60,16 69,26 69,50 Z"
        body = f'<g mask="url(#{m})"><path d="{head}" fill="{col}"/>'
        # vapor
        body += (
            f'<path d="M22,30 C17,24 27,20 22,12 M78,30 C83,24 73,20 78,12" stroke="{col}" '
            f'stroke-width="4" {st} opacity="0.8"/>'
        )
        # tentáculos que cuelgan por fuera del caldero
        body += (
            f'<path d="M34,40 C22,38 8,44 7,58 C6,68 14,71 17,65" stroke="{col}" '
            f'stroke-width="7" {st}/>'
            f'<path d="M66,40 C78,38 92,44 93,58 C94,68 86,71 83,65" stroke="{col}" '
            f'stroke-width="7" {st}/></g>'
        )
        pot = (
            f'<path d="M18,56 L82,56 L77,88 C76,92 73,94 69,94 L31,94 C27,94 24,92 23,88 Z" '
            f'fill="{col2}"/>'
            f'<rect x="14" y="47" width="72" height="9" rx="4.5" fill="{col2}"/>'
        )
        body += pot
    return f"<g {t}>{mask}{body}</g>"


# --------------------------------------------------------------------------- logotipo


def wordmark(
    b: Brand,
    x: float,
    y_top: float,
    size: float,
    col: str,
    tag: str,
    tag_text: str,
    knockout: bool = False,
    outline: str | None = None,
):
    """«Pulpa» + placa «SA». Devuelve (svg, ancho, alto). y_top = parte alta de las mayúsculas."""
    d1, w1, cap = text_path(b.word_font, "Pulpa", size, 0, 0, b.track)
    pad = size * 0.12
    gap = size * 0.10
    d2, w2, _ = text_path(b.word_font, "SA", size * 0.78, 0, 0, b.track)
    cap2 = cap * 0.78
    tx = w1 + gap + pad
    rect_x = w1 + gap
    # placa de SA centrada en la altura de mayúsculas de «Pulpa»
    rect_y = -cap / 2 - cap2 / 2 - pad
    rect_h = cap2 + 2 * pad
    rect_w = w2 + 2 * pad
    sa_base = rect_y + pad + cap2
    g = f'<g transform="translate({x:.2f},{y_top + cap:.2f})">'
    if outline:  # cartel luminoso: solo tubos
        sw = size * 0.035
        g += (
            f'<path d="{d1}" fill="none" stroke="{outline}" stroke-width="{sw:.2f}" stroke-linejoin="round"/>'
        )
        g += (
            f'<rect x="{rect_x:.2f}" y="{rect_y:.2f}" width="{rect_w:.2f}" height="{rect_h:.2f}" '
            f'rx="{pad:.2f}" fill="none" stroke="{tag}" stroke-width="{sw:.2f}"/>'
        )
        g += (
            f'<path transform="translate({tx:.2f},{sa_base:.2f})" d="{d2}" fill="none" '
            f'stroke="{tag}" stroke-width="{sw:.2f}" stroke-linejoin="round"/>'
        )
    else:
        g += f'<path d="{d1}" fill="{col}"/>'
        if knockout:
            m = uid("sa")
            g += (
                f'<mask id="{m}" maskUnits="userSpaceOnUse" x="{rect_x - 5:.2f}" y="{rect_y - 5:.2f}" '
                f'width="{rect_w + 10:.2f}" height="{rect_h + 10:.2f}">'
                f'<rect x="{rect_x - 5:.2f}" y="{rect_y - 5:.2f}" width="{rect_w + 10:.2f}" '
                f'height="{rect_h + 10:.2f}" fill="#fff"/>'
                f'<path transform="translate({tx:.2f},{sa_base:.2f})" d="{d2}" fill="#000"/></mask>'
                f'<rect x="{rect_x:.2f}" y="{rect_y:.2f}" width="{rect_w:.2f}" height="{rect_h:.2f}" '
                f'rx="{pad:.2f}" fill="{tag}" mask="url(#{m})"/>'
            )
        else:
            g += (
                f'<rect x="{rect_x:.2f}" y="{rect_y:.2f}" width="{rect_w:.2f}" height="{rect_h:.2f}" '
                f'rx="{pad:.2f}" fill="{tag}"/>'
                f'<path transform="translate({tx:.2f},{sa_base:.2f})" d="{d2}" fill="{tag_text}"/>'
            )
    g += "</g>"
    width = rect_x + rect_w
    height = cap + size * 0.24  # descendente de la «p»
    return g, width, height


def tagline(
    b: Brand,
    x: float,
    y_base: float,
    size: float,
    col: str,
    anchor: str = "start",
    max_w: float | None = None,
) -> tuple[str, float]:
    d, w, _ = text_path(b.tag_font, b.tagline, size, 0, 0, 0.08)
    if max_w and w > max_w:
        size *= max_w / w
        d, w, _ = text_path(b.tag_font, b.tagline, size, 0, 0, 0.08)
    ox = x - w / 2 if anchor == "middle" else x
    return f'<path transform="translate({ox:.2f},{y_base:.2f})" d="{d}" fill="{col}"/>', w


def horizontal(
    b: Brand,
    x: float,
    y: float,
    h: float,
    *,
    mono: str | None = None,
    on_dark: bool = False,
    with_tag: bool = True,
) -> tuple[str, float]:
    """Versión horizontal: símbolo + logotipo (+ lema). h = alto del símbolo."""
    if mono:
        sc, wc, tg, tt, tl, ko = mono, mono, mono, None, mono, True
    elif on_dark:
        sc, wc, tg, tt, tl, ko = b.paper, b.paper, b.accent, b.paper, b.extra, False
    else:
        sc, wc, tg, tt, tl, ko = b.main, b.main, b.accent, b.paper, b.accent, False
    s2 = b.accent if not mono and b.symbol in ("caldeiro", "romaria") else sc
    out = symbol(b, x, y, h, sc, s2)
    size = h * 0.52
    wx = x + h * 1.06
    wy = y + h * (0.16 if with_tag else 0.26)
    wm, ww, wh = wordmark(b, wx, wy, size, wc, tg, tt or b.paper, knockout=ko)
    out += wm
    total = h * 1.06 + ww
    if with_tag:
        tsvg, _ = tagline(b, wx + ww / 2, wy + wh + size * 0.36, size * 0.2, tl, "middle", ww)
        out += tsvg
    return out, total


def compact(b: Brand, cx: float, cy: float, r: float, *, mono: str | None = None) -> str:
    """Versión compacta: insignia redonda con el símbolo y «PulpaSA» debajo."""
    bg = mono or b.main
    fg = b.paper
    out = ""
    if mono:
        # monocromo: anillo + símbolo + texto en un solo color, fondo transparente
        out += f'<circle cx="{cx}" cy="{cy}" r="{r * 0.95:.2f}" fill="none" stroke="{mono}" stroke-width="{r * 0.07:.2f}"/>'
        out += symbol(b, cx - r * 0.5, cy - r * 0.72, r, mono, mono)
        wm, ww, _ = wordmark(b, 0, 0, r * 0.26, mono, mono, mono, knockout=True)
        out += f'<g transform="translate({cx - ww / 2:.2f},{cy + r * 0.38:.2f})">{wm}</g>'
        return out
    out += f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="{bg}"/>'
    out += f'<circle cx="{cx}" cy="{cy}" r="{r * 0.88:.2f}" fill="none" stroke="{b.accent}" stroke-width="{r * 0.04:.2f}"/>'
    out += symbol(b, cx - r * 0.5, cy - r * 0.72, r, fg, b.accent)
    wm, ww, _ = wordmark(b, 0, 0, r * 0.26, fg, b.accent, b.paper)
    out += f'<g transform="translate({cx - ww / 2:.2f},{cy + r * 0.38:.2f})">{wm}</g>'
    return out


# --------------------------------------------------------------------------- usos (lámina)


def neon_sign(b: Brand, x: float, y: float, w: float, h: float) -> str:
    f = uid("glow")
    out = (
        f'<filter id="{f}" x="-20%" y="-40%" width="140%" height="180%">'
        f'<feGaussianBlur stdDeviation="{h * 0.03:.2f}" result="b"/>'
        '<feMerge><feMergeNode in="b"/><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge>'
        "</filter>"
    )
    out += f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{h * 0.08:.2f}" fill="{b.dark}"/>'
    out += f'<rect x="{x + 6}" y="{y + 6}" width="{w - 12}" height="{h - 12}" rx="{h * 0.06:.2f}" fill="none" stroke="#000" stroke-opacity=".35" stroke-width="3"/>'
    size = h * 0.34
    _, ww, wh = wordmark(b, 0, 0, size, "#fff", "#fff", "#fff")
    sym = h * 0.56
    total = sym * 1.05 + ww
    ox = x + (w - total) / 2
    sa_col = "#FFFFFF" if b.key == "a" else b.extra
    wm, _, _ = wordmark(b, ox + sym * 1.05, y + h * 0.33, size, "", sa_col, "", outline=b.neon)
    sym_glow = symbol(b, ox, y + (h - sym) / 2, sym, b.neon, sa_col)
    out += f'<g filter="url(#{f})">{sym_glow}{wm}</g>'
    # soportes
    out += f'<rect x="{x + w * 0.2 - 4}" y="{y + h}" width="8" height="{h * 0.25:.2f}" fill="#555"/>'
    out += f'<rect x="{x + w * 0.8 - 4}" y="{y + h}" width="8" height="{h * 0.25:.2f}" fill="#555"/>'
    return out


def awning(b: Brand, x: float, y: float, w: float, h: float) -> str:
    n = 12
    sw = w / n
    out = f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="{b.paper}"/>'
    for i in range(0, n, 2):
        out += f'<rect x="{x + i * sw:.2f}" y="{y}" width="{sw:.2f}" height="{h}" fill="{b.stripe}"/>'
    # faldón festoneado
    vy = y + h
    vh = h * 0.18
    for i in range(n):
        c = b.stripe if i % 2 == 0 else b.paper
        x0 = x + i * sw
        out += (
            f'<path d="M{x0:.2f},{vy:.2f} h{sw:.2f} v{vh * 0.4:.2f} a{sw / 2:.2f},{vh * 0.6:.2f} 0 0 1 '
            f'-{sw:.2f},0 Z" fill="{c}"/>'
        )
    out += f'<rect x="{x}" y="{vy - 3:.2f}" width="{w}" height="6" fill="{b.main}"/>'
    # placa central con el logo
    pw, ph = w * 0.56, h * 0.48
    px, py = x + (w - pw) / 2, y + h * 0.26
    out += f'<rect x="{px:.2f}" y="{py:.2f}" width="{pw:.2f}" height="{ph:.2f}" rx="{ph * 0.12:.2f}" fill="{b.paper}" stroke="{b.main}" stroke-width="5"/>'
    lh = ph * 0.66
    _, lw = horizontal(b, 0, 0, lh)
    hs, _ = horizontal(b, px + (pw - lw) / 2, py + (ph - lh) / 2, lh)
    return out + hs


def cap(b: Brand, cx: float, cy: float, s: float) -> str:
    out = (
        f'<path d="M{cx - s:.1f},{cy:.1f} C{cx - s:.1f},{cy - s * 1.15:.1f} {cx + s:.1f},{cy - s * 1.15:.1f} '
        f'{cx + s:.1f},{cy:.1f} Z" fill="{b.main}"/>'
        f'<path d="M{cx - s * 0.2:.1f},{cy - 2:.1f} C{cx + s * 0.6:.1f},{cy - 6:.1f} {cx + s * 1.7:.1f},{cy:.1f} '
        f"{cx + s * 1.8:.1f},{cy + s * 0.18:.1f} C{cx + s:.1f},{cy + s * 0.3:.1f} {cx:.1f},{cy + s * 0.2:.1f} "
        f'{cx - s * 0.2:.1f},{cy + s * 0.14:.1f} Z" fill="{b.accent}"/>'
        f'<circle cx="{cx}" cy="{cy - s * 0.87:.1f}" r="{s * 0.07:.1f}" fill="{b.accent}"/>'
    )
    out += compact(b, cx, cy - s * 0.42, s * 0.36)
    return out


def apron(b: Brand, cx: float, top: float, s: float) -> str:
    w = s
    out = (
        f'<path d="M{cx - w * 0.28:.1f},{top:.1f} L{cx + w * 0.28:.1f},{top:.1f} L{cx + w * 0.3:.1f},{top + s * 0.38:.1f} '
        f"L{cx + w * 0.5:.1f},{top + s * 0.45:.1f} L{cx + w * 0.46:.1f},{top + s * 1.2:.1f} "
        f"L{cx - w * 0.46:.1f},{top + s * 1.2:.1f} L{cx - w * 0.5:.1f},{top + s * 0.45:.1f} "
        f'L{cx - w * 0.3:.1f},{top + s * 0.38:.1f} Z" fill="{b.main}"/>'
        f'<path d="M{cx - w * 0.28:.1f},{top:.1f} C{cx - w * 0.3:.1f},{top - s * 0.3:.1f} {cx + w * 0.3:.1f},{top - s * 0.3:.1f} '
        f'{cx + w * 0.28:.1f},{top:.1f}" fill="none" stroke="{b.accent}" stroke-width="6"/>'
        f'<rect x="{cx - w * 0.3:.1f}" y="{top + s * 0.86:.1f}" width="{w * 0.6:.1f}" height="{s * 0.2:.1f}" rx="6" '
        f'fill="none" stroke="{b.accent}" stroke-width="4"/>'
    )
    sym = s * 0.34
    out += symbol(b, cx - sym / 2, top + s * 0.12, sym, b.paper, b.accent)
    wm, ww, _ = wordmark(b, 0, 0, s * 0.1, b.paper, b.accent, b.paper)
    out += f'<g transform="translate({cx - ww / 2:.1f},{top + s * 0.5:.1f})">{wm}</g>'
    return out


def tray(b: Brand, cx: float, cy: float, w: float, h: float) -> str:
    out = (
        f'<rect x="{cx - w / 2:.1f}" y="{cy - h / 2:.1f}" width="{w:.1f}" height="{h:.1f}" rx="14" fill="{b.main}"/>'
        f'<rect x="{cx - w / 2 + 12:.1f}" y="{cy - h / 2 + 12:.1f}" width="{w - 24:.1f}" height="{h - 24:.1f}" rx="8" fill="{b.paper}"/>'
    )
    # papel salvamanteles con patrón de símbolos
    for i in range(4):
        for j in range(2):
            sx = cx - w / 2 + 26 + i * (w - 52) / 4
            sy = cy - h / 2 + 22 + j * (h - 44) / 2
            out += symbol(b, sx, sy, (h - 44) / 2.4, b.extra, b.extra).replace("<g ", '<g opacity="0.3" ', 1)
    lh = h * 0.3
    _, lw = horizontal(b, 0, 0, lh, with_tag=False)
    hs, _ = horizontal(b, cx - lw / 2, cy - lh / 2, lh, with_tag=False)
    return (
        out
        + f'<rect x="{cx - lw / 2 - 10:.1f}" y="{cy - lh / 2 - 8:.1f}" width="{lw + 20:.1f}" height="{lh + 16:.1f}" rx="10" fill="{b.paper}"/>'
        + hs
    )


def cup(b: Brand, cx: float, top: float, s: float) -> str:
    out = (
        f'<path d="M{cx - s * 0.36:.1f},{top:.1f} L{cx + s * 0.36:.1f},{top:.1f} L{cx + s * 0.28:.1f},{top + s:.1f} '
        f'L{cx - s * 0.28:.1f},{top + s:.1f} Z" fill="{b.paper}" stroke="{b.main}" stroke-width="3"/>'
        f'<rect x="{cx - s * 0.4:.1f}" y="{top - s * 0.08:.1f}" width="{s * 0.8:.1f}" height="{s * 0.1:.1f}" rx="5" fill="{b.main}"/>'
        f'<path d="M{cx - s * 0.335:.1f},{top + s * 0.72:.1f} L{cx + s * 0.335:.1f},{top + s * 0.72:.1f} '
        f'L{cx + s * 0.28:.1f},{top + s:.1f} L{cx - s * 0.28:.1f},{top + s:.1f} Z" fill="{b.accent}"/>'
    )
    out += compact(b, cx, top + s * 0.38, s * 0.24)
    return out


def ticket(b: Brand, x: float, y: float, w: float, h: float) -> str:
    hh = h * 0.24
    out = (
        f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="10" fill="{b.dark}"/>'
        f'<path d="M{x},{y + 10} a10,10 0 0 1 10,-10 h{w - 20} a10,10 0 0 1 10,10 v{hh - 10} h-{w} Z" fill="{b.main}"/>'
    )
    out += compact(b, x + hh * 0.55, y + hh / 2, hh * 0.38)
    d, tw, cap_h = text_path(b.tag_font, "PEDIDO #1", hh * 0.36, 0, 0, 0.04)
    out += f'<path transform="translate({x + hh * 1.1:.1f},{y + hh / 2 + cap_h / 2:.1f})" d="{d}" fill="{b.paper}"/>'
    d, tw, cap_h = text_path(b.tag_font, "POLBO Á FEIRA ×2", h * 0.1, 0, 0, 0.04)
    out += f'<path transform="translate({x + 16:.1f},{y + hh + h * 0.2:.1f})" d="{d}" fill="{b.paper}"/>'
    # barra de tiempo
    out += (
        f'<rect x="{x + 16}" y="{y + h * 0.56:.1f}" width="{w - 32}" height="{h * 0.07:.1f}" rx="4" fill="#ffffff22"/>'
        f'<rect x="{x + 16}" y="{y + h * 0.56:.1f}" width="{(w - 32) * 0.62:.1f}" height="{h * 0.07:.1f}" rx="4" fill="{b.accent}"/>'
    )
    d, tw, cap_h = text_path(b.word_font, "00:42", h * 0.2, 0, 0, 0.02)
    out += f'<path transform="translate({x + w - 16 - tw:.1f},{y + h - 16:.1f})" d="{d}" fill="{b.extra}"/>'
    return out


def label(text: str, x: float, y: float, col: str = "#333", size: float = 18) -> str:
    d, _, _ = text_path("inter_bold", text, size, 0, 0, 0.02)
    return f'<path transform="translate({x:.1f},{y:.1f})" d="{d}" fill="{col}"/>'


def svg_doc(w: float, h: float, body: str, bg: str | None = None) -> str:
    bgr = f'<rect width="{w}" height="{h}" fill="{bg}"/>' if bg else ""
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{w:.0f}" height="{h:.0f}" '
        f'viewBox="0 0 {w:.2f} {h:.2f}">{bgr}{body}</svg>\n'
    )


def sheet(b: Brand) -> str:
    W, H = 1800, 1300
    o = f'<rect width="{W}" height="{H}" fill="#ECE8E1"/>'
    o += label(f"PulpaSA · Propuesta {b.key.upper()} · {b.name}", 40, 62, "#222", 34)
    o += label(f"Lema: «{b.tagline.capitalize()}»", 40, 98, "#555", 20)
    # paleta
    for i, (n, c) in enumerate(
        [
            ("principal", b.main),
            ("acento", b.accent),
            ("papel", b.paper),
            ("noche", b.dark),
            ("apoyo", b.extra),
            ("neón", b.neon),
        ]
    ):
        x = 1000 + i * 128
        o += f'<rect x="{x}" y="28" width="110" height="54" rx="8" fill="{c}" stroke="#0002"/>'
        o += label(c.upper(), x + 4, 104, "#444", 15) + label(n, x + 4, 124, "#777", 14)

    def panel(x, y, w, h, title, fill="#FFFFFF"):
        return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="14" fill="{fill}"/>' + label(
            title, x + 14, y + 26, "#888" if fill != "#222" else "#bbb", 15
        )

    # fila 1: versiones
    o += panel(40, 150, 700, 280, "HORIZONTAL")
    hs, hw = horizontal(b, 0, 0, 170)
    o += f'<g transform="translate({40 + (700 - hw) / 2:.1f},{205})">{hs}</g>'
    o += panel(760, 150, 280, 280, "COMPACTA")
    o += compact(b, 900, 300, 115)
    o += panel(1060, 150, 340, 280, "MONOCROMO")
    ms, mw = horizontal(b, 0, 0, 80, mono="#111111")
    o += f'<g transform="translate({1060 + (340 - mw) / 2:.1f},{200})">{ms}</g>'
    ms, mw = horizontal(b, 0, 0, 80, mono="#111111", with_tag=False)
    o += f'<g transform="translate({1060 + (340 - mw) / 2:.1f},{318})">{ms}</g>'
    o += panel(1420, 150, 340, 280, "SOBRE ESCURO", b.dark)
    ds, dw = horizontal(b, 0, 0, 80, on_dark=True)
    o += f'<g transform="translate({1420 + (340 - dw) / 2:.1f},{200})">{ds}</g>'
    o += compact(b, 1590, 368, 48, mono="#FFFFFF")

    # fila 2: cartel luminoso + toldo
    o += panel(40, 450, 700, 420, "CARTEL LUMINOSO", "#3A3F44")
    o += neon_sign(b, 90, 520, 600, 230)
    o += panel(760, 450, 1000, 420, "TOLDO")
    o += '<rect x="800" y="490" width="10" height="360" fill="#6B4A2F"/><rect x="1710" y="490" width="10" height="360" fill="#6B4A2F"/>'
    o += awning(b, 790, 500, 940, 250)

    # fila 3: uniforme, bandeja, vaso, ticket
    o += panel(40, 890, 560, 370, "UNIFORME (GORRA Y DELANTAL)")
    o += cap(b, 150, 1130, 95)
    o += apron(b, 440, 960, 230)
    o += panel(620, 890, 520, 370, "BANDEJA")
    o += tray(b, 880, 1080, 460, 270)
    o += panel(1160, 890, 220, 370, "VASO")
    o += cup(b, 1270, 980, 220)
    o += panel(1400, 890, 360, 370, "TICKET / HUD", "#C9C4BB")
    o += ticket(b, 1430, 960, 300, 220)
    return svg_doc(W, H, o)


def overview() -> str:
    W, H = 1800, 720
    o = f'<rect width="{W}" height="{H}" fill="#ECE8E1"/>'
    o += label("PulpaSA · tres propuestas (PUL-088)", 40, 60, "#222", 34)
    for i, b in enumerate(BRANDS):
        x = 40 + i * 590
        o += f'<rect x="{x}" y="100" width="560" height="580" rx="16" fill="#fff"/>'
        o += label(f"{b.key.upper()} · {b.name}", x + 20, 140, "#333", 24)
        hs, hw = horizontal(b, 0, 0, 110)
        o += f'<g transform="translate({x + (560 - hw) / 2:.1f},175)">{hs}</g>'
        o += compact(b, x + 140, 420, 100)
        o += f'<rect x="{x + 270}" y="320" width="260" height="200" rx="12" fill="{b.dark}"/>'
        ds, dw = horizontal(b, 0, 0, 60, on_dark=True)
        o += f'<g transform="translate({x + 270 + (260 - dw) / 2:.1f},385)">{ds}</g>'
        for j, c in enumerate([b.main, b.accent, b.paper, b.dark, b.extra]):
            o += f'<rect x="{x + 30 + j * 100}" y="570" width="90" height="70" rx="8" fill="{c}" stroke="#0002"/>'
    return svg_doc(W, H, o)


# --------------------------------------------------------------------------- exportación


def write(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


def raster(svg: Path, png: Path, width: int | None = None) -> None:
    png.parent.mkdir(parents=True, exist_ok=True)
    args = ["magick", "-background", "none", "-density", "96", f"RSVG:{svg}"]
    if width:
        args += ["-resize", f"{width}x"]
    args += ["-strip", f"PNG32:{png}"]
    subprocess.run(args, check=True)


def main() -> None:
    for b in BRANDS:
        d = SRC_DIR / f"propuesta_{b.key}"
        h = 200.0
        _, hw = horizontal(b, 0, 0, h)
        pad = 24
        hs, _ = horizontal(b, pad, pad, h)
        files = {
            "horizontal": svg_doc(hw + 2 * pad, h + 2 * pad, hs),
            "compacta": svg_doc(512, 512, compact(b, 256, 256, 250)),
            "mono_negro": svg_doc(hw + 2 * pad, h + 2 * pad, horizontal(b, pad, pad, h, mono="#111111")[0]),
            "mono_blanco": svg_doc(hw + 2 * pad, h + 2 * pad, horizontal(b, pad, pad, h, mono="#FFFFFF")[0]),
            "simbolo": svg_doc(512, 512, symbol(b, 6, 6, 500, b.main, b.accent)),
        }
        for name, txt in files.items():
            svg = d / f"pulpasa_{b.key}_{name}.svg"
            write(svg, txt)
            width = 1024 if name.startswith(("horizontal", "mono")) else 512
            raster(svg, TEX_DIR / f"propuesta_{b.key}" / f"pulpasa_{b.key}_{name}.png", width)
        lam = d / f"lamina_{b.key}.svg"
        write(lam, sheet(b))
        raster(lam, EVI_DIR / f"lamina_{b.key}_{b.name.lower().replace('ñ', 'n').replace('í', 'i')}.png")
    ov = SRC_DIR / "propuestas.svg"
    write(ov, overview())
    raster(ov, EVI_DIR / "propuestas_resumo.png")


if __name__ == "__main__":
    main()
