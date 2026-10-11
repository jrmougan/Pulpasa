---
id: PUL-132
title: QA de D26
status: in_progress
milestone: M3e
role: qa-tester
deps: [PUL-131]
orca_task: null
unity_sources: []
owns: [docs/evidence/PUL-132/**, godot/tests/integration/test_d26_no_mute_press.gd*, godot/tests/integration/test_d26_touch_flow.gd*, docs/backlog/PUL-132-qa-de-d26.md]
touches_scenes: []
---

## Target
D26 (`docs/design/decisions.md`), contrato en `docs/arch/` (ADR-003 §11, ADR-004 §6, ADR-005 Enmienda D26,
ADR-006 §4.1, `signals.md`, `scene-tree.md` §9). Partición original y notas de propietarios entre oleadas:
`docs/backlog/PUL-120-contratos-d26.md` («Partición en fichas»). Oleada 4. Diseño:
`docs/design/features/lenguaje-acciones.md` y `controles-tactiles.md`. Touches scenes original: ninguna

## Change
verificación de D26 en `level_01` contra `lenguaje-acciones.md` y
  `controles-tactiles.md`; guía de playtest para el responsable.

## Constraints
- Solo las rutas de `owns`/`touches_scenes`. Si un cambio rompe un test fuera de tus owns, para y avisa al producer.
- Tipado estático, datos en `.tres`, lógica en `core/` RefCounted; no inventes `uid://`.
- Nombres exactos del contrato (manda sobre el diseño; equivalencias en PUL-120).

## Acceptance
- [ ] AC1 `test_d26_no_mute_press.gd`: ≥ 40 combinaciones mano × objetivo sobre `level_01` real (no fixtures sueltos),
  cada pulsación con objetivo da exactamente una respuesta (éxito con su cue o `rejected` + motivo) y ninguna es muda;
  incluye los casos del estudio de PUL-119 (cortar crudo, 7.º corte, mismo aliño, caja a medias en dispensador/cuenco,
  caja errónea en la zona, olla con quemado).
- [ ] AC2 `test_d26_touch_flow.gd`: partida en perfil MOBILE con `--touch` simulado solo con eventos táctiles
  (stick, acción, cambiar, pausa) que cocina, corta, aliña y entrega al menos una caja; multitáctil (stick + acción a la vez).
- [ ] AC3 Capturas en `docs/evidence/PUL-132/` a 1280×720, 1920×1080, 2340×1080 `--touch` y 800×370 (con y sin `--touch`):
  prompt OK y BLOQUEADO, anillo de cocción listo y aviso de quemado, contador N/6, cuenco, zona encendida, aros activo
  e inactivo, HUD y tickets sin solaparse con stick y botones, game over sin controles táctiles.
- [ ] AC4 Tabla de medidas en Evidence contra los AC de `controles-tactiles.md` y `lenguaje-acciones.md` (px reales del
  icono del prompt, botón de acción, texto mínimo, px por metro, grosor de anillos) con OK/KO por AC.
- [ ] AC5 Lista de hallazgos con gravedad (sin arreglarlos fuera de owns) y guía de playtest breve para el responsable
  (qué probar en PC y en móvil, preguntas abiertas: soltar al suelo por accidente, zurdos, háptica, 36 px en un teléfono).
- [ ] AC6 `tools/verify.sh` completo en verde.


## Plan

## Evidence
