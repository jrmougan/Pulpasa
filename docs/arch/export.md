# Exportación (PUL-010)

Prueba temprana pedida por ADR-005. Presets en `godot/export_presets.cfg`: Linux x86_64,
Windows x86_64 y Web. Plantillas 4.7.2 en `~/.local/share/godot/export_templates/4.7.2.stable`.

## Cómo exportar
```sh
tools/export.sh [linux|windows|web|all]   # salida en build/<plataforma>/ (ignorado por git)
# Probar web en local:
cd build/web && python3 -m http.server 8765   # abrir http://localhost:8765/index.html
# Probar Linux:
build/linux/pulpasa.x86_64 --headless --quit-after 120
```
Se exporta en modo release. Se excluyen `tests/`, `addons/gut/` y `.gut_reports/`.

## Decisiones
- Web usa **Compatibility** vía `rendering/renderer/rendering_method.web="gl_compatibility"`;
  escritorio sigue en Forward+.
- Web **sin hilos** (`variant/thread_support=false`): no necesita `SharedArrayBuffer`, así que no
  exige las cabeceras COOP/COEP y vale cualquier servidor estático (itch.io, `http.server`).
  Coste: sin hilos de audio/físicas/carga en paralelo; revisar si el rendimiento lo pide.
- Sin GDExtension en web.

## Tamaños (release, 2026-10-03, escena boot)
| Build | Total | Detalle |
|---|---|---|
| Linux | 71 MB | ejecutable ~70 MB + `.pck` 556 KB |
| Windows | 105 MB | `.exe` + `.pck` 556 KB (el `.exe` es el binario de la plantilla, sin comprimir) |
| Web | 39 MB | `index.wasm` 38 MB (mucho menos con gzip/brotli en servidor) + `.pck` 556 KB + `index.js` 276 KB |

Los `.pck` son pequeños porque aún solo hay la escena de arranque; el tamaño real crecerá con
mallas y texturas (hipótesis de ADR-005). Medir de nuevo en el spike 3D.

## Verificación
- AC2: build Linux en headless con `--quit-after 120` imprime «Pulpasa boot OK» y sale con 0.
- AC3: Chrome carga `boot.tscn` en web: WebGL 2.0 / Compatibility, sin errores de consola.
  Captura en `docs/evidence/PUL-010/web-boot.jpg`, log en `console-web.txt`.
- Windows: solo se comprueba que exporta; no se ha ejecutado (sin Wine/Windows).

## Limitaciones de Compatibility observadas
Con la escena actual (un cubo) no se aprecian diferencias. Conocidas y a vigilar en el spike 3D:
sin SDFGI/VoxelGI/SSAO/SSR, glow y sombras más limitados, tonemapping/colores algo distintos
a Forward+, y menos luces por objeto. Tampoco se ha medido FPS.
