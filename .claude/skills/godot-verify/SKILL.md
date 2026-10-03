---
name: godot-verify
description: Cómo verificar un cambio en Pulpasa - tools/verify.sh (lint, import, tests GUT, smoke) y verificación visual con el MCP de Godot (ejecutar, input simulado, captura, errores). Úsala antes de dar una ficha por terminada.
---
# Verificar un cambio

## 1. Verificación automática (siempre)

```bash
tools/verify.sh          # gdformat, gdlint, import, tests GUT, smoke de 120 frames
tools/verify.sh --quick  # solo formato, lint e import
```

Si falla un test, el log completo está en `godot/.gut_reports/last.log`.
Un test concreto: `cd godot && godot --headless -s addons/gut/gut_cmdln.gd -gselect=test_x.gd -gunit_test_name=test_y`.

## 2. Verificación visual (AC visuales o de interacción)

Con el MCP `godot` (proyecto en `godot/`, ruta absoluta en `projectPath`):

1. `run_project` con `background: true` (y `scene` si no es la principal).
2. `simulate_input` para llegar al estado del AC (acciones del InputMap, no teclas sueltas).
3. `take_screenshot`. Copia el PNG de `godot/.mcp/godot-runtime/screenshots/` a
   `docs/evidence/<id>/<ac>-<descripcion>.png`.
4. `get_debug_output`: cero `SCRIPT ERROR`/`ERROR`. Los `WARNING` de X11/xic son ruido conocido.
5. `stop_project`, siempre, aunque algo falle.

Sin pantalla (worker en segundo plano), lanza Claude bajo `xvfb-run -a`. Está comprobado en
esta máquina con Vulkan.

## Reglas
- Las capturas son evidencia para revisión humana, no comparación de píxeles.
- No uses `run_script` para modificar estado que el AC debería alcanzar por input.
- Si no puedes verificar algo, dilo en `## Evidence` como «no verificable» con el motivo.
