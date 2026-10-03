# Dificultad progresiva (Should, dificultad por fases)

**Slug:** dificultad-progresiva · **Original:** mecánica «Variación de dificultad».

## Descripción
La partida se divide en **fases** definidas en datos. Cada fase fija cuántos puestos de entrega están
activos y el `max_time` de las comandas. La reposición inmediata tras cada entrega se mantiene
(`comandas.md`); la dificultad sube al pasar de fase. Valores provisionales (GDD §11, pregunta 5).

| Fase | Desde | Hasta | Puestos activos | `max_time` |
|------|-------|-------|-----------------|------------|
| 1 | 0 s | 100 s | 2 | 90 s |
| 2 | 100 s | 200 s | 3 | 70 s |
| 3 | 200 s | 300 s | 4 | 50 s |

## Criterios de aceptación
- **AC1** Given el inicio de partida, Then la fase es 1, hay 2 puestos con comanda y las comandas nuevas tienen `max_time` 90 s.
- **AC2** Given la partida a 100 s, When cambia el reloj de 99,9 a 100,0 s, Then la fase pasa a 2, se emite `phase_changed` una vez y en ≤ 1 s hay 3 puestos con comanda.
- **AC3** Given la partida a 200 s, When cambia de fase, Then hay 4 puestos activos y nunca más de `max_active_orders` = 4.
- **AC4** Given un cambio de fase, Then las comandas ya activas conservan su `max_time` original.
- **AC5** Given dos partidas con la misma semilla, Then la secuencia de comandas generadas es idéntica.
- **AC6** Given `match_duration` distinto de 300 s, Then los límites de fase se escalan proporcionalmente (fase = tercio de la partida).

## Datos (`.tres`)
Lista de fases (inicio como fracción de `match_duration`, puestos activos, `max_time`).
