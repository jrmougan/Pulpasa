# PUL-152: recaptura de D26 con el estado final de M3e

Medidas y capturas de `docs/evidence/PUL-132/` rehechas con el código de `main` en `039c737` (después de
PUL-133, PUL-134 y PUL-138). `level_01` real, con ventana, una ejecución de Godot por resolución.

```sh
bash docs/evidence/PUL-152/run_all.sh   # ~4 min; abre ventanas
```

| Fichero | Origen | Cambio frente al original |
|---|---|---|
| `capture_boot.gd`, `capture_d26.gd` | PUL-132 | Safe area inyectada siempre (la de diseño con `--safe`; si no, **nula**) en la UI, en `TouchControls` y también en `CameraRig` (`set_safe_margins`). Botones en fila (hueco horizontal y bordes inferiores, D27.1) y zona de botones de la cámara. Borde superior real del anillo de la olla (H-01). Textos del game over (H-03). Mismas 14 escenas. |
| `capture_caso09_boot.gd`, `capture_caso09.gd` | PUL-138 `capture_pul138.gd` | 2 safe areas × 2 ollas × 2 posiciones, el activo en reposo con física real, solape con la zona y con las cajas de los discos. `--host-safe` deja la safe area del sistema (para comparar con PUL-136/138). |
| `run_all.sh` | PUL-132 | Resoluciones de AC1 y caso 09. `--disable-vsync`: con la ventana sin foco u ocultada (Wayland), el V-Sync deja el juego a 1 FPS. `--audio-driver Dummy` (sin sonido, regla de `godot-verify`). Aborta si Godot sale con código ≠ 0, si su salida trae `ERROR` o si falta la línea `MEDIDAS` (`set -euo pipefail` y log por ejecución; `GODOT=<ruta>` permite probarlo con un binario simulado). |

Errores de limpieza: la primera versión de `capture_caso09.gd` salía con el nivel aún en el árbol y Godot imprimía
`ERROR: 4 resources still in use at exit` (los `AudioStreamOggVorbis` del ambiente de `level_audio.tscn` en
reproducción). Ahora libera el nivel y espera 0,2 s antes de `quit()`; la recaptura con el runner endurecido sale
con código 0 y sin ningún `ERROR`, y los 10 JSON salen idénticos byte a byte a los de la primera captura (los JPG
committeados se conservan: solo cambiaría su codificación).

Ficheros: `<res>-<perfil>-<NN>-<escena>.jpg` (54: 13 en cada escritorio y 14 en cada táctil),
`<res>-<perfil>-medidas.json` (5), `<res>-caso09-<nula|diseno>-<oeste|este>-<z3_1|z3_4>.jpg` (16),
`<res>-caso09-medidas.json` (3, con 8 vistas cada uno) y `<res>-host-caso09-medidas.json` (2, comparación de H-05).
A 1920×1080 táctil solo hay JSON (el script borra sus JPG, igual que PUL-132).

## Estado por AC
| AC | Resultado | Evidencia |
|---|---|---|
| AC1 | **PASA** | `run_all.sh` genera las 14 escenas a 2340×1080 táctil (safe 132/0/132/63) y 800×370 táctil, y 13 a 1280×720 y 1920×1080 de escritorio (la 02, stick activo, solo existe en táctil, como en PUL-132). Más los JSON de esas 4 y de 1920×1080 táctil. |
| AC2 | **PASA** | Tabla de medidas más abajo: todo OK a 1080 y en táctil. Valores de D27 exactos: acción (2202, 942) y cambiar (2028, 972) con safe nula; (2070, 879) y (1896, 909) con la de diseño; hueco 24 px; bordes inferiores 0 px de diferencia. |
| AC3 | **PASA** | H-01, H-02 y H-03 siguen corregidos (filas propias en la tabla; capturas 07, 09, 10 y 13). |
| AC4 | **PASA** | 24 vistas en `<res>-caso09-medidas.json`; safe nula: 0 px en todas (también 0 a 800×370, por debajo de los ≤ 8 px de D27). Safe de diseño: 6,6 / 35,0 px a 1080 y 2,2 / 12,0 px a 800×370, comparadas con las dos referencias más abajo. 16 JPG. |
| AC5 | ver la ficha | `tools/verify.sh` completo y `tools/check_owns.py`. |

## Tabla de medidas (px reales de pantalla; entre paréntesis, el equivalente a 1080)
Fuente: `<tag>-medidas.json`. CT = `controles-tactiles.md`, LA = `lenguaje-acciones.md`. «PC» = escritorio.
Las columnas de 800×370 sirven para ver composición y solapes, no tamaños (fuera del rango soportado; nota
de PUL-132: `UiScale` limita la escala a [0,67; 1,5]).

| Medida (AC) | Mínimo | 2340×1080 táctil, safe de diseño | 1920×1080 táctil | 1920×1080 PC | 1280×720 PC | 800×370 táctil | Resultado |
|---|---|---|---|---|---|---|---|
| Icono del prompt (LA AC3) | 64 a 1080; 48 a 720 | 64 | 64 | 64 | 48 | 48 | OK |
| Placa del prompt (LA AC3) | 80 a 1080 | 80 | 80 | 80 | 60 | 60 | OK |
| Icono de motivo / aspa (LA) | 32 / 24 a 1080 | 32 / 24 | 32 / 24 | 32 / 24 | 24 / 18 | 24 / 18 | OK |
| Botón de acción, diámetro / zona táctil (CT AC2) | 180 ± 2 / ≥ 204 | 180 / 204 | 180 / 204 | n/a | n/a | 61,7 / 69,9 (180 / 204) | OK |
| Centro de acción (CT AC2, D27.1) | (2070, 879) con safe de diseño; (1782, 942) a 1920 | (2070, 879) | (1782, 942) | n/a | n/a | (752,3, 322,7) | OK |
| Margen de acción a la safe area (CT AC2) | ≥ 48 | 48 / 48 | 48 / 48 | n/a | n/a | 16,4 (48) | OK |
| Cambiar: diámetro, centro (CT AC3, D27.1) | 120 ± 2; (1896, 909) con safe de diseño; (1608, 972) a 1920 | 120; (1896, 909) | 120; (1608, 972) | n/a | n/a | 41,1 (120); (692,7, 333) | OK |
| Cambiar: hueco horizontal / bordes inferiores (CT AC3) | 24 ± 2 / ± 2 | 24 / 0 | 24 / 0 | n/a | n/a | 8,2 (24) / 0 | OK |
| Pausa (CT AC3) | 120 ± 2 en (2100, 108) | 120 en (2100, 108) | 120 en (1812, 108) | n/a | n/a | 41,1 en (762,6, 37) | OK |
| Zona de botones de la cámara (D27.2) | x ≥ ancho − safe der. − 390, y ≥ alto − safe inf. − 240 | 1818, 777 | 1530, 840 | n/a | n/a | 666, 287,8 | OK |
| Stick: base / radio (CT AC4) | 300 / 150 | 300 / 150 | 300 / 150 | n/a | n/a | 102,8 / 51,4 (300 / 150) | OK |
| Texto mínimo (CT AC14) | 36 a 1080 en táctil | 36 | 36 | 19,5 (HUD) | 13 (19,5) | 12,3 (36) | OK en táctil; PC sin cambios (AC21) |
| Botones de menú, pausa y game over (CT AC18) | ≥ 120 de alto, ≥ 24 de hueco | 120; huecos 24 (pausa y game over) | 120 | 78-90 | 52-60 | 41,1 (120) | OK en táctil |
| 4 tickets: ancho, hueco, banda (CT AC15) | 330-380; 16 ± 1; ≤ 200 | 380 / 16 / 174 | 342 / 15 / 174 | n/a | n/a | 130,2 / 5,5 / 59,6 | OK |
| HUD y tickets fuera del stick y de los botones (CT AC16) | 0 solapes | 0 | 0 | n/a | n/a | 0 | OK |
| Px por metro / personaje (CT AC10) | ≥ 120 / ≥ 192 en táctil; 107 ± 2 en PC | 121,6 / 194,5 | 121,6 / 194,5 | 66,8 / 106,9 | 44,5 / 71,3 (106,9) | 41,7 / 66,6 (194,5) | OK |
| Anillo de cocción: trazo / diámetro (LA AC15) | ≥ 8 / ≥ 64 a 1080 | 8 / 64 | 8 / 64 | 8 / 64 | 5,3 / 42,7 (8 / 64) | 2,7 / 21,9 (8 / 64) | OK |
| **H-01** Anillo de la olla con el activo en la fila trasera (−1,3, −3,1): dentro de pantalla y borde superior ≥ 200 a 1080 | sí / ≥ 200 | dentro, 267,2 | dentro, 267,2 | dentro, 353,5 | dentro, 235,6 (353,5) | dentro, 91,5 (267,2) | **OK** (en PUL-132: −65 px, fuera) |
| Barra del contador / numeral (LA AC14) | ≥ 8 / ≥ 36 a 1080 | 16,7 / 68,9 | 16,7 / 68,9 | 9,2 / 37,8 | 6,1 / 25,2 (9,2 / 37,8) | 5,7 / 23,6 (16,7 / 68,9) | OK |
| Muesca del cuenco (LA AC17) | ≥ 24 a 1080 | 24 | 24 | 24 | 16 (24) | 8,2 (24) | OK |
| Aro del activo (LA AC18) | ≥ 8 a 1080 | 10 | 10 | 10 | 6,7 (10) | 3,4 (10) | OK |
| **H-02** Aro del inactivo (LA AC18) | ≤ 3 a 1080 | 2,5 | 2,5 | 2,5 | 1,7 (2,5) | 0,9 (2,5) | **OK** (en PUL-132: 4,6 en móvil) |
| Marcador ▼ del activo; ▼ del inactivo (LA AC18) | ≥ 24; oculto | 28; oculto | 28; oculto | 28; oculto | 24; oculto | 24; oculto | OK |
| Zona de entrega encendida (LA F1) | con la caja que coincide | sí | sí | sí | sí | sí | OK |
| Game over sin controles táctiles | ocultos | ocultos | ocultos | n/a | n/a | ocultos | OK |
| **H-03** Game over sin «cajas/minuto» (D26.7) | ningún texto | «Turno terminado», «Pulpeiro ineficiente», «Recaudación: 0 €» | igual | igual | igual | igual | **OK** |

El anillo de la tabla es el del aviso de quemado (escena 09); en la 07 y la 08 está en el mismo sitio. En PC
`under_top_band` del JSON sale `true` porque la «banda» de escritorio incluye el bloque HUD de abajo
(`band_height_px` 1068): esa medida solo tiene sentido en táctil.

## Caso 09 (AC4)
Solape = alto de la intersección del rectángulo del contador (unión de los visuales proyectados de `%CutCounter`)
con la zona de `CameraRig._button_zone`, en px reales; peor pasaplatos de los 6. Detalle por pasaplatos, posición
real del activo y foco de cámara en `<res>-caso09-medidas.json` (`views.<safe>-<olla>-<z>`). Con física real el
activo queda exactamente donde se coloca (−1,3 / 0,7; −3,1 / −3,4) en las 24 vistas.

| Resolución | Safe | Oeste z −3,1 | Oeste z −3,4 | Este z −3,1 | Este z −3,4 | Pasaplatos con solape | Umbral | Resultado |
|---|---|---|---|---|---|---|---|---|
| 2340×1080 | nula | 0 | 0 | 0 | 0 | — | 0 | OK |
| 1920×1080 | nula | 0 | 0 | 0 | 0 | — | 0 | OK |
| 800×370 | nula | 0 | 0 | 0 | 0 | — | ≤ 8 | OK |
| 2340×1080 | diseño | 6,6 | 35,0 | 6,6 | 35,0 | 04-06 | sin umbral (D27.3) | registrado |
| 1920×1080 | diseño | 6,6 | 35,0 | 6,6 | 35,0 | 04 (oeste), 04-06 (este) | sin umbral | registrado |
| 800×370 | diseño | 2,2 | 12,0 | 2,2 | 12,0 | 04-06 | sin umbral | registrado |

Con la safe de diseño, frente a las dos referencias previas (px reales):

| Resolución | Vista | Medido | ADR-005 D27.3 (estimación) | `test_camera_button_zone.gd` (PUL-138) | Diferencia > 2 px y por qué |
|---|---|---|---|---|---|
| 2340×1080 | oeste z −3,1 | 6,6 | 20,8 | 6,6 | −14,2 con la ADR: H-05 |
| 2340×1080 | oeste z −3,4 | 35,0 | 51,0 | 35,1 | −16,0 con la ADR: H-05 |
| 2340×1080 | este z −3,1 | 6,6 | 22,6 | 6,6 | −16,0 con la ADR: H-05 |
| 2340×1080 | este z −3,4 | 35,0 | 51,0 | 35,1 | −16,0 con la ADR: H-05 |
| 1920×1080 | oeste z −3,1 | 6,6 | 20,8 | 6,6 | −14,2 con la ADR: H-05 |
| 1920×1080 | oeste z −3,4 | 35,0 | 51,0 | 35,1 | −16,0 con la ADR: H-05 |
| 1920×1080 | este z −3,1 | 6,6 | 22,6 | 6,6 | −16,0 con la ADR: H-05 |
| 1920×1080 | este z −3,4 | 35,0 | 51,0 | 35,1 | −16,0 con la ADR: H-05 |
| 800×370 | oeste z −3,1 | 2,2 | 17,7 | 2,2 | −15,5 con la ADR: H-05 |
| 800×370 | oeste z −3,4 | 12,0 | 28,0 | 12,0 | −16,0 con la ADR: H-05 |
| 800×370 | este z −3,1 | 2,2 | 18,3 | 2,2 | −16,1 con la ADR: H-05 |
| 800×370 | este z −3,4 | 12,0 | 28,0 | 12,0 | −16,0 con la ADR: H-05 |

- **Con el test de PUL-138 coincide** (≤ 0,1 px): con el código actual, la física no mueve al activo, el recorte este
  no cambia el foco en z (solo en x: `CameraFollow.clear_east_cover`) y el redondeo de `SafeAreaMargin` no afecta a
  la zona de la cámara (la cámara usa márgenes sin redondear; los botones sí redondean: a 800×370 la safe de diseño
  da 45,2 / 21,58 en la cámara y 45,22 / 21,58 en `SafeAreaMargin`, < 0,1 px).
- **Con la estimación de la ADR difiere ~16 px en todas las vistas** y por la misma causa, comprobada: los rectángulos
  de contador que usó (PUL-136, «actual») se midieron con la safe area del sistema de la máquina de captura, que tiene un
  panel superior de 32 px (`DisplayServer.get_display_safe_area()` = (0, 32, 2560, 1408)). `CameraRig` sumó esos 32 px a
  la banda superior y el foco quedó 0,15-0,17 m más al norte (−4,30 / −4,62 frente a −4,153 / −4,453), con los contadores
  ~16 px más abajo en pantalla. `<res>-host-caso09-medidas.json` (`--host-safe`, safe del sistema en la pasada nula)
  reproduce sus datos al décimo: contador del 06 en y = 648,4 (PUL-136: 648,3) y foco −4,621 a 2340×1080; y = 232,6
  (PUL-138: 232,6) y **6,4 px** de solape en z −3,4 a 800×370, que es el «residuo de 6,4 px» de PUL-136, PUL-138 y D27.
  Con una safe area nula de verdad ese residuo es 0. Ver H-05.
- **Rectángulo del contador usado:** es la unión de las AABB de los visuales (numeral `Label3D` incluido), más alta que lo
  que se ve. En `2340x1080-caso09-diseno-*-z3_4.jpg` la barra visible del contador acaba hacia y ≈ 740 (lectura de la
  captura, ± 5 px), por encima de la zona (777) y del disco de acción (789): el solape de 35 px es del rectángulo, no del
  dibujo. Solape con los discos visibles (caja del círculo): 0 en z −3,1 y 23,0 (7,9 a 800×370) en z −3,4, también con el
  rectángulo conservador (`max_overlap_disc_box_px`).

## Hallazgos
| Id | Gravedad | Hallazgo | Dónde |
|---|---|---|---|
| H-01 | — | **Corregido.** El anillo de la olla está dentro de pantalla y bajo la banda superior en móvil (borde superior 267,2 a 1080). | capturas 07-09 |
| H-02 | — | **Corregido.** Aro del inactivo 2,5 px a 1080 en móvil y PC. | captura 10 |
| H-03 | — | **Corregido.** Game over sin «cajas/minuto». | captura 13 |
| H-05 | Media | **La safe area del sistema no es nula en un escritorio Linux con panel** y se aplica a la ventana: `DisplayServer.get_display_safe_area()` devuelve el área de trabajo del monitor (sin el panel de 32 px de GNOME) en coordenadas de pantalla, y `UiScale.safe_margins` la cruza con el tamaño de la ventana sin tener en cuenta dónde está. Efectos medidos (primera ejecución, sin inyectar): a 1920×1080 táctil la pausa baja a (1812, 139,5), la banda superior mide 205,5 px (> 200, falso KO de CT AC15/AC16) y en escritorio los tickets bajan 31,5 px; la cámara móvil desplaza el foco 0,15 m. Consecuencia en la documentación: las cifras del caso 09 de PUL-136, PUL-137 (ADR-005 D27.3) y la captura de PUL-138 (6,4 px a 800×370, 20,8-51,0 px con la safe de diseño) llevan esos 32 px; los valores con safe nula de verdad son 0 y 2,2-35,0 px. No afecta a Android/iOS (allí la safe area es la del dispositivo), sí a quien juegue en ventana en Linux y a cualquier evidencia capturada sin inyectar la safe area. Propuesta para el responsable: (a) solo documental, corregir las cifras de D27.3 y del residuo de D27 con estas; (b) además, ignorar la safe area del sistema en el perfil de escritorio. | `godot/ui/widgets/ui_scale.gd` (`safe_margins`), `safe_area_margin.gd`, `camera_rig.gd` (`_current_safe_margins`); ADR-005 D27.3 |
| H-06 | Baja | Con la ventana sin foco u ocultada (Wayland) el juego va a 1 FPS con V-Sync: las capturas de PUL-132 y PUL-138 tardan ~15 s por vista. Solo afecta a las herramientas de evidencia; `run_all.sh` usa `--disable-vsync`. | `run_all.sh` |

(H-04 de PUL-132, el panel de GUT, no se revisa aquí: no es de D26 ni de capturas.)

No encontrado: ningún solape de HUD/tickets con el stick, los botones o la pausa; ningún texto táctil < 36 px a 1080;
ninguna regresión en escritorio frente a PUL-132 (mismas medidas; el aro del activo pasa de 10,2 a 10 px por el trazo
constante de PUL-133).
