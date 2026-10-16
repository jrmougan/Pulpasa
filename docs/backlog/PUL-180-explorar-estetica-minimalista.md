---
id: PUL-180
title: Explorar una estética minimalista y proponer direcciones para elegir
status: in_progress
milestone: M3f
role: game-designer
deps: []
orca_task: null
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
- [ ] AC1 Given el juego en `main`, When se ejecuta el script de captura, Then hay al menos 3 capturas
  de partida (1920×1080 sin HUD y con HUD, 800×370) en `docs/evidence/PUL-180/partida/`, y la salida
  del script no tiene ningún ERROR.
- [ ] AC2 Given las 3 direcciones, When se abre `docs/art/minimal/`, Then cada una tiene un documento
  con los 6 apartados del punto 2 del Change y una paleta de entre 8 y 16 colores en hex, y los
  colores de §3.4 se distinguen entre sí: contraste ≥ 3:1 frente a la superficie donde aparecen
  (tabla calculada en la evidencia).
- [ ] AC3 Given cada dirección, When se compara su imagen con la de partida, Then conserva la cámara y
  la posición de los 4 puestos, las 2 ollas, la barra y los 2 cocineros (comprobación visual
  anotada), y dice si es generada o un prototipo en el motor.
- [ ] AC4 `docs/art/minimal/README.md` tiene la tabla comparativa con las 4 columnas (v2 + 3
  direcciones), la recomendación y al menos 3 preguntas para el responsable.
- [ ] AC5 `tools/verify.sh --quick` en verde y `tools/check_owns.py` limpio.

## Plan
(Lo escribe el worker antes de empezar.)

## Evidence
(Lo rellena el worker.)
