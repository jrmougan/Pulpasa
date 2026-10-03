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
- **AC5** Given el personaje activo, Then está marcado con un indicador visible (aro/color) distinto del inactivo.
- **AC6** Given el modo individual con 2 personajes, When se cambia 10 veces seguidas en 2 s, Then no hay errores en consola y siempre hay exactamente 1 personaje activo.
- **AC8** Given teclado + mando (o dos mandos), When la partida arranca desde el menú en modo Local 2P, Then cada dispositivo controla a un solo jugador (ver `mando-y-reasignacion.md`).
- **AC7** Given el modo de 2 jugadores, When un jugador entrega una caja, Then la recaudación es compartida (un solo contador).

## Datos (`.tres`)
Esquemas de entrada en `InputMap` (J1: WASD+E+Q; J2: flechas+Intro+Mayús; indicativo), `switch_cooldown` (0,2 s).

## Verificación
GUT para AC2–AC4, AC6–AC7; captura para AC5.
