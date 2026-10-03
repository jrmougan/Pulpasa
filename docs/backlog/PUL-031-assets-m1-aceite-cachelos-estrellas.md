---
id: PUL-031
title: Incorporar iconos y placeholders de aceite, cachelos y estrellas
status: done
milestone: M1
role: asset-pipeline
agent: kimi (fácil)
deps: []
orca_task: task_31c90f34dce0
unity_sources: []
owns: [godot/assets/textures/icons/**, godot/assets/models/placeholders/**, godot/assets/materials/**, godot/assets/CREDITS.md, docs/assets/licenses-pul-031.md, godot/tests/unit/test_assets_m1.gd, godot/tests/unit/test_assets_m1.gd.uid, docs/evidence/PUL-031/**]
touches_scenes: []
---

## Target
Assets que necesitan PUL-028/029/030, con la regla D16 (solo licencias confirmadas: CC0, CC BY, OFL, MIT).

## Change
1. Iconos SVG: aceite (botella), cachelos (patata), estrella llena y vacía. Preferible game-icons.net (CC BY 3.0,
   con autor) o CC0.
2. Placeholders 3D con primitivas: botella de aceite, cachelos crudos y cocidos (color distinto), cachelera
   (caja o saco), con frente en −Z y dimensiones razonables junto a la olla de PUL-008.
3. Atribuciones en `godot/assets/CREDITS.md` y tabla en `docs/assets/licenses-pul-031.md` (el producer la consolida).

## Constraints
- Desde M1 manda el diseño (`docs/design/gdd.md`, `features/`, `decisions.md`), no Unity (D17). Donde una feature cite «paridad», prevalecen D8–D10 y D17.
- Capa común (ADR-003 §0) y núcleos `RefCounted` con dependencias inyectadas (ADR-002). Datos de balance en `.tres`.
- Cambios de firma de señales: solo si la ficha lo dice; actualiza `docs/arch/signals.md` en ese caso.
- Antes de cerrar: `tools/verify.sh` en verde y `tools/check_owns.py <tu-rama> jrmougan/agentica-migracion-godot-alpha` limpio (los hooks de Claude Code no corren en tu agente: el merge gate sí).
- Nada de assets de la tabla «Pendientes» de `licenses.md` ni de Pandazole.

## Acceptance
- [ ] AC1 Los 4 iconos y los 4 placeholders cargan sin errores → `test_assets_m1.gd`.
- [ ] AC2 Cada asset nuevo con URL, licencia y autor en `licenses-pul-031.md` y `CREDITS.md`.
- [ ] AC3 Captura de los placeholders en `docs/evidence/PUL-031/`. `tools/verify.sh` verde, `check_owns` limpio.

## Plan

1. Iconos SVG de game-icons.net (repo oficial github.com/game-icons/icons), todos de Delapouite,
   CC BY 3.0, sin el fondo negro: `oil.svg` («Olive»: rama de olivo con aceitunas, inequívoco para
   aceite de oliva; en revisión se descartó «Wine bottle» por incluir una copa de vino y
   «Oil can» por no ser botella), `potato.svg` («Potato»), `star_full.svg` («Round star») y
   `star_empty.svg` (modificación de «Round star»: solo contorno). Elegidos tras rasterizar y
   comparar 15 candidatos con `Image.load_svg_from_string`.
2. Placeholders 3D con primitivas, generados con un script GDScript tipado temporal
   (`godot --headless -s`, se borra tras generar; mismo patrón que PUL-008): `oil_bottle.tscn`
   (0,4 m de alto, vidrio verde + aceite + etiqueta + tapón), `cachelos_raw.tscn` y
   `cachelos_cooked.tscn` (mismo ovoide de 0,18 m, materiales marrón y pálido) y
   `cachelera.tscn` (caja de 0,5×0,32×0,42 m con cachelos asomando). Todos con raíz `Node3D` y
   marcador `Front` en −Z; dimensiones coherentes con la olla (r=0,33, h=0,65).
3. Materiales nuevos `ph_oil` (vidrio verde translúcido, `transparency = 1` con alfa 0,45 para
   que el aceite interior se vea — corrección de revisión), `ph_oil_liquid`, `ph_cachelo_raw`,
   `ph_cachelo_cooked` (la cachelera reutiliza `ph_wood`).
4. Tests GUT `godot/tests/unit/test_assets_m1.gd` (TDD sobre los AC): carga de los 4 iconos y de
   los 4 placeholders (instancia, Front existente **y en −Z**, mallas), colores crudo/cocido
   distintos y presencia de URL, licencia y autor en `licenses-pul-031.md` y `CREDITS.md`.
5. Atribuciones: `godot/assets/CREDITS.md` y tabla nueva `docs/assets/licenses-pul-031.md` con las
   mismas columnas que `licenses.md` (Asset (origen) | Destino | Licencia | Atribución requerida).

## Evidence

- AC1: `test_assets_m1.gd` — 4 tests, 51 aserciones, en verde (`tools/verify.sh` completo OK tras
  la revisión: gdformat, gdlint, import, GUT y smoke de 120 frames). Iconos rasterizados en
  `docs/evidence/PUL-031/ac1-iconos.png` (actualizada con «Olive»).
- AC2: `docs/assets/licenses-pul-031.md` con las columnas de `licenses.md` (URL+obra+autor en la
  1ª columna, modificación de `star_empty` como nota); atribución CC BY 3.0 a Delapouite en
  `godot/assets/CREDITS.md`. Test `test_ac2_atribuciones_mencionan_los_assets_nuevos`.
- AC3: `docs/evidence/PUL-031/ac3-placeholders.png` (cachelera, olla de PUL-008 como referencia de
  escala, botella de aceite con el aceite visible por el vidrio translúcido, cachelo crudo y
  cocido), recapturada con el MCP de Godot tras la revisión; 0 errores en el log de ejecución.
- `tools/check_owns.py jrmougan/pul-031 jrmougan/agentica-migracion-godot-alpha` limpio.
