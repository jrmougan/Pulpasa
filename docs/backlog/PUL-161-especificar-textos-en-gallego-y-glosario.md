---
id: PUL-161
title: Poner al día los textos en gallego y escribir el glosario
status: draft
milestone: M4
role: game-designer
deps: []
orca_task: null
unity_sources: []
owns: [docs/design/features/textos-gallego.md, docs/design/glosario-gl.md, docs/evidence/PUL-161/**, docs/backlog/PUL-161-especificar-textos-en-gallego-y-glosario.md]
touches_scenes: []
---

## Target
Should «textos en gallego» (`features/textos-gallego.md`, AC1–AC5). Desde que se escribió han entrado D25
(4 recetas, aliños), D26 (verbos, motivos, menús y tutorial táctiles) y D27. GDD original en gallego
(`main.tex`, solo lectura) como fuente de términos.

## Change
1. Inventario de las cadenas visibles hoy (menús, pausa, resultados, HUD, tickets, nombres de recetas,
   `performance_texts` de `round_config.tres`, verbos y motivos, tutorial), con dónde vive cada una
   (`.tscn`, `.gd` o `.tres`) y si cabe en 2340×1080 y 1280×720.
2. `docs/design/glosario-gl.md`: término castellano → gallego para el vocabulario del juego (polbo á feira,
   cachelos, aliño, pulpeiro, verbos y motivos de D26), con la fuente (`main.tex` o propuesta).
3. Actualizar `textos-gallego.md`: convención de claves, idiomas de la alpha (pregunta P1), idioma por
   defecto (hoy AC3: castellano), dónde se elige (opciones, PUL-160) y AC con números.

## Constraints
- Solo `docs/design/`. El formato de fichero y la API los fija PUL-163.
- Los textos en gallego son propuesta: la revisión por un hablante nativo es pregunta P9 del plan de M4.

## Acceptance
- [ ] AC1 Inventario en `docs/evidence/PUL-161/README.md` con ≥ 1 fila por pantalla y el origen de cada cadena.
- [ ] AC2 Glosario con todos los verbos y motivos de D26, las 4 recetas y los 4 `performance_texts`.
- [ ] AC3 `textos-gallego.md` con AC numéricos, cada uno con test o captura; preguntas abiertas explícitas.
- [ ] AC4 `tools/verify.sh --quick` en verde; `check_owns` limpio.

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
