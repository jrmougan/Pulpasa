# Coop local 2P, modo individual y cambio de personaje (Must, D3)

**Slug:** jugadores-y-cambio · **Prototipo:** `PlayerController`, `PlayerInput` (Input System).

## Descripción
- **Cooperativo local**: 2 jugadores, cada uno con su personaje y esquema de entrada propio.
- **Modo individual**: 1 jugador controla un personaje; al pulsar «cambiar» pasa al otro. El no
  controlado se queda quieto, conserva lo que lleva y su acción en curso (corte) se pausa.

## Criterios de aceptación
- **AC1** Given una partida con 2 jugadores, When J1 pulsa mover y J2 no, Then solo se mueve el personaje 1.
- **AC2** Given el modo individual, When se pulsa «cambiar», Then el control pasa al otro personaje en < 0,2 s (200 ms medidos entre la pulsación y el primer movimiento posible) y se emite `character_switched` una vez.
- **AC3** Given el personaje no controlado, Then su velocidad es 0 y sigue en su posición durante 5 s.
- **AC4** Given el personaje no controlado con un objeto en la mano, When se cambia, Then conserva el objeto.
- **AC5** Given el personaje activo, Then está marcado con un indicador visible (aro/color) distinto del inactivo. *(Precisado por D26, AC5' y AC9.)*
- **AC5' (D26, activo legible)** Given Individual con dos personajes, Then el activo muestra un anillo de suelo **sólido de ≥ 8 px de grosor** (a 1080 de alto) y un marcador ▼ de ≥ 24 px sobre la cabeza; el inactivo, un anillo **discontinuo gris de ≤ 3 px** sin marcador; en escala de grises el contraste entre ambos anillos es ≥ 3:1; el color del anillo del jugador no es amarillo (choca con el gorro de P2 y con el ámbar de BLOQUEADO). Hoy ambos llevan anillo azul. *Test:* `test_player_ring.gd` + captura.
- **AC9 (D26, cue de cambio)** Given Individual, When se pulsa cambiar, Then suena 1 cue `character_switch` (sample propio, hoy el cambio no suena) y el anillo del nuevo activo se anima ≥ 0,3 s; el cambio sigue en < 0,2 s (AC2). *Test:* `test_player_switch.gd` + `test_feedback_cues.gd`.
- **AC10 (D26, móvil)** Given el perfil táctil, Then la partida solo se arranca en modo Individual (Local 2P es de PC/mando; `menu-principal.md` AC6); el botón de cambiar de `controles-tactiles.md` hace lo mismo que `p1_switch`, con la cámara siguiendo al nuevo activo en 0,35 s. *Test:* `test_main_menu_touch.gd` + `test_camera_follow.gd`.
- **AC11 (D26, Local 2P)** Given Local 2P, Then cada jugador tiene su propio prompt de acción con marcador de jugador (`lenguaje-acciones.md` AC21) y su propio objetivo activo con histéresis. *Test:* `test_action_prompt.gd`.
- **AC6** Given el modo individual con 2 personajes, When se cambia 10 veces seguidas en 2 s, Then no hay errores en consola y siempre hay exactamente 1 personaje activo.
- **AC8** Given teclado + mando (o dos mandos), When la partida arranca desde el menú en modo Local 2P, Then cada dispositivo controla a un solo jugador (ver `mando-y-reasignacion.md`).
- **AC7** Given el modo de 2 jugadores, When un jugador entrega una caja, Then la recaudación es compartida (un solo contador).

## Datos (`.tres`)
Esquemas de entrada en `InputMap` (J1: WASD+E+Q; J2: flechas+Intro+Mayús; indicativo), `switch_cooldown` (0,2 s).

## Verificación
GUT para AC2–AC4, AC6–AC7 y AC9–AC11; captura para AC5 y AC5'.
