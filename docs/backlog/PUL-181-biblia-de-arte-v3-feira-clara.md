---
id: PUL-181
title: Escribir la biblia de arte v3 «Feira Clara» y partir su implementación en fichas
status: draft
milestone: M3f
role: game-designer
deps: [PUL-180]
orca_task: null
unity_sources: []
owns: [docs/art/art-bible.md, docs/art/art-bible-v2.md, docs/art/moodboard-v3*, docs/backlog/PUL-18[2-9]-*.md, docs/evidence/PUL-181/**, docs/backlog/PUL-181-biblia-de-arte-v3-feira-clara.md]
touches_scenes: []
---

## Target
D28 (2026-10-17): el responsable elige la dirección **A · «Feira Clara»** de PUL-180
(`docs/art/minimal/direccion-a-color-plano.md`, `README.md` y el prototipo
`docs/evidence/PUL-180/capture_minimal.gd`), con una **primera oleada solo de materiales y escena**,
sin remodelar `.glb`. La biblia vigente (`docs/art/art-bible.md`, v2, D22) queda sustituida en estilo,
materiales y post-proceso.

## Change
1. Archiva la v2 como `docs/art/art-bible-v2.md` y reescribe `docs/art/art-bible.md` como **v3**. Debe
   incluir:
   - qué cambia frente a la v2 (tabla, como en la §0 de la v2);
   - la paleta cerrada en hex con el uso de cada color;
   - la biblioteca de materiales planos compartidos: nombre del `.tres`, color, roughness y
     metallic, y a qué superficies se aplica;
   - luz y entorno (`WorldEnvironment`, `DirectionalLight3D` y post-proceso permitido: SSAO sí o
     no, sombras);
   - qué atrezo se quita y cuál se queda;
   - legibilidad de estados y de los colores de §3.4, con los contrastes recalculados;
   - impacto en la UI y el HUD.

   Lo que la v2 tenía y la v3 conserva (unidades, escala, nodos de contrato, nombres, cámara) se
   referencia, no se copia. Resuelve en la biblia los puntos débiles que vio la revisión de PUL-180:
   - el cartel superior, que en el prototipo queda como un rectángulo vacío;
   - los números de los puestos, que salen delineados o degradados en móvil;
   - el entorno con textura (`env_plate`);
   - el SSAO.
2. Lámina de paleta propia `docs/art/moodboard-v3.svg`.
3. Parte la implementación en **fichas `draft` PUL-182 a PUL-189** con el formato de `_TEMPLATE.md`:
   - en oleadas, sin solapar `owns` ni `touches_scenes`, y con `level_01.tscn` en una sola ficha de
     integración;
   - con roles de `.claude/agents/` (asset-pipeline, gameplay-engineer o ui-engineer) y ≤ 5 AC con
     números y su test o captura;
   - sin `.glb` nuevos ni remodelados.

   Incluye la ficha de QA visual: antes y después con el mismo script de captura y la misma cámara, a
   1920×1080 y a 800×370, y rendimiento medido con el mismo método antes y después. Incluye también la
   limpieza de los materiales y texturas v2 que queden sin uso. Revisa si PUL-144, PUL-145 y PUL-146
   (arte v2) quedan obsoletas o se absorben, y dilo en la evidencia (no edites esas fichas).
4. `docs/evidence/PUL-181/README.md`: plan de oleadas, dependencias, fichas creadas y preguntas para el
   responsable.

## Constraints
- Solo documentación: no se cambia código, escenas, `.tres` ni `.glb`. No edites
  `docs/backlog/README.md`, `docs/design/decisions.md` ni `roadmap.md`: los actualiza el coordinador.
- Siguen D14, D16, D20, D21 (marca PulpaSA), D26 (iconos, prompts y legibilidad en móvil) y los colores
  de §3.4.
- Lo que deba decidir el responsable va como pregunta, no como supuesto.

## Acceptance
- [ ] AC1 Given la v2, When se abre `docs/art/art-bible.md`, Then dice «v3», enlaza la v2 archivada y
  D28, y tiene la tabla de cambios, una paleta cerrada de entre 12 y 20 colores en hex y la biblioteca de
  materiales (≤ 20 `.tres`) con su uso.
- [ ] AC2 Given la paleta v3, When se calculan los contrastes de los 5 colores de §3.4 frente a cada
  superficie donde aparecen, Then todos son ≥ 3:1 (tabla y script en `docs/evidence/PUL-181/`).
- [ ] AC3 Given los 4 puntos débiles de PUL-180 (cartel, números, `env_plate`, SSAO), When se lee la
  biblia, Then cada uno tiene una regla concreta.
- [ ] AC4 Given las fichas PUL-182.., When se comparan sus `owns` y `touches_scenes` dentro de cada
  oleada, Then no se solapan, `level_01.tscn` aparece en una sola ficha, y hay una ficha de QA visual con
  medida de rendimiento antes y después.
- [ ] AC5 `tools/verify.sh --quick` en verde y `tools/check_owns.py` limpio.

## Plan
(Lo escribe el worker antes de empezar.)

## Evidence
(Lo rellena el worker.)
