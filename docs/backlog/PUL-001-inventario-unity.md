---
id: PUL-001
title: Inventariar el proyecto Unity y mapearlo a Godot
status: ready
milestone: F0
role: migration-analyst
deps: []
orca_task: null
unity_sources: [Assets/Scripts/**, Assets/Resources/**, Assets/Prefabs/**, Assets/Scenes/**]
owns: [docs/migration/**]
touches_scenes: []
---

## Target
Todo `Assets/` (solo lectura). Salida en `docs/migration/`.

## Change
Crear `docs/migration/inventory.md` con:
1. Una fila por script, ScriptableObject, prefab y escena: origen, responsabilidad, destino Godot
   (nodo/escena/Resource/autoload), fase de M0 (0–8) y notas.
2. Lista de bugs y código muerto que NO se porta (ver docs/design/decisions.md y la propuesta).
3. Lista de assets (FBX, texturas, audio, fuentes) con licencia/origen y si se reutilizan.

## Constraints
No editar nada fuera de `docs/migration/`. No convertir assets todavía.

## Acceptance
- [ ] AC1 Los 46 scripts propios de `Assets/Scripts` aparecen en el inventario.
- [ ] AC2 Cada fila tiene destino Godot y fase asignada.
- [ ] AC3 Los bugs conocidos (doble `CompleteOrder`, temporizadores duplicados, `EmissionHighlighter`) están listados con archivo:línea.

## Plan

## Evidence
