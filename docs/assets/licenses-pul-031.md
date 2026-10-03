# Licencias de los assets de PUL-031 (M1: aceite, cachelos y estrellas)

Regla D16: solo entra lo que tiene licencia confirmada (CC0, CC BY, OFL, MIT o propio).
El producer consolida esta tabla en `docs/assets/licenses.md`.

## Iconos SVG (game-icons.net, CC BY 3.0)

| Asset (origen) | Destino en `godot/` | Licencia | Atribución requerida |
|---|---|---|---|
| https://game-icons.net/1x1/delapouite/olive.html («Olive», Delapouite) | `assets/textures/icons/oil.svg` | CC BY 3.0 | Sí: «Olive» por Delapouite, game-icons.net |
| https://game-icons.net/1x1/delapouite/potato.html («Potato», Delapouite) | `assets/textures/icons/potato.svg` | CC BY 3.0 | Sí: «Potato» por Delapouite, game-icons.net |
| https://game-icons.net/1x1/delapouite/round-star.html («Round star», Delapouite) | `assets/textures/icons/star_full.svg` | CC BY 3.0 | Sí: «Round star» por Delapouite, game-icons.net |
| Derivado de https://game-icons.net/1x1/delapouite/round-star.html («Round star», Delapouite) | `assets/textures/icons/star_empty.svg` | CC BY 3.0 | Sí: modificación de «Round star» por Delapouite, game-icons.net |

Texto de la licencia: https://creativecommons.org/licenses/by/3.0/
Los SVG se descargaron del repositorio oficial https://github.com/game-icons/icons (mismos
autores y licencia que la web) y se modifican quitando el rectángulo negro de fondo, salvo
`star_empty.svg`, que además deja solo el contorno de la estrella (`fill="none"`, trazo blanco).
Para el aceite se usa «Olive» (aceituna/rama de olivo): «Wine bottle» incluía una copa de vino
y «Oil can» no es una botella (revisión de PUL-031).

## Placeholders 3D y materiales (creados en el proyecto)

| Asset (origen) | Destino en `godot/` | Licencia | Atribución requerida |
|---|---|---|---|
| Propio (primitivas; dimensiones junto a la olla de PUL-008) | `assets/models/placeholders/oil_bottle.tscn` | Propio | No |
| Propio (primitivas) | `assets/models/placeholders/cachelos_raw.tscn` | Propio | No |
| Propio (primitivas) | `assets/models/placeholders/cachelos_cooked.tscn` | Propio | No |
| Propio (primitivas) | `assets/models/placeholders/cachelera.tscn` | Propio | No |
| Propio | `assets/materials/ph_oil.tres`, `ph_oil_liquid.tres`, `ph_cachelo_raw.tres`, `ph_cachelo_cooked.tres` | Propio | No |
