# Pipeline de arte: Blender → glTF → Godot

Autor: PUL-043 (asset-pipeline). Aplica D20 y las reglas técnicas de [`art-bible.md`](art-bible.md)
§2 (que mandan sobre este documento). Todo se ejecuta **desde la raíz del repo**.

## 1. Requisitos

| Pieza | Versión | Nota |
|---|---|---|
| Blender | 5.2.2 LTS (`blender` en el PATH) | El de Fedora avisa de OCIO 2.5 vs 2.4 y de que faltan Draco/MeshOptimizer: son avisos inocuos (usa color management de reserva y no comprimimos mallas) |
| Add-on MCP de Blender Lab | 1.0.3 (extensión `lab_blender_org.mcp`, ≥ Blender 5.1) | Instalado en `~/.config/blender/5.2/extensions/` (Windows: `%APPDATA%\Blender Foundation\Blender\5.2\extensions\`). Abre un socket TCP local. Tras instalarlo desde la interfaz, **guarda las preferencias**: si no, el Blender `-b` no lo carga y `-c blender_mcp` no existe |
| Servidor MCP `blender-mcp` | Blender Lab `lab/blender_mcp` @ `dbbf836ad4b1025f14a2b3b504c43903f39e0b04` (subdirectorio `mcp`) | Fijado en `.mcp.json` y lanzado con `uvx` (uv de `mise.toml`). El primer arranque compila el paquete (~1 min) y Claude lo da por caído: lánzalo una vez a mano para llenar la caché de uv |
| Godot | 4.7.2 | Importador glTF nativo |

## 2. MCP de Blender

**Alta**: la entrada `blender` de `.mcp.json` (y `enabledMcpjsonServers` en `.claude/settings.json`)
la aprobó el responsable (gate humano; `.mcp.json` no pertenece a ninguna ficha de asset). No se
cambia su versión sin otra aprobación.

```json
"blender": {
  "command": "uvx",
  "args": ["--from", "git+https://projects.blender.org/lab/blender_mcp.git@dbbf836ad4b1025f14a2b3b504c43903f39e0b04#subdirectory=mcp", "blender-mcp"],
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
| Ejecutar código | `execute_blender_code` (Blender conectado), `execute_blender_code_for_cli` (abre un `.blend` en un Blender `-b` aparte) | Modelado por `bpy`/`bmesh`; asignar materiales `mat_*` |
| Inspección de escena | `get_objects_summary`, `get_object_detail_summary` | Comprobar colecciones, jerarquía, escala/rotación |
| Inspección de `.blend` | `get_blendfile_summary_datablocks`, `…_missing_files`, `…_of_linked_libraries`, `…_path_info`, `…_usage_guess` (y variantes `_for_cli`) | Revisar un `.blend` sin abrirlo en la sesión |
| Imagen | `render_thumbnail_to_path`, `render_viewport_to_path`, `get_screenshot_of_window_as_image`, `get_screenshot_of_area_as_image`, `get_screenshot_of_window_as_json` | Capturas de revisión (las de ventana requieren Blender con interfaz) |
| Navegación de UI | `jump_to_tab_by_name`, `jump_to_tab_by_space_type`, `jump_to_view3d_object_by_name`, `jump_to_view3d_object_data_by_name` | Solo con interfaz; no se usan en headless |
| Documentación | `search_api_docs`, `get_python_api_docs`, `search_manual_docs` | API `bpy` y manual de Blender 5.x |

## 3. Plantilla `art/blender/_template.blend`

Punto de partida de **todo** asset: ábrela y guárdala como `art/blender/<asset>.blend` (un `.blend`
por ficha, art-bible §2.4). Contiene:

- **Unidades**: métrico, `Unit Scale = 1.0`, longitud en metros (1 u Blender = 1 m = 1 u Godot), 30 fps.
- **Colección `export`**: lo único que se exporta. Trae un `Empty` raíz `asset` (renómbralo con el
  nombre del asset; todo lo exportable cuelga de él) y el marcador **`Anchor_Front`** en (0, 0,5, 0),
  delante (+Y) y sin rotación (una esfera pequeña). Modela el frente hacia +Y; el exportador lo convierte en −Z de Godot. No lo
  borres: `test_assets_models.gd` lo usa para comprobar la orientación.
- **Colección `reference`** (no se exporta, no renderiza): `ref_character_1_8m` (caja de 0,6 × 0,3
  × 1,8 m, origen en la base) y `ref_counter_1m` (encimera de 1 × 0,8 × 1 m) en alámbrico, y la
  flecha `ref_front_+Y`.
- **Materiales v2** (art-bible v2 §3, PUL-074): los 45 `mat_*` de `art/blender/_materials_v2.blend`,
  **enlazados** (link, ruta relativa `//_materials_v2.blend`; por eso el `.blend` del asset debe vivir
  en `art/blender/`). La tira `ref_materials_v2` de `reference` los mantiene vivos y sirve de muestrario.
  Reutilízalos; no crees materiales a mano. Catálogo y convenciones en [`materials-v2.md`](materials-v2.md).
  Los 32 colores planos de la v1 ya no están en la plantilla (los `.blend` de M3 conservan su copia).

## 4. Export headless: `tools/blender_export.py`

```sh
# Destino estándar: godot/assets/models/<categoría>/<asset>/<asset>.glb (<asset> = nombre del .blend)
blender -b art/blender/octopus.blend --python tools/blender_export.py -- --category food --max-tris 600
# Destino explícito o personaje con animaciones
blender -b art/blender/character.blend --python tools/blender_export.py -- --category characters --animations
blender -b art/blender/x.blend --python tools/blender_export.py -- --out godot/assets/models/items/x/x.glb
# Prueba de humo: cubo de 1 m sobre la plantilla → godot/assets/models/_pipeline/test_cube/test_cube.glb
blender -b art/blender/_template.blend --python tools/blender_export.py -- --smoke-cube
# Asset de prueba de la biblioteca v2 → godot/assets/models/_pipeline/materials_v2_test/ (PUL-074)
blender -b art/blender/_template.blend --python tools/blender_export.py -- --materials-test
```

Categorías: `characters`, `food`, `items`, `stations`, `furniture`, `environment` (y `_pipeline`
para pruebas del pipeline). El script **valida antes de exportar** y sale con código 1 si:

- falta la colección `export`, está vacía o tiene más de una raíz;
- algún objeto exportado (mallas, `Empty`, la raíz incluida) tiene escala distinta de (1,1,1) o
  rotación distinta de cero, en local o en mundo (`Ctrl+A → All Transforms`);
- hay cámaras, luces o sufijos de colisión (`-col`, `-colonly`…);
- falta `Anchor_Front`, está sobre el origen o se desvía más de 1° del eje +Y;
- se pasa `--max-tris` y la colección lo supera (presupuestos de art-bible §2.2);
- una textura de un material exportado no existe en disco o mide más de 1024 px (art-bible v2 §4.2).

Exporta glTF 2.0 binario solo de la colección `export` (incluidas anidadas), `+Y Up`,
modificadores aplicados, materiales con sus texturas embebidas y tangentes (para los normal maps),
sin cámaras, luces ni *extras*; animaciones y skins solo con
`--animations`. Escribe un resumen `blender_export: OK <ruta> (N objetos, T triángulos, K KiB)`.

## 5. Import en Godot (`.glb.import`)

La primera vez que exporta un `.glb`, `blender_export.py` siembra su `.glb.import` con los ajustes
del pipeline; Godot conserva `[params]` al importar y completa `uid`, rutas y el resto de claves.
Si el `.import` ya existe no se toca (los cambios a mano en el editor se respetan). Ajustes:

| Clave | Valor | Por qué |
|---|---|---|
| `nodes/root_scale`, `nodes/apply_root_scale` | `1.0`, `true` | 1 u = 1 m; la escala se fija en Blender |
| `nodes/use_name_suffixes`, `nodes/use_node_type_suffixes` | `false` | **Sin generación de colisiones** ni nodos por sufijo: colisiones y nodos de contrato los pone la escena (art-bible §2.3) |
| `materials/extract` | `0` | Materiales embebidos en el `.glb` (`StandardMaterial3D` importado); se sustituyen en la escena si hace falta |
| `meshes/ensure_tangents` | `true` | Normal maps de la biblioteca v2 (art-bible v2 §3.2); los `.import` anteriores a PUL-074 siguen con `false` (no tienen normal maps) |
| `meshes/generate_lods`, `meshes/create_shadow_meshes` | `true` | Por defecto de Godot |
| `meshes/light_baking` | `1` (static) | Por defecto |
| `animation/import`, `animation/fps` | `true`, `30` | Clips del personaje (PUL-044) |
| `gltf/naming_version`, `gltf/embedded_image_handling` | `2`, `1` (extraer texturas) | Las texturas embebidas se extraen como `<asset>_<imagen>.png` junto al `.glb` (§8) |

Después de exportar: `godot --headless --path godot --import` (o abrir el editor) y versionar
`.glb`, `.glb.import` y las texturas extraídas con sus `.png.import` (§8). Los `.glb` **no se envuelven en `.tscn`**: la escena de gameplay instancia el
`.glb` bajo su nodo `Model` (`docs/arch/scene-tree.md` §3).

## 6. Comprobación automática: `godot/tests/unit/test_assets_models.gd`

Recorre todos los `.glb` de `godot/assets/models/**` salvo `placeholders/` y comprueba que cada uno:
importa y su raíz es `Node3D`; tiene `.import` con `root_scale = 1`, sufijos desactivados y
materiales embebidos; ningún nodo, **raíz incluida**, tiene escala sin aplicar; su caja de mallas
mide entre 0,05 m y 6 m de alto y ≤ 12 m de planta, con la base en y = 0 (±0,05); tiene
`Anchor_Front` en −Z con ≤ 1° de desviación; no trae cámaras ni luces. Todo se mide en el espacio
del padre de la instancia, así que la transformación de la raíz cuenta. Casos negativos generados en
memoria (raíz escalada y girada, raíz girada, frente ladeado, hijo escalado, base desplazada, sin
marcador, cámara/luz) comprueban que el validador los rechaza. Además exige el cubo de humo `_pipeline/test_cube` y que mida
1 m. Las medidas finas de cada pieza (±10 % de art-bible §2.1) las revisa la ficha del asset con
la captura en `scale_check`.

## 7. Flujo completo de un asset (resumen para PUL-044..PUL-055)

1. `tools/blender_mcp.sh start` (si se usa el MCP).
2. Copiar la plantilla a `art/blender/<asset>.blend`, renombrar `asset`, modelar en `export` con el
   frente a +Y y el origen en el centro de la base; materiales `mat_*` enlazados de la biblioteca v2 y
   UV a 1 unidad = 2 m (§8).
3. `blender -b art/blender/<asset>.blend --python tools/blender_export.py -- --category <cat> --max-tris <N>`.
4. `godot --headless --path godot --import` y `tools/verify.sh` (incluye `test_assets_models.gd`).
5. Captura frente a `godot/scenes/scale_check.tscn` en `docs/evidence/<id>/` (con una escena
   temporal que instancie `scale_check.tscn` y el `.glb`; no se versiona).
6. `tools/blender_mcp.sh stop`.

Evidencia del cubo de humo: [`docs/evidence/PUL-043/`](../evidence/PUL-043/).

## 8. Texturas de la biblioteca v2 (PUL-074)

Resumen para las fichas de la v2 (PUL-075..PUL-085); el detalle está en [`materials-v2.md`](materials-v2.md).

1. **Materiales**: solo los `mat_*` enlazados de `_materials_v2.blend` (vienen en la plantilla) más el
   atlas propio del asset (art-bible v2 §3.3). Un color nuevo de una textura neutra se añade al
   generador de la biblioteca, no al `.blend` del asset.
2. **UV**: 1 unidad de UV = 2 m (512 px → 256 px/m); el suelo, 1 UV = 4 m. `box_uv()` de
   `tools/blender_export.py` es la proyección de referencia (la usa `--materials-test`).
3. **Atlas propio**: hornéalo en Blender (≤ 1024², art-bible v2 §4.2) y guárdalo en
   `art/blender/textures/<asset>/` o empaquetado en el `.blend`; conéctalo con los mismos nodos que la
   biblioteca (Image → Mix MULTIPLY → Base Color; ORM → Separate Color G/B × factor; Normal Map).
4. **Export**: el `.glb` **embebe** todas las texturas (las de la biblioteca y el atlas) y
   `blender_export.py` falla si alguna falta en disco o pasa de 1024 px. Así cada `.glb` es
   autocontenido y cumple «materiales embebidos» de `test_assets_models.gd`.
5. **Import**: Godot extrae las imágenes junto al `.glb` (`<asset>_<imagen>.png`). Tras el primer
   import, deja sus `.png.import` con `compress/mode=2`, `mipmaps/generate=true`,
   `detect_3d/compress_to=0` y, en los `_normal`, `compress/normal_map=1`; reimporta y versiona PNG e
   `.import`. Ejemplo: [`godot/assets/models/_pipeline/materials_v2_test/`](../../godot/assets/models/_pipeline/materials_v2_test/).
6. **En escena** (decals, sustituciones, mallas sin UV v2): `godot/assets/materials/v2/mat_*.tres`
   apuntan a las mismas texturas de `godot/assets/textures/v2/`.
