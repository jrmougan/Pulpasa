# PUL-197 AC1: las 58 filas del gate

Las líneas son las de esta rama. Fuera de las 58 filas: T3 en `docs/design/decisions.md:43`, y el índice y la resolución en `docs/arch/README.md:19` y `docs/arch/gate-enmiendas.md:3`.

| Fila | Estado | Qué se hizo | Dónde consta |
|---|---|---|---|
| G01 | aplicada | Estado aceptada | `docs/arch/ADR-002-eventbus-autoloads.md:206` |
| G02 | aplicada | Estado aceptada | `docs/arch/ADR-002-eventbus-autoloads.md:206` |
| G03 | aplicada | Estado aceptada; método sustituido por el de ADR-006 §6 | `docs/arch/ADR-002-eventbus-autoloads.md:206`, `docs/arch/ADR-002-eventbus-autoloads.md:225` |
| G04 | aplicada | Estado aceptada | `docs/arch/ADR-002-eventbus-autoloads.md:206` |
| G05 | aplicada | Estado aceptada; la excepción de sandbox no afecta al juego | `docs/arch/ADR-002-eventbus-autoloads.md:232` |
| G06 | aplicada | Estado aceptada | `docs/arch/ADR-002-eventbus-autoloads.md:232` |
| G07 | aplicada | Estado aceptada; filas de dispensador, cuenco y `Tray` marcadas como sustituidas | `docs/arch/ADR-003-arbol-escenas-composicion.md:155`, `docs/arch/ADR-003-arbol-escenas-composicion.md:184` |
| G08 | pendiente: cinco frases de §8.2 son falsas desde D26 y la fila no prevé corregirlas: `interact_pressed()` suelta si el objetivo no consume (`godot/components/interaction_component.gd:79`); dispensador solo con la mano vacía, e `is_reachable_from` falso con algo en la mano (`godot/core/action_rules.gd:88`, `godot/entities/stations/seasoning_dispenser.gd:42`); cuenco siempre con `actor.holder` (`godot/entities/stations/cachelos_bowl.gd:67`, `godot/core/action_rules.gd:110`); `Slot.accepted_group` consume (`godot/entities/stations/slot.gd:118`, `godot/tests/integration/test_slot.gd:248`); la caja guardada consume con la mano llena (`godot/core/action_rules.gd:42`) | Sí aplicado: `%ErrorAudio` y antirrebote marcados como sustituidos; conservado que dispensador y cuenco devuelven `true` al rechazar | `docs/arch/ADR-003-arbol-escenas-composicion.md:227`, `docs/arch/ADR-003-arbol-escenas-composicion.md:219`, `docs/arch/scene-tree.md:284` |
| G09 | aplicada | `apply_seasoning` como API vigente; `toggle_seasoning` y `get_box` como baja | `docs/arch/ADR-003-arbol-escenas-composicion.md:248`, `docs/arch/ADR-003-arbol-escenas-composicion.md:253` |
| G10 | aplicada | Bandeja quitada de la línea | `docs/arch/ADR-003-arbol-escenas-composicion.md:262` |
| G11 | aplicada | `counter_full_time` añadido; 6 deja de ser provisional | `docs/arch/ADR-003-arbol-escenas-composicion.md:432`, `docs/arch/ADR-003-arbol-escenas-composicion.md:433`, `docs/arch/scene-tree.md:510`, `docs/design/decisions.md:29` |
| G12 | aplicada | Junto con G22; nota D26 añadida bajo los motivos de §10.2 | `docs/arch/ADR-003-arbol-escenas-composicion.md:418`, `docs/arch/ADR-003-arbol-escenas-composicion.md:517` |
| G13 | pendiente: citar `test_trash_bin.gd` también sería falso para los puestos: el test recorre el grupo `interactable` (`godot/tests/integration/test_trash_bin.gd:294`) y `OrderStand` salió de él por D26 (`godot/entities/stations/order_stand.tscn:33`); ningún test comprueba esa distancia y la fila no prevé la corrección | El resto de §10.3 y de la regla de colocación consta aceptado | `docs/arch/ADR-003-arbol-escenas-composicion.md:572` |
| G14 | aplicada | Estado aceptada | `docs/arch/ADR-003-arbol-escenas-composicion.md:418` |
| G15 | aplicada | `rejected` con `BOX_NOT_FULL` y `ALREADY_APPLIED` | `docs/arch/ADR-003-arbol-escenas-composicion.md:614` |
| G16 | aplicada | Excepción ampliada | `docs/arch/ADR-003-arbol-escenas-composicion.md:672` |
| G17 | aplicada | Estado aceptada | `docs/arch/ADR-003-arbol-escenas-composicion.md:634` |
| G18 | aplicada | Estado aceptada | `docs/arch/ADR-003-arbol-escenas-composicion.md:634` |
| G19 | aplicada | «Un cue por efecto» y paso 1 con `hint_of` y `_floor_hint()`; también el título de la tabla de ADR-006 §4.1 y la secuencia de `signals.md` §3 | `docs/arch/ADR-003-arbol-escenas-composicion.md:764`, `docs/arch/ADR-003-arbol-escenas-composicion.md:746`, `docs/arch/ADR-006-audio-feedback.md:186`, `docs/arch/signals.md:173` |
| G20 | aplicada | `advance(delta)` desde `_process`; `int` en los tipos | `docs/arch/ADR-003-arbol-escenas-composicion.md:820`, `docs/arch/ADR-003-arbol-escenas-composicion.md:824` |
| G21 | aplicada | Estado aceptada | `docs/arch/ADR-003-arbol-escenas-composicion.md:634` |
| G22 | aplicada | Se conserva «sin emisión en el juego» con nota de que `order_stand.gd:156` lo incumple hasta PUL-198; no afirma que ya se cumpla | `docs/arch/ADR-003-arbol-escenas-composicion.md:879`, `docs/arch/ADR-003-arbol-escenas-composicion.md:1012` |
| G23 | aplicada | Indicador alineado con `scene-tree.md` §9.1; `Portions0..4` | `docs/arch/ADR-003-arbol-escenas-composicion.md:919`, `docs/arch/ADR-003-arbol-escenas-composicion.md:918` |
| G24 | aplicada | Estado aceptada | `docs/arch/ADR-003-arbol-escenas-composicion.md:634` |
| G25 | aplicada | Frase de lectura de la entrada reescrita, en conjunto y con la pausa en `_input` | `docs/arch/ADR-004-input-coop-local.md:164`, `docs/arch/ADR-004-input-coop-local.md:168` |
| G26 | aplicada | La lista de `TouchConfig` se declara mínima | `docs/arch/ADR-004-input-coop-local.md:227` |
| G27 | aplicada | Firma corregida | `docs/arch/ADR-004-input-coop-local.md:236` |
| G28 | aplicada | Estado aceptada | `docs/arch/ADR-004-input-coop-local.md:153` |
| G29 | aplicada | Caso de Atrás en el menú añadido | `docs/arch/ADR-004-input-coop-local.md:259` |
| G30 | aplicada | Estado aceptada | `docs/arch/ADR-005-dimension-3d-2d.md:123` |
| G31 | aplicada | Estado aceptada | `docs/arch/ADR-005-dimension-3d-2d.md:123` |
| G32 | aplicada | `menu_card_width` añadido, en unidades de lienzo como en el código | `docs/arch/ADR-005-dimension-3d-2d.md:167` |
| G33 | aplicada | `window_size` en la firma; «envuelven su contenido» | `docs/arch/ADR-005-dimension-3d-2d.md:194`, `docs/arch/ADR-005-dimension-3d-2d.md:196` |
| G34 | aplicada | Estado aceptada | `docs/arch/ADR-005-dimension-3d-2d.md:123` |
| G35 | aplicada | Estado aceptada | `docs/arch/ADR-005-dimension-3d-2d.md:123` |
| G36 | aplicada | Estado aceptada | `docs/arch/ADR-005-dimension-3d-2d.md:327` |
| G37 | aplicada | Estado aceptada; propone ficha aparte para `test_camera_follow.gd`, no creada | `docs/arch/ADR-005-dimension-3d-2d.md:327` |
| G38 | aplicada | Estado aceptada | `docs/arch/ADR-005-dimension-3d-2d.md:327` |
| G39 | aplicada | Estado aceptada | `docs/arch/ADR-005-dimension-3d-2d.md:327` |
| G40 | aplicada | Estado aceptada | `docs/arch/ADR-006-audio-feedback.md:5` |
| G41 | aplicada | Estado aceptada | `docs/arch/ADR-006-audio-feedback.md:5` |
| G42 | aplicada | Estado aceptada | `docs/arch/ADR-006-audio-feedback.md:5` |
| G43 | aplicada | Estado aceptada; solo la frase de `deliver_error` se marca histórica, porque el resto de ese párrafo sigue vigente | `docs/arch/ADR-006-audio-feedback.md:5`, `docs/arch/ADR-006-audio-feedback.md:206` |
| G44 | aplicada | Estado aceptada | `docs/arch/ADR-006-audio-feedback.md:5` |
| G45 | aplicada | Lectura aprobada y registrada; retirado «Pendiente de R2» | `docs/arch/signals.md:307`, `docs/design/features/audio-y-fx.md:11`, `docs/arch/ADR-006-audio-feedback.md:101` |
| G46 | aplicada | Estado aceptado; cinco receptores añadidos, `order_stand.gd` fuera de `delivery_rejected`, `hud.gd` como Could explícito, `camera_rig.gd` en la fila | `docs/arch/signals.md:3`, `docs/arch/signals.md:76`, `docs/arch/signals.md:97`, `docs/arch/signals.md:80`, `docs/arch/signals.md:89`, `docs/arch/signals.md:98` |
| G47 | aplicada | Cinco filas a D25 y D26; secuencia antigua histórica; secuencia del cuenco vigente | `docs/arch/signals.md:210`, `docs/arch/signals.md:218`, `docs/arch/signals.md:237`, `docs/arch/signals.md:256` |
| G48 | aplicada | Fila de AC5 actualizada | `docs/arch/signals.md:296` |
| G49 | aplicada | D23 ratificada por el responsable | `docs/arch/signals.md:11`, `docs/arch/ADR-003-arbol-escenas-composicion.md:6` |
| G50 | aplicada | Junto con G51; nota D26 inline en `Rejection` y en la secuencia del dispensador | `docs/arch/signals.md:16`, `docs/arch/signals.md:54`, `docs/arch/signals.md:253` |
| G51 | aplicada | Se conserva la frase con nota de PUL-198; no afirma que ya se cumpla | `docs/arch/signals.md:26`, `docs/arch/signals.md:89`, `docs/arch/scene-tree.md:614` |
| G52 | aplicada | Estado aceptado; título, dimensión, energía 1,18 y puesto en la capa `world` | `docs/arch/scene-tree.md:1`, `docs/arch/scene-tree.md:3`, `docs/arch/scene-tree.md:40`, `docs/arch/scene-tree.md:415`, `docs/arch/scene-tree.md:292` |
| G53 | aplicada | Árbol de la estación redibujado desde las escenas, con `Portions0..4`; tabla de objetivos actualizada | `docs/arch/scene-tree.md:331`, `docs/arch/scene-tree.md:385`, `docs/arch/scene-tree.md:396` |
| G54 | aplicada | Multiplicadores en lugar de `max_time` | `docs/arch/scene-tree.md:483` |
| G55 | aplicada | D23 ratificada; apagado por D28 anotado | `docs/arch/scene-tree.md:12`, `docs/arch/scene-tree.md:426` |
| G56 | aplicada | Quitado «pendiente del QA» | `docs/arch/scene-tree.md:16` |
| G57 | pendiente: la línea que atribuye la regla a `test_level_01.gd` es falsa y sustituirla por `test_trash_bin.gd` también lo sería para los puestos (ver G13); la fila no prevé esa corrección | Sí aplicado: spawner honesto, `toggle_seasoning` de baja y `rejected` del dispensador (en el árbol redibujado) | `docs/arch/scene-tree.md:113`, `docs/arch/scene-tree.md:106`, `docs/arch/scene-tree.md:246`, `docs/arch/scene-tree.md:362` |
| G58 | aplicada | Perfil en lugar de pantalla táctil; `REFERENCE_HEIGHT_PX` fuera de las bajas | `docs/arch/scene-tree.md:170`, `docs/arch/scene-tree.md:621` |

Recuento: 55 aplicadas, 3 pendientes.
