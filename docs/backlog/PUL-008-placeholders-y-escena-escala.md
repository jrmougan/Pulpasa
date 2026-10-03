---
id: PUL-008
title: Crear placeholders 3D, importar muebles propios y montar la escena de escala
status: done
milestone: M0
role: asset-pipeline
deps: []
orca_task: task_68ed8d3c8a08
unity_sources: [Assets/Art/Furniture/**, Assets/Art/Materials/**, Assets/Prefabs/**, Assets/Scenes/Levels/Level_01.unity]
owns: [godot/assets/models/**, godot/assets/materials/**, godot/scenes/scale_check.tscn, godot/scenes/scale_check.tscn.uid, godot/tests/integration/test_scale_check.gd, godot/tests/integration/test_scale_check.gd.uid, docs/assets/licenses.md]
touches_scenes: [godot/scenes/scale_check.tscn]
---

## Target
Fase 3 de M0 (modelos y materiales), con D14 (3D ortográfica), D15 (sin Pandazole) y D16 (solo
licencias confirmadas). `docs/assets/licenses.md` dice qué se puede usar.

## Change
1. Importa `Mueblecajas.fbx` y `order_stand.fbx` a `godot/assets/models/furniture/`. Revisa
   escala (1 unidad = 1 m) y orientación (Unity +Z adelante → Godot −Z).
2. Placeholders 3D como escenas de malla simple (primitivas + `StandardMaterial3D`) en
   `godot/assets/models/placeholders/`, con dimensiones tomadas de los prefabs/escena de Unity:
   olla, fogón, nevera, mesa (3 variantes del nivel), caja (Small/Medium/Large), bote de
   condimento, pulpo (crudo/cocido como color) y personaje (cápsula con «nariz» que marque el frente).
3. Materiales: recrea los `Art/Materials/**` de Unity como `StandardMaterial3D` `.tres` en
   `godot/assets/materials/` (mismos colores; sin texturas de licencia dudosa).
4. `scenes/scale_check.tscn`: suelo con rejilla de 1 m, cámara ortográfica con los parámetros de
   Unity (ADR-005: tamaño ~6,37, ~38°), todos los modelos y placeholders alineados y el cubo de 1 m.
5. Añade a `docs/assets/licenses.md` lo importado.

## Constraints
- No uses ningún asset de la tabla «Pendientes» ni de Pandazole.
- Placeholders sin lógica: solo malla, material y colisión simple si procede. Las entidades
  jugables son fases 4–6.
- `.tscn` vía MCP o editor; no inventes uid.

## Acceptance
- [x] AC1 Los dos FBX propios importan sin errores y su AABB está en metros plausibles (± 20 % de Unity) → `test_scale_check.gd`.
- [x] AC2 Existe un placeholder por cada elemento listado, con el frente en −Z → `test_scale_check.gd`.
- [x] AC3 Captura de `scale_check.tscn` con la cámara ortográfica de Unity en `docs/evidence/PUL-008/` (revisión humana).
- [x] AC4 `licenses.md` actualizado; `tools/verify.sh` en verde.

## Plan
Generado con script headless de Godot (ResourceSaver), sin uids inventados; script temporal retirado.

## Evidence
- `tools/verify.sh`: ✓ verify OK (gdformat, gdlint, import, GUT 36/36, smoke).
- AC1/AC2: `godot/tests/integration/test_scale_check.gd`. AABB importados: Mueblecajas 1,14×0,92×1,80 m; order_stand 1,92×2,02×0,77 m.
- AC3: `docs/evidence/PUL-008/scale_check.png` (revisión humana).
- Notas: `Camera3D.size` es el alto total (12,74 = 2 × 6,37 de Unity); posición z espejada (Unity −5,86 → +5,86). Mueblecajas va sin la rotación de −90° del nivel. La orientación del frente de los FBX no se pudo verificar sin referencia: revisar en la captura.
- Revisión codex aplicada: cajas y bote con bounds de mesh × transforms de prefab (no collider); envoltorio `Mueblecajas.tscn` (yaw +90°, frente −Z, FBX original intacto; colocación del nivel en fase 8); tests con referencias derivadas y dirección global de Front/Nose/Handle; captura renovada.
