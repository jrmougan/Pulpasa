# Eventos de entorno: gaiteros (Could)

**Slug:** eventos-de-entorno · **Original:** «Eventos de entorno» (grupo de gaiteiros).

## Descripción
Cada `event_interval` un grupo de gaiteros cruza la zona de preparación durante `event_duration`
y bloquea el paso (caos cooperativo). Sin daño, solo obstáculo.

## Criterios de aceptación
- **AC1** Given una partida a 90 s (`first_event_time`, dato), Then aparece el primer grupo de gaiteros y se emite `environment_event_started`.
- **AC2** Given el evento activo, Then dura 6 s y se emite `environment_event_ended` una vez.
- **AC3** Given un personaje en la trayectoria, When el grupo pasa, Then el personaje no se atraviesa ni queda atrapado (puede salir en ≤ 1 s).
- **AC4** Given una partida de 300 s, Then ocurren como máximo 2 eventos.
- **AC5** Given la pausa, Then el grupo se detiene.

## Datos (`.tres`)
`first_event_time` (90 s), `event_interval` (90 s), `event_duration` (6 s).
