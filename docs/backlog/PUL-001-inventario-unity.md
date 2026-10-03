---
id: PUL-001
title: Inventariar el proyecto Unity y mapearlo a Godot
status: review
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
- [x] AC1 Los 46 scripts propios de `Assets/Scripts` aparecen en el inventario.
- [x] AC2 Cada fila tiene destino Godot y fase asignada.
- [x] AC3 Los bugs conocidos (doble `CompleteOrder`, temporizadores duplicados, `EmissionHighlighter`) están listados con archivo:línea.

## Plan
1. Leer los 47 `.cs`, mapear GUIDs de scripts → prefabs/escenas y prefabs → nivel.
2. Leer los 13 `.asset` de `Resources/` y los overrides de `Level_01.unity`.
3. Contar referencias de cada asset de arte/audio/fuente para decidir reutilización.
4. Fases de M0 confirmadas por el coordinador (documentadas al inicio del inventario).

## Evidence
- `docs/migration/inventory.md`: §1 scripts (47 filas), §2 ScriptableObjects (13), §3 prefabs (18) + escenas (2) + config, §4 bugs (B1–B18) y código muerto, §5 assets con origen/licencia.
- AC1: la ficha dice 46 scripts, pero en `Assets/Scripts` hay 47 `.cs`; los 47 aparecen (comprobado con un bucle `grep` sobre cada ruta: 0 ausentes).
- AC2: cada fila de §1–§3 tiene destino y fase 0–8; lo que no se porta lleva `—` y remite a §4.
- AC3: B1 doble `CompleteOrder` (`OrderSystem.cs:103` + `OrderStand.cs:61`), B2 temporizadores duplicados (`ProductivitySystem.cs:45/47`, `ProductivityUIDisplay.cs:23/36`), B3 `EmissionHighlighter` (`EmissionHighlighter.cs:15`, `:25-28`; `HighlightController.cs:11-12`).
- `tools/verify.sh`: OK (gdformat, gdlint, import, GUT 2/2, smoke).
- Pendiente fuera de alcance: verificar licencias marcadas **verificar** en §5 (Boite Hamburger, Condiment.obj, iconos, audio, OCRAEXT).
