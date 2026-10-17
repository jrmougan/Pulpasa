---
id: PUL-180
title: Explorar una estética minimalista y proponer direcciones para elegir
status: done
milestone: M3f
role: game-designer
deps: []
orca_task: task_538481a1af8b
unity_sources: []
owns: [docs/art/minimal/**, docs/evidence/PUL-180/**, docs/backlog/PUL-180-explorar-estetica-minimalista.md]
touches_scenes: []
---

## Target
El responsable quiere darle una vuelta al arte hacia algo **más minimalista** (2026-10-17). Estado
actual: estética v2 (D22), un diorama detallado de puesto callejero según `docs/art/art-bible.md` y
`docs/art/style-refs/referencia-elegida-2026-10-06.png`, con texturas, desgaste y atrezo denso de
fondo. Restricciones que siguen vigentes: D14 (3D, cámara ortográfica fija), D16 (solo licencias
confirmadas: nada de imágenes ni assets de terceros), D20 (arte propio hecho en Blender por agente),
D21 (marca **PulpaSA**), D26 (lenguaje de acciones, iconos y legibilidad, también en móvil a 800×370) y
§3.4 de la biblia v1 (colores de pegatinas y condimentos, que identifican la jugabilidad).

## Change
1. **Estado de partida:** captura el nivel actual sin HUD y con HUD a 1920×1080, y una vista móvil a
   800×370. Copia y adapta un script de captura (por ejemplo, `docs/evidence/PUL-152/capture_boot.gd`
   o `docs/art/style-refs/capture_style_refs.gd`, que está desfasado: la caja es única y la API es
   `apply_seasoning`) en `docs/evidence/PUL-180/`.
2. **3 direcciones minimalistas distintas** en `docs/art/minimal/`, por ejemplo: color plano sin
   texturas y con sombras suaves; formas geométricas puras con una paleta muy reducida; un estilo
   «papel o maqueta blanca» con acentos de color solo en lo jugable. Para cada una:
   - nombre y una frase de intención;
   - paleta cerrada en hex (fondo, superficies, jugables, acentos de estado, UI);
   - reglas de forma, material, luz y post-proceso;
   - qué atrezo desaparece o se simplifica;
   - cómo se leen los estados (crudo, cocido, quemado, caja llena, aliños) y los colores de §3.4;
   - impacto en la UI y el HUD.
3. **Una imagen por dirección**, comparable con la de partida (misma cámara, composición y
   posición de cada elemento). Vale una imagen generada a partir de la captura propia (no de
   terceros) o, mejor, un **prototipo en el motor**: un script en `docs/evidence/PUL-180/` que, en
   tiempo de ejecución, sustituya materiales, luz y entorno y oculte el atrezo antes de capturar, sin
   tocar escenas ni recursos versionados. Indica en cada imagen cómo se obtuvo.
4. **Comparativa y recomendación** en `docs/art/minimal/README.md`:
   - tabla de las 3 direcciones frente a la v2 (legibilidad a 1080p y a 800×370, coherencia con la
     marca PulpaSA, coste estimado de rehacer assets: qué `.glb`, materiales y escenas tocaría, y
     rendimiento esperado);
   - la recomendación;
   - las preguntas para el responsable.

## Constraints
- Exploración: **no se cambia** código de juego, escenas, `.tres`, `.glb`, materiales ni la biblia.
  Todo lo nuevo va en `docs/art/minimal/` y `docs/evidence/PUL-180/`.
- Nada de imágenes, fuentes ni assets de terceros (D16). Las imágenes generadas parten solo de
  capturas propias del juego.
- La elección es del responsable (gate humano). Después vendrán la biblia v3 y las fichas de
  implementación, que no forman parte de esta ficha.

## Acceptance
- [x] AC1 Given el juego en `main`, When se ejecuta el script de captura, Then hay al menos 3 capturas
  de partida (1920×1080 sin HUD y con HUD, 800×370) en `docs/evidence/PUL-180/partida/`, y la salida
  del script no tiene ningún ERROR.
- [x] AC2 Given las 3 direcciones, When se abre `docs/art/minimal/`, Then cada una tiene un documento
  con los 6 apartados del punto 2 del Change y una paleta de entre 8 y 16 colores en hex, y los
  colores de §3.4 se distinguen entre sí: contraste ≥ 3:1 frente a la superficie donde aparecen
  (tabla calculada en la evidencia).
- [x] AC3 Given cada dirección, When se compara su imagen con la de partida, Then conserva la cámara y
  la posición de los 4 puestos, las 2 ollas, la barra y los 2 cocineros (comprobación visual
  anotada), y dice si es generada o un prototipo en el motor.
- [x] AC4 `docs/art/minimal/README.md` tiene la tabla comparativa con las 4 columnas (v2 + 3
  direcciones), la recomendación y al menos 3 preguntas para el responsable.
- [x] AC5 `tools/verify.sh --quick` en verde y `tools/check_owns.py` limpio.

## Plan
1. **Inspección de árbol de escena y materiales en vivo:** listar los nodos, mallas (`MeshInstance3D`) y nombres de materiales de `level_01.tscn` en tiempo de ejecución para mapear qué elementos son jugables (Z0/Z1/Z2) y cuáles son atrezo secundario o fondo (Z3).
2. **Script de captura y prototipo en el motor (`docs/evidence/PUL-180/`):**
   - Crear `capture_boot.gd` y `capture_minimal.gd` (con tipado estático estricto, sin errores de consola) que escenifiquen una partida representativa (comandas activas, pulpo crudo en mostrador, pulpo cociendo/cocido/quemado, caja llena con aliño y cachelos, caja en corte en pasaplatos, cocineros posicionados) usando la API vigente (`box.tres`, `apply_seasoning`).
   - Capturar el **estado de partida (v2)** en `docs/evidence/PUL-180/partida/`: `1920x1080_sin_hud.png`, `1920x1080_con_hud.png` y `800x370_movil.png` (con perfil móvil y cámara móvil de D26/D27).
   - Implementar en el mismo prototipo de motor la transformación en caliente (sin tocar escenas ni recursos versionados) de las **3 direcciones minimalistas** (sustitución de materiales por `StandardMaterial3D` lisos sin texturas de ruido/desgaste, ajuste de `WorldEnvironment`, `DirectionalLight3D`, `OmniLight3D` y viñeta, y ocultación selectiva de atrezo Z3/Z1), generando las capturas equivalentes para cada dirección.
3. **Diseño de las 3 direcciones minimalistas (`docs/art/minimal/`):**
   - **Dirección A (`direccion-a-color-plano.md`) — «Feira Clara» (Color plano cálido y sombras suaves):** evolución limpia de la romería gallega y PulpaSA sin texturas de desgaste ni ruido, con sombreado suave, iluminación diurna limpia y atrezo perimetral simplificado en bloques de color plano. Paleta cerrada de 16 colores hex.
   - **Dirección B (`direccion-b-geometrica.md`) — «Bloques de Romería» (Geometría pura y paleta gráfica reducida):** abstracción geométrica rotunda con paleta reducida (14 colores hex), alto contraste gráfico, sombras duras nítidas, eliminación total de atrezo decorativo Z3 y lectura tipo tablero táctico.
   - **Dirección C (`direccion-c-maqueta-papel.md`) — «Maqueta de Papel» (Blanco arquitectónico con acentos jugables):** estética de maqueta de papel/cartón pluma monocroma (`brand_paper` y grises cálidos de granito) donde **solo** tienen color saturado los objetos jugables, los estados de cocción, los aliños (§3.4), los puestos y los cocineros. Paleta cerrada de 15 colores hex.
4. **Cálculo de contrastes (§3.4 y estados) y comprobación visual (`docs/evidence/PUL-180/`):**
   - Script en Python (`build_evidence.py`) que calcule las tablas de contraste WCAG de luminancia relativa de los colores de §3.4 y estados frente a las superficies donde aparecen (verificando contraste ≥ 3:1 en las 3 direcciones) y genere las láminas comparativas y la comprobación visual anotada de posiciones (4 puestos, 2 ollas, barra, 2 cocineros).
5. **Comparativa, recomendación y preguntas (`docs/art/minimal/README.md`):**
   - Redactar la tabla comparativa de 4 columnas (v2 + 3 direcciones: legibilidad a 1080p y 800×370, coherencia con PulpaSA, coste en `.glb`/materiales/escenas y rendimiento esperado), la recomendación razonada y las preguntas abiertas para el gate humano del responsable.
6. **Verificación y cierre:** ejecutar `tools/verify.sh --quick` y `python3 tools/check_owns.py`, documentar `## Evidence` en la ficha y cerrar con commit y `worker_done`.

## Evidence
- **AC1 (Estado de partida y script sin errores):**
  - Scripts adaptados a `box.tres` y `apply_seasoning`: `docs/evidence/PUL-180/capture_boot.gd` y `docs/evidence/PUL-180/capture_minimal.gd`.
  - Ejecución limpia (`0` líneas con `ERROR`, código de salida `0`): `docs/evidence/PUL-180/capture_log.txt`.
  - Capturas de partida en `docs/evidence/PUL-180/partida/`: `1920x1080_sin_hud.png`, `1920x1080_con_hud.png` y `800x370_movil.png`.
- **AC2 (3 direcciones minimalistas y tabla de contraste §3.4 ≥ 3:1):**
  - `docs/art/minimal/direccion-a-color-plano.md` («Feira Clara», paleta cerrada de **16 colores hex**, 6 apartados completos).
  - `docs/art/minimal/direccion-b-geometrica.md` («Bloques de Romería», paleta cerrada de **14 colores hex**, 6 apartados completos).
  - `docs/art/minimal/direccion-c-maqueta-papel.md` («Maqueta de Papel», paleta cerrada de **15 colores hex**, 6 apartados completos, alineada con `#E4DFD5` y cocineros `#2F6FB5`/`#F2C230` de `capture_minimal.gd`).
  - Cálculo reproducible de luminancia relativa y contraste WCAG 2.1 en `docs/evidence/PUL-180/contrastes_sec34.md` (generado por `docs/evidence/PUL-180/build_evidence.py`): los 5 colores de §3.4 superan el umbral ≥ 3:1 frente a la superficie donde aparecen (`dulce/#EDE8DF = 3.9052:1`, `picante/#EDE8DF = 7.3993:1`, `sal/#1D3557 = 11.2449:1`, `aceite/#B8283D = 3.6770:1`, `cachelos/#B8283D = 4.2551:1`, `sal/#18222C = 14.6519:1`, `sal/#2A2320 = 14.0517:1`; mínimos en soportes primarios de estación/UI: **3.9052:1** en Dir. A, **4.0418:1** en Dir. B y **4.3358:1** en Dir. C; mínimo sobre cama de pulpo `#B8283D`: **3.6770:1** en las tres; mínimo incluyendo cuenco `#8E6B47` en Dir. A: **3.3390:1**) y se distinguen entre sí por doble codificación color + forma D26.
- **AC3 (Imágenes de prototipo en el motor y comprobación visual anotada de posiciones):**
  - Imágenes principales: `docs/art/minimal/direccion-a-color-plano.png`, `docs/art/minimal/direccion-b-geometrica.png` y `docs/art/minimal/direccion-c-maqueta-papel.png` (más sus variantes con HUD y `800×370` en `docs/evidence/PUL-180/direccion_{a,b,c}/`). Todas obtenidas como **prototipo en el motor** en tiempo de ejecución sin tocar escenas ni recursos versionados.
  - Coordenadas exportadas en `docs/evidence/PUL-180/posiciones_verificadas.json` y comprobación visual anotada en `docs/evidence/PUL-180/comprobacion_posiciones_anotada.png` (más mosaico móvil en `docs/evidence/PUL-180/comparativa_movil_800x370.png` e índice en `docs/evidence/PUL-180/README.md`), con desviación calculada en `build_evidence.py` de **0.0 px** a `1920×1080` y **0.1 px por eje (0.14 px euclídea)** en móvil a `800×370` para los 4 puestos (`OrderStand1..4`), las 2 ollas (`Kitchen`, `Kitchen2`), la barra (`Bar_SeasoningStation`) y los 2 cocineros (`Player1`, `Player2`).
- **AC4 (Comparativa de 4 columnas, recomendación, preguntas y decisión del responsable):**
  - `docs/art/minimal/README.md` incluye la tabla comparativa de 4 columnas (`v2 actual` + 3 direcciones, etiquetando los ahorros de rendimiento como hipótesis de producción y documentando `env_plate` y el SSAO activo en los prototipos A y C), las regresiones visuales del prototipo a resolver en la biblia v3 (números `#1..#4` delineados/degradados en móvil a `800×370` y cartel superior vacío en Dir. A), la recomendación razonada, las 5 preguntas y la **decisión del responsable en la sección 4 (Dirección A «Feira Clara» con alcance de materiales y escena)**.
- **AC5 (`tools/verify.sh --quick` y `tools/check_owns.py`):**
  - `tools/verify.sh --quick`:
    ```text
    == gdformat --check
    241 files would be left unchanged

    == gdlint
    Success: no problems found

    == import

    ✓ verify OK
    ```
  - `python3 tools/check_owns.py jrmougan/pul-180 main`:
    ```text
    check_owns: 29 rutas dentro de owns de PUL-180.
    ```


