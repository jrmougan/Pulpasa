---
id: PUL-009
title: Incorporar audio, fuentes e iconos con licencia libre
status: ready
milestone: M0
role: asset-pipeline
deps: []
orca_task: null
unity_sources: [Assets/Audio/**, Assets/Art/Icons/**, Assets/Art/Logo/**, Assets/Plugins/TextMesh Pro/Fonts/**]
owns: [godot/assets/audio/**, godot/assets/fonts/**, godot/assets/textures/**, godot/ui/theme/**, godot/tests/unit/test_assets_audio_ui.gd, godot/tests/unit/test_assets_audio_ui.gd.uid, docs/assets/licenses.md]
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
4. Fichero `CREDITS.md` en `godot/assets/` con las atribuciones obligatorias, y filas en `docs/assets/licenses.md`.

## Constraints
- Nada de la tabla «Pendientes» de licenses.md (audio original, OCRAEXT, iconos sin origen).
- Solo licencias CC0, CC BY u OFL. Si una fuente no deja clara la licencia, no se usa.
- No crees escenas de juego; el uso de los sonidos llega en fases 6–7.

## Acceptance
- [ ] AC1 Los 5 SFX existen, cargan como `AudioStream` y el de hervir tiene loop → `test_assets_audio_ui.gd`.
- [ ] AC2 `default_theme.tres` carga y usa la fuente incorporada → mismo test.
- [ ] AC3 Cada asset nuevo tiene fila en licenses.md con URL y licencia, y `CREDITS.md` recoge las atribuciones.
- [ ] AC4 `tools/verify.sh` en verde.

## Plan

## Evidence
