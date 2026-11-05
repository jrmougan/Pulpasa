# Pipeline de arte: Blender → glTF → Godot

Autor: PUL-043 (asset-pipeline); puesto al día para la estética v3 (D28) en PUL-194. Aplica D20 y las
reglas de [`art-bible.md`](art-bible.md) (v3: paleta §2 y materiales §3) y las de escala, orientación y nombres
que la v3 conserva de [`art-bible-v1.md`](art-bible-v1.md) §2 (v3 §0.2); todas mandan sobre este documento. Todo se ejecuta **desde la raíz del repo**.

**Estado de la migración v2 → v3.** La biblioteca de materiales v2 (`art/blender/_materials_v2.blend`,
`godot/assets/materials/v2/`, `godot/assets/textures/v2/`, los PNG extraídos junto a los `.glb` y
[`materials-v2.md`](materials-v2.md)) **sigue en el repo**; PUL-188 solo borra `godot/assets/materials/v2/`, `godot/assets/textures/v2/` y los
`godot/assets/models/**/*.png` (y sus `.png.import`). `art/blender/_materials_v2.blend`, `_template.blend`, `materials-v2.md` y el banco
`_pipeline/**` no figuran en su `owns` y siguen: qué hacer con ellos lo decide PUL-201. Existe, pero no es vigente: ningún asset nuevo la usa como destino (§8).

## 1. Requisitos

| Pieza | Versión | Nota |
|---|---|---|
| Blender | 5.2 LTS. Linux: Flathub (`org.blender.Blender`), invocable como `blender` en el PATH. Windows: instalador oficial (probado aquí: 5.2.3 LTS en `C:/Program Files/Blender Foundation/Blender 5.2/`, fuera del PATH) | Linux: envoltorio en `~/.local/bin/blender`: `exec flatpak run org.blender.Blender "$@"`. Lo usan `tools/blender_mcp.sh` y `BLENDER_PATH` del servidor MCP. Windows: ver §1.1 |
| Add-on MCP de Blender Lab | 1.0.3 (extensión `lab_blender_org.mcp`, ≥ Blender 5.1) | Instalado en `~/.var/app/org.blender.Blender/config/blender/5.2/extensions/` (Flatpak) (Windows: `%APPDATA%\Blender Foundation\Blender\5.2\extensions\`). Abre un socket TCP local. Tras instalarlo desde la interfaz, activa *Allow Online Access* (Preferencias › Sistema) y **guarda las preferencias**: si no, el Blender `-b` no lo carga y `-c blender_mcp` no existe |
| Servidor MCP `blender-mcp` | Blender Lab `lab/blender_mcp` @ `v1.0.3` (subdirectorio `mcp`, misma versión que el add-on) | Fijado en `.mcp.json` y lanzado con `uvx` (uv de `mise.toml`). El primer arranque compila el paquete (~1 min) y Claude lo da por caído: lánzalo una vez a mano para llenar la caché de uv |
| Godot | 4.7.2 | Importador glTF nativo |

### 1.1 Blender en Windows (comprobado en Windows 11 con Git Bash, Blender 5.2.3 LTS)

- **Export headless: funciona.** Con el ejecutable por ruta completa (no está en el PATH):
  `"/c/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b art/blender/<asset>.blend --python tools/blender_export.py -- ...`
  (en Git Bash; las rutas del `--out` pueden ir con `C:/...`). Desde `cmd` o PowerShell, la ruta nativa
  `C:\Program Files\...\blender.exe` con los mismos argumentos. `blender_export.py` usa solo `pathlib`, así que
  la barra no importa.
- **`tools/blender_mcp.sh`: funciona solo bajo Git Bash**, con `BLENDER_PATH` apuntando al `.exe` (el valor por
  defecto `blender` no existe en el PATH de Windows) y con el add-on MCP 1.0.3 instalado en
  `%APPDATA%\Blender Foundation\Blender\5.2\extensions\lab_blender_org\mcp`. Probado con un puerto propio
  (`BLENDER_MCP_PORT`): `start` abre el puerto, `status` ve el PID y `stop` lo cierra. Funciona porque Git Bash emula `/proc` y `/dev/tcp`; en `cmd` o PowerShell el script no se puede ejecutar. En Windows
  `XDG_RUNTIME_DIR` no existe y el script cae en `/tmp` de Git Bash (el PID y el log quedan ahí).
- **No probado:** Blender instalado desde Microsoft Store/winget, el arranque del servidor `uvx blender-mcp`
  desde Claude en Windows (solo se probó el lado Blender), y las variantes `_for_cli` de las tools MCP (buscan
  `blender` en el PATH).
- **macOS: no verificable** aquí (no hay máquina para probarlo); no se documenta ninguna ruta.

## 2. MCP de Blender

**Alta**: la entrada `blender` de `.mcp.json` (y `enabledMcpjsonServers` en `.claude/settings.json`)
la aprobó el responsable (gate humano; `.mcp.json` no pertenece a ninguna ficha de asset). No se
cambia su versión sin otra aprobación.

```json
"blender": {
  "command": "uvx",
  "args": ["--python", "3.13", "--from", "git+https://projects.blender.org/lab/blender_mcp.git@v1.0.3#subdirectory=mcp", "blender-mcp"],
  "env": { "BLENDER_MCP_PORT": "${BLENDER_MCP_PORT:-9876}", "BLENDER_PATH": "blender" }
}
```

**Cómo se lanza junto al agente.** El servidor MCP lo arranca Claude Code; ese servidor habla por
TCP con un Blender que tiene el add-on activo. Antes de usar las tools `mcp__blender__*` hay que
levantar ese Blender (sin pantalla) y pararlo al terminar:

```sh
tools/blender_mcp.sh start    # blender -b -c blender_mcp --port $BLENDER_MCP_PORT (9876)
tools/blender_mcp.sh status
tools/blender_mcp.sh stop
```

- El PID y el log quedan en `$XDG_RUNTIME_DIR/pulpasa_blender_mcp/` (fuera del repo). `stop` solo
  actúa si el PID sigue siendo ese Blender (`-c blender_mcp --port <puerto>`), envía TERM, espera
  10 s y escala a KILL; si el arranque falla (puerto sin abrir en `BLENDER_MCP_START_TIMEOUT`, 30 s
  por defecto) mata el proceso lanzado y borra el PID.
- No uses `--factory-startup`: desactiva las extensiones y `-c blender_mcp` deja de existir.
- En modo `-b` no hay respuestas diferidas: cada petición debe terminar antes de devolver.
- Dos agentes a la vez: cada uno con su `BLENDER_MCP_PORT` (exportado antes de lanzar Claude).
- Si las tools no aparecen, el fallback es el mismo flujo sin MCP:
  `blender -b <fichero.blend> --python <script.py>`.

**Tools que expone** (prefijo `mcp__blender__`):

| Grupo | Tools | Uso en Pulpasa |
|---|---|---|
| Ejecutar código | `execute_blender_code` (Blender conectado), `execute_blender_code_for_cli` (abre un `.blend` en un Blender `-b` aparte) | Modelado por `bpy`/`bmesh`; nombrar los slots de material (§3, §8.1) |
| Inspección de escena | `get_objects_summary`, `get_object_detail_summary` | Comprobar colecciones, jerarquía, escala/rotación |
| Inspección de `.blend` | `get_blendfile_summary_datablocks`, `…_missing_files`, `…_of_linked_libraries`, `…_path_info`, `…_usage_guess` (y variantes `_for_cli`) | Revisar un `.blend` sin abrirlo en la sesión |
| Imagen | `render_thumbnail_to_path`, `render_viewport_to_path`, `get_screenshot_of_window_as_image`, `get_screenshot_of_area_as_image`, `get_screenshot_of_window_as_json` | Capturas de revisión (las de ventana requieren Blender con interfaz) |
| Navegación de UI | `jump_to_tab_by_name`, `jump_to_tab_by_space_type`, `jump_to_view3d_object_by_name`, `jump_to_view3d_object_data_by_name` | Solo con interfaz; no se usan en headless |
| Documentación | `search_api_docs`, `get_python_api_docs`, `search_manual_docs` | API `bpy` y manual de Blender 5.x |

## 3. Plantilla `art/blender/_template.blend`

Punto de partida de **todo** asset: ábrela y guárdala como `art/blender/<asset>.blend` (un `.blend`
por ficha, art-bible-v1 §2.4). Contiene:

- **Unidades**: métrico, `Unit Scale = 1.0`, longitud en metros (1 u Blender = 1 m = 1 u Godot), 30 fps.
- **Colección `export`**: lo único que se exporta. Trae un `Empty` raíz `asset` (renómbralo con el
  nombre del asset; todo lo exportable cuelga de él) y el marcador **`Anchor_Front`** en (0, 0,5, 0),
  delante (+Y) y sin rotación (una esfera pequeña). Modela el frente hacia +Y; el exportador lo convierte en −Z de Godot. No lo
  borres: `test_assets_models.gd` lo usa para comprobar la orientación.
- **Colección `reference`** (no se exporta, no renderiza): `ref_character_1_8m` (caja de 0,6 × 0,3
  × 1,8 m, origen en la base) y `ref_counter_1m` (encimera de 1 × 0,8 × 1 m) en alámbrico, y la
  flecha `ref_front_+Y`.
- **Materiales: aún enlaza la biblioteca v2** (45 `mat_*` de `art/blender/_materials_v2.blend`, link con ruta
  relativa `//_materials_v2.blend`; por eso el `.blend` del asset debe vivir en `art/blender/`). La tira
  `ref_materials_v2` de la colección `reference` de la plantilla mantiene vivos esos 45 `mat_*` y sirve de muestrario: no la borres. La plantilla
  no se ha migrado y ninguna ficha abierta lo hace (PUL-188 no la menciona). En la v3 el color y el acabado **no
  se definen en Blender**, sino en los 18 `.tres` de `godot/assets/materials/v3/` (art-bible §3.1). Un
  material de Blender solo sirve como **nombre de slot** del `.glb` (regla única, §8.1): cada malla lleva un
  slot con nombre claro y estable, y el `.glb.import` lo redirige a un `.tres` v3 (§5). Ese slot puede ser un
  material plano sin nodos de imagen creado para nombrarlo, o un `mat_*` de la plantilla.
- **Aviso sobre la v2.** El exportador usa `export_image_format="NONE"`: el `.glb` no embebe imágenes aunque el
  `mat_*` v2 tenga PBR, y ya no depende de `godot/assets/textures/v2` (que PUL-188 borra). Pero el **color
  base** del slot v2 sí llega a Godot como un `StandardMaterial3D` con ese nombre y un color fuera de la paleta v3
  hasta que el slot se redirija a un `.tres` v3 (§5): ese paso es obligatorio, ni el export ni el import avisan
  si se olvida.

## 4. Export headless: `tools/blender_export.py`

```sh
# Destino estándar: godot/assets/models/<categoría>/<asset>/<asset>.glb (<asset> = nombre del .blend)
blender -b art/blender/octopus.blend --python tools/blender_export.py -- --category food --max-tris 600
# Destino explícito o personaje con animaciones
blender -b art/blender/character.blend --python tools/blender_export.py -- --category characters --animations
blender -b art/blender/x.blend --python tools/blender_export.py -- --out godot/assets/models/items/x/x.glb
# Prueba de humo: cubo de 1 m sobre la plantilla → godot/assets/models/_pipeline/test_cube/test_cube.glb
blender -b art/blender/_template.blend --python tools/blender_export.py -- --smoke-cube
# Heredado de la v2 (PUL-074), NO es una prueba de la v3 → godot/assets/models/_pipeline/materials_v2_test/
# (no lo ejecutes: reescribiría el .glb versionado con uno sin imágenes. PUL-188 no lo borra: art-bible §3.3.5 mantiene
# `_pipeline/**` como banco excluido; solo borra sus PNG, tras lo cual `--materials-test`, que valida texturas, fallaría)
blender -b art/blender/_template.blend --python tools/blender_export.py -- --materials-test
```

Categorías: `characters`, `food`, `items`, `stations`, `furniture`, `environment` (y `_pipeline`
para pruebas del pipeline). El script **valida antes de exportar** y sale con código 1 si:

- falta la colección `export`, está vacía o tiene más de una raíz;
- algún objeto exportado (mallas, `Empty`, la raíz incluida) tiene escala distinta de (1,1,1) o
  rotación distinta de cero, en local o en mundo (`Ctrl+A → All Transforms`);
- hay cámaras, luces o sufijos de colisión (`-col`, `-colonly`…);
- falta `Anchor_Front`, está sobre el origen o se desvía más de 1° del eje +Y;
- se pasa `--max-tris` y la colección lo supera (presupuestos de art-bible-v1 §2.2);
- (solo `--materials-test`, heredado de la v2) una textura no existe en disco o mide más de 1024 px. Los
  export normales y `--smoke-cube` no comprueban texturas porque no las exportan.

Exporta glTF 2.0 binario solo de la colección `export` (incluidas anidadas), `+Y Up`,
modificadores aplicados, materiales (para conservar los nombres de slot) pero sin imágenes
(`export_image_format="NONE"`), sin tangentes, cámaras,
luces ni *extras*; animaciones y skins solo con
`--animations`. Escribe un resumen `blender_export: OK <ruta> (N objetos, T triángulos, K KiB)`.

**Prueba de humo del exportador (v3).** `--smoke-cube` y la exportación de cualquier asset terminan con
`blender_export: OK`. Para probar sin ensuciar el repo, abre la plantilla (sin guardarla), añade una malla bajo
`asset` y llama al script con `--out` a un directorio temporal fuera de `godot/`. Así se hizo en PUL-194
([`docs/evidence/PUL-194/`](../evidence/PUL-194/)): `.glb` generado y `.glb.import` sembrado con los ajustes de §5.
`--smoke-cube` (con `mat_wood_used` y `mat_plastic_red`, nombres de slot) escribe siempre en
`godot/assets/models/_pipeline/test_cube/` (el cubo está versionado y lo exige `test_assets_models.gd`) y **no admite `--out`**:
combinarlos termina con error para no sobrescribir ese `.glb` sin querer (lo mismo con `--materials-test`). Para probarlo
fuera del repo, copia `tools/` y las dos `.blend` (`_template.blend` y `_materials_v2.blend`) a un árbol temporal y ejecútalo allí.
En PUL-194 se probó así: exit 0, `.glb` de 3 KiB sin imágenes.

## 5. Import en Godot (`.glb.import`)

La primera vez que exporta un `.glb`, `blender_export.py` siembra su `.glb.import` con los ajustes
del pipeline; Godot conserva `[params]` al importar y completa `uid`, rutas y el resto de claves.
Si el `.import` ya existe no se toca (los cambios a mano en el editor se respetan). Ajustes (art-bible v3
§3.2, §3.3 y §9.2):

| Clave | Valor | Por qué |
|---|---|---|
| `gltf/embedded_image_handling` | `0` (descartar todas las texturas) | **Obligatorio** (art-bible v3 §3.3.1): con `1` Godot vuelve a extraer los PNG junto al `.glb`, y la v3 prohíbe las texturas PBR de superficie |
| `materials/extract` | `0` | Obligatorio (`test_assets_models.gd`); los materiales no se extraen, se redirigen |
| `meshes/ensure_tangents` | `false` | Sin normal maps en la v3, no hacen falta tangentes |
| `nodes/root_scale`, `nodes/apply_root_scale` | `1.0`, `true` | 1 u = 1 m; la escala se fija en Blender |
| `nodes/use_name_suffixes`, `nodes/use_node_type_suffixes` | `false` | **Sin generación de colisiones** ni nodos por sufijo: colisiones y nodos de contrato los pone la escena (art-bible-v1 §2.3) |
| `meshes/generate_lods`, `meshes/create_shadow_meshes` | `true` | Por defecto de Godot |
| `meshes/light_baking` | `1` (static) | Por defecto |
| `animation/import`, `animation/fps` | `true`, `30` | Clips del personaje (PUL-044) |
| `gltf/naming_version` | `2` | Nombres de nodos estables |

**Asignación de materiales (paso manual, no lo siembra el script).** Cada slot de material del `.glb` se
redirige a un `.tres` de `res://assets/materials/v3/` dentro de `_subresources["materials"]`:

```
_subresources={
"materials": {
"<slot_name>": {
"use_external/enabled": true,
"use_external/fallback_path": "",
"use_external/path": "res://assets/materials/v3/mat_<nombre>.tres"
}
}
}
```

La tabla slot → material (atlas incluidos) y los slots funcionales que se conservan están en art-bible v3
§3.3 y en [`../evidence/PUL-181/slots_reales.md`](../evidence/PUL-181/slots_reales.md). Un color que falte
en los 18 `.tres` no se arregla en el `.glb`: es una decisión de paleta (art-bible §2 y §3.1).

Estado real de los `.glb.import` existentes: los 40 tienen `embedded_image_handling=0`, pero 30 conservan
`ensure_tangents=true` (sin efecto visual; ninguna ficha abierta lo cambia; si se quiere uniformidad, pedir
ficha al coordinador). Los valores de la tabla rigen para los `.glb` nuevos. Después de
exportar: `godot --headless --path godot --import` y versionar `.glb` y `.glb.import` (ya no se versionan PNG
extraídos). Los `.glb` **no se envuelven en `.tscn`**: la escena de gameplay instancia el
`.glb` bajo su nodo `Model` (`docs/arch/scene-tree.md` §3).

## 6. Comprobación automática: `godot/tests/unit/test_assets_models.gd`

Recorre todos los `.glb` de `godot/assets/models/**` salvo `placeholders/` y comprueba que cada uno:
importa y su raíz es `Node3D`; tiene `.import` con `root_scale = 1`, sufijos desactivados y
`materials/extract` = 0; ningún nodo, **raíz incluida**, tiene escala sin aplicar; su caja de mallas
mide entre 0,05 m y 6 m de alto y ≤ 12 m de planta, con la base en y = 0 (±0,05); tiene
`Anchor_Front` en −Z con ≤ 1° de desviación; no trae cámaras ni luces. Todo se mide en el espacio
del padre de la instancia, así que la transformación de la raíz cuenta. Casos negativos generados en
memoria (raíz escalada y girada, raíz girada, frente ladeado, hijo escalado, base desplazada, sin
marcador, cámara/luz) comprueban que el validador los rechaza. Además exige el cubo de humo `_pipeline/test_cube` y que mida
1 m. Las medidas finas de cada pieza (±10 % de art-bible-v1 §2.1) las revisa la ficha del asset con
la captura en `scale_check`.

## 7. Flujo completo de un asset (resumen para PUL-044..PUL-055)

1. `tools/blender_mcp.sh start` (si se usa el MCP).
2. Copiar la plantilla a `art/blender/<asset>.blend`, renombrar `asset`, modelar en `export` con el
   frente a +Y y el origen en el centro de la base; un slot de material con nombre claro por cada
   material v3 que vaya a usar la malla (nombre de slot según §3 y §8.1; el color no se define en Blender).
   Sin texturas ni UV de textura.
3. `blender -b art/blender/<asset>.blend --python tools/blender_export.py -- --category <cat> --max-tris <N>`.
4. Redirigir los slots del `.glb.import` a los `.tres` v3 (§5), `godot --headless --path godot --import` y
   `tools/verify.sh` (incluye `test_assets_models.gd`).
5. Captura frente a `godot/scenes/scale_check.tscn` en `docs/evidence/<id>/` (con una escena
   temporal que instancie `scale_check.tscn` y el `.glb`; no se versiona).
6. `tools/blender_mcp.sh stop`.

Evidencia del cubo de humo: [`docs/evidence/PUL-043/`](../evidence/PUL-043/).

## 8. Materiales y texturas de la v3 (D28, art-bible v3 §3)

Sustituye al antiguo §8 de la biblioteca v2. Resumen para las fichas de arte; manda
[`art-bible.md`](art-bible.md) §3.

1. **Materiales**: solo los 18 `.tres` de `godot/assets/materials/v3/` (art-bible §3.1): colores planos,
   `metallic = 0`, `specular_mode = SPECULAR_DISABLED`, sin albedo, ORM ni normal. El color y el acabado
   no se definen en Blender: en Blender solo existe un slot con nombre (material plano sin nodos de imagen, o un
   `mat_*` de la plantilla) y se reutiliza el `.tres` por slot (§5).
2. **Texturas 3D prohibidas** (art-bible §3.2.1): ninguna textura de ruido/desgaste, ningún `*_orm.png` ni
   `*_normal.png`. Ni se hornean atlas ni se proyecta UV de caja. Excepciones, y solo estas:
   `mat_tent_plate.tres` con `res://assets/models/environment/romeria_v2/tent_plate_albedo.png` (cartel de marca)
   y los iconos planos de UI y señalética listados en art-bible §3.2.2.
3. **Export**: el `.glb` no necesita llevar texturas útiles; `blender_export.py` exporta sin imágenes
   (`export_image_format="NONE"`) y, con `gltf/embedded_image_handling = 0`, Godot descartaría las que hubiera.
   Solo `--materials-test` (v2) valida existencia y tamaño de texturas.
4. **Import**: `.glb.import` con `embedded_image_handling = 0`, `materials/extract = 0` y los slots redirigidos
   (§5). Un `.glb` nuevo no genera PNG ni `.png.import` que versionar, salvo la excepción de §8.2; los PNG existentes los borra PUL-188 (§8.6).
5. **Atlas multicolor y slots compartidos**: se resuelven con la tabla de art-bible §3.3.3-§3.3.5; la
   variación por estado (crudo/cocido/quemado) se hace con visibilidad de nodos o `surface_material_override`
   en la escena dueña, no con texturas.
6. **Lo que aún existe de la v2**. PUL-188 borra `godot/assets/materials/v2/`, `godot/assets/textures/v2/` y los PNG
   extraídos junto a los `.glb` (incluidos los de `_pipeline/`). No figura en su `owns` y sigue: `art/blender/_materials_v2.blend` (enlazada por `_template.blend`; ninguna
   ficha migra la plantilla: si PUL-188 borra `textures/v2`, un `.blend` con `mat_*` v2 solo exporta con el
   exportador de PUL-194, que ya no lee texturas), `materials-v2.md` y el banco
   `_pipeline/materials_v2_test/` (el `.glb` se queda, excluido por art-bible §3.3.5, sin sus PNG; su destino es PUL-201). No se usan como referencia de ningún asset nuevo y no se re-exportan.
