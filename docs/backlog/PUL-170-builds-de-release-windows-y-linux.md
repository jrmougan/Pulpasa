---
id: PUL-170
title: Preparar los builds de release de Windows y Linux
status: draft
milestone: M4
role: godot-architect
deps: []
orca_task: null
unity_sources: []
owns: [godot/export_presets.cfg, tools/export.sh, docs/arch/export.md, godot/assets/branding/app_icon*, docs/evidence/PUL-170/**, docs/backlog/PUL-170-builds-de-release-windows-y-linux.md]
touches_scenes: []
---

## Target
Must 1 de la alpha (smoke en builds Windows y Linux). Hoy `tools/export.sh` exporta (PUL-010) pero Windows
nunca se ha ejecutado, los tamaños son de la escena de arranque de 2026-10-03 y no hay icono, metadatos ni
paquete distribuible.

## Change
1. Presets Linux y Windows de release: nombre, icono de la app (marca PulpaSA, `docs/art/brand.md`),
   metadatos de Windows (producto, compañía, versión desde `config/version`), exclusiones de tests y sandboxes.
2. `tools/export.sh` genera además un `.zip` por plataforma con la versión en el nombre y un `LICENSES.txt`
   (o el formato que decida PUL-160 para los créditos).
3. Medir tamaño y tiempo de arranque al menú del build Linux; dejar documentado cómo probar Windows
   (máquina real o Wine: pregunta P3 del plan).

## Constraints
- No cambia el renderizador de escritorio (Forward+) ni el preset web; Android es de PUL-15x.
- `project.godot` no se toca (es de PUL-168 en su oleada); la versión se lee, no se cambia.

## Acceptance
- [ ] AC1 `tools/export.sh linux` y `windows` salen con 0 y generan `build/<plat>/pulpasa-<versión>-<plat>.zip`.
- [ ] AC2 El build Linux arranca al menú en ≤ 5 s con `--quit-after 300` y 0 líneas `ERROR` (log en evidencia).
- [ ] AC3 `export.md` al día: tamaños medidos, icono, metadatos y cómo probar cada plataforma.
- [ ] AC4 `tools/verify.sh` en verde; `check_owns` limpio.

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
