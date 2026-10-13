---
id: PUL-154
title: Que el panel de salida de GUT no se quede con el puntero en los tests de UI
status: review
milestone: M4
role: qa-tester
deps: []
orca_task: null
unity_sources: []
owns: [godot/.gutconfig.json, godot/tests/helpers/gut_pre_run.gd*, godot/tests/integration/test_d26_touch_flow.gd*, godot/tests/integration/test_gut_pointer.gd*, docs/evidence/PUL-154/**, docs/backlog/PUL-154-panel-de-gut-y-clics-en-tests.md]
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
- [x] AC1 Given un `Button` a pantalla completa bajo GUT (headless), When `test_gut_pointer.gd` envía un
  clic (`InputEventMouseButton` pulsar y soltar en su centro) sin tocar `TestOutput`, Then `pressed` se
  emite exactamente 1 vez. → `test_gut_pointer.gd`.
- [x] AC2 Given `test_d26_touch_flow.gd` sin el apaño del `mouse_filter`, Then pasa y toca «Reanudar» con
  un `InputEventScreenTouch` real. → `test_d26_touch_flow.gd`.
- [x] AC3 `tools/verify.sh` completo en verde (mismo número de tests + 1) y `tools/check_owns.py` limpio;
  `.gut_reports/junit.xml` se sigue generando.

## Plan
GUT 9.7.1 no tiene opción de GUI que suelte el puntero: `opacity` no afecta a la entrada y
`compact_mode` deja un `MinGui` de 280×145 abajo a la derecha que sigue comiéndose clics (justo donde
van los botones táctiles). Se usa la opción `pre_run_script` de `.gutconfig.json` con un hook
(`GutHookScript`) que pone `MOUSE_FILTER_IGNORE` a todos los `Control` de la capa de GUT (padre de la
instancia `gut`). Solo cambia la entrada; no imprime nada (consola y `junit.xml` iguales) y solo
afecta a `gut_cmdln` (el panel GUT del editor usa su propia config). Ampliar `owns` con
`godot/tests/helpers/gut_pre_run.gd*` (aprobado por el coordinador, opción A). Test nuevo con un
`Button` a pantalla completa y clics reales en el centro y en la esquina inferior derecha; quitar
`_let_pointer_through_gut_output()` de `test_d26_touch_flow.gd`.

## Evidence
- Cambio de `owns`: se añadió `godot/tests/helpers/gut_pre_run.gd*` (aprobado por el coordinador:
  «opción A»; nadie más de la oleada toca `tests/helpers`).
- Cambios: `godot/.gutconfig.json` (`pre_run_script`), `godot/tests/helpers/gut_pre_run.gd` (hook),
  `godot/tests/integration/test_gut_pointer.gd` (nuevo, 1 test), `test_d26_touch_flow.gd` sin el apaño.
- AC1: `test_ac1_real_click_reaches_full_screen_button_under_gut_output` pasa: comprueba que
  `TestOutput` está en el árbol, que el `Button` cubre la vista, y que un clic
  (`InputEventMouseButton` pulsar+soltar por `Input.parse_input_event`) en el centro emite `pressed`
  1 vez y otro en la esquina inferior derecha lo lleva a 2 (pedido del coordinador). El test muerde:
  sin el hook falla la esquina (`[1] expected to equal [2]`). → `docs/evidence/PUL-154/con-hook.log`,
  `sin-hook.log` (config temporal con solo estos dos scripts, con y sin `pre_run_script`).
- AC2: `test_d26_touch_flow.gd` sin el apaño pasa con el hook; sin él falla «tocar «Reanudar»
  reanuda» (y lo que va detrás). Mismos logs.
- AC3: `tools/verify.sh` completo en verde: 1337 tests / 1337 pasan (antes 1336: +1 test), smoke OK;
  `.gut_reports/junit.xml` se genera (1337 `<testcase>`). `tools/check_owns.py jrmougan/pul-154 main`:
  9 rutas dentro de owns. → `docs/evidence/PUL-154/verify.log`.
- No verificado: la salida en una ejecución con ventana (no headless) desde `gut_cmdln`; ahí los
  botones de la GUI de GUT (p. ej. continuar tras `pause_before_teardown`) dejan de responder al ratón.
  Ningún test del proyecto usa esa pausa. Pregunta para el responsable: ¿se acepta, o se limita el
  hook a `DisplayServer.get_name() == "headless"`?
