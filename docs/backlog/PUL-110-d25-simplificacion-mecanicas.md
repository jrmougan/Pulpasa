---
id: PUL-110
title: Registrar D25 (simplificación de mecánicas) y poner el diseño al día
status: in_progress
milestone: M3d
role: game-designer
deps: []
orca_task: null
unity_sources: []
owns: [docs/design/decisions.md, docs/design/roadmap.md, docs/design/level-layouts.md, docs/design/gdd.md, docs/design/rediseno-estaciones.md, docs/design/m3c-gate.md, docs/design/features/corte-pulpo.md, docs/design/features/condimentacion.md, docs/design/features/estacion-condimentos.md, docs/design/features/comandas.md, docs/design/features/entrega-y-puntuacion.md, docs/design/features/dificultad-progresiva.md, docs/design/features/tutorial-breve.md, docs/design/features/audio-y-fx.md, docs/design/features/cubo-basura.md, docs/backlog/PUL-110-d25-simplificacion-mecanicas.md]
touches_scenes: []
---

## Target
Diseño (`docs/design/`). Resultado del playtest de M3c (2026-10-10) y del estudio de mecánicas aprobado por el responsable ese mismo día: hay demasiadas mecánicas que no piden decisión.

## Change
Registrar **D25** en `decisions.md` y reflejarla en el GDD y las features. Contenido aprobado de D25:

1. **Caja única.** Se quitan los tamaños S/M/L: una sola caja, `presses_to_fill` = **6** (provisional, se re-mide en QA), `amount_per_full_box` sigue (1 pulpo = 2 cajas). El rack da una sola caja; el ticket ya no muestra talla. La caja errónea (D8) pasa a ser solo de contenido (aliño o cachelos).
2. **Aliño de una pulsación.** Los 4 dispensadores (sal, aceite, pimentón dulce, picante) se sustituyen por **2 dispensadores de aliño completo**: *aliño dulce* (sal gorda + aceite + pimentón dulce) y *aliño picante* (sal gorda + aceite + pimentón picante). Con una caja **llena** en la mano, una pulsación aplica el aliño; pulsar el otro lo **sustituye**; pulsar el mismo no hace nada (no hay toggle de quitar: lo que está mal se tira al cubo). Se van el toggle, `paprika_swap` como regla aparte y la sal y el aceite sueltos. Gesto visual breve de sal gorda, pimentón y aceite al aplicar. Cuenco de cachelos **sin cambios** (D10, D23: 2 raciones por cachelo, máx. 4, alterna cachelos con la caja llena). La caja muestra 1 pegatina de aliño + la de cachelos.
3. **Recetas por contenido.** Sin tamaños, las recetas se distinguen por aliño y cachelos: 4 comandas posibles (dulce/picante × con/sin cachelos). Nombres cortos que quepan en el ticket (≤ 14 caracteres, p. ej. «Á feira», «Picante», «Con cachelos», «Picante e cachelos» si cabe; decide el diseñador) y precios monótonos con el esfuerzo (con cachelos paga más). Sustituye a Individual/Doble/Familiar.
4. **Cubo de basura.** 2 cubos (cocina, junto a las ollas; servicio, junto al rack), a ≥ 1,5 m de pasaplatos y del hueco. Es objetivo **solo con algo en la mano**: caja (vacía, a medias o llena, con lo que lleve) o ingrediente (pulpo crudo o cocido, cachelos). Lo destruye: la mano queda vacía. **Sin penalización** (`trash_penalty` = 0, en datos). El pulpo quemado se sigue desechando en la olla. Cue `trash`. Sustituye la propuesta de GDD §10 «Devolver la caja errónea». Criterios de partida T1–T7 abajo.
5. **Progresión por fases.** La dificultad escala mecánicas además de puestos y paciencia: fase 1 solo aliño dulce sin cachelos; fase 2 entra el picante; fase 3 entran los cachelos. El tutorial enseña solo la fase 1.

D25 modifica D23 (corte 4/6/10, S/M/L en ticket y rack, «se pulsa cada dispensador»), D18 (dispensadores que alternan, `paprika_swap`) y concreta D8. Siguen D4 (sí/no, ahora: qué aliño y cachelos sí/no), D9, D10, D13 (pulsación repetida para cortar), D3 y la tecla única. Fecha: 2026-10-10, decidido por el responsable tras el playtest de M3c y el estudio de mecánicas.

## Constraints
- `decisions.md` manda sobre el GDD; el resto de documentos se ajusta a D25. Las features superadas se marcan como tales (como se hizo con `paridad-unity.md`), no se borran.
- Nueva feature `features/cubo-basura.md` con criterios Given/When/Then verificables. Partir de estos:
  - T1 Caja llena y condimentada en la mano a ≤ 1,5 m del cubo, E → mano vacía en el mismo frame, la caja liberada, `trashed` 1 vez, recaudación igual.
  - T2 Pulpo crudo/cocido o cachelos en la mano → igual que T1. Un quemado en la olla no lo ve el cubo.
  - T3 Mano vacía → el cubo no es objetivo.
  - T4 Una tirada → 1 cue `trash` y respuesta visual ≥ 0,3 s.
  - T5 `trash_penalty` en datos; cambiarlo no exige código.
  - T6 `level_01`: 2 cubos a ≥ 1,5 m de pasaplatos y del hueco, que conserva ≥ 1,0 m libre; ninguno bajo el HUD a 1280×720.
- `m3c-gate.md`: anotar el resultado del gate (playtest 2026-10-10: «mejor, pero sobran mecánicas»; R15 y R17 se re-miden tras D25; el resto de filas queda superado o pendiente según D25).
- Sin código ni contratos (`docs/arch/` es de PUL-111, en paralelo).

## Acceptance
- [x] AC1 `decisions.md` tiene D25 con el contenido de arriba y las referencias cruzadas en D8, D18 y D23 (anotar «modificada por D25»)
- [x] AC2 GDD (§3, §4, §6, §9, §10) y `rediseno-estaciones.md` reflejan D25
- [x] AC3 `corte-pulpo.md`, `condimentacion.md`, `estacion-condimentos.md`, `comandas.md` y `entrega-y-puntuacion.md`: los AC que dependían de tamaños, de 4 dispensadores o de toggle quedan superados con su sustituto verificable
- [x] AC4 `cubo-basura.md` nuevo con T1–T6 (o más)
- [x] AC5 `dificultad-progresiva.md` y `tutorial-breve.md` con las 3 fases; `audio-y-fx.md` con el cue `trash`
- [x] AC6 Tabla de recetas (nombre, aliño, cachelos, precio) en `comandas.md`

## Plan
1. D25 en `decisions.md` (fila nueva + notas cruzadas en D4, D8, D18, D23).
2. GDD (§2 bucle, §3, §4, §5, §6, §9, §10, §11) y nota de superación en `rediseno-estaciones.md`.
3. Features: reescribir `corte-pulpo`, `condimentacion`, `estacion-condimentos`, `comandas`; retocar
   `entrega-y-puntuacion`; crear `cubo-basura` (T1–T9); fases en `dificultad-progresiva` y
   `tutorial-breve`; cue `trash` y gesto de aliño en `audio-y-fx`.
4. Resultado del gate en `m3c-gate.md`.
5. Elección de recetas: 4 nombres ≤ 14 caracteres con tono gallego, precios crecientes con el esfuerzo.

## Evidence
Solo documentación; sin código ni capturas. Ficheros cambiados: `docs/design/decisions.md`, `gdd.md`,
`rediseno-estaciones.md`, `m3c-gate.md`, `features/{corte-pulpo,condimentacion,estacion-condimentos,
comandas,entrega-y-puntuacion,dificultad-progresiva,tutorial-breve,audio-y-fx,cubo-basura}.md` y esta
ficha. Recetas elegidas (`comandas.md`): Á feira 8 €, Picante 9 €, Con cachelos 12 €, Bravo cachelos 13 €
(todas provisionales, a datos). `grep` de «S/M/L», «Tray» y «paprika_swap» en las features vigentes:
solo quedan en notas de «sustituido/retirado por D25».
