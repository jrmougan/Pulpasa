# Licencias de assets

Regla D16: en el proyecto Godot solo entra lo que tiene licencia confirmada. Toda incorporación
añade una fila aquí. Lo dudoso se sustituye por alternativas libres o primitivas.

## Confirmados

| Asset (origen) | Destino en `godot/` | Licencia | Atribución requerida |
|---|---|---|---|
| `Art/Furniture/Mueblecajas.fbx` | `assets/models/furniture/Mueblecajas.fbx` (+ envoltorio `Mueblecajas.tscn`) | Propio (equipo Pulpasa) | No |
| `Art/Furniture/order_stand.fbx` | `assets/models/furniture/order_stand.fbx` | Propio (equipo Pulpasa) | No |
| `Art/Materials/**` (colores y parámetros; sin texturas) | `assets/materials/*.tres` | Propio | No |
| `Animations/Packaging/Box/*.anim` | — | Propio | No |
| https://opengameart.org/content/boiling-water-loops (`cooking_without_cover_01.ogg`, TinyWorlds) | `assets/audio/boiling_water_loop.ogg` (loop en import) | CC0 | No |
| https://opengameart.org/content/various-scissors (`hair_scissors_01.mp3`, sinny; convertido a ogg) | `assets/audio/cut.ogg` | CC0 | No |
| https://opengameart.org/content/scrapes (`scrape-3.ogg`, AntumDeluge) | `assets/audio/pepper_mill.ogg` | CC0 | No |
| https://kenney.nl/assets/interface-sounds (`confirmation_002.ogg`) | `assets/audio/delivery_ok.ogg` | CC0 | No |
| https://kenney.nl/assets/interface-sounds (`error_005.ogg`) | `assets/audio/delivery_error.ogg` | CC0 | No |
| `Plugins/TextMesh Pro/Fonts/LiberationSans.ttf` y su `OFL.txt` | `assets/fonts/LiberationSans.ttf`, `assets/fonts/OFL.txt` | SIL OFL 1.1 | Incluir licencia OFL |
| `Art/Icons/pepper-hot-solid.svg` = Line Awesome «pepper-hot-solid» por Icons8 (https://github.com/icons8/line-awesome/blob/master/svg/pepper-hot-solid.svg; licencia https://github.com/icons8/line-awesome/blob/master/LICENSE.md) | `assets/textures/icons/pepper-hot-solid.svg`, `assets/textures/icons/LICENSE-line-awesome.md` | MIT (o Good Boy License) | Sí: autor Icons8, obra Line Awesome, texto de licencia incluido |
| https://game-icons.net/1x1/lorc/octopus.html (Lorc) sustituye a `Art/Icons/octopus` | `assets/textures/icons/octopus.svg` | CC BY 3.0 | Sí: «Octopus» por Lorc, game-icons.net |
| https://game-icons.net/1x1/lorc/salt-shaker.html (Lorc) sustituye a `Art/Icons/salt` | `assets/textures/icons/salt.svg` | CC BY 3.0 | Sí: «Salt shaker» por Lorc, game-icons.net |
| https://game-icons.net/1x1/delapouite/crosshair.html (Delapouite) sustituye a `Art/Icons/selection` | `assets/textures/icons/selection.svg` | CC BY 3.0 | Sí: «Crosshair» por Delapouite, game-icons.net |
| `Art/Logo/PulpaSA.png` | `assets/textures/logo/PulpaSA.png` | Propio | No |
| https://game-icons.net/1x1/delapouite/olive.html («Olive», Delapouite) | `assets/textures/icons/oil.svg` | CC BY 3.0 | Sí: «Olive» por Delapouite, game-icons.net |
| https://game-icons.net/1x1/delapouite/potato.html («Potato», Delapouite) | `assets/textures/icons/potato.svg` | CC BY 3.0 | Sí: «Potato» por Delapouite, game-icons.net |
| https://game-icons.net/1x1/delapouite/round-star.html («Round star», Delapouite) | `assets/textures/icons/star_full.svg` | CC BY 3.0 | Sí: «Round star» por Delapouite, game-icons.net |
| Derivado de https://game-icons.net/1x1/delapouite/round-star.html («Round star», Delapouite) | `assets/textures/icons/star_empty.svg` | CC BY 3.0 | Sí: modificación de «Round star» por Delapouite, game-icons.net |
| Propio (primitivas; dimensiones junto a la olla de PUL-008) | `assets/models/placeholders/oil_bottle.tscn` | Propio | No |
| Propio (primitivas) | `assets/models/placeholders/cachelos_raw.tscn` | Propio | No |
| Propio (primitivas) | `assets/models/placeholders/cachelos_cooked.tscn` | Propio | No |
| Propio (primitivas) | `assets/models/placeholders/cachelera.tscn` | Propio | No |
| Propio | `assets/materials/ph_oil.tres`, `ph_oil_liquid.tres`, `ph_cachelo_raw.tres`, `ph_cachelo_cooked.tres` | Propio | No |
| https://game-icons.net/1x1/lorc/small-fire.html («Small fire», Lorc; verificado contra https://raw.githubusercontent.com/game-icons/icons/master/lorc/small-fire.svg, sin el fondo negro) | `assets/textures/icons/small-fire.svg` | CC BY 3.0 | Sí: «Small fire» por Lorc, game-icons.net |
| `assets/textures/icons/pepper-hot-solid.svg` (ya listado en `licenses.md`): solo se añade `fill="#fff"` | `assets/textures/icons/pepper-hot-solid.svg` | MIT (o Good Boy License) | Sí: Icons8, Line Awesome |

Los SVG de game-icons.net se modifican quitando el rectángulo negro de fondo. Atribuciones completas en `godot/assets/CREDITS.md`.

## Creados en el proyecto (PUL-008)

| Asset | Destino en `godot/` | Licencia | Atribución requerida |
|---|---|---|---|
| Placeholders de primitivas (olla, fogón, nevera, 3 mesas, 3 cajas, bote, 2 pulpos, personaje); dimensiones tomadas de prefabs Unity y Pandazole solo como medida | `assets/models/placeholders/*.tscn` | Propio (creados por el equipo) | No |
| Materiales `ph_*` de los placeholders | `assets/materials/ph_*.tres` | Propio | No |

Los materiales `hot_pepper_quad`, `salt_quad`, `octopus_symbol` y `reticule` conservan solo el color
de Unity; sus texturas (iconos sin origen) no se importan.

## Pendientes de confirmar (no se usan hasta confirmarlos)

| Asset | Motivo |
|---|---|
| `Art/Characters/freakycapucha.fbx`, `Art/Characters/BillGatos.fbx` | Propios según metadatos de Blender; falta confirmación del responsable |
| `Art/Ingredients/Octopus.fbx` | Ídem |
| `Art/Ingredients/Condiment.obj` | Sin metadatos |
| `Art/Packaging/Boite Hamburger.fbx` | Probablemente externo |
| `Art/Icons/{octopus,salt,selection}` | Sin origen |
| `Art/UI/ticket_dentado.png` | Propio probable |
| `Audio/SFX/*` | Sin metadatos |
| `OCRAEXT.TTF` | Licencia desconocida |

## Descartados
Pandazole Kitchen Assets (D15), Kevin Iglesias Human Animations (sin uso).
