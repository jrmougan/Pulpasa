# Mando Xbox y reasignación (Must)

**Slug:** mando-y-reasignacion · **Original:** «Compatibilidade de controis».

## Descripción
Soporte de mando Xbox además de teclado y ratón; el jugador 2 puede usar mando o teclado.

## Criterios de aceptación
- **AC1** Given un mando conectado antes de iniciar, When arranca la partida, Then se asigna al jugador libre y controla movimiento (stick, zona muerta 0,2), interactuar y cortar.
- **AC2** Given un mando en uso en partida, When se desconecta, Then se pausa la partida y se muestra aviso en ≤ 0,5 s.
- **AC3** Given 2 mandos conectados, When ambos jugadores mueven el stick a la vez, Then cada uno controla a un jugador distinto y ninguno controla a ambos.
- **AC5** Given solo mandos conectados, When se recorre menú → partida → game over → reintentar, Then no hace falta teclado en ningún punto.
- **AC4** Given el `InputMap` cargado, When un test recorre todas las acciones de juego, Then existe binding de teclado y de mando (verificado por test sobre `InputMap`).

- **AC6 (D26, táctil)** Given el perfil táctil (`controles-tactiles.md`), When se activan el stick virtual, el botón de acción, el de cambiar y el de pausa, Then se producen las mismas acciones de entrada que teclado/mando del jugador 1 (movimiento analógico con zona muerta 0,2, interactuar, cambiar, pausa) y el recorrido menú → partida → game over → reintentar se completa **solo con toque**. *Test:* `test_touch_input.gd`.
- **AC7 (D26, coexistencia)** Given un mando conectado en el perfil táctil, When llega un evento del mando, Then los controles táctiles se ocultan y el mando funciona como en AC1; When llega un toque, Then reaparecen. *Test:* `test_touch_input.gd`.

*Local 2P con dos mandos o teclado + mando sigue siendo solo de PC (D26): el perfil táctil no ofrece Local 2P.*

## Datos
`InputMap` en `project.godot`; zona muerta en datos (mando 0,2; stick táctil `stick_deadzone` 0,2 en `TouchProfileData`).

## Notas de alcance (Must)
Es parte del Must «Coop local 2P y mando Xbox»: debe poder completarse el flujo menú → partida →
game over solo con mando (ver `menu-principal.md` AC4).
