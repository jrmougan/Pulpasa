---
id: PUL-005
title: Portar los ScriptableObjects a Resources y .tres
status: ready
milestone: M0
role: gameplay-engineer
deps: []
orca_task: null
unity_sources: [Assets/Scripts/ScriptableObjects/**, Assets/Resources/**, Assets/Prefabs/Packaging/**]
owns: [godot/resources/**, godot/data/**, godot/tests/unit/test_data_*.gd, godot/tests/unit/test_data_*.gd.uid]
touches_scenes: []
---

## Target
Fase 1 de M0. `docs/migration/inventory.md` §2 (13 `.asset`) y la fila de ScriptableObjects de §1.

## Change
1. Clases Resource en `godot/resources/` con `class_name`: `BoxData`, `IngredientData`,
   `RecipeData`, `OrderData`, `SeasoningData`, `OrderCatalog` (lista tipada de `OrderData`) y
   `RoundConfig` (duración de ronda y demás números de `RoundState` según ADR-002).
   Enums (`IngredientType`, `CookingState`, `SeasoningType`) dentro de su script.
2. Instancias `.tres` en `godot/data/{boxes,ingredients,recipes,orders,seasonings,config}/` con los
   **valores del prototipo** (paridad M0): 3 cajas con `fill_per_press` 0,2 / 0,1 / 0,05 (sacado de
   los prefabs Small/Medium/Large), pulpo con `cook_time` 5, 3 recetas, 3 comandas
   (`max_time` 0, `base_points` 0), 3 condimentos, catálogo con las 3 comandas y `RoundConfig`
   con 180 s (paridad; D5 = 300 s entra en M1).
3. Corrige los defectos de datos del inventario (B17: `Salt` con esquema antiguo, cajas Small/Medium
   apuntando a un GUID inexistente). No portes `DrinkSO`.
4. Campos que M1 necesitará (precio base, `max_time`) existen ya con el valor de paridad.

## Constraints
- Capa común: sin tipos 3D. Las referencias a escenas (`PackedScene`) pueden quedar vacías hasta
  las fases 3–6; documéntalo.
- `.tres` escritos a mano: no inventes `uid://`. Escríbelos sin uid y deja que `godot --headless --import`
  los genere; versiona lo que genere.
- No tocar `project.godot`, `autoload/` ni `core/`.

## Acceptance
- [ ] AC1 Las 3 comandas cargan desde `data/orders/catalog.tres` con su receta, caja y condimentos tal como en Unity (Order_1: ComboDuo + 2 especias; Order_3 sin especias) → `test_data_catalog.gd`.
- [ ] AC2 Cada caja tiene `fill_per_press` 0,2 / 0,1 / 0,05 → `test_data_boxes.gd`.
- [ ] AC3 Ningún `.tres` tiene referencias rotas (todos cargan con `load()` sin errores) → `test_data_integrity.gd`.
- [ ] AC4 `tools/verify.sh` en verde.

## Plan

## Evidence
