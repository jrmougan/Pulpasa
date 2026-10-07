"""PUL-087: estadísticas globales de color (luminancia media, saturación, temperatura) de la
referencia frente a las capturas. Uso: python3 color_stats.py <png>..."""

import colorsys
import sys

from PIL import Image, ImageStat

for path in sys.argv[1:]:
    img = Image.open(path).convert("RGB").resize((480, 270))
    r, g, b = (c / 255 for c in ImageStat.Stat(img).mean)
    hsv = img.convert("HSV")
    s_mean = ImageStat.Stat(hsv).mean[1] / 255
    lum = ImageStat.Stat(img.convert("L"))
    print(
        f"{path}: luma_media={lum.mean[0] / 255:.3f} contraste(sd)={lum.stddev[0] / 255:.3f} "
        f"saturacion={s_mean:.3f} calidez(R-B)={r - b:+.3f} "
        f"tono_medio={colorsys.rgb_to_hsv(r, g, b)[0] * 360:.0f}"
    )
