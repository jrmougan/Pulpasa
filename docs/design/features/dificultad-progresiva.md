# Dificultad progresiva (Should, dificultad por fases; D25)

**Slug:** dificultad-progresiva · **Original:** mecánica «Variación de dificultad».

## Descripción
La partida se divide en **fases** definidas en datos. Cada fase fija cuántos puestos de entrega están
activos, el `max_time` de las comandas y, desde D25, **qué mecánicas entran en juego** (qué recetas
se piden). La reposición inmediata tras cada entrega se mantiene (`comandas.md`); la dificultad sube al
pasar de fase. Valores provisionales (GDD §11, pregunta 5).

| Fase | Desde | Hasta | Puestos activos | Paciencia | Recetas posibles (D25) | Mecánica nueva |
|------|-------|-------|-----------------|-----------|------------------------|----------------|
| 1 | 0 s | 100 s | 2 | ×1,0 del `max_time` de la receta | Á feira | Solo aliño dulce, sin cachelos |
| 2 | 100 s | 200 s | 3 | ×0,85 | Á feira, Picante | Entra el aliño picante |
| 3 | 200 s | 300 s | 4 | ×0,7 | Á feira, Picante, Con cachelos, Bravo cachelos | Entran los cachelos (olla + cuenco) |

*Cambio del responsable (2026-10-06): multiplicador sobre la paciencia de la receta en lugar de 90/70/50 s fijos.*
*D25 (2026-10-10): la dificultad escala mecánicas además de puestos y paciencia.*

## Criterios de aceptación
- **AC1** Given el inicio de partida, Then la fase es 1, hay 2 puestos con comanda, las comandas nuevas tienen el `max_time` de su receta (×1,0) y todas son «Á feira».
- **AC2** Given la partida a 100 s, When cambia el reloj de 99,9 a 100,0 s, Then la fase pasa a 2, se emite `phase_changed` una vez y en ≤ 1 s hay 3 puestos con comanda.
- **AC3** Given la partida a 200 s, When cambia de fase, Then hay 4 puestos activos y nunca más de `max_active_orders` = 4.
- **AC4** Given un cambio de fase, Then las comandas ya activas conservan su `max_time` original (y su receta, aunque la fase nueva la excluyera).
- **AC5** Given dos partidas con la misma semilla, Then la secuencia de comandas generadas es idéntica.
- **AC6** Given `match_duration` distinto de 300 s, Then los límites de fase se escalan proporcionalmente (fase = tercio de la partida).
- **AC7 (D25)** Given 200 comandas generadas con semilla fija en la fase 1, Then el 100 % son «Á feira»; en la fase 2, el 100 % son «Á feira» o «Picante» y aparecen ambas; en la fase 3, aparecen las 4 recetas y ≥ 1 de cada una en 200 generaciones. Ninguna comanda con cachelos ni picante antes de su fase. *Test:* `test_phase_catalog.gd`.
- **AC8 (D25)** Given la fase 2 a 100,0 s, When se genera la primera comanda nueva, Then puede ser «Picante» y se emite `phase_changed`; Given la fase 3, Then «Con cachelos» y «Bravo cachelos» pueden salir desde el mismo instante del cambio (≤ 1 s). *Test:* `test_phase_catalog.gd`.
- **AC9 (D25)** Given `PhaseData`, Then cada fase declara en `PhaseData.orders` las comandas permitidas (la fase 1, «Á feira»; la 2, «Á feira» y «Picante»; la 3, las 4) en datos y cambiarla no exige código. *Test:* `test_data_phases.gd`.

## Datos (`.tres`)
Lista de fases (inicio como fracción de `match_duration`, puestos activos, `max_time` multiplicador y,
desde D25, `PhaseData.orders: Array[OrderData]`; vacía = todo el catálogo).

## Preguntas abiertas
1. **¿Se mantienen los tercios con 2 mecánicas nuevas?** Los límites 100/200 s son provisionales; si
   los cachelos entran tarde (200 s) quedan solo 100 s para disfrutarlos. Lo decide el playtest.
