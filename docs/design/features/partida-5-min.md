# Partida de 5 minutos y flujo de pantallas (Must, D5)

**Slug:** partida-5-min · **Prototipo:** `ProductivitySystem`, `MainMenu`, `PauseManager`, `PauseMenuController`, `GameOverUI`, `Bootstrap`.

## Descripción
Menú principal → partida de `match_duration` = 300 s (dato) → pantalla de resultados
(recaudación, estrellas) → reintentar o menú. Pausa durante la partida.

## Criterios de aceptación
- **AC1** Given el menú principal, When se elige «Individual» o «Local 2P» (parametrizado por modo), Then se carga el nivel en ≤ 3 s y el cronómetro arranca en 300 s en ambos casos.
- **AC2** Given una partida a 0 s, When se cumple el tiempo, Then se emite `match_finished` una vez, las acciones de los jugadores se bloquean y se muestra la pantalla de resultados con recaudación y estrellas.
- **AC3** Given una partida en curso, When se pulsa «Pausa», Then el cronómetro, las comandas y la cocción se detienen (delta de reloj = 0 durante 5 s de pausa) y se muestra el menú de pausa.
- **AC4** Given la pausa, When se pulsa «Reanudar», Then todo continúa desde donde estaba (±0,05 s).
- **AC5** Given la pantalla de resultados, When se pulsa «Reintentar», Then la partida empieza con recaudación 0, 0 comandas activas, olla libre y reloj en 300 s.
- **AC6** Given `match_duration` = 60 en datos, When se juega, Then la partida dura 60 s sin cambiar código.

## Datos (`.tres`)
`match_duration` (300 s).

## Verificación
GUT para AC2, AC3 (reloj), AC5, AC6; smoke con MCP y captura para AC1, AC4.
