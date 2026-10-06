# Licencias de assets

Regla D16: en el proyecto Godot solo entra lo que tiene licencia confirmada. Toda incorporación
añade una fila aquí. Lo dudoso se sustituye por alternativas libres o primitivas.

## Confirmados

| Asset (origen) | Destino en `godot/` | Licencia | Atribución requerida |
|---|---|---|---|
| Montserrat Black y Bold (Julieta Ulanovsky y colaboradores; github.com/JulietaUla/Montserrat), convertidas a trazados en `art/brand/*.svg` (PUL-088) | `assets/textures/brand/pulpasa_*.png` | SIL OFL 1.1 | No en el dibujo; si se distribuye la fuente, incluir `OFL.txt` |
| Símbolo, placas y maquetas de `art/brand/` (PUL-088) | `assets/textures/brand/pulpasa_*.png` | Propio (equipo Pulpasa) | No |
| `docs/evidence/PUL-073/luz_v2.blend` (PUL-073, escena de luz de referencia) | — (solo evidencia) | Propio (equipo Pulpasa) | No |
| `art/blender/cook.blend` v2 (PUL-075) | `assets/models/characters/cook/cook.glb` y calcas | Propio (equipo Pulpasa) | No |
| `art/blender/seasoning_station.blend` v2 (PUL-082) | `assets/models/stations/seasoning_station/*` | Propio (equipo Pulpasa) | No |
| `art/blender/pot.blend` v2 (PUL-078) | `assets/models/stations/pot/pot.glb` y texturas | Propio (equipo Pulpasa) | No |
| `art/blender/_materials_v2.blend` (PUL-074, texturas procedurales propias) | `assets/materials/v2/*.tres`, `assets/textures/v2/*` | Propio (equipo Pulpasa) | No |
| `art/blender/octopus.blend` (PUL-045, D20) | `assets/models/food/octopus/octopus.glb`, `octopus_pieces.glb` | Propio (equipo Pulpasa) | No |
| `art/blender/cachelos.blend` (PUL-046, D20) | `assets/models/food/cachelos/cachelos.glb`, `cachelos_pieces.glb` | Propio (equipo Pulpasa) | No |
| `art/blender/box.blend` (PUL-047, D20) | `assets/models/items/box/box.glb`, `box_box_stickers.png` | Propio (equipo Pulpasa); iconos del atlas derivados de los ya registrados (Lorc, Delapouite: CC BY 3.0; Line Awesome: MIT) | Sí, la de esos iconos |
| `art/blender/cook.blend` (PUL-044, D20) | `assets/models/characters/cook/cook.glb` | Propio (equipo Pulpasa) | No |
| `art/blender/pot.blend` (PUL-048, D20) | `assets/models/stations/pot/pot.glb` | Propio (equipo Pulpasa) | No |
| `art/blender/octopus_storage.blend` (PUL-049, D20) | `assets/models/stations/octopus_storage/octopus_storage.glb` | Propio (equipo Pulpasa) | No |
| `art/blender/cachelos_storage.blend` (PUL-050, D20) | `assets/models/stations/cachelos_storage/cachelos_storage.glb` | Propio (equipo Pulpasa) | No |
| `art/blender/box_shelf.blend` (PUL-051, D20) | `assets/models/stations/box_shelf/box_shelf.glb` | Propio (equipo Pulpasa) | No |
| `art/blender/order_stand.blend` (PUL-053, D20) | `assets/models/stations/order_stand/order_stand.glb` | Propio (equipo Pulpasa) | No |
| `art/blender/seasoning_station.blend` (PUL-052, D20) | `assets/models/stations/seasoning_station/*.glb` | Propio (equipo Pulpasa) | No |
| `art/blender/counters.blend` (PUL-054, D20) | `assets/models/furniture/counters/*.glb` | Propio (equipo Pulpasa) | No |
| `art/blender/romeria.blend` (PUL-055, D20) | `assets/models/environment/romeria/{ground,tent,decor}.glb` | Propio (equipo Pulpasa) | No |
| https://opengameart.org/node/114926 («Celtic Loop», stereoscopic) | `assets/audio/bg_romeria_loop.ogg` | CC0 | No |
| https://opengameart.org/content/crowd-shoutingspeaking-ambience (StarNinjas) | `assets/audio/fol_feria_loop.ogg` | CC0 | No |
| Kenney (RPG Audio, Music Jingles, Interface Sounds, UI Audio; kenney.nl) | `assets/audio/fx_{grab,drop,order_new,order_expired,burn_warning,burned,phase_change,ui_click}.ogg` | CC0 | No (detalle en `docs/assets/audio-sources.md`) |
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
| Propio | `assets/materials/ph_oil.tres`, `ph_oil_liquid.tres`, `ph_cachelo_raw.tres`, `ph_cachelo_cooked.tres` | Propio | No |
| https://game-icons.net/1x1/lorc/small-fire.html («Small fire», Lorc; verificado contra https://raw.githubusercontent.com/game-icons/icons/master/lorc/small-fire.svg, sin el fondo negro) | `assets/textures/icons/small-fire.svg` | CC BY 3.0 | Sí: «Small fire» por Lorc, game-icons.net |
| `assets/textures/icons/pepper-hot-solid.svg` (ya listado en `licenses.md`): solo se añade `fill="#fff"` | `assets/textures/icons/pepper-hot-solid.svg` | MIT (o Good Boy License) | Sí: Icons8, Line Awesome |

Los SVG de game-icons.net se modifican quitando el rectángulo negro de fondo. Atribuciones completas en `godot/assets/CREDITS.md`.

## Creados en el proyecto (PUL-008)

| Asset | Destino en `godot/` | Licencia | Atribución requerida |
|---|---|---|---|
| Placeholders de primitivas que siguen en uso (`box_small`, `table_square`; el resto, en «Retirados»); dimensiones tomadas de prefabs Unity y Pandazole solo como medida | `assets/models/placeholders/*.tscn` | Propio (creados por el equipo) | No |
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

## Retirados
Quitados del repositorio en PUL-067 (sustituidos por el arte propio de M3, D20); todos eran propios, sin atribución.

| Asset | Antes en `godot/` | Sustituido por |
|---|---|---|
| Placeholders de primitivas: olla, fogón, nevera, 2 mesas (larga, media), 2 cajas (media, grande), 2 pulpos, personaje | `assets/models/placeholders/{pot,stove,fridge,table_long,table_medium,box_medium,box_large,octopus_raw,octopus_cooked,character}.tscn` | `.glb` de PUL-045..055 |
| Placeholders de PUL-031: bote de aceite, cachelos crudo/cocido, cachelera | `assets/models/placeholders/{oil_bottle,cachelos_raw,cachelos_cooked,cachelera}.tscn` | PUL-046, PUL-050 |
| `Art/Furniture/Mueblecajas.fbx` (+ envoltorio `Mueblecajas.tscn`) | `assets/models/furniture/Mueblecajas.*` | `box_shelf.glb` (PUL-051) |

Los materiales `ph_*` se conservan por ahora (fuera de `owns` de PUL-067).

## Descartados
Pandazole Kitchen Assets (D15), Kevin Iglesias Human Animations (sin uso).
