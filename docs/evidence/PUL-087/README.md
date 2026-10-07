# PUL-087 — QA visual y de rendimiento de la estética v2

Rama `jrmougan/pul-087` sobre `jrmougan/agentica-migracion-godot-alpha` (M3b mergeado:
PUL-072..086, 088, 089). Fecha: 2026-10-07. Máquina: RTX 3090, Godot 4.7.2 Forward+.

## Contenido

| Ruta | Qué es |
|---|---|
| `despues/` | Mismo plano que `style-refs/actual-2026-10-06/` (`capture_style_refs.gd`, 1920×1080, Xvfb) |
| `ac1_comparativa_nivel.png` | Referencia / antes (v1) / progreso (07-10) / después |
| `ac1_comparativa_hud.png` | Referencia y después con HUD |
| `ac1_zona_{cocina,puestos,carpa}.png` | Misma zona en referencia, antes y después |
| `zoom_ollas_pizarras.png`, `zoom_estanteria_bandejas.png` | Detalle de desajustes |
| `ac1_luminancia.txt` | `PUL-073/check_luminance.py` sobre `despues/00` (§6.1-6) |
| `ac1_color_global.txt`, `color_stats.py` | Luma, contraste, saturación y calidez frente a la referencia |
| `make_comparativa.py` | Genera las láminas |
| `measure_perf.gd`, `perf/*.json`, `perf/*.jpg` | Medición de rendimiento (AC2) |
| `perf/base_mem.gd` | Memoria de texturas sin nivel (solo Environment + sol con sombra) |
| `partidas/` | Partidas completas con el MCP (AC3) |
| `render_blend.py`, `render_environment_v2.png` | Render de `art/blender/environment_v2.blend` (Blender 5.2 por CLI, sin puerto) |

## AC2 — rendimiento a 1920×1080 (pantalla real, sin vsync ni límite de fps)

Partida real arrancada con `GameState.start_level`, 60 s medidos tras 240 frames de calentamiento,
jugadores moviéndose y pulsando interactuar con acciones del InputMap.

| Modo | Tilt-shift | fps medios | Frame medio / p99 | GPU medio / p99 | Draw calls (p99) |
|---|---|---|---|---|---|
| Individual | no | **426** | 2,35 / 3,30 ms | **1,28 / 1,29 ms** | 699 |
| Individual | sí | 385 | 2,60 / 3,52 ms | 1,51 / 1,52 ms | 697 |
| Local 2P | no | 423 | 2,36 / 3,31 ms | 1,29 / 1,30 ms | 726 |
| Local 2P | sí | 382 | 2,61 / 3,54 ms | 1,52 / 1,53 ms | 728 |

(El máximo de ~570 ms de cada JSON es el frame de la captura de pantalla a mitad de medición.)

Frente a §4.3 de la biblia v2:

| Límite | Medido | Resultado |
|---|---|---|
| 60 fps a 1080p, GPU ≤ 12 ms medio, ≤ 16,6 ms p99 | ≥ 382 fps, GPU ≤ 1,53 ms p99 | **pasa** (×8 de margen) |
| ≤ 1 000 draw calls | 690–729 | pasa |
| ≤ 60 materiales distintos en pantalla | **60 nombres**, pero **235–239 recursos** de material | pasa por nombre, falla por recurso (D5) |
| ≤ 8 luces dinámicas, ≤ 2 con sombra además de la direccional | 5 omni sin sombra + 1 direccional | pasa |
| Escena en pantalla ≤ 250 000 tris (§4.1) | 80 100 tris de malla visibles; 149 000 primitivas por frame contando el pase de sombras | pasa |
| Memoria de texturas del nivel ≤ 256 MB (§4.2) | 412 MB en total = 314 MB de render (buffers, sombras, cielo; `perf/base_mem.gd`) + ~97 MB de assets | pasa en assets, ambiguo en total (D6) |

Memoria de vídeo total: 477 MB (texturas 412, buffers 37).

Coste aislado por efecto (Xvfb, 8 s; el valor absoluto bajo Xvfb no sirve, ver abajo, pero sí la
proporción): SSAO ≈ 20 % del GPU, sombra direccional ≈ 50 % de los draw calls (694 → 367),
glow+ajuste ≈ 6 %, bombillas ≈ 4 %, tilt-shift ≈ +18 % en pantalla real.

**Ojo con Xvfb**: bajo `xvfb-run` el mismo nivel da 12 fps y 21 ms de GPU; es un artefacto de la
presentación de Vulkan sobre Xvfb (con todo apagado sigue en 14 ms). Las medidas válidas son las de
pantalla real.

## AC3 — partidas completas con el MCP

Godot MCP (`run_project` en modo background). Por modo: menú → modo → nivel con input real
(teclado con `tests/integration/level_walker.gd` inyectado por `run_script`: nevera → olla,
cachelera → olla, estantería → bandeja, ir al puesto), la ronda entera de 300 s hasta el game
over; después Salir → menú → Local 2P, y en 2P Reintentar → pausa con Esc.

| Partida | Errores de juego en consola |
|---|---|
| Individual (300 s, game over) | 0 |
| Local 2P (300 s, game over, reintentar, pausa) | 0 |

El único `SCRIPT ERROR` del log es de un `run_script` mío mal tipado (el iterador sin tipo), no del
juego. Las ejecuciones de `-s` (capturas y medición) acaban con el aviso habitual de recursos y
ObjectDB al salir con `quit()`, también presente en `tools/verify.sh`.

Notas de herramienta (no son del juego):
- `run_project` del MCP no admite `--audio-driver Dummy`: el audio se silenció con
  `AudioServer.set_bus_mute` en el primer `run_script` (1–2 s tras arrancar; el menú pudo sonar
  ese instante).
- En modo background la ventana oculta va a **1 fps** por el vsync de XWayland; se arregla con
  `DisplayServer.window_set_vsync_mode(VSYNC_DISABLED)` + `Engine.max_fps = 60` en `run_script`.
  La ventana del MCP es 1280×757, no 16:9.

## AC1 — desajustes frente a la referencia, por asset

Gravedad: **A** afecta a la legibilidad o a un límite de la biblia; **M** se nota frente a la
referencia; **B** cosmético o deuda técnica. Ninguno se ha arreglado aquí (fuera de `owns`).

| # | Asset (ficha) | Desajuste | Grav. | Propuesta |
|---|---|---|---|---|
| D1 | Puestos de entrega (PUL-083) | El rótulo de comanda (`#1`, `#2`, `–`) perdió la tarjeta blanca de la v1: texto oscuro directamente sobre las rayas del toldillo; en rojo/azul se lee peor, y el guion sobre amarillo casi se pierde (`ac1_zona_puestos.png`) | A | Devolver una placa clara detrás del rótulo (o texto claro con contorno), §3/§6 |
| D2 | Cocedores (PUL-078) | El vapor apenas se ve (8 esferas pequeñas); la referencia tiene dos columnas de vapor claras que dicen «aquí se cuece» | M | Más partículas/tamaño y alfa suave, solo con la olla cociendo (ya lo gobierna `cooking_station.gd`) |
| D3 | Cocedores (PUL-078) | La tapa abierta, vista desde la cámara, se lee como un disco gris flotando sobre la olla (`zoom_ollas_pizarras.png`) | B | Inclinarla menos o apoyarla contra el muro/bisagra visible |
| D4 | Ambiente (PUL-073/085) | Más claro y amarillo que la referencia: luma media 0,51 frente a 0,42, contraste 0,147 frente a 0,165, tono 41° frente a 31° (`ac1_color_global.txt`); lo amarillo viene sobre todo del suelo de arena | M | `render_config.tres`: `ambient_light_energy` 0,5 → 0,4 y `adjustment_contrast` 1,1 → 1,15; suelo algo más pardo/oscuro (PUL-085). Saturación (0,38) ya por encima de la referencia (0,31), no tocarla |
| D5 | Materiales de los .glb (PUL-084/085) | 60 materiales distintos por nombre (justo el límite de §4.3) pero **239 recursos**: cada .glb embebe su copia de `mat_steel_*`, `mat_rubber`, etc. Sin efecto medible en fps | M | Ficha de pipeline: materiales externos compartidos (`assets/materials/v2/*.tres`) al importar los .glb |
| D6 | Texturas de los .glb (PUL-084) | 410 PNG importados, solo 69 distintos (341 duplicados): ~95 MB de texturas para ~16 MB únicos. La memoria de texturas total es 412 MB, de los que 314 MB son de render (buffers, sombras, cielo) | M | Misma ficha que D5 (deduplicar al importar) y aclarar en §4.2 si los 256 MB cuentan solo assets |
| D7 | Encimeras delanteras (PUL-084/089) | El acero de la fila de delante (Z1, junto a los kioscos) y la columna derecha salen casi blancos con manchas de brillo de las bombillas; en la referencia el acero es gris azulado mate | B | Bajar `specular`/subir roughness en `mat_steel_brushed_top` o la energía especular de las omni |
| D8 | HUD «Turno» (PUL-086) | A 1080p tapa la mesa de comensales izquierda (Z3, no jugable); en ventanas más estrechas (1280×757 del MCP) llega al borde de la encimera izquierda y la estantería | B | Aceptable; si se quiere, panel más bajo o semitransparente fuera de 16:9 |
| D9 | Restos de la v1 | Ninguno visible. Quedan ocultos: los 9 `PassSlot` instancian `assets/models/placeholders/table_square.tscn` (`visible = false`, colisión 0) y `art/blender/romeria.blend` (fuente v1) sigue en el repo | B | Limpiar en una ficha de deuda (cambia `slot.tscn` y `level_01.tscn`) |

Sin desajuste: siluetas y estados crudo/cocido/quemado se distinguen; pegatinas de la sal en
blanco con anillo de tinta, coherentes en ticket, tanque y estación (PUL-086); colores por puesto
y aros de jugador; marca PulpaSA en cartel, toldo, tickets, pausa y game over; ninguna zona
jugable fuera de 0,08–0,95 de luminancia por mediana (`ac1_luminancia.txt`). Las encimeras vacías
frente a las cargadas de la referencia son decisión de §5 (lo jugable limpio), no desajuste.
