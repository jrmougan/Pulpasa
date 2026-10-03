---
id: PUL-010
title: Configurar exportación Linux, Windows y Web y probarla temprano
status: review
milestone: M0
role: godot-architect
deps: []
orca_task: null
unity_sources: []
owns: [godot/export_presets.cfg, tools/export.sh, godot/project.godot, docs/arch/export.md, docs/evidence/PUL-010/**]
touches_scenes: []
---

## Target
Prueba temprana de exportación pedida por ADR-005 (riesgo web con 3D). Plantillas 4.7.2 ya
instaladas en `~/.local/share/godot/export_templates/4.7.2.stable`.

## Change
1. `export_presets.cfg` con tres presets: Linux x86_64, Windows x86_64 y Web.
2. Web con renderizador **Compatibility** (`rendering/renderer/rendering_method.web`), sin
   cambiar Forward+ en escritorio. Variante sin hilos si evita requisitos COOP/COEP; documenta la elección.
3. `tools/export.sh [linux|windows|web|all]` → `build/<plataforma>/`, añadiendo `build/` al `.gitignore` raíz.
4. `docs/arch/export.md`: cómo exportar, tamaños obtenidos, limitaciones de Compatibility observadas.

## Constraints
- No cambiar autoloads ni InputMap. Solo los ajustes de render/exportación en `project.godot`.
- No subir builds al repo.

## Acceptance
- [x] AC1 `tools/export.sh all` genera los tres builds sin errores.
- [x] AC2 El build de Linux arranca en headless y termina sin errores (`--quit-after 120`).
- [x] AC3 El build web se sirve en local y carga `boot.tscn` en Chromium/Chrome sin errores de consola; captura en `docs/evidence/PUL-010/` (si no puedes abrir un navegador, márcalo «no verificable» y deja el comando para que lo pruebe una persona).
- [x] AC4 Tamaños de cada build anotados en export.md; `tools/verify.sh` en verde.

## Plan

## Evidence
- Presets, `tools/export.sh`, `docs/arch/export.md`; capturas y log en `docs/evidence/PUL-010/`.
- **Producer**: añadir `/build/` al `.gitignore` raíz (no está en `owns`). Hasta entonces `build/` queda sin trackear.
