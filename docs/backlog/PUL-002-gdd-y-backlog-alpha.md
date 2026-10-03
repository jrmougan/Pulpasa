---
id: PUL-002
title: Escribir el GDD de trabajo y el backlog de la alpha
status: review
milestone: F0
role: game-designer
deps: []
orca_task: null
unity_sources: []
owns: [docs/design/gdd.md, docs/design/features/**]
touches_scenes: []
---

## Target
GDD original en `/home/jeromo/vibedora/dev/pulpasa_docs/main.tex` (gallego, solo lectura) y
`docs/design/decisions.md`.

## Change
1. `docs/design/gdd.md` en castellano: resumen operativo del GDD aplicando D1–D7 y corrigiendo
   erratas (regla «atacar enemigos», objetivo del nivel confuso).
2. `docs/design/features/<slug>.md` por cada feature Must y Should de la alpha, con criterios
   de aceptación verificables (Given/When/Then) y números concretos.

## Constraints
No tocar `main.tex`. No crear fichas de backlog (eso lo hace el producer a partir de features/).
Alcance según la propuesta: Must/Should/Could/Won't.

## Acceptance
- [ ] AC1 Cada decisión D1–D7 está reflejada en el GDD de trabajo.
- [ ] AC2 Hay una feature por cada Must (8) con al menos 2 criterios medibles.
- [ ] AC3 Lista de preguntas abiertas al final de gdd.md, si las hay.

## Plan

## Evidence

- AC1: `docs/design/gdd.md` §3 tabla D1–D7 (cada una enlaza a su feature) y §8 erratas.
- AC2: 8 Must en `docs/design/features/` (movimiento-e-interaccion, corte-pulpo, coccion-pulpo,
  condimentacion, comandas, entrega-y-puntuacion, partida-5-min, jugadores-y-cambio), con 4–8 AC
  Given/When/Then medibles cada una. Además 4 Should (dificultad-progresiva, audio-y-fx,
  eventos-de-entorno, mando-y-reasignacion).
- AC3: `gdd.md` §9 Preguntas abiertas (9).
- `tools/verify.sh`: verde (GUT 2/2, smoke OK).
- Nota: la «propuesta» MoSCoW no estaba en el repo; los 8 Must se derivaron del bucle de juego.
  El producer debe validar la selección. Los números (tiempos, euros, umbrales) son provisionales.

## Revisión del producer (2.ª ronda)
- Rebase sobre `jrmougan/agentica-migracion-godot-alpha`; `roadmap.md` es la fuente del MoSCoW.
- Flujo corregido: pulpo crudo → olla → pulpo cocido → corte sobre caja (pulsar, 20 pulsaciones/caja) → condimentos → entrega (gdd §2/§4, corte-pulpo, coccion-pulpo).
- MoSCoW alineado (gdd §6): Must incluye mando Xbox, feedback mínimo, menú principal y paridad Unity (nuevas: `paridad-unity.md`, `menu-principal.md`); gaiteros → Could; Should = olla que se pasa, dificultad por fases, volumen, gallego, tutorial (nuevas fichas de feature).
- Preguntas abiertas depuradas; «pulsar vs mantener» queda como pregunta nº 6.
