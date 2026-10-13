---
id: PUL-171
title: Pantalla de opciones desde el menú principal y la pausa
status: draft
milestone: M4
role: ui-engineer
deps: [PUL-167, PUL-168, PUL-169]
orca_task: null
unity_sources: []
owns: [godot/ui/menus/options_menu.gd*, godot/ui/menus/main_menu.gd*, godot/ui/menus/pause_menu.gd*, godot/data/i18n/options.*, godot/tests/integration/test_options_menu.gd*, docs/evidence/PUL-171/**, docs/backlog/PUL-171-pantalla-de-opciones.md]
touches_scenes: [godot/ui/menus/options_menu.tscn, godot/ui/menus/main_menu.tscn, godot/ui/menus/pause_menu.tscn]
---

## Target
`features/opciones-de-volumen.md` reescrita en PUL-160 con la lista de ajustes **aprobada en G0** (P2); núcleo de
ajustes de PUL-167; claves de PUL-168. Si G0 elige que el tutorial se abra con un botón del menú (P5, opciones b o c
de PUL-162), esta ficha es también la **dueña de ese botón** en `main_menu.tscn`, porque es la que tiene el menú
en O4 (API del botón: ADR-007, PUL-163).

## Change
1. Escena de opciones con los ajustes aprobados en G0, abierta desde el menú principal y desde la pausa,
   navegable con teclado, mando y táctil. **Propuesta mínima** si G0 no amplía: 3 sliders de volumen
   (Música, Ambiente, Efectos) y selector de idioma; cualquier ajuste más se añade según la lista aprobada.
2. Solo si G0 elige b o c: botón «Tutorial» en el menú principal que lanza el tutorial por la API de ADR-007.

## Constraints
- Lee y escribe ajustes solo a través del núcleo de PUL-167; ninguna ruta absoluta de nodos.
- Textos con claves en `data/i18n/options.*` (fichero creado vacío por PUL-168); el gallego lo completa PUL-173.
- Perfil móvil: filas ≥ 120 px de alto y texto ≥ 36 px a 1080 (`controles-tactiles.md`).
- Si la lista aprobada en G0 supone más de 5 AC, la ficha se parte antes de pasar a `ready`.

## Acceptance
- [ ] AC1 Given el menú principal o la pausa, When se elige «Opciones», Then se abre en ≤ 1 frame y «Volver» devuelve al mismo menú con el
  foco en «Opciones»; si G0 eligió b o c, Given el menú, When se elige «Tutorial», Then se carga el nivel en modo tutorial en ≤ 3 s → `test_options_menu.gd`.
- [ ] AC2 Given cada slider de volumen, When se mueve con el mando en pasos del 10 %, Then el bus cambia en el mismo frame (0 % → −80 dB,
  100 % → 0 dB) y el valor persiste (±0,001) tras recrear el núcleo de ajustes → `test_options_menu.gd`.
- [ ] AC3 Given el selector de idioma y cada ajuste adicional aprobado en G0, When se cambia, Then su efecto se aplica en ≤ 0,5 s y persiste → `test_options_menu.gd`.
- [ ] AC4 Given 1920×1080 (escritorio) y 2340×1080 (táctil), When se abre la pantalla, Then 0 filas por debajo de 120 px de alto en táctil y
  el recorrido completo se hace solo con mando → `test_options_menu.gd` + capturas en `docs/evidence/PUL-171/`.
- [ ] AC5 Given la rama de la ficha, When se ejecutan `tools/verify.sh` y `python3 tools/check_owns.py <rama>`, Then ambos salen con código 0 y 0 rutas fuera de `owns` → salida pegada en `docs/evidence/PUL-171/README.md`.

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
