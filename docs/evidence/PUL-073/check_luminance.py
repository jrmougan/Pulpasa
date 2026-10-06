"""PUL-073 AC2: luminancia relativa (sRGB lineal) de zonas jugables en la captura 1920x1080.

Uso: python3 check_luminance.py <png>...  Regla biblia v2 §6.1-6: nada jugable < 0,08 ni > 0,95.
Se mide la mediana de cada zona (el objeto) y la fracción de píxeles fuera de rango.
"""
import sys
import warnings
from PIL import Image

warnings.simplefilter("ignore", DeprecationWarning)

ZONES = {
    "encimera_fondo": (1010, 440, 1590, 485),
    "encimera_barra": (420, 640, 1500, 690),
    "frente_condimentos": (755, 700, 1080, 722),
    "pegatinas_comanda": (900, 580, 985, 606),
    "pegatinas_nevera": (495, 458, 580, 482),
    "olla_1": (760, 440, 825, 505),
    "olla_2": (928, 440, 995, 505),
    "estanteria_platos": (412, 795, 455, 880),
    "kiosco_1_numero": (603, 995, 638, 1030),
    "kiosco_2_numero": (773, 995, 808, 1030),
    "kiosco_3_numero": (1028, 995, 1063, 1030),
    "kiosco_4_numero": (1198, 995, 1233, 1030),
    "kiosco_cartel_1": (590, 905, 652, 945),
    "aro_jugador": (1262, 868, 1338, 912),
    "suelo_jugable": (450, 780, 1200, 880),
    "jugador_1": (510, 500, 565, 630),
}


def lin(c: float) -> float:
    c /= 255.0
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def lum(p: tuple) -> float:
    return 0.2126 * lin(p[0]) + 0.7152 * lin(p[1]) + 0.0722 * lin(p[2])


def main() -> None:
    worst = 0
    for path in sys.argv[1:]:
        img = Image.open(path).convert("RGB")
        print(f"## {path}")
        print(f"{'zona':22} {'mediana':>8} {'p05':>6} {'p95':>6} {'<0.08':>6} {'>0.95':>6}")
        for name, box in ZONES.items():
            vals = sorted(lum(p) for p in img.crop(box).getdata())
            n = len(vals)
            med, p05, p95 = vals[n // 2], vals[n // 20], vals[n * 19 // 20]
            dark = sum(v < 0.08 for v in vals) / n
            burn = sum(v > 0.95 for v in vals) / n
            flag = " FALLA" if med < 0.08 or med > 0.95 else ""
            worst += bool(flag)
            print(f"{name:22} {med:8.3f} {p05:6.3f} {p95:6.3f} {dark:6.1%} {burn:6.1%}{flag}")
    sys.exit(1 if worst else 0)


if __name__ == "__main__":
    main()
