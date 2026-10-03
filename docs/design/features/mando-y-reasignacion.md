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

## Datos
`InputMap` en `project.godot`; zona muerta en datos.

## Notas de alcance (Must)
Es parte del Must «Coop local 2P y mando Xbox»: debe poder completarse el flujo menú → partida →
game over solo con mando (ver `menu-principal.md` AC4).
