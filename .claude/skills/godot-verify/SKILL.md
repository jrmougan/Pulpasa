---
name: godot-verify
description: Cómo verificar un cambio en Pulpasa - tools/verify.sh (sincronía de AGENTS.md y CLAUDE.md, lint, import, compilación de scripts, tests GUT, smoke) y verificación visual con el MCP de Godot (ejecutar, input simulado, captura, errores). Úsala antes de dar una ficha por terminada.
---
# Verificar un cambio

## 1. Verificación automática (siempre)

```bash
tools/verify.sh          # sincronía de AGENTS.md y CLAUDE.md, gdformat, gdlint, import, compilación de scripts, tests GUT, smoke de 120 frames
tools/verify.sh --quick  # lo mismo sin tests ni smoke
```

La compilación (`tools/check_scripts.gd`) hace `load()` y `can_instantiate()` de todos los `.gd` salvo `addons/`,
`.godot/` y `.mcp/`, y lista los que fallan. Hace falta porque ni el import ni el smoke detectan errores de tipo en
scripts que nada carga. También falla con cualquier `SCRIPT ERROR`: la lista puede omitir un script cuya dependencia
no compila, pero el error sí lo nombra.

La suite completa puede tardar ~8 min (también `tools/merge_gate.sh`): en Claude Code, lánzala con
`run_in_background` y espera el aviso, sin sondear. Mientras iteras, usa `--quick` y el test concreto.
En Windows, desde Git Bash, no PowerShell.

Si falla un test, el log completo está en `godot/.gut_reports/last.log`.
Un test concreto: `cd godot && mkdir -p .gut_reports && godot --headless --import >/dev/null 2>&1; godot --headless -s addons/gut/gut_cmdln.gd -gselect=test_x.gd -gunit_test_name=test_y`.
El import solo hace falta la primera vez en cada worktree. Ambos filtros son subcadenas.

## 2. Verificación visual (AC visuales o de interacción)

Con el MCP `godot` (proyecto en `godot/`, ruta absoluta en `projectPath`):

1. `run_project` con `background: true`; `scene: scenes/levels/level_01.tscn` para saltar el menú (la principal es main_menu).
2. Juego: `simulate_input` con `type: action` y `p1_*`. Menús: `get_ui_elements` y `click_element` por nombre de nodo. Usa `watch` y `results[]` para comprobar el efecto sin capturar.
3. `take_screenshot` (`responseMode: path_only` si solo guardas evidencia). Copia el PNG de `godot/.mcp/godot-runtime/screenshots/` a
   `docs/evidence/<id>/<ac>-<descripcion>.png`.
4. `get_debug_output`: cero `SCRIPT ERROR`/`ERROR`. Los `WARNING` de X11/xic (Linux) son ruido conocido.
5. `stop_project`, siempre, aunque algo falle.

En Linux sin pantalla (worker en segundo plano), lanza Claude bajo `xvfb-run -a` (comprobado con
Vulkan). En Windows y macOS no hace falta: `background: true` ya oculta la ventana.

## 3. Captura por script (estados y cámaras reproducibles)

Desde `godot/`: `godot --audio-driver Dummy --resolution 1920x1080 -s res://../docs/evidence/<id>/capture_boot.gd`
(Linux sin pantalla: antepón `xvfb-run -a`). Un script `-s` se compila antes de los autoloads: el
arranque no referencia nada del proyecto y carga la herramienta como nodo (modelo:
`docs/evidence/PUL-152/capture_boot.gd`).

## Reglas
- Sin `--headless` (capturas, escenas sueltas), añade `--audio-driver Dummy`: el audio sale por los
  altavoces del responsable aunque la ventana sea virtual. `run_project` no lo admite: silencia los
  buses con `run_script` nada más arrancar. Comprueba el audio por señales o estado de los reproductores.
- Las capturas son evidencia para revisión humana, no comparación de píxeles.
- No uses `run_script` para modificar estado que el AC debería alcanzar por input.
- Si no puedes verificar algo, dilo en `## Evidence` como «no verificable» con el motivo.
- Evidencia: series de capturas en JPG salvo que el AC necesite píxeles exactos; sin fotogramas
  sueltos ni logs vacíos. Logs en UTF-8/LF y sin rutas absolutas (en PowerShell, cuidado con la codificación de `>`).
