---
id: PUL-072
title: Reescribir la biblia de arte con la estética de referencia
status: ready
milestone: M3b
role: game-designer
deps: []
orca_task: null
unity_sources: []
owns: [docs/art/art-bible.md, docs/art/moodboard*, docs/art/style-refs/**, docs/evidence/PUL-072/**]
touches_scenes: []
---

## Target
El responsable eligió una nueva dirección visual el 2026-10-06: `docs/art/style-refs/referencia-elegida-2026-10-06.png`. Hay que trasladarla a
una biblia de arte v2 que sirva de regla común para rehacer todos los assets (PUL-073..PUL-086).

## Change
Reescribe `docs/art/art-bible.md` (v2; conserva la v1 como `docs/art/art-bible-v1.md`, añádelo a tu owns):
1. **Estilo**: diorama estilizado de puesto de comida callejero, detallado y «vivido»: acero
   inoxidable cepillado, metal pintado con desgaste, plástico rojo, madera usada, arpillera, tierra
   apisonada con rodadas y charcos, rejillas, cables y tuberías; luz cálida de bombillas sobre un
   ambiente algo apagado; sensación de maqueta (tilt-shift opcional). Analiza la imagen y concreta.
2. **Paleta v2** (hex) y **materiales**: biblioteca de materiales estilizados (PUL-074) con texturas
   pequeñas pintadas/procedurales y detalles de desgaste; qué se permite ya que la v1 prohibía
   (texturas, normal maps sencillos, AO horneado) y qué no (fotorrealismo, ruido que mate la lectura).
3. **Presupuestos** de triángulos y texturas por tipo (más altos que la v1, con un objetivo de
   rendimiento: 60 fps a 1080p en la máquina de desarrollo, que mide PUL-087).
4. **Densidad de detalle**: qué es atrezo de fondo (sin colisión, puede ser denso) y qué es jugable
   (siempre limpio y legible).
5. **Legibilidad** (§3) adaptada: pulpo crudo/cocido/quemado, cachelos, platos/bandejas con
   pegatinas, colores de puesto, aros de jugador; nada de detalle encima de lo jugable.
6. **Marca (D21)**: la identidad de **PulpaSA** la diseña PUL-088 en paralelo (`docs/art/brand.md`);
   la biblia la enlaza y fija dónde aparece (cartel, toldo, uniformes, bandejas, UI). Propón el tono
   (franquicia satírica de puesto de pulpo o romería con marca) y déjalo como pregunta en Evidence.
7. Tabla **asset → cambio** para PUL-073..PUL-086 (qué se rehace, qué se retexturiza, qué atrezo
   nuevo hace falta).

## Constraints
- Solo documentación. Sin imágenes de terceros (D16): describe la referencia; la referencia es del
  responsable y ya está en el repo. **Gate humano** antes de lanzar PUL-073..PUL-086.
- El logotipo histórico `assets/textures/logo/PulpaSA.png` (propio, del prototipo) puede servir de punto de partida.

## Acceptance
- [ ] AC1 Biblia v2 con estilo, paleta, materiales, presupuestos, densidad y legibilidad
- [ ] AC2 Tabla asset → cambio completa para PUL-073..PUL-086
- [ ] AC3 Enlace a la identidad de PUL-088 y pregunta de tono en Evidence

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
