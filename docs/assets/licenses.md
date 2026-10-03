# Licencias de assets

Regla D16: en el proyecto Godot solo entra lo que tiene licencia confirmada. Toda incorporación
añade una fila aquí. Lo dudoso se sustituye por alternativas libres o primitivas.

## Confirmados

| Asset (origen) | Destino en `godot/` | Licencia | Atribución requerida |
|---|---|---|---|
| `Art/Furniture/Mueblecajas.fbx` | — | Propio (equipo Pulpasa) | No |
| `Art/Furniture/order_stand.fbx` | — | Propio (equipo Pulpasa) | No |
| `Art/Materials/**` (colores y parámetros) | — | Propio | No |
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

Los SVG de game-icons.net se modifican quitando el rectángulo negro de fondo. Atribuciones completas en `godot/assets/CREDITS.md`.

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
