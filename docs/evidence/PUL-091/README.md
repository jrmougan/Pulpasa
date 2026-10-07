# PUL-091 · Evidencia y reproducción

Propuesta de arte, sin integración, preparada para gate humano. Informe principal:
[rediseño de estaciones](../../art/rediseno-estaciones-arte.md).

## Entregables

- AC1: capturas `00_nivel_sin_hud.png`, `01_nivel_completo.png` y
  `06_estados_controlados.png`, todas 1920×1080 desde CameraRig de level_01.
  Matriz de lectura por elemento en §1 del informe; `actual_*_1x.png` sin reescalado.
- AC2: lenguaje de formas, color e iconos en §2; conserva marca y restricciones v2.
- AC3: `art/concepts/estaciones/direction_{A,B}.blend`, cinco renders de detalle por dirección,
  dos renders a escala de juego y [comparativa actual/A/B](comparativa_actual_A_B.png).
- AC4: presupuestos, materiales enlazados, cambios por asset y dependencias condicionales
  en §4–5; números de maquetas separados de objetivos de producción.

El fixture de estados muestra S/M/L en columnas y vacío/50 %/lleno en filas. Modifica el estado
solo en memoria para auditar arte; no demuestra interacciones ni que se pueda entregar un pedido.
`capture_audit.gd` deriva del script de referencia existente; `capture_states.gd` es propio.
Capturas limpias válidas tras el import inicial del worktree; logs de las ejecuciones válidas.

## Reproducir desde la raíz

```sh
# Si el worktree aún no tiene caché de importación:
godot --headless --audio-driver Dummy --path godot --import
xvfb-run -a godot --audio-driver Dummy --path godot --resolution 1920x1080 \
  -s ../docs/evidence/PUL-091/capture_audit.gd -- "$PWD/docs/evidence/PUL-091"
xvfb-run -a godot --audio-driver Dummy --path godot --resolution 1920x1080 \
  -s ../docs/evidence/PUL-091/capture_states.gd -- "$PWD/docs/evidence/PUL-091"
blender -b --python art/concepts/estaciones/build_concepts.py -- A
blender -b --python art/concepts/estaciones/build_concepts.py -- B
blender -b --python docs/evidence/PUL-091/validate_concepts.py
python3 docs/evidence/PUL-091/compose_boards.py
GODOT_PATH="$PWD/docs/evidence/PUL-091/godot_dummy.sh" tools/verify.sh
python3 tools/check_owns.py jrmougan/pul-091 jrmougan/agentica-migracion-godot-alpha
```

`godot_dummy.sh` solo añade el driver silencioso a todos los procesos que lanza verify.
No se usa puerto Blender, MCP, ni procesos ajenos. Los conceptos reutilizan materiales enlazados
al `.blend` de la biblioteca; iconos PNG empaquetados y atlas propio de muestras dentro de cada
concepto. Para regenerar los PNG de icono: `magick -background none <SVG existente> -resize 128x128
<PNG de concepto>`; el mapeo es `sweet/hot → pepper-hot-solid`, `salt → salt`, `oil → oil`,
`potato → potato`, `fire → small-fire`, todos en `godot/assets/textures/icons/`.
No se han incorporado fuentes visuales nuevas de terceros.

## Validación y límites

- `verify.log`: **verde**, 68 scripts, **735/735 tests**, 9 052 asserts, import/lint/formato y smoke OK.
- `concept_validation.json`: los dos archivos reabren, sus bibliotecas y texturas existen;
  cámara ortográfica 1920×1080, ancho 22,6489 m, rotación Blender X=52° (38° bajo horizontal).
  `reopen_A.png` comprueba el render del archivo guardado, además de la sesión de generación.
- `owns.log`: comprobación de ownership después del commit.
- Los renders de detalle son ampliados; `*_native_1080.png` son la revisión de escala, no el nivel
  integrado. No se toma el tamaño de los detalles como evidencia de lectura a distancia.
- Blender tiene OCIO 2.4 con configuración de 2.5: avisa y usa fallback. Renders revisados por forma
  y composición; para aprobación colorimétrica rigen los hex del documento y la prueba futura en Godot.
- Godot informa al cerrar el fixture de 8 ObjectDB y 4 recursos vivos; no hubo errores de scripts
  durante las capturas válidas. Es el cierre del harness, no una regresión en escenas de producción.
- Hace falta selección humana y resolver las reglas de PUL-090 antes de fichas de implementación.
  No se ha aprobado ninguna dirección ni creado fichas nuevas.
