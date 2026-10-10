---
id: PUL-116
title: Re-medir R15/R17 tras D25 y preparar el playtest de M3d
status: in_progress
milestone: M3d
role: qa-tester
deps: [PUL-115]
orca_task: null
unity_sources: []
owns: [docs/evidence/PUL-116/**, docs/design/m3d-gate.md, godot/tests/tools/**, docs/backlog/PUL-116-qa-d25.md]
touches_scenes: []
---

## Target
Rehacer las mediciones del bot de PUL-102 (`docs/evidence/PUL-102/`) con la caja única de 6 cortes, el aliño de una pulsación y el cubo: R15 (Individual sin cambio, pedido desde cero ≤ 50 m), R17 (Coop, media de pedidos 2–4 ≤ 4,6 s), pulsaciones por comanda, recuperación con el cubo (T7 de `cubo-basura.md`) y umbrales de estrellas 30/60/90 € con los precios nuevos.

## Change
Tabla antes (PUL-102) / después en `docs/evidence/PUL-116/README.md`, capturas, y guía de playtest `docs/design/m3d-gate.md` (25 min, qué mirar y qué decidir: aliño, caja única, cubos, fases, precios, largo del mostrador).

## Acceptance
- [x] AC1 Tabla de R15, R17, pulsaciones y recuperación con cubo
- [x] AC2 Propuesta de umbrales de estrellas si cambian
- [x] AC3 `docs/design/m3d-gate.md`
- [ ] AC4 `tools/verify.sh` en verde

## Plan
1. Copiar y adaptar el bot de PUL-102 a `docs/evidence/PUL-116/` (caja única de 6 cortes, aliño de una
   pulsación, 4 comandas reales, cubos) sin tocar `level_walker.gd` ni `test_level_01_r16.gd` (PUL-118).
2. Medir con el bot: Individual y Coop con las 4 comandas, R15 con 4 sitios para la caja, R17 secuencial
   y adelantado (oeste y este), recuperación T7 (cubo y aliño), 4 partidas completas con fases reales.
3. Capturas a 1920×1080 con el MCP (Local 2P y estación) y recortes del mostrador y del rack.
4. README con tabla antes/después, `docs/design/m3d-gate.md` y `tools/verify.sh`.

## Evidence
Todo en `docs/evidence/PUL-116/` (README.md con tablas, JSON y 4 capturas). Guía: `docs/design/m3d-gate.md`.

| AC | Resultado | Evidencia |
|---|---|---|
| AC1 R15 (≤ 50 m) | **no cumple con el bot**: 54,7 m (45,3 sin la salida inicial), antes 55,0 / 45,3 | README «R15», `metrics_solo_*.json` |
| AC1 R17 (media 2–4 ≤ 4,6 s) | cumple con flujo adelantado y oeste: **3,05 s** (antes 4,09); este 5,27 s y secuencial 6,17 s no | README «R17», `metrics_chain_*.json` |
| AC1 pulsaciones | Á feira y Picante 14 / 11; con cachelos 19 / 12 | README «Pulsaciones por comanda» |
| AC1 recuperación T7 (≤ 15 s) | 13,23 s puesto 1 (cumple); 16,78 s puesto 4 (no); con el otro aliño 1,3 s | README «T7», `metrics_recover.json` |
| AC2 umbrales | propuesta 40 / 90 / 150 € (hoy 30 / 60 / 90 €; el bot secuencial saca 150–195 €); sin cambiar datos | README «Umbrales», `metrics_round_*.json` |
| AC3 guía | `docs/design/m3d-gate.md` | fichero |
| AC4 `tools/verify.sh` | verde (ver abajo) | salida del verify |

Comprobado por el bot y por capturas; **no comprobado**: juego humano, Coop de 300 s, Individual con
cambio, recuperación sin pulpo sobrante. Hallazgos sin arreglar (ninguno bloquea; no hay bug del juego):
modelo del rack con S/M/L, los dos aliños comparten icono, mostrador de 5,2 m con 3 objetivos en 2 m,
panel de 4 tickets sobre el cartel, HUD «Cajas / minuto».

`tools/verify.sh`: 1.ª pasada en rojo por `test_level_01_r16` (el intermitente de PUL-118, `order_completed`
1 en vez de 2; sin relación con esta ficha, que no toca código del juego); 2.ª pasada **verde**
(gdformat, gdlint, import, GUT 73 scripts / 828 tests, smoke).
