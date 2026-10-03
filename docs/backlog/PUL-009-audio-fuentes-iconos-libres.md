---
id: PUL-009
title: Incorporar audio, fuentes e iconos con licencia libre
status: review
milestone: M0
role: asset-pipeline
deps: []
orca_task: null
unity_sources: [Assets/Audio/**, Assets/Art/Icons/**, Assets/Art/Logo/**, Assets/Plugins/TextMesh Pro/Fonts/**]
owns: [godot/assets/audio/**, godot/assets/fonts/**, godot/assets/textures/**, godot/assets/CREDITS.md, godot/ui/theme/**, godot/tests/unit/test_assets_audio_ui.gd, godot/tests/unit/test_assets_audio_ui.gd.uid, docs/assets/licenses-pul-009.md]
touches_scenes: []
---

## Target
Fase 3 de M0 (audio, fuentes, iconos) bajo D16: solo licencias confirmadas.

## Change
1. **Efectos**: sustituye los 5 SFX del prototipo (hervir en bucle, cortar, molinillo, entrega
   correcta, entrega errónea) por equivalentes **CC0** (p. ej. Kenney.nl, freesound con filtro CC0).
   Guarda URL de origen y licencia de cada uno. Bucles en `.ogg` con loop activado en el import.
2. **Fuente**: LiberationSans (OFL, ya en el repo) o una OFL de Google Fonts con aire de feria,
   con su `OFL.txt`. Crea `ui/theme/default_theme.tres` que la use.
3. **Iconos**: `pepper-hot-solid.svg` (CC BY, con atribución) y sustitutos CC0/CC BY para pulpo,
   sal y retícula de selección. Copia el logo propio `PulpaSA.png`.
4. Fichero `CREDITS.md` en `godot/assets/` con las atribuciones obligatorias, y una tabla con el mismo formato que `docs/assets/licenses.md` en `docs/assets/licenses-pul-009.md` (el producer la consolida al fusionar; PUL-008 edita licenses.md en paralelo).

## Constraints
- Nada de la tabla «Pendientes» de licenses.md (audio original, OCRAEXT, iconos sin origen).
- Solo licencias CC0, CC BY u OFL. Si una fuente no deja clara la licencia, no se usa.
- No crees escenas de juego; el uso de los sonidos llega en fases 6–7.

## Acceptance
- [ ] AC1 Los 5 SFX existen, cargan como `AudioStream` y el de hervir tiene loop → `test_assets_audio_ui.gd`.
- [ ] AC2 `default_theme.tres` carga y usa la fuente incorporada → mismo test.
- [ ] AC3 Cada asset nuevo tiene fila en licenses-pul-009.md con URL y licencia, y `CREDITS.md` recoge las atribuciones.
- [ ] AC4 `tools/verify.sh` en verde.

## Plan

## Evidence

Evidence (tools/verify.sh): gdformat, gdlint, import OK; GUT 8 scripts, 37/37 tests passed (incl. `test_assets_audio_ui.gd`); smoke OK; `✓ verify OK`.
Notas: sin captura visual (solo audio/tema, sin escenas). Hervor: `loop=true` en `boiling_water_loop.ogg.import`. Iconos octopus/salt/selection de game-icons.net (CC BY 3.0).
Corrección: el icono pimiento es Line Awesome (Icons8, MIT), no Font Awesome; verify OK.
