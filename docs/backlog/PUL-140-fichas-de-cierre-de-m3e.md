---
id: PUL-140
title: Crear las fichas de cierre de M3e (guía de playtest y export Android)
status: review
milestone: M3e
role: game-designer
deps: []
orca_task: null
unity_sources: []
owns: [docs/backlog/PUL-15[0-4]-*.md, docs/evidence/PUL-140/**, docs/backlog/PUL-140-fichas-de-cierre-de-m3e.md]
touches_scenes: []
---

## Target
El cierre de M3e (D26, `docs/design/roadmap.md`): falta la guía del playtest humano (no existe
`docs/design/m3e-gate.md`; hay modelos en `m3c-gate.md` y `m3d-gate.md`) y la ficha futura del export
Android y el renderizador móvil (alcance de la alpha, punto 11), que debe incluir comprobar en teléfono la
limitación aceptada D27.3 (safe area inferior de 63 px). Diseño vigente: `docs/design/decisions.md`
(D26, D27), `features/controles-tactiles.md` y las fichas PUL-119..138.

## Change
Fichas `draft` con ids **PUL-150 a PUL-154**, formato de `_TEMPLATE.md`, por ejemplo:
1. Escribir `docs/design/m3e-gate.md`: guion del playtest del lenguaje de acciones en PC (y la parte de
   teléfono, condicionada al export), con qué mirar, qué medir y cómo anotar los resultados.
2. Export Android y renderizador móvil: toolchain, preset, renderizador, prueba en dispositivo real, y la
   comprobación de D27.3 y de los criterios de `controles-tactiles.md` que solo se ven en teléfono.
   Estado `blocked` con el motivo (falta toolchain y dispositivo).
3. Lo que encuentres al repasar D26/D27 que quede sin ficha (por ejemplo, criterios marcados para el
   playtest o para el teléfono).
Resumen en `docs/evidence/PUL-140/README.md`: qué fichas creas y por qué.

## Constraints
- Solo crear fichas y el resumen: **no escribas** la guía ni código.
- **No edites** `docs/backlog/README.md`, `docs/design/roadmap.md` ni otros docs de diseño: los
  actualiza el coordinador. Usa solo los ids PUL-150..154.
- Cada AC con números y su test o captura; `owns` mínimos sin solaparse entre fichas.

## Acceptance
- [x] AC1 Ficha de la guía `m3e-gate.md` y ficha `blocked` del export Android con D27.3 incluida.
- [x] AC2 `docs/evidence/PUL-140/README.md` lista las fichas y lo revisado de D26/D27.
- [x] AC3 `tools/verify.sh --quick` en verde; `check_owns` limpio.

## Plan
1. Repasar D26, D27, `roadmap.md` (M3e, Must 11), `controles-tactiles.md`, `lenguaje-acciones.md`
   (preguntas abiertas), ADR-005 (Enmiendas D26 y D27, D27.3), `docs/arch/export.md`, los modelos
   `m3c-gate.md`/`m3d-gate.md` y las fichas PUL-119..138 (sobre todo hallazgos y guía de PUL-132 y su
   seguimiento en PUL-133..138).
2. Crear en `draft` (o `blocked`) PUL-150 guía `m3e-gate.md`, PUL-151 export Android y renderizador móvil
   (D27.3 incluida), y con lo que quede sin ficha: PUL-152 recaptura de medidas tras PUL-133..138 (la
   guía las necesita), PUL-153 teléfono vía build web (pregunta al responsable) y PUL-154 panel de GUT que
   tapa el puntero (H-04 de PUL-132). `owns` mínimos y disjuntos.
3. `docs/evidence/PUL-140/README.md`: fichas, motivo, lo revisado de D26/D27 y preguntas.
4. `tools/verify.sh --quick` y `tools/check_owns.py`; Evidence, `review`, commit.

## Evidence
Resumen y lo revisado de D26/D27: `docs/evidence/PUL-140/README.md`.

| AC | Resultado |
|---|---|
| AC1 | `PUL-150-guia-playtest-m3e.md` (draft, guía `m3e-gate.md`, deps PUL-152) y `PUL-151-export-android-y-renderizador-movil.md` (**blocked**: sin Android SDK, sin plantillas 4.7.2 y sin teléfono; AC4 con D27.3 y la safe area real). Además PUL-152 (recaptura de D26 con el estado final y caso 09 con safe de diseño), PUL-153 (teléfono vía build web, pregunta al responsable) y PUL-154 (H-04 de PUL-132, panel de GUT; M4). `owns` disjuntos, sin escenas |
| AC2 | README con la tabla de fichas, la tabla punto de D26/D27 → estado → ficha y 4 preguntas (perfil táctil en PC sin pantalla táctil, teléfono por web, toolchain Android, estado «propuesta» de las enmiendas de ADR) |
| AC3 | `tools/verify.sh --quick`: `✓ verify OK`. `tools/check_owns.py jrmougan/pul-140 ac249d1`: 7 rutas, todas dentro de owns (rc 0) |
