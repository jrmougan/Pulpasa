---
id: PUL-154
title: Que el panel de salida de GUT no se quede con el puntero en los tests de UI
status: draft
milestone: M4
role: qa-tester
deps: []
orca_task: null
unity_sources: []
owns: [godot/.gutconfig.json, godot/tests/integration/test_d26_touch_flow.gd*, godot/tests/integration/test_gut_pointer.gd*, docs/evidence/PUL-154/**, docs/backlog/PUL-154-panel-de-gut-y-clics-en-tests.md]
touches_scenes: []
---

## Target
Hallazgo H-04 (baja) del QA de D26 (`docs/backlog/PUL-132-qa-de-d26.md`, Evidence): con GUT el panel
`TestOutput` cubre la ventana y se queda con el puntero, también en headless, así que ningún test puede
hacer clic real en un botón. Sigue vivo: `godot/tests/integration/test_d26_touch_flow.gd` (función que
pone el `mouse_filter` de `TestOutput` a `IGNORE`, hacia la línea 152) lo esquiva a mano. Ninguna ficha
posterior (PUL-133..138) lo trató. No bloquea el gate de M3e; afecta a los tests de menús táctiles y de
opciones que vengan en M4.

## Change
Resolverlo en la configuración de GUT (`.gutconfig.json`, opciones de la GUI de GUT 9.7.1) o, si no hay
opción, con un ayudante de test compartido en `godot/tests/`; quitar el apaño de
`test_d26_touch_flow.gd`.

## Constraints
- No edites `godot/addons/` (regla 7) ni `tools/verify.sh`. Si la solución exige tocarlos, para y avisa
  al coordinador.
- Si la solución es un ayudante nuevo fuera de `owns`, pide ampliar `owns` antes de crearlo.
- `tools/verify.sh` sigue verde en Linux; la salida de GUT en consola y el `junit.xml` no cambian.

## Acceptance
- [ ] AC1 Given un `Button` a pantalla completa bajo GUT (headless), When `test_gut_pointer.gd` envía un
  clic (`InputEventMouseButton` pulsar y soltar en su centro) sin tocar `TestOutput`, Then `pressed` se
  emite exactamente 1 vez. → `test_gut_pointer.gd`.
- [ ] AC2 Given `test_d26_touch_flow.gd` sin el apaño del `mouse_filter`, Then pasa y toca «Reanudar» con
  un `InputEventScreenTouch` real. → `test_d26_touch_flow.gd`.
- [ ] AC3 `tools/verify.sh` completo en verde (mismo número de tests + 1) y `tools/check_owns.py` limpio;
  `.gut_reports/junit.xml` se sigue generando.

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
