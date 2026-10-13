---
id: PUL-139
title: Triar los pendientes sueltos del roadmap y crear sus fichas
status: review
milestone: M4
role: qa-tester
deps: []
orca_task: null
unity_sources: []
owns: [docs/backlog/PUL-14[2-9]-*.md, docs/evidence/PUL-139/**, docs/backlog/PUL-139-triaje-de-pendientes-sueltos.md]
touches_scenes: []
---

## Target
Los pendientes de `docs/design/roadmap.md` que no tienen ficha: secciones «Pendientes detectados para la
fase 8», «en M1», «en M3» y «en M3b» (defectos D1–D9 del QA de PUL-087, `scene-tree.md` sin
`Bulbs`/`Vignette`, POP del puesto que tapa su número, test FIFO de PUL-029, cachelo crudo/cocido). Muchos
pueden estar ya resueltos por fichas posteriores (PUL-088..138, en especial M3c: PUL-090..103).

## Change
1. Para cada pendiente, comprobar en el código, las escenas, los tests, `docs/arch` y las fichas
   posteriores si sigue vivo (con captura vía MCP cuando sea visual). Resultado: **resuelto** (con la
   ficha o commit que lo resolvió), **vivo** o **obsoleto** (el diseño ya no lo tiene).
2. Por cada pendiente vivo, o grupo coherente, una ficha `draft` con el formato de `_TEMPLATE.md`
   (Target, Change, Constraints, Acceptance con números y test o captura; `owns` y `touches_scenes`
   mínimos y sin solaparse entre ellas), con ids **PUL-142 a PUL-149**. Hito `M4` salvo que proceda otro.
   Lo que sea balance o audio para escucha humana va como nota en la tabla, no como ficha.

## Constraints
- Solo documentación: no se toca código, escenas, datos ni contratos.
- **No edites** `docs/backlog/README.md` ni `docs/design/roadmap.md`: los actualiza el coordinador al
  mergear. Usa solo los ids PUL-142..149 (otros workers crean fichas en paralelo con otros rangos).
- Si un pendiente necesita una decisión de diseño o un cambio de contrato, la ficha lo dice y queda
  en `draft` con la pregunta explícita.

## Acceptance
- [x] AC1 `docs/evidence/PUL-139/README.md` tiene una tabla con cada pendiente, su estado
  (resuelto/vivo/obsoleto) y la prueba (ficha, commit, fichero:línea o captura).
- [x] AC2 Cada pendiente vivo tiene ficha `draft` PUL-142..149 o una nota de por qué no la lleva.
- [x] AC3 `tools/verify.sh --quick` en verde; `check_owns` limpio.

## Plan
1. Listar los pendientes de las cuatro secciones del roadmap (24, separando D9 en sus dos partes).
2. Para cada uno, buscar en código, escenas, tests, `docs/arch`, fichas posteriores y `git log -S` si
   sigue vivo; capturar por MCP/Xvfb lo visual que no se pueda leer en el código (POP del puesto).
3. Tabla en `docs/evidence/PUL-139/README.md`; fichas `draft` PUL-142.. agrupando por escena y rol para
   que `owns` no se solapen; notas para lo que es escucha humana, balance o herramienta.

## Evidence
- Tabla completa y pruebas: `docs/evidence/PUL-139/README.md`. Resultado: 24 pendientes → 9 resueltos
  o superados, 3 obsoletos (botes de la estantería, color del `SmallSpawner`, `order_2`), 12 vivos.
- Captura nueva: `docs/evidence/PUL-139/deliver_ok_strip.png` (`capture_stand_pop.gd`): el número del
  puesto desaparece en el 15–55 % del POP de `deliver_ok`; `order_new` no lo tapa.
- Fichas `draft` (M4): PUL-142 (POP del puesto, pregunta al arquitecto si cambia el árbol), PUL-143
  (test de plazas de la olla), PUL-144 (vapor y tapa, D2/D3), PUL-145 (ambiente y acero, D4/D7,
  pregunta de gusto al responsable), PUL-146 (materiales y texturas compartidos + borrar
  `romeria.blend`, D5/D6/D9b, pregunta sobre §4.2). PUL-147..149 sin usar.
- Sin ficha, con nota: escucha humana del audio y balance (van a M4, PUL-141), D8 (aceptado por
  PUL-087) y la limitación `--audio-driver` del MCP (herramienta).
- AC1 cumple, AC2 cumple, AC3 cumple (salida real abajo).
- Ronda 2 (revisión con CHANGES): PUL-146 AC4 pasa a comparación humana antes/después sobre el mismo
  commit, cámara y estado (sin umbral de píxeles ni capturas de PUL-087); PUL-145 AC1/AC3 exigen captura
  nueva y reproducible (`despues/00` de PUL-087 solo como referencia) y dejan explícito el orden
  PUL-146 → PUL-145 si se ajusta `mat_steel_brushed_top` (los `.glb` embeben ese material); PUL-143
  reconoce que `test_level_01` ya cubre la separación de anillos y se queda con la de anclas (3 AC).
- Ronda 3: PUL-145 y PUL-146 ya no remiten a `docs/art/style-refs/capture_style_refs.gd` (usa tallas y
  condimentos retirados y `toggle_seasoning`): piden copiarlo en su `docs/evidence/<id>/`, adaptarlo a la
  caja única y a los aliños actuales (`apply_seasoning`) y usar esa copia y ese estado para el antes y el
  después, con cero errores. El script histórico no se toca y los `owns` no cambian.
- `tools/verify.sh --quick` (rama con `main` mergeado, `d899778`):
  ```
  == gdformat --check
  235 files would be left unchanged
  == gdlint
  Success: no problems found
  == import
  ✓ verify OK
  ```
- `python3 tools/check_owns.py jrmougan/pul-139 main` (tras el commit de la ronda 2):
  ```
  check_owns: 12 rutas dentro de owns de PUL-139.
  ```
  Sin la base como segundo argumento compara contra `HEAD` y da 0 rutas.
