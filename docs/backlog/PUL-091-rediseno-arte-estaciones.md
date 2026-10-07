---
id: PUL-091
title: Auditar la lectura visual de estaciones y bandejas y proponer su rediseño artístico
status: ready
milestone: M3c
role: asset-pipeline
deps: []
orca_task: null
unity_sources: []
owns: [docs/art/rediseno-estaciones-arte.md, art/concepts/estaciones/**, docs/evidence/PUL-091/**]
touches_scenes: []
---

## Target
Rediseño del **arte** de todo lo relacionado con estaciones (lo ejecuta Codex por decisión del
responsable, 2026-10-07): estación de condimentos (mostrador, 4 dispensadores, cuenco de cachelos,
bandeja de pase, lados), bandejas/platos S/M/L con relleno, condimentos y pegatinas (`badge_row`),
rack de bandejas (`box_shelf`), encimeras/slots donde se dejan, y kioscos de entrega (`order_stand`).
Fuentes actuales: `art/blender/{seasoning_station,box,box_shelf,counters,order_stand}.blend`,
`godot/entities/stations/`, `godot/entities/items/`. Reglas: `docs/art/art-bible.md` (v2),
`docs/art/brand.md`, `docs/art/materials-v2.md`, `docs/art/pipeline.md`. Referencia elegida:
`docs/art/style-refs/referencia-elegida-2026-10-06.png`. Hallazgos previos del QA: `docs/evidence/PUL-087/README.md` (D1–D3, D7).

## Change
Solo propuesta (no se integra en Godot todavía). Escribe `docs/art/rediseno-estaciones-arte.md`:
1. **Auditoría de lectura** a la cámara del juego (capturas de `level_01` a 1920×1080, cámara ortográfica
   real): ¿se distingue qué dispensador es cuál, desde qué lado se usa, dónde va la bandeja, el tamaño
   S/M/L, cuánto falta para llenarla, qué lleva, qué kiosco es cuál? Puntúa cada elemento (claro / dudoso / no se lee) con captura.
2. **Lenguaje de affordances** común: forma/color/icono de «aquí se deja», «aquí se pulsa», «desde este
   lado», estado lleno/vacío/listo, coherente con la paleta v2 y la marca (pimentón/marino/papel).
3. **2 direcciones de rediseño** por elemento, con **conceptos renderizados en Blender** desde la cámara
   del juego (ortográfica, mismo ángulo) en `art/concepts/estaciones/` (`.blend` + `.png`) y una lámina
   comparativa actual vs A vs B en `docs/evidence/PUL-091/`.
4. Presupuesto (triángulos, materiales reutilizados de `_materials_v2.blend`) y lista de cambios por
   asset para las fichas de implementación de arte que vendrán tras el gate.
5. Lo que dependa de reglas de juego (el diseñador prepara en paralelo `docs/design/rediseno-estaciones.md`,
   PUL-090) se marca como variante condicional, no se decide aquí.

## Constraints
- Blender solo por línea de comandos (`blender -b ... --python ...`); **nunca** el puerto 9876 ni
  cierres procesos de Blender ajenos (el responsable puede tenerlo abierto).
- No modifiques `art/blender/*.blend` existentes ni nada de `godot/`: los conceptos van en ficheros nuevos.
- Godot para capturas: `xvfb-run -a godot --audio-driver Dummy ...` (el audio sonaría en los altavoces).
- Sin imágenes ni modelos de terceros (D16). Antes de cerrar: `tools/verify.sh` y
  `tools/check_owns.py jrmougan/pul-091 jrmougan/agentica-migracion-godot-alpha` en verde.
- **Gate humano** antes de crear las fichas de arte.

## Acceptance
- [ ] AC1 Auditoría de lectura con capturas a la cámara del juego y puntuación por elemento
- [ ] AC2 Lenguaje de affordances documentado con paleta v2/marca
- [ ] AC3 Dos direcciones por elemento con renders de Blender y lámina comparativa
- [ ] AC4 Presupuesto y lista de cambios por asset; dependencias de reglas marcadas como condicionales

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
