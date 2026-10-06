---
id: PUL-072
title: Reescribir la biblia de arte con la estética de referencia
status: review
milestone: M3b
role: game-designer
deps: []
orca_task: null
unity_sources: []
owns: [docs/art/art-bible.md, docs/art/art-bible-v1.md, docs/art/moodboard*, docs/art/style-refs/**, docs/evidence/PUL-072/**]
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
- [x] AC1 Biblia v2 con estilo, paleta, materiales, presupuestos, densidad y legibilidad
- [x] AC2 Tabla asset → cambio completa para PUL-073..PUL-086
- [x] AC3 Enlace a la identidad de PUL-088 y pregunta de tono en Evidence

## Plan
1. Analizar la referencia (imagen completa y recortes ampliados de cocina, kioscos y tickets; muestreo
   de color) y compararla con `style-refs/actual-2026-10-06/` y la biblia v1.
2. Archivar la v1 como `docs/art/art-bible-v1.md` (`git mv`, con aviso en cabecera) y añadirla a `owns`.
3. Escribir `docs/art/art-bible.md` v2: qué cambia (§0), estilo y análisis de la referencia (§1, con
   luz y post para PUL-073), paleta hex (§2), biblioteca de materiales y qué se permite (§3),
   presupuestos de triángulos/texturas/rendimiento (§4), zonas de detalle (§5), legibilidad con
   contrastes calculados (§6), marca PulpaSA (§7), tabla asset → cambio (§8), checklist (§9) y
   preguntas abiertas (§10).
4. Lámina propia de paleta `docs/art/moodboard-v2.svg` generada desde las tablas de §2.
5. `tools/verify.sh` y `check_owns`.

## Evidence
- Biblia v2: `docs/art/art-bible.md`; v1 archivada: `docs/art/art-bible-v1.md`; paleta:
  `docs/art/moodboard-v2.svg` (render en `docs/evidence/PUL-072/moodboard-v2.png`).
- AC1: §1 estilo y análisis de la referencia (+ luz/post §1.3), §2 paleta hex (54 colores + condimentos
  de la v1), §3 materiales (catálogo, permitido/prohibido, atlas), §4 presupuestos (tris ×2–6 de la v1,
  texturas ≤ 512²/1024², ≈ 256 px/m, 60 fps a 1080p con GPU ≤ 12 ms, orden de recorte), §5 zonas Z0–Z3,
  §6 legibilidad (crudo/cocido/quemado, bandejas, pegatinas, puestos, jugadores).
- Contrastes calculados (luminancia relativa WCAG) con los hex de §2: pulpo crudo/cocido 3,2:1,
  cocido/quemado 2,5:1, crudo/quemado 8,1:1; cachelos crudo/cocido 3,3:1, cocido/quemado 10,3:1,
  crudo/quemado 3,1:1; rodajas sobre papel 3,2:1; papel/bandeja 4,0:1; camiseta/suelo 3,0:1;
  dígitos ámbar sobre panel 5,9:1.
- Hallazgos de legibilidad que la referencia no resuelve y la biblia corrige: pulpo cocido sobre bandeja
  roja da 1,2:1 → bandeja con **papel antigrasa** (§6.4); patatas sueltas en el suelo y comida de atrezo
  en encimeras imitan objetos jugables → prohibidas en Z0/Z1 (§5); charcos tan oscuros como un objeto →
  aclarados (`ground_puddle`); pilas de bandejas sobre encimeras → solo en el rack.
- AC2: tabla §8 con PUL-073..PUL-086 (acción rehacer/retexturizar/nuevo, cambios, atrezo nuevo,
  presupuesto y dependencias) y orden recomendado. Sugerencia al coordinador: añadir PUL-076 a los `deps`
  de PUL-079 (pulpos dentro del tanque).
- AC3: §7 enlaza `docs/art/brand.md` (PUL-088, en paralelo; aún no existe en esta rama) y fija dónde
  aparece la marca y en qué versión (cartel, toldo, uniformes, bandejas, kioscos, menús, UI).
- **Pregunta de tono para el responsable**: ¿PulpaSA como **franquicia satírica con raíz de romería**
  (propuesta: «Pulpa, S.A.», uniformes, TPV, cámaras, cartel luminoso, en un campo de feria gallego con
  barro, fentos y cuncas) o como **romería con marca** (pulpería tradicional con logo pintado, sin guiños
  corporativos)?
- Otras decisiones del responsable (§10): muro de bloques o granito; si se fija una máquina de
  referencia modesta además de la RTX 3090; tilt-shift como opción de ajustes; vestuario de los comensales.
- **Gate humano** antes de lanzar PUL-073..PUL-086.
