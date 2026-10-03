# Mando Xbox y reasignación (Should)

**Slug:** mando-y-reasignacion · **Original:** «Compatibilidade de controis».

## Descripción
Soporte de mando Xbox además de teclado y ratón; el jugador 2 puede usar mando o teclado.

## Criterios de aceptación
- **AC1** Given un mando conectado antes de iniciar, Then se asigna al jugador libre y controla movimiento (stick, zona muerta 0,2), interactuar y cortar.
- **AC2** Given un mando desconectado en partida, Then se pausa la partida y se muestra aviso en ≤ 0,5 s.
- **AC3** Given 2 mandos, Then cada uno controla a un jugador distinto y ninguno controla a ambos.
- **AC4** Given una acción del mapa, Then existe binding de teclado y de mando (verificado por test sobre `InputMap`).

## Datos
`InputMap` en `project.godot`; zona muerta en datos.
