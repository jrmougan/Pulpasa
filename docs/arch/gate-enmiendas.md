# Gate de enmiendas pendientes

Documento de trabajo para el gate humano (PUL-196, 2026-11-04). **Ningún agente acepta nada**: este
documento solo recomienda. Los estados siguen siendo los de cada cabecera hasta que el responsable
decida. Cada fila se comprobó contra el código de la rama de PUL-196 (base `cac6ac1`); si el código
cambia, las líneas citadas pueden moverse.

Cómo leer las recomendaciones:
- **aceptar**: el código hace lo que dice el texto. Se puede cambiar el estado tal cual.
- **aceptar con cambios**: el código está implementado, pero el texto no coincide del todo. La fila
  dice qué cambiar **antes** de aceptar. Ese cambio de texto lo hace el arquitecto en una ficha aparte.
- **rechazar**: ninguna fila lo recomienda. No hay enmienda sin implementar ni contraria a una decisión.

Resultado: 34 filas para aceptar, 24 para aceptar con cambios y 0 para rechazar. Todo lo vigente está
implementado; lo único que no lo está es el aviso «Fase n» del HUD (G46), que es un Could. El riesgo no
es de código: los documentos se escribieron por capas y parte del texto antiguo ya no coincide con el
juego. `comprobaciones.txt` es `docs/evidence/PUL-196/comprobaciones.txt`.

## Decisiones que hacen falta aparte de la tabla

1. **G03**: ADR-002 Enmienda 1 nombra un método que no existe (`set_new_order_max_time`). ADR-006 §6, ya
   aceptado, y el código usan `set_new_order_patience_multiplier`. No hay nada que decidir salvo aprobar
   el cambio de nombre en el texto, pero la enmienda no debería aceptarse tal cual.
2. **R2 (G45)**: nadie registró la respuesta. ADR-006 está aceptado, pero `signals.md` sigue diciendo
   «Pendiente de R2» y el AC2 de `audio-y-fx` sigue pidiendo una señal de `EventBus`.
3. **D23 (G49, G55)**: `signals.md` y `scene-tree.md` dicen «pendiente de la revisión del producer» y
   ADR-003 §9 dice «aceptada por el producer». El ciclo de `README.md` pide gate humano del responsable:
   el responsable debe decidir si esa aceptación vale o la ratifica aquí.
4. **T3**: propuesta al final del documento.

## Tabla

El id de fila (`G01`…) sirve para decidir fila a fila. «Sin divergencia» quiere decir que lo citado
coincide; no se han repetido medidas de playtest ni de rendimiento (ver «Qué no se ha comprobado»).

| # | Documento y sección | Ficha | Qué decide | ¿Implementada? (ruta:línea o test) | Divergencia entre código y texto | Recomendación |
|---|---|---|---|---|---|---|
| G01 | ADR-002 Enmienda 1.1 | PUL-066 | Quinto autoload `AudioDirector`, adaptador de `AudioMix`, único escritor del volumen de buses | Sí. `godot/project.godot:20`, `godot/autoload/audio_director.gd:21`, `godot/autoload/audio_director.gd:51`, `godot/tests/unit/test_audio_mix.gd:13` | Sin divergencia | aceptar |
| G02 | ADR-002 Enmienda 1.2 | PUL-066 | `RoundState` emite `phase_changed` y `RoundManager` la reenvía; orden dentro de `start` y `advance` | Sí. `godot/core/round_state.gd:11`, `godot/core/round_state.gd:148`, `godot/core/round_state.gd:163`, `godot/autoload/round_manager.gd:103`, `godot/tests/unit/test_phases.gd:130` | Sin divergencia | aceptar |
| G03 | ADR-002 Enmienda 1.3 | PUL-066 | Métodos nuevos de `OrderBoard` para las fases | Sí, con otro nombre. `godot/core/order_board.gd:69`, `godot/core/order_board.gd:76` | **Sí.** `docs/arch/ADR-002-eventbus-autoloads.md:225` dice `set_new_order_max_time(seconds)`; el código y ADR-006 §6 usan `set_new_order_patience_multiplier(factor)`, y no hay ninguna aparición de `set_new_order_max_time` en `godot/`. Ya lo avisó PUL-070 | aceptar con cambios: sustituir el método por el de ADR-006 §6 |
| G04 | ADR-002 Enmienda 1.4 | PUL-066 | `RoundConfig.rng_seed`; `OrderService.setup` la usa si no recibe `rng` | Sí. `godot/resources/round_config.gd:25`, `godot/autoload/order_service.gd:30`, `godot/tests/unit/test_phases.gd:384` | Sin divergencia | aceptar |
| G05 | ADR-002 Enmienda 2.1 | PUL-120 | Emisor no autoload en el bus: un emisor por señal y por `player_index` | Sí. `godot/components/interaction_component.gd:116`, `godot/components/interaction_component.gd:172`, `godot/tests/unit/test_interaction_component.gd:363` | Sin divergencia | aceptar |
| G06 | ADR-002 Enmienda 2.2 y 2.3 | PUL-120 | `GameState` gana el perfil de plataforma, escala y pausa al perder el foco; ningún autoload nuevo | Sí. `godot/autoload/game_state.gd:21`, `godot/autoload/game_state.gd:62`, `godot/autoload/game_state.gd:66`, `godot/autoload/game_state.gd:77`, `godot/core/platform_profile.gd:18`, `godot/tests/unit/test_game_state.gd:240` | Sin divergencia | aceptar |
| G07 | ADR-003 §8.1 | PUL-056 | Regla de lado: `StationSide`, `side_of`, método opcional `is_reachable_from` | Sí. `godot/core/station_side.gd:10`, `godot/entities/stations/seasoning_station.gd:35`, `godot/components/interaction_detector.gd:164`, `godot/components/interaction_contract.gd:16`, `godot/tests/unit/test_station_side.gd:8` | **Sí.** `docs/arch/ADR-003-arbol-escenas-composicion.md:182` dice que el dispensador devuelve `false` si la mano lleva algo; `godot/entities/stations/seasoning_dispenser.gd:42` ignora la mano y solo filtra el lado (§11.2). Las filas de `Tray` y del cuenco también son historia | aceptar con cambios: aceptar la regla de lado y marcar como sustituidas por §9 y §11 las filas de dispensador, cuenco y `Tray` |
| G08 | ADR-003 §8.2 | PUL-056 | Dispensador y cuenco consumen la pulsación al rechazar; `Slot.accepted_group` | Sí, lo vigente. `godot/entities/stations/seasoning_dispenser.gd:71`, `godot/entities/stations/cachelos_bowl.gd:84`, `godot/entities/stations/slot.gd:17`, `godot/entities/stations/slot.gd:94` | **Sí.** El texto cita `%ErrorAudio` y `toggle_guard`; en la estación solo hay `%Feedback` (`godot/entities/stations/seasoning_station.tscn:56`) y `toggle_guard` está dado de baja (`godot/tests/integration/test_seasoning_station.gd:407`) | aceptar con cambios: conservar consumir y rechazar y `accepted_group`; marcar `%ErrorAudio` y antirrebote como sustituidos |
| G09 | ADR-003 §8.3 | PUL-056 | Reglas en `SeasoningRules`, API de la caja, `station.get_box()` | Parcial. `godot/core/seasoning_rules.gd:8`, `godot/core/seasoning_rules.gd:88` | **Sí.** `toggle_seasoning` no existe (`godot/tests/integration/test_box.gd:277`) ni `get_box`; la API real es `godot/entities/items/box.gd:80`. La nota «Estado tras el montaje» de §11 ya lo reconoce | aceptar con cambios: citar `apply_seasoning` como API vigente; `toggle_seasoning` y `get_box` como baja |
| G10 | ADR-003 §8.4 | PUL-056 | Una escena por dispensador y cuenco, estación en `world`, `%BadgeRow` de mundo, bajas | Sí. `godot/entities/stations/seasoning_station.tscn:19`, `godot/entities/stations/seasoning_station.tscn:40`, `godot/entities/stations/seasoning_station.tscn:52`, `godot/entities/items/badge_row.gd:152`. Las bajas no existen (salida en `comprobaciones.txt`) | Menor: `docs/arch/ADR-003-arbol-escenas-composicion.md:241` aún nombra la bandeja; la nota D23 de §8 ya la cubre | aceptar |
| G11 | ADR-003 §10.1 | PUL-111 | Caja única, receta sin caja, validador sin caja, rack de un spawner, ticket sin talla | Sí. `godot/resources/box_data.gd:8`, `godot/data/boxes/box.tres:9`, `godot/resources/recipe_data.gd:8`, `godot/core/order_validator.gd:9`, `godot/core/box_contents.gd:6`, `godot/entities/stations/box_shelf.tscn:24`, `godot/entities/stations/box_shelf.tscn:38`, `godot/ui/tickets/ticket_entry.gd:46` | Menor: `godot/resources/box_data.gd:10` (`counter_full_time`) no está en la lista de campos que quedan. `presses_to_fill` sigue marcado como provisional (`docs/arch/ADR-003-arbol-escenas-composicion.md:412`) | aceptar con cambios: añadir el campo; el responsable decide si 6 deja de ser provisional |
| G12 | ADR-003 §10.2 | PUL-111 | Dos dispensadores de aliño, `SeasoningRules.apply`, `Box.apply_seasoning`, `%Gesture`, disposición | Sí. `godot/resources/seasoning_data.gd:7`, `godot/core/seasoning_rules.gd:21`, `godot/core/seasoning_rules.gd:41`, `godot/entities/items/box.gd:80`, `godot/entities/items/box.gd:159`, `godot/entities/items/box.gd:161`, `godot/entities/stations/seasoning_dispenser.tscn:75`, `godot/entities/stations/seasoning_station.tscn:41`, `godot/entities/stations/seasoning_station.tscn:47`, `godot/entities/stations/seasoning_station.tscn:53`, `godot/resources/box_badge_style.gd:18` | Texto ya corregido en el propio documento: `ALREADY_APPLIED` silencioso y `toggle()` los sustituye §11.7, con nota. Sin divergencia con §11 aplicado | aceptar, junto con §11.7 (G22): por separado §10.2 describiría un comportamiento que ya no existe |
| G13 | ADR-003 §10.3 | PUL-111 | Cubo de basura: reglas, datos, contrato, señal local, dos instancias, regla de colocación | Sí. `godot/core/trash_rules.gd:10`, `godot/resources/trash_bin_data.gd:6`, `godot/data/config/trash_bin.tres:7`, `godot/entities/stations/trash_bin.gd:27`, `godot/entities/stations/trash_bin.gd:44`, `godot/entities/stations/trash_bin.gd:47`, `godot/entities/stations/trash_bin.tscn:13`, `godot/scenes/levels/level_01.tscn:89`, `godot/scenes/levels/level_01.tscn:92`, `godot/tests/integration/test_trash_bin.gd:291` | **Sí, menor.** `docs/arch/ADR-003-arbol-escenas-composicion.md:542` dice que la regla de 1,5 m la exige `test_level_01.gd`; ese test solo fija las posiciones (`godot/tests/integration/test_level_01.gd:33`) y la distancia se comprueba en `test_trash_bin.gd` | aceptar con cambios: citar `test_trash_bin.gd` |
| G14 | ADR-003 §10.4 | PUL-111 | Cuatro recetas y comandas, catálogo único, bajas | Sí. `godot/data/recipes/a_feira.tres:11`, `godot/data/recipes/bravo_cachelos.tres:11`, `godot/data/orders/con_cachelos.tres:12`, `godot/data/orders/order_catalog.tres:11`, `godot/data/config/round_config.tres:16`, `godot/tests/unit/test_data_integrity.gd:254` | Sin divergencia | aceptar |
| G15 | ADR-003 §10.5 | PUL-111 | Ninguna señal nueva en `EventBus`; local `TrashBin.trashed` | Sí. `godot/entities/stations/trash_bin.gd:8`, `godot/tests/unit/test_event_bus.gd:53` | Sin divergencia | aceptar |
| G16 | ADR-003 §11.1 | PUL-120 | Tipos comunes `ActionVerb`, `ActionReason`, `ActionHint`, `ActionRules`, `HoldRepeat`, `HeldKind` | Sí. `godot/core/action_verb.gd:25`, `godot/core/action_verb.gd:27`, `godot/core/action_reason.gd:21`, `godot/core/action_hint.gd:7`, `godot/core/action_hint.gd:48`, `godot/core/action_rules.gd:9`, `godot/core/hold_repeat.gd:36`, `godot/entities/items/held_kind.gd:8` | Sin divergencia | aceptar |
| G17 | ADR-003 §11.2 | PUL-120 | `get_action_hint` obligatorio, una sola resolución, `can_interact` honesto | Sí. `godot/components/interaction_contract.gd:12`, `godot/components/interaction_contract.gd:13`, `godot/entities/stations/slot.gd:70`, `godot/entities/stations/slot.gd:111`, `godot/entities/stations/item_spawner.gd:16`, `godot/tests/integration/test_stations_contract.gd:75` | Sin divergencia (lo de «hasta la oleada de montaje» ya está cumplido) | aceptar |
| G18 | ADR-003 §11.3 | PUL-120 | Detector: filtro por hint, sin control no hay objetivo, hint de suelo, histéresis, publicación | Sí. `godot/components/interaction_detector.gd:28`, `godot/components/interaction_detector.gd:43`, `godot/components/interaction_detector.gd:84`, `godot/components/interaction_detector.gd:134`, `godot/components/interaction_detector.gd:139`, `godot/components/interaction_detector.gd:146`, `godot/components/interaction_detector.gd:154`, `godot/core/interaction_scoring.gd:70`, `godot/data/config/player_config.tres:16`, `godot/tests/unit/test_interaction_scoring.gd:386` | Sin divergencia | aceptar |
| G19 | ADR-003 §11.4 | PUL-120 | Respuesta única por pulsación, suelo, mantener para cortar, bus del hint | Sí. `godot/components/interaction_component.gd:68`, `godot/components/interaction_component.gd:81`, `godot/components/interaction_component.gd:113`, `godot/components/interaction_component.gd:127`, `godot/entities/player/player.gd:214`, `godot/core/player_input.gd:38`, `godot/data/config/input_config.tres:9` | Sin divergencia | aceptar |
| G20 | ADR-003 §11.5 | PUL-120 | `ActionPrompt` en el mundo, registro estático, datos de iconos | Sí. `godot/entities/player/action_prompt.tscn:6`, `godot/components/action_prompt.gd:35`, `godot/components/action_prompt.gd:41`, `godot/components/action_prompt.gd:424`, `godot/components/hold_component.gd:91`, `godot/resources/action_icon_set.gd:8`, `godot/resources/action_icon_set.gd:36`, `godot/tests/integration/test_action_prompt.gd:316` | Sin divergencia | aceptar |
| G21 | ADR-003 §11.6 | PUL-120 | Tabla por receptor y fixture de 250 filas o más | Sí. `godot/tests/fixtures/action_matrix.csv:1` (354 líneas), `godot/tests/unit/test_action_rules.gd:110`, `godot/tests/integration/test_action_matrix.gd:734` | Sin divergencia; comprobada mediante esos tests, no rama a rama | aceptar |
| G22 | ADR-003 §11.7 | PUL-120 | Entrega solo por zona, cuenco que solo pone, verbo del aliño en datos | Sí. `godot/entities/stations/order_stand.tscn:33`, `godot/entities/stations/order_stand.tscn:34`, `godot/entities/stations/order_stand.gd:92`, `godot/entities/stations/order_stand.gd:142`, `godot/data/config/round_config.tres:38`, `godot/entities/stations/cachelos_bowl.gd:116`, `godot/data/seasonings/sweet_dressing.tres:13`, `godot/tests/integration/test_order_stand.gd:328`, `godot/tests/integration/test_order_stand.gd:425` | Sin divergencia | aceptar |
| G23 | ADR-003 §11.8 | PUL-120 | Estado legible: anillo de cocción, contador de corte, medidor del cuenco, personaje activo, contorno | Sí. `godot/entities/stations/kitchen.tscn:133`, `godot/entities/stations/cooking_station.gd:119`, `godot/resources/kitchen_data.gd:11`, `godot/entities/items/box.tscn:95`, `godot/entities/stations/cachelos_bowl.tscn:49`, `godot/entities/player/player.tscn:206`, `godot/entities/player/player.tscn:213`, `godot/entities/player/player.tscn:220`, `godot/components/highlightable.gd:70`, `godot/shaders/highlight_outline.gdshader:4` | **Sí, menor.** `docs/arch/ADR-003-arbol-escenas-composicion.md:885` describe un solo indicador; hay un hermano `%InactiveIndicator` que recibe `inactive_material` (`godot/entities/player/player.gd:21`). `scene-tree.md` §9.1 sí lo recoge | aceptar con cambios: alinear con `scene-tree.md` §9.1 |
| G24 | ADR-003 §11.9 | PUL-120 | Dos señales nuevas en `EventBus` y dos locales | Sí. `godot/autoload/event_bus.gd:35`, `godot/autoload/event_bus.gd:37`, `godot/components/interaction_component.gd:15`, `godot/tests/unit/test_event_bus.gd:61` | Sin divergencia | aceptar |
| G25 | ADR-004 §6.1 | PUL-120 | El táctil alimenta las acciones existentes; `project.godot` no gana eventos | Sí. `godot/ui/touch/virtual_stick.gd:151`, `godot/ui/touch/touch_button.gd:126`, `godot/ui/touch/touch_controls.gd:88`. Cero apariciones de `ScreenTouch` en `project.godot` (`comprobaciones.txt`) | Sin divergencia | aceptar |
| G26 | ADR-004 §6.2 | PUL-120 | Escena `TouchControls`, multitáctil, stick flotante, botón de acción, háptica, `TouchConfig` | Sí. `godot/ui/touch/touch_controls.tscn:23`, `godot/ui/touch/touch_controls.tscn:34`, `godot/ui/touch/touch_controls.tscn:40`, `godot/ui/touch/touch_controls.tscn:47`, `godot/ui/touch/touch_controls.tscn:54`, `godot/ui/touch/touch_controls.tscn:63`, `godot/ui/touch/action_button.gd:26`, `godot/ui/touch/action_button.gd:152`, `godot/resources/touch_config.gd:7`, `godot/scenes/levels/level_01.tscn:128`, `godot/ui/touch/touch_controls.gd:23` | **Sí, menor.** `TouchConfig` tiene campos que el contrato no lista, por ejemplo `godot/resources/touch_config.gd:27` | aceptar con cambios: añadir los campos o decir que la lista es el mínimo |
| G27 | ADR-004 §6.3 | PUL-120 | Cuándo se ven los controles: `TouchInput` puro | Sí. `godot/core/touch_input.gd:19`, `godot/core/touch_input.gd:34`, `godot/ui/touch/touch_controls.gd:159` | **Sí.** `docs/arch/ADR-004-input-coop-local.md:231` dice `source_of(event)`; el código es `source_of(event, joy_deadzone)` | aceptar con cambios: corregir la firma |
| G28 | ADR-004 §6.4 | PUL-120 | Corte al mantener, común a todas las entradas | Sí. `godot/core/player_input.gd:38`, `godot/core/hold_repeat.gd:36`, `godot/core/action_verb.gd:27`, `godot/resources/input_config.gd:10`, `godot/components/interaction_component.gd:132` | Sin divergencia | aceptar |
| G29 | ADR-004 §6.5 | PUL-120 | Menú móvil, pausa por foco y tecla Atrás, pantalla encendida | Sí. `godot/ui/menus/main_menu.gd:50`, `godot/autoload/game_state.gd:77`, `godot/autoload/game_state.gd:79`, `godot/autoload/game_state.gd:199`, `godot/tests/integration/test_app_lifecycle.gd:30`, `godot/tests/integration/test_app_lifecycle.gd:48` | **Sí, menor.** Atrás en el menú sale del juego (`godot/ui/menus/main_menu.gd:65`) con `godot/project.godot:12`; el contrato solo habla de la pausa | aceptar con cambios: añadir ese caso |
| G30 | ADR-005 Enmienda D26 E1 | PUL-120 | Perfil de plataforma | Sí. `godot/core/platform_profile.gd:18`, `godot/autoload/game_state.gd:21`, `godot/autoload/game_state.gd:62`, `godot/tests/unit/test_platform_profile.gd:12` | Sin divergencia | aceptar |
| G31 | ADR-005 Enmienda D26 E2 | PUL-120 | Escalado del lienzo y baja de `UiScale.factor()` | Sí. `godot/project.godot:33`, `godot/project.godot:35`, `godot/project.godot:36`, `godot/project.godot:37`, `godot/ui/widgets/ui_scale.gd:12`. Cero apariciones de `factor` en `ui_scale.gd` y de `UiScale.factor` en el juego (`comprobaciones.txt`) | Sin divergencia en esta ADR (ver G58 para `scene-tree.md`) | aceptar |
| G32 | ADR-005 Enmienda D26 E3 | PUL-120 | `UiProfile` y conversión en `UiScale` | Sí. `godot/resources/ui_profile.gd:7`, `godot/data/config/ui_profile_mobile.tres:8`, `godot/data/config/ui_profile_mobile.tres:12`, `godot/data/config/ui_profile_mobile.tres:13`, `godot/ui/widgets/ui_scale.gd:12`, `godot/ui/widgets/ui_scale.gd:17`, `godot/ui/widgets/ui_scale.gd:23`, `godot/tests/integration/test_ui_scale.gd:80` | **Sí, menor.** `godot/resources/ui_profile.gd:13` (`menu_card_width`) no está en el contrato | aceptar con cambios: añadir el campo |
| G33 | ADR-005 Enmienda D26 E4 | PUL-120 | Safe area y zonas reservadas | Sí. `godot/ui/widgets/safe_area_margin.gd:1`, `godot/ui/widgets/safe_area_margin.gd:18`, `godot/ui/hud/hud.gd:2`, `godot/ui/tickets/order_tickets_panel.gd:2`, `godot/ui/touch/touch_controls.tscn:23`, `godot/ui/menus/menu_panel.tscn:22`, `godot/ui/menus/main_menu.tscn:5`, `godot/ui/menus/pause_menu.tscn:15`, `godot/ui/menus/game_over.tscn:16`, `godot/tests/unit/test_ui_scale_math.gd:26` | Sin divergencia (pausa y game over la heredan de `menu_panel.tscn`) | aceptar |
| G34 | ADR-005 Enmienda D26 E5 | PUL-120 | Cámara por perfiles, seguimiento, flecha, banda superior y zona de botones | Sí. `godot/entities/camera/camera_rig.gd:16`, `godot/entities/camera/camera_rig.gd:17`, `godot/entities/camera/camera_rig.gd:19`, `godot/entities/camera/camera_rig.gd:58`, `godot/entities/camera/camera_rig.gd:194`, `godot/entities/camera/camera_rig.tscn:13`, `godot/resources/camera_profile.gd:24`, `godot/data/config/camera_desktop.tres:7`, `godot/data/config/camera_mobile.tres:7`, `godot/data/config/camera_mobile.tres:16`, `godot/core/camera_follow.gd:46`, `godot/core/camera_follow.gd:99`, `godot/core/camera_follow.gd:119`, `godot/scenes/levels/level_01.tscn:120`, `godot/tests/integration/test_camera_follow.gd:95` | Sin divergencia | aceptar |
| G35 | ADR-005 Enmienda D26 E6 | PUL-120 | Qué no cambia; la capa común sigue sin tipos de mundo | Sí. El `grep` de tipos de mundo en los seis ficheros solo da un comentario, `godot/resources/camera_profile.gd:5` (`comprobaciones.txt`) | Sin divergencia | aceptar |
| G36 | ADR-005 Enmienda D27.1 | PUL-137 | Botón de cambiar a la izquierda del de acción, alineado abajo | Sí (PUL-138). `godot/ui/touch/touch_controls.gd:137`, `godot/ui/touch/touch_controls.gd:145`, `godot/tests/integration/test_touch_layout.gd:85`, `godot/tests/integration/test_touch_layout.gd:97` | Sin divergencia | aceptar |
| G37 | ADR-005 Enmienda D27.2 | PUL-137 | Zona de botones anclada a la safe area; `button_zone_height_px` | Sí. `godot/resources/ui_profile.gd:29`, `godot/data/config/ui_profile_mobile.tres:22`, `godot/data/config/ui_profile_mobile.tres:23`, `godot/data/config/ui_profile_desktop.tres:23`, `godot/entities/camera/camera_rig.gd:243`, `godot/tests/integration/test_touch_layout.gd:199`, `godot/tests/integration/test_camera_follow.gd:189`. Cero apariciones de `button_zone_top_px` en `godot/` | Sin divergencia | aceptar |
| G38 | ADR-005 Enmienda D27.3 | PUL-137 | Caso 09 resuelto, con residuos y limitación con safe area inferior | Sí, con test. `godot/tests/integration/test_camera_button_zone.gd:264` | Sin divergencia observada. La tabla de píxeles no se ha vuelto a medir aquí | aceptar: es una limitación que el responsable ya aceptó según el texto |
| G39 | ADR-005 Enmienda D27.4 | PUL-137 | Qué no cambia: `TouchConfig`, `CameraProfile`, `signals.md`, árbol táctil | Sí. `godot/ui/touch/touch_controls.gd:124`, `godot/resources/touch_config.gd:15`, `godot/ui/touch/touch_controls.tscn:54` | Sin divergencia | aceptar |
| G40 | ADR-006 Enmienda D25 §4 | PUL-111 | Cue `trash`; `unseason` solo al sustituir | Sí. `godot/data/audio/feedback_map.tres:171`, `godot/data/audio/feedback_map.tres:172`, `godot/entities/stations/trash_bin.gd:11`, `godot/entities/items/box.gd:159` | Sin divergencia | aceptar |
| G41 | ADR-006 Enmienda D25 §5 | PUL-111 | El quemado se sigue desechando en la olla | Sí. `godot/core/action_rules.gd:46`, `godot/entities/stations/cooking_station.gd:396` | Sin divergencia | aceptar |
| G42 | ADR-006 Enmienda D25 §6 | PUL-111 | Comandas por fase: `PhaseData.orders` y `set_order_pool` | Sí. `godot/resources/phase_data.gd:14`, `godot/core/order_board.gd:62`, `godot/core/order_board.gd:83`, `godot/core/order_board.gd:107`, `godot/core/round_state.gd:161`, `godot/data/config/round_config.tres:16`, `godot/data/config/round_config.tres:23`, `godot/data/config/round_config.tres:30`, `godot/tests/unit/test_phases.gd:700` | Sin divergencia | aceptar |
| G43 | ADR-006 Enmienda D26 §4.1 | PUL-120 | Una respuesta por pulsación y cues distintos; bajas del mapa | Sí. `godot/data/audio/feedback_map.tres:155`, `godot/data/audio/feedback_map.tres:158`, `godot/data/audio/feedback_map.tres:168`, `godot/data/audio/feedback_map.tres:170`, `godot/entities/stations/cooking_station.gd:354`, `godot/entities/stations/cooking_station.gd:393`, `godot/entities/items/box.gd:199`, `godot/entities/player/player.gd:214`, `godot/entities/player/player.gd:220`, `godot/tests/unit/test_feedback_distinct.gd:16` | **Sí, menor.** `docs/arch/ADR-006-audio-feedback.md:206` sigue diciendo que correcta y errónea se distinguen con `deliver_error`, que ya no existe (`godot/tests/integration/test_order_stand.gd:425`) | aceptar con cambios: marcar ese párrafo como histórico |
| G44 | ADR-006 Enmienda D26, háptica | PUL-120 | La vibración la hace el botón táctil, no el mapa | Sí. `godot/ui/touch/action_button.gd:27`, `godot/ui/touch/action_button.gd:152` | Sin divergencia | aceptar |
| G45 | `signals.md` §5, nota final, y ADR-006 §3 (R2) | PUL-066 | Leer el AC2 de `audio-y-fx` como «su señal, de `EventBus` o local» | Sí, es lo implementado. `godot/entities/items/box.gd:199`, `godot/entities/player/player.gd:214`, `godot/entities/stations/order_stand.gd:197` | **Sí, documental.** `docs/arch/signals.md:299` dice «Pendiente de R2» y `docs/design/features/audio-y-fx.md:11` sigue pidiendo señal de `EventBus`. La ficha PUL-066 no registra la respuesta | aceptar con cambios: aprobar la lectura y actualizar las dos líneas |
| G46 | `signals.md`, estado «propuesto» | PUL-003 | El catálogo como contrato | Sí en nombres y firmas: `godot/tests/unit/test_event_bus.gd:53`, `godot/tests/unit/test_event_bus.gd:61`. No implementado: aviso «Fase n» del HUD, Could (`docs/arch/signals.md:79`) | **Sí.** Receptores que el catálogo no lista: `godot/autoload/game_state.gd:51`, `godot/autoload/game_state.gd:52`, `godot/entities/player/character_switcher.gd:29`, `godot/ui/menus/pause_menu.gd:29`, `godot/ui/touch/touch_controls.gd:38` | aceptar con cambios: añadir esos receptores y quitar `hud.gd` de `phase_changed` o dejarlo como Could explícito |
| G47 | `signals.md`, enmienda PUL-056 | PUL-056 | Tipos de la estación y señales locales; `EventBus` no cambia | Sí. `godot/entities/items/box.gd:161`, `godot/entities/stations/cachelos_bowl.gd:15`, `godot/entities/stations/seasoning_dispenser.gd:13`, `godot/core/station_side.gd:10` | **Sí.** `docs/arch/signals.md:206` dice que `seasoned` solo la emite `toggle_seasoning`; `docs/arch/signals.md:217` habla de quitar cachelos; `docs/arch/signals.md:53` dice `EXCLUSIVE_TAKEN` «solo con `paprika_swap`» | aceptar con cambios: actualizar esas tres filas a D25 y D26 |
| G48 | `signals.md`, enmienda M3 | PUL-066 | `phase_changed`, secuencias, señales de quemado, `played` | Sí. `godot/autoload/event_bus.gd:16`, `godot/entities/stations/cooking_station.gd:29`, `godot/entities/stations/cooking_station.gd:31`, `godot/entities/stations/cooking_station.gd:33`, `godot/components/feedback_player.gd:13` | **Sí.** `docs/arch/signals.md:287` lista `deliver_error` + `SHAKE`, baja de D26 | aceptar con cambios: actualizar la fila |
| G49 | `signals.md`, enmienda D23 | PUL-093 | Sin señales nuevas; receptores del indicador de entrega y del ticket | Sí. `godot/entities/stations/order_stand.gd:77`, `godot/core/seasoning_rules.gd:8`, `godot/tests/unit/test_event_bus.gd:53` | **Sí, de estado.** `docs/arch/signals.md:10` dice «pendiente de la revisión del producer»; `docs/arch/ADR-003-arbol-escenas-composicion.md:249` dice aceptada | aceptar con cambios: actualizar el estado y resolver la pregunta 3 |
| G50 | `signals.md`, enmienda D25 | PUL-111 | Local `trashed`, `ALREADY_APPLIED`, `PhaseData.orders` | Sí. `godot/entities/stations/trash_bin.gd:8`, `godot/core/seasoning_rules.gd:21`, `godot/resources/phase_data.gd:14` | Menor: `docs/arch/signals.md:251` dice `ALREADY_APPLIED` en silencio, y la nota D26 del mismo documento lo corrige | aceptar, junto con G51 |
| G51 | `signals.md`, enmienda D26 | PUL-120 | Dos señales en el bus, tipos, señales locales, `delivery_rejected` sin emisión en el juego | Sí. `godot/autoload/event_bus.gd:35`, `godot/autoload/event_bus.gd:37`, `godot/components/interaction_detector.gd:28`, `godot/components/interaction_component.gd:15`, `godot/entities/camera/camera_rig.gd:194`, `godot/autoload/order_service.gd:96` | Sin divergencia con la fila. La cadena de reenvío de `delivery_rejected` sigue viva (P3 del gate, conservada a propósito) | aceptar |
| G52 | `scene-tree.md`, estado «propuesto» | PUL-003 | El árbol como contrato | Sí en lo esencial: `godot/scenes/levels/level_01.tscn:32`, `godot/scenes/levels/level_01.tscn:36`, `godot/scenes/levels/level_01.tscn:128` | **Sí.** `docs/arch/scene-tree.md:38` dice «Dimensión pendiente»; `docs/arch/scene-tree.md:423` dice energía 1,34 y son 1,18 (`godot/entities/environment/environment.tscn:32`, `godot/tests/integration/test_level_01.gd:662`, PUL-183); `docs/arch/scene-tree.md:284` mantiene el puesto en `interactable` (lo corrige §9.2) | aceptar con cambios: corregir esas líneas y el título («objetivo de M0») |
| G53 | `scene-tree.md`, enmienda PUL-056 | PUL-056 | Estación de condimentos y planta B: §2, §3, §5, §6, §7 | Sí. `godot/entities/stations/seasoning_station.tscn:19`, `godot/entities/stations/seasoning_station.tscn:41`, `godot/entities/stations/seasoning_station.tscn:47`, `godot/entities/stations/seasoning_station.tscn:53`, `godot/entities/stations/slot.gd:17` | **Sí.** `docs/arch/scene-tree.md:334` conecta `rejected` a `season_error`; `docs/arch/scene-tree.md:350` mantiene `%ErrorAudio`; `docs/arch/scene-tree.md:356` describe el `is_reachable_from` de M3c, y `godot/entities/stations/seasoning_dispenser.gd:42` ignora la mano | aceptar con cambios: redibujar el árbol de la estación tal como está |
| G54 | `scene-tree.md`, enmienda M3 | PUL-066 | `AudioDirector`, `LevelAudio`, `%Feedback`, datos de audio, fases y quemado, §8 buses | Sí. `godot/project.godot:20`, `godot/entities/environment/level_audio.tscn:21`, `godot/entities/environment/level_audio.gd:10`, `godot/autoload/audio_director.gd:51`, `godot/data/config/round_config.tres:15`, `godot/data/config/round_config.tres:22`, `godot/data/config/round_config.tres:29` | **Sí.** `docs/arch/scene-tree.md:489` dice `max_time 90 / 70 / 50`; los datos son multiplicadores 1,0 / 0,85 / 0,7 (ADR-006 §6) | aceptar con cambios: corregir la línea |
| G55 | `scene-tree.md`, enmienda D23 | PUL-093 | Estación sin `Tray`, 6 `PassSlot`, hueco, indicador de entrega, `BoxData`, `StandPalette` | Sí. `godot/scenes/levels/level_01.tscn:50`, `godot/scenes/levels/level_01.tscn:65`, `godot/entities/environment/kitchen_layout.tscn:90`, `godot/entities/environment/kitchen_layout.tscn:109`, `godot/entities/environment/kitchen_layout.tscn:127`, `godot/entities/stations/order_stand.gd:77`, `godot/entities/stations/order_stand.gd:28` | **Sí, de estado.** Igual que G49. `Bulbs` y `Vignette` siguen en el árbol, pero apagados por D28 (`godot/entities/environment/environment.tscn:43`, `godot/entities/environment/environment.tscn:87`) y el texto no lo dice | aceptar con cambios: actualizar el estado y anotar el apagado por D28 |
| G56 | `scene-tree.md`, recogida de PUL-073 | PUL-073 | `Bulbs` y `Vignette`, «pendiente del QA de M3b» | Los nodos existen: `godot/entities/environment/environment.tscn:42`, `godot/entities/environment/environment.tscn:85` | **Sí, de estado.** `docs/arch/scene-tree.md:14` sigue pendiente, pero PUL-073 está `done` y el roadmap da M3b por cerrado en lo técnico (`docs/design/roadmap.md:13`) | aceptar con cambios: quitar «pendiente del QA» |
| G57 | `scene-tree.md`, enmienda D25 | PUL-111 | Caja única, rack, estación con 2 dispensadores, cubos, ticket sin talla, datos, bajas | Sí. `godot/entities/stations/box_shelf.tscn:24`, `godot/entities/stations/trash_bin.tscn:13`, `godot/scenes/levels/level_01.tscn:89`, `godot/scenes/levels/level_01.tscn:92`, `godot/data/boxes/box.tres:9`, `godot/data/config/trash_bin.tres:7` | **Sí.** `docs/arch/scene-tree.md:104` dice que `ItemSpawner.can_interact` es `true` con la mano llena, y ya es honesto (`godot/entities/stations/item_spawner.gd:16`); `docs/arch/scene-tree.md:108` atribuye la regla a `test_level_01.gd` (G13) | aceptar con cambios: corregir las dos líneas |
| G58 | `scene-tree.md`, enmienda D26 (§9) | PUL-120 | Prompt, aros, táctil, cámara móvil, datos D26 | Sí. `godot/entities/player/player.tscn:229`, `godot/entities/items/box.tscn:95`, `godot/entities/stations/kitchen.tscn:133`, `godot/ui/touch/touch_controls.tscn:23`, `godot/entities/camera/camera_rig.tscn:13` | **Sí.** `docs/arch/scene-tree.md:163` dice «con pantalla táctil» y manda el perfil (`godot/ui/touch/touch_controls.gd:23`, y ADR-004 §6 descarta ese criterio); `docs/arch/scene-tree.md:627` da de baja `REFERENCE_HEIGHT_PX`, que sigue en `godot/ui/widgets/ui_scale.gd:7` y se usa en `godot/ui/tickets/order_tickets_panel.gd:81` | aceptar con cambios: corregir las dos líneas |

## Propuesta sobre T3

`docs/design/decisions.md:43` dice: «`godot/` en este repo; Unity (`Assets/`) queda como especificación
hasta la paridad». `docs/design/decisions.md:23` (D17) renuncia a la paridad más allá de M0, y desde M1
`Assets/` es solo referencia.

**Propuesta:** marcar T3 como «Superada por D17» en lo que dice de Unity. Lo de `godot/` en este repo
sigue vigente, así que el texto recomendado es: «`godot/` en este repo. *Superada por D17 en lo demás:
`Assets/` es solo referencia desde M1.*». No se ha cambiado `decisions.md`: lo decide el responsable.

## Apariciones de `grep -inE "propuest|pendiente"` en `docs/arch`

Se excluye este documento. `pendiente` también coincide dentro de «independiente».

| Aparición | Dónde queda |
|---|---|
| `docs/arch/ADR-001-gdscript-convenciones.md:96` | Fuera: «rutas propuestas» del inventario, no es una enmienda |
| `docs/arch/ADR-001-gdscript-convenciones.md:138` | Fuera: arreglo externo pendiente de publicar. ADR-001 Enmienda 1 está aprobada y la ficha cubre ADR-002 a ADR-006 |
| `docs/arch/ADR-002-eventbus-autoloads.md:3` | G01–G04 |
| `docs/arch/ADR-002-eventbus-autoloads.md:4` | G05, G06 |
| `docs/arch/ADR-002-eventbus-autoloads.md:164` | Fuera: «independiente» |
| `docs/arch/ADR-002-eventbus-autoloads.md:206` | G01–G04 |
| `docs/arch/ADR-002-eventbus-autoloads.md:232` | G05, G06 |
| `docs/arch/ADR-003-arbol-escenas-composicion.md:3` | G07–G10 |
| `docs/arch/ADR-003-arbol-escenas-composicion.md:8` | G11–G15 |
| `docs/arch/ADR-003-arbol-escenas-composicion.md:10` | G16–G24 |
| `docs/arch/ADR-003-arbol-escenas-composicion.md:15` | Fuera: referencia caducada a «D14 pendiente»; D14 está cerrada. Conviene corregirla al aceptar |
| `docs/arch/ADR-003-arbol-escenas-composicion.md:153` | G07–G10 |
| `docs/arch/ADR-003-arbol-escenas-composicion.md:397` | G11–G15 |
| `docs/arch/ADR-003-arbol-escenas-composicion.md:603` | G16–G24 |
| `docs/arch/ADR-003-arbol-escenas-composicion.md:913` | Fuera: alternativa descartada («propuesta del diseño») |
| `docs/arch/ADR-003-arbol-escenas-composicion.md:942` | Fuera: alternativa descartada, redactada antes de D14 |
| `docs/arch/ADR-004-input-coop-local.md:4` | G25–G29 |
| `docs/arch/ADR-004-input-coop-local.md:32` | Fuera: contexto caducado sobre D14. Conviene corregirlo al aceptar |
| `docs/arch/ADR-004-input-coop-local.md:139` | Fuera: «independiente» |
| `docs/arch/ADR-004-input-coop-local.md:153` | G25–G29 |
| `docs/arch/ADR-005-dimension-3d-2d.md:4` | G30–G35 |
| `docs/arch/ADR-005-dimension-3d-2d.md:5` | G30–G39 |
| `docs/arch/ADR-005-dimension-3d-2d.md:6` | G36–G39 |
| `docs/arch/ADR-005-dimension-3d-2d.md:14` | Fuera: contexto histórico, anterior a la decisión del propio ADR |
| `docs/arch/ADR-005-dimension-3d-2d.md:88` | Fuera: recomendación histórica; la decisión aceptada está en `docs/arch/ADR-005-dimension-3d-2d.md:108` |
| `docs/arch/ADR-005-dimension-3d-2d.md:119` | Fuera: consecuencia escrita antes de decidir D14 |
| `docs/arch/ADR-005-dimension-3d-2d.md:124` | G30–G35 |
| `docs/arch/ADR-005-dimension-3d-2d.md:326` | G36–G39 |
| `docs/arch/ADR-006-audio-feedback.md:4` | G40–G42 |
| `docs/arch/ADR-006-audio-feedback.md:6` | G43, G44 |
| `docs/arch/ADR-006-audio-feedback.md:168` | Fuera: nombre de cue «propuesto por el diseño» |
| `docs/arch/ADR-006-audio-feedback.md:244` | Fuera: «independiente» |
| `docs/arch/README.md:6` | Fuera: «independiente» |
| `docs/arch/README.md:11` | G01–G06 |
| `docs/arch/README.md:12` | G07–G24 |
| `docs/arch/README.md:13` | G25–G29 |
| `docs/arch/README.md:14` | G30–G39 |
| `docs/arch/README.md:15` | G40–G44 |
| `docs/arch/README.md:16` | G46–G51 |
| `docs/arch/README.md:17` | G52–G58 |
| `docs/arch/README.md:19` | Fuera: enlace a este documento |
| `docs/arch/README.md:22` | Fuera: definición del ciclo |
| `docs/arch/scene-tree.md:3` | G52 |
| `docs/arch/scene-tree.md:5` | G53 |
| `docs/arch/scene-tree.md:7` | G54 |
| `docs/arch/scene-tree.md:10` | G55 |
| `docs/arch/scene-tree.md:14` | G56 |
| `docs/arch/scene-tree.md:21` | G57 |
| `docs/arch/scene-tree.md:27` | G58 |
| `docs/arch/scene-tree.md:38` | G52 |
| `docs/arch/scene-tree.md:639` | G58 |
| `docs/arch/scene-tree.md:707` | Fuera: pictogramas pendientes de assets, tarea de arte y no de contrato |
| `docs/arch/signals.md:3` | G46 |
| `docs/arch/signals.md:5` | G47 |
| `docs/arch/signals.md:6` | G48 |
| `docs/arch/signals.md:10` | G49 |
| `docs/arch/signals.md:15` | G50 |
| `docs/arch/signals.md:21` | G51 |
| `docs/arch/signals.md:39` | Fuera: «independientes» |
| `docs/arch/signals.md:299` | G45 |

## Qué no se ha comprobado

- Medidas de px, rendimiento y playtest (tabla de D27.3, px/m de E5, valor provisional de `presses_to_fill`):
  se citan los tests que las cubren o quedan señaladas en su fila, pero no se han vuelto a medir.
- Comportamiento en teléfono real: el código y los tests corren en escritorio con perfil simulado.
- Cada fila se comprobó leyendo el código y con `grep`, no ejecutando cada comportamiento por separado.
  La suite completa pasó en esta rama (1378 de 1378 tests, `docs/evidence/PUL-196/verify-completo.txt`),
  así que los tests citados están en verde; eso prueba lo que esos tests comprueban, no cada frase de la
  fila.
