# PUL-023 evidencia
- 1 pausa: `hud_paused.png` (HUD atenuado) + `test_hud.gd::test_pause_changed_dims_and_restores_hud`.
- 2 formato y color: `hud_ratio_green.png` (100.0s, 3 cajas -> 1.80 en verde; la captura en pausa muestra 2.25 verde) + `test_ratio_is_green_above_one_and_red_otherwise`.
- 3 claves explícitas: `test_data_catalog.gd::test_translation_keys_are_explicit`.
- 4 escenas/tema: variaciones `MenuPrimaryButton`/`MenuSecondaryButton` y colores `RoundHUD` en `default_theme.tres`; test_main_menu verde.
- 5 `restart_level` -> `start_level(mode)`: `test_game_state.gd` + ADR-002.
- 6 `ui_cancel`: `test_pause_menu.gd::test_ui_cancel_resumes_only_while_paused`.
- 7 doble accept: `test_main_menu.gd::test_double_accept_starts_level_once`.
