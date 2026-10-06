# Evidencia PUL-068
Medición con `ffmpeg -af ebur128=peak=true` sobre `godot/assets/audio/`:
bg_romeria_loop −16,1 LUFS (pico −3,1) · fol_feria_loop −22,4 · fx_burned −18,3 · fx_burn_warning −18,3 · fx_drop −19,6 ·
fx_order_expired −18,1 · fx_order_new −18,0 · fx_phase_change −18,1 · fx_grab y fx_ui_click: <0,4 s, normalizados por pico.
Importación: `godot --headless --import` sin errores; `.import` de BG y FOL con `loop=true`.
Licencias: ver `docs/assets/audio-sources.md`.
