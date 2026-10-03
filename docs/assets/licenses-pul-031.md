# Licencias de los assets de PUL-031 (M1: aceite, cachelos y estrellas)

Regla D16: solo entra lo que tiene licencia confirmada (CC0, CC BY, OFL, MIT o propio).
El producer consolida esta tabla en `docs/assets/licenses.md`.

## Iconos SVG (game-icons.net, CC BY 3.0)

| Asset en `godot/` | Origen (URL) | Autor | Licencia | Modificación |
|---|---|---|---|---|
| `assets/textures/icons/oil.svg` | https://game-icons.net/1x1/delapouite/wine-bottle.html («Wine bottle») | Delapouite | CC BY 3.0 | Se elimina el fondo negro |
| `assets/textures/icons/potato.svg` | https://game-icons.net/1x1/delapouite/potato.html («Potato») | Delapouite | CC BY 3.0 | Se elimina el fondo negro |
| `assets/textures/icons/star_full.svg` | https://game-icons.net/1x1/delapouite/round-star.html («Round star») | Delapouite | CC BY 3.0 | Se elimina el fondo negro |
| `assets/textures/icons/star_empty.svg` | Derivado de https://game-icons.net/1x1/delapouite/round-star.html («Round star») | Delapouite | CC BY 3.0 | Solo el contorno (`fill="none"`, trazo blanco) |

Texto de la licencia: https://creativecommons.org/licenses/by/3.0/
Los SVG se descargaron del repositorio oficial https://github.com/game-icons/icons (mismos
autores y licencia que la web). Para «aceite» se eligió «Wine bottle» por ser la botella más
parecida a una botella de aceite de oliva; «Oil can» se descartó por no ser una botella.

## Placeholders 3D y materiales (creados en el proyecto)

| Asset en `godot/` | Origen | Licencia | Atribución requerida |
|---|---|---|---|
| `assets/models/placeholders/oil_bottle.tscn` | Propio (primitivas; dimensiones junto a la olla de PUL-008) | Propio | No |
| `assets/models/placeholders/cachelos_raw.tscn` | Propio (primitivas) | Propio | No |
| `assets/models/placeholders/cachelos_cooked.tscn` | Propio (primitivas) | Propio | No |
| `assets/models/placeholders/cachelera.tscn` | Propio (primitivas) | Propio | No |
| `assets/materials/ph_oil.tres`, `ph_oil_liquid.tres`, `ph_cachelo_raw.tres`, `ph_cachelo_cooked.tres` | Propio | Propio | No |
