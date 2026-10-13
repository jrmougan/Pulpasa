---
id: PUL-163
title: ADR-007 de ajustes persistentes, localización y tutorial
status: draft
milestone: M4
role: godot-architect
deps: [PUL-160, PUL-161, PUL-162]
orca_task: null
unity_sources: []
owns: [docs/arch/ADR-007-ajustes-localizacion-tutorial.md, docs/arch/signals.md, docs/arch/scene-tree.md, docs/arch/README.md, docs/evidence/PUL-163/**, docs/backlog/PUL-163-adr-007-ajustes-localizacion-y-tutorial.md]
touches_scenes: []
---

## Target
Contratos para las features de PUL-160..162: ajustes persistentes, cambio de idioma en caliente y tutorial.
Hoy `AudioMix`/`AudioDirector` (ADR-006 §2) guardan el volumen solo en memoria.

## Change
1. ADR-007: núcleo `RefCounted` de ajustes en `core/` (lectura/escritura de `user://settings.cfg`, valores
   por defecto en `.tres`, versión de esquema y qué pasa con un fichero corrupto o antiguo); quién lo adapta
   (autoload existente o nuevo, ADR-002) y cómo llega el volumen a `AudioDirector`.
2. Localización: formato (`.csv` o `.po`), ruta bajo `godot/data/`, convención de claves, registro en
   `project.godot` (`internationalization/locale/translations`), cómo se traducen textos de `.tres`
   (nombres de receta, `performance_texts`) y cómo se refresca la UI al cambiar de idioma.
3. Tutorial: núcleo de pasos, cómo escucha a `EventBus`, dónde se instancia el panel (`scene-tree.md`) y
   cómo se configura su fase.
4. Señales nuevas en `signals.md` (p. ej. ajustes o idioma cambiados, paso de tutorial) y rutas de `owns`
   propuestas para PUL-167..175.

## Constraints
- Contrato cerrado: requiere gate humano antes de que PUL-167, 168 y 169 pasen a `ready`.
- `autoload/`, `core/`, `resources/` y `ui/` sin tipos 3D/2D de mundo; nada de rutas absolutas de nodos.

## Acceptance
- [ ] AC1 Given ADR-007, When se revisa, Then cada uno de los 3 temas (ajustes, localización, tutorial) tiene contexto, decisión,
  ≥ 1 alternativa descartada con motivo y consecuencias (12 apartados, 0 vacíos) → lista de comprobación en `docs/evidence/PUL-163/README.md`.
- [ ] AC2 Given `signals.md`, When se añaden las señales nuevas, Then cada una tiene emisor, ≥ 1 oyente y payload tipado (0 campos `Variant`),
  y `scene-tree.md` sitúa la pantalla de opciones, los créditos y el panel del tutorial → diff de ambos ficheros citado en la evidencia.
- [ ] AC3 Given la sección «Ficheros y campos para PUL-167..175», When se cruza con los `owns` de esas 7 fichas, Then cada ruta propuesta
  coincide o se indica el cambio para el producer; 0 solapes dentro de una oleada del plan de PUL-141 → tabla en la evidencia.
- [ ] AC4 Given la ruta de menú del tutorial (si G0 elige b o c), When se fija el contrato, Then el ADR dice qué API llama el botón y que su
  dueño es PUL-171 → apartado del ADR citado en la evidencia.
- [ ] AC5 Given la rama de la ficha, When se ejecutan `tools/verify.sh --quick` y `python3 tools/check_owns.py <rama>`, Then ambos salen con código 0 y 0 rutas fuera de `owns` → salida pegada en `docs/evidence/PUL-163/README.md`.

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
