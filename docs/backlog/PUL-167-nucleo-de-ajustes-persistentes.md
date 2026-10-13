---
id: PUL-167
title: Núcleo de ajustes persistentes y volumen guardado
status: draft
milestone: M4
role: gameplay-engineer
deps: [PUL-163]
orca_task: null
unity_sources: []
owns: [godot/core/settings_store.gd*, godot/resources/settings_defaults.gd*, godot/data/config/settings_defaults.tres, godot/autoload/audio_director.gd*, godot/tests/unit/test_settings_store.gd*, godot/tests/integration/test_settings_persistence.gd*, docs/evidence/PUL-167/**, docs/backlog/PUL-167-nucleo-de-ajustes-persistentes.md]
touches_scenes: []
---

## Target
ADR-007 (PUL-163), parte de ajustes; `features/opciones-de-volumen.md` (PUL-160). Rutas de `owns`
provisionales: el producer las ajusta a la sección «Ficheros y campos» de ADR-007 al pasar a `ready`.

## Change
Núcleo `RefCounted` que carga, valida y guarda los ajustes en `user://settings.cfg` con valores por defecto
en `.tres`, y su adaptador según ADR-007. El volumen de los 3 buses se lee al arrancar y se guarda al cambiar.

## Constraints
- ADR-002 (lógica en `core/`, adaptador fino) y ADR-006 §2 (`AudioDirector` único escritor de los buses).
- Sin UI: la pantalla es PUL-171. Las señales, solo las de `signals.md`.

## Acceptance
- [ ] AC1 Given sin `settings.cfg`, When se crea el núcleo, Then los valores son los de `settings_defaults.tres` (Música 70 %,
  Ambiente 70 %, Efectos 100 % salvo cambio en PUL-160) → `test_settings_store.gd`.
- [ ] AC2 Given un cambio de volumen guardado, When se recrea el núcleo, Then el valor se conserva (±0,001) → `test_settings_persistence.gd`.
- [ ] AC3 Given un `settings.cfg` corrupto o con claves desconocidas, When se carga, Then se usan los valores por defecto
  con 0 errores en consola y el fichero se reescribe válido en ≤ 1 guardado → `test_settings_store.gd`.
- [ ] AC4 Given el núcleo y `AudioDirector`, When un bus se fija a 0 % y luego a 100 %, Then queda a −80 dB y a 0 dB (±0,01) (`opciones-de-volumen.md` AC2) → `test_settings_persistence.gd`.
- [ ] AC5 Given la rama de la ficha, When se ejecutan `tools/verify.sh` y `python3 tools/check_owns.py <rama>`, Then ambos salen con código 0 y 0 rutas fuera de `owns` → salida pegada en `docs/evidence/PUL-167/README.md`.

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
