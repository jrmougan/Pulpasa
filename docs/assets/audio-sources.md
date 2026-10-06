# Fuentes de audio M3 (PUL-068)

Todo CC0 (D16). Licencia verificada en la página de cada recurso el 2026-10-06. Procesado: ffmpeg, estéreo 44,1 kHz,
`.ogg` Vorbis q4, `loudnorm` (música −16 LUFS, ambiente −22 LUFS, FX −18 LUFS; `fx_grab` y `fx_ui_click` son
demasiado cortos para medir LUFS: ajustados por pico a −4/−6 dBTP). Los bucles tienen crossfade de la cola con la
cabeza (2 s música, 1,5 s ambiente) y `loop=true` en el `.import`.

| Archivo | Uso | Origen | Autor | Licencia | Atribución |
|---|---|---|---|---|---|
| `bg_romeria_loop.ogg` | BG (música, bucle ~41 s) | https://opengameart.org/node/114926 («Celtic Loop», `celtic_0.mp3`) | stereoscopic | CC0 (página: «CC0») | "Celtic Loop" by stereoscopic, CC0 (OpenGameArt) |
| `fol_feria_loop.ogg` | FOL (ambiente de multitud, bucle ~26 s) | https://opengameart.org/content/crowd-shoutingspeaking-ambience (`crowd_shouting_0.ogg`) | StarNinjas | CC0 (página: «CC0») | "Crowd Shouting/Speaking Ambience" by StarNinjas, CC0 (OpenGameArt) |
| `fx_grab.ogg` | coger | Kenney RPG Audio, `handleSmallLeather.ogg` | Kenney | CC0 | Kenney (kenney.nl), CC0 |
| `fx_drop.ogg` | soltar | Kenney RPG Audio, `dropLeather.ogg` | Kenney | CC0 | Kenney (kenney.nl), CC0 |
| `fx_order_new.ogg` | nueva comanda | Kenney Music Jingles, `Pizzicato jingles/jingles_PIZZI03.ogg` | Kenney | CC0 | Kenney (kenney.nl), CC0 |
| `fx_order_expired.ogg` | comanda caducada | Kenney Music Jingles, `Hit jingles/jingles_HIT03.ogg` | Kenney | CC0 | Kenney (kenney.nl), CC0 |
| `fx_burn_warning.ogg` | aviso de quemado | Kenney Interface Sounds, `error_003.ogg` | Kenney | CC0 | Kenney (kenney.nl), CC0 |
| `fx_burned.ogg` | quemado | Kenney RPG Audio, `metalPot3.ogg` | Kenney | CC0 | Kenney (kenney.nl), CC0 |
| `fx_phase_change.ogg` | cambio de fase | Kenney Music Jingles, `Steel jingles/jingles_STEEL05.ogg` | Kenney | CC0 | Kenney (kenney.nl), CC0 |
| `fx_ui_click.ogg` | botón de UI | Kenney UI Audio, `click3.ogg` | Kenney | CC0 | Kenney (kenney.nl), CC0 |

## Packs de Kenney (todos CC0, `License.txt` del zip: «Creative Commons Zero, CC0»)
- RPG Audio: https://kenney.nl/assets/rpg-audio
- Music Jingles: https://kenney.nl/assets/music-jingles
- Interface Sounds: https://kenney.nl/assets/interface-sounds
- UI Audio: https://kenney.nl/assets/ui-audio
Cita de la página de cada pack: «Creative Commons CC0 allows you to waive all your rights to the work worldwide under copyright law.»

## Notas
- `bg_romeria_loop`: música celta/irlandesa (no es gaita gallega); sirve como BG provisional. Hay pocas pistas CC0 de gaita/pandereta.
- `fol_feria_loop`: la fuente suena a multitud gritando/hablando (tags «market»); es el mejor ambiente CC0 encontrado. Se mezcla bajo (−22 LUFS).
- Los FX son una selección por nombre y duración; conviene una escucha humana y, si alguno no encaja, sustituirlo por otro del mismo pack.
- No se han conectado a escenas (PUL-071).
