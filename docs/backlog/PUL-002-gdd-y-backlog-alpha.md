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
- AC2: los **9 Must del roadmap** («Alcance aprobado») trazados a features en `gdd.md` §6:
  1 paridad → `paridad-unity`; 2/3/8 → `comandas` (ciclo, paciencia, iconos); 4 → `entrega-y-puntuacion`;
  5 → `jugadores-y-cambio` + `mando-y-reasignacion`; 6 → `jugadores-y-cambio`; 7 → `menu-principal`;
  D4 → `condimentacion`; 9 → `audio-y-fx`. Soporte Must: `movimiento-e-interaccion`, `coccion-pulpo`,
  `corte-pulpo`, `partida-5-min`. Todas con ≥ 2 AC medibles en Given/When/Then.
- **5 Should**: `olla-que-se-pasa`, `dificultad-progresiva`, `opciones-de-volumen`, `textos-gallego`, `tutorial-breve`.
  Could: `eventos-de-entorno` (gaiteros).
- AC3: `gdd.md` §11 Preguntas abiertas (6); §9 reglas vigentes de paridad; §10 propuestas para gate humano.
- Revisiones: flujo corregido (pulpo crudo → olla → cocido → corte → condimentos → entrega); 2.ª ronda (codex)
  aplicada: reposición inmediata, `fill_per_press` por tipo de caja, HUD de recaudación, precedencia
  entrega/caducidad, variantes de cocción, fases de dificultad, galego Should, volumen movido al Should.
- `tools/verify.sh`: verde.
- Los números (tiempos, euros, umbrales, fases) son provisionales. Esta ficha está fuera del `owns`
  estricto; la actualización de Evidence la autorizó el producer.
