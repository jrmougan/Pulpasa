---
id: PUL-200
title: Corregir lo que pipeline.md dice de materials_v2_test y ref_materials_v2
status: done
milestone: M4
role: asset-pipeline
deps: []
orca_task: null
unity_sources: []
owns: [docs/art/pipeline.md]
touches_scenes: []
---

## Target
`docs/art/pipeline.md` §3, §4 (línea 120) y §8.6.

## Change
- Afirma que PUL-188 borrará `materials_v2_test` y lo lista como existente «hasta PUL-188». PUL-188 solo borra `godot/assets/models/**/*.png`, y art-bible §3.3.5 mantiene `_pipeline/**` como banco excluido: tras PUL-188 queda el `.glb` sin sus PNG y `--materials-test` fallará.
- La reescritura de §3 quitó la nota de `ref_materials_v2`, que mantiene vivos los 45 `mat_*` de la plantilla: restaurarla.

## Constraints
Solo documentación; contrástalo con la ficha de PUL-188 y art-bible. No abras ni modifiques `.blend`. Lo que hacer con esos restos es PUL-201.

## Acceptance
- [x] AC1 Given `pipeline.md`, When se contrasta con el `owns` de PUL-188 y art-bible §3.3.5, Then no afirma nada falso sobre `_pipeline/**` → docs/evidence/PUL-200/

## Plan
1. Contrastar `pipeline.md` con el `owns` de PUL-188 y art-bible §3.3.5.
2. Corregir cabecera, §3 (restaurar nota `ref_materials_v2`), §4, §8.4 y §8.6.
3. Tabla frase-fuente en `docs/evidence/PUL-200/`; `tools/verify.sh --quick`.

## Evidence
Tabla frase-fuente: `docs/evidence/PUL-200/frase-fuente.md`. `tools/verify.sh --quick`: ver informe del commit.
