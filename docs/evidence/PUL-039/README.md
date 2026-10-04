# PUL-039 — Evidencia: no se logra entregar en level_01

## Reproducción

1. **MCP (`run_project` sobre `level_01.tscn`, teclas reales WASD/E con `simulate_input`).**
   Con una caja correcta en la mano, el detector elige el puesto y la entrega funciona:
   - entrando en `%DeliveryZone` del puesto 4: 0 € → 18 €;
   - pulsando E delante del puesto 1: 0 € → 8 € (`ac2-01-…`, `ac2-02-…`).
   La caja de la evidencia AC2 se montó con `run_script` (llenado y condimentos de la comanda);
   el recorrido y la entrega son con teclado. La preparación completa con teclado está en el test e2e.
2. **`tests/integration/test_delivery_e2e.gd`** (headless, `level_01` real, `GameState.start_level`):
   prepara la caja solo con teclas simuladas y el detector real (estantería de cajas → nevera →
   olla → cortes → condimentos de la estantería o cachelos cocidos → puesto). Con la paciencia
   real del catálogo **falla de forma intermitente**: la caja es correcta
   (`OrderValidator.matches` = true contra la comanda elegida) pero el puesto la rechaza
   (`delivery_rejected`), porque la comanda caducó mientras se preparaba y el puesto ya tiene
   otra con otra receta.

## Causa raíz

No falla ni el detector, ni la física, ni la zona, ni la validación. Falla el **tiempo**:

| Comanda (receta) | `max_time` | Preparación con teclado, ruta óptima de bot |
|---|---|---|
| order_2 (individual, pimentón + sal) | 40 s | ~54 s → **caduca siempre** |
| order_6 (individual, aceite + cachelos) | 50 s | ~33 s |
| order_1 (familiar, picante + sal) | 60 s | ~50 s |
| order_5 / order_4 / order_3 | 70 / 75 / 90 s | — |

- Las 4 comandas iniciales salen a la vez (tras `first_order_delay` = 5 s) con su reloj en marcha.
  Un jugador humano (aprendiendo dónde está cada cosa) tarda bastante más que la ruta del bot:
  **todas caducan antes de la primera entrega** (`ac1-02-…`: la #2 caduca a los 40 s y la
  sustituye la #5 en el mismo puesto, recaudación 0 €).
- Al reponerse, el puesto pide otra receta: la caja preparada para la comanda anterior se
  rechaza con penalización (D8). Si se entra en la zona y además se pulsa E, se penaliza dos
  veces (un intento por entrada y otro por pulsación).

Hallazgos secundarios (no bloquean, empeoran la experiencia):
- Cruzar la `%DeliveryZone` de un puesto vecino con la caja la intenta entregar ahí:
  rechazo y penalización.
- El puesto no tiene `Highlightable`: no se ve a qué puesto apunta E.
- E alcanza el puesto desde ~2,0–2,2 m (radio del detector 2,2 m) y la zona empieza a ~2,0 m:
  casi no hay sitio para entregar con E sin pisar antes la zona.

## Capturas

- `ac1-01-comandas-iniciales.png`: las 4 comandas al empezar.
- `ac1-02-comanda-2-caduca-a-los-40s.png`: la #2 (40 s) caduca y el puesto 2 pasa a la #5; 0 €.
- `ac2-01-antes-caja-correcta-ante-puesto-1.png`: P1 con la caja de la #1 delante del puesto 1, 0 €.
- `ac2-02-despues-E-entrega-8eur.png`: tras pulsar E, la #1 se completa (puesto 1 → #6), 8 €.
