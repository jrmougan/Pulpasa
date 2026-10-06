# Referencias de estilo

Capturas del estado actual para iterar la estética con un generador de imágenes (p. ej. Gemini)
antes de tocar el juego. Se regeneran con:

```sh
# Desde la raíz del repo (audio mudo: no suena por los altavoces)
xvfb-run -a godot --audio-driver Dummy --path godot --resolution 1920x1080 \
  -s "$PWD/docs/art/style-refs/capture_style_refs.gd" -- "$PWD/docs/art/style-refs/actual-AAAA-MM-DD"
```

## `actual-2026-10-06/`
| Archivo | Uso |
|---|---|
| `00_nivel_sin_hud.png` | **La principal para Gemini**: nivel completo sin HUD |
| `01_nivel_completo.png` | Igual, con HUD y tickets |
| `02_cocina.png` | Arcón, cachelera y ollas (una con pulpo quemado) |
| `03_estacion_condimentos.png` | Estación con plato y pegatinas |
| `04_puestos_entrega.png` | Puestos de entrega |
| `05_carpa_y_entorno.png` | Carpa, cartel y decoración |

## Prompts para Gemini (adjunta `00_nivel_sin_hud.png`)
Pide siempre que **conserve la composición, la cámara y la posición de cada elemento**, para que
las variantes sean comparables y aplicables al juego.

Base (en inglés suele funcionar mejor):
> Restyle this top-down orthographic screenshot of a cooperative cooking game set in a Galician
> "pulpo á feira" fair stall. Keep the exact same camera, layout, objects and their positions
> (octopus fridge, potato basket, two copper pots, central counter with condiment dispensers,
> plate shelf, four delivery stands numbered 1–4, striped tent with the "PULPO Á FEIRA" sign,
> two cooks). Only change the art style to: **<ESTILO>**. Game-ready, readable from a distance,
> no text other than the sign and stand numbers.

Estilos para probar (uno por imagen):
1. `cel-shaded cartoon with thick dark outlines and saturated colors, like Overcooked`
2. `hand-painted stylized textures, warm watercolor look, soft shadows`
3. `soft pastel low-poly with golden-hour sunset lighting and long shadows`
4. `tilt-shift miniature diorama, toy-like materials, shallow depth of field`
5. `night fair with warm string lights and lanterns, cozy glow, darker sky`
6. `Galician rustic: granite stone, aged wood, copper and linen, earthy palette`

Cuando una te guste, pide variantes de esa misma («same style, more <x>») y guarda la elegida en
`docs/art/style-refs/` para actualizar la biblia de arte.
