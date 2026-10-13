---
id: PUL-170
title: Preparar presets, versión y empaquetado de los builds de Windows y Linux
status: draft
milestone: M4
role: godot-architect
deps: [PUL-160]
orca_task: null
unity_sources: []
owns: [godot/project.godot, godot/export_presets.cfg, tools/export.sh, docs/arch/export.md, godot/assets/branding/app_icon*, docs/evidence/PUL-170/**, docs/backlog/PUL-170-preparar-presets-y-empaquetado.md]
touches_scenes: []
---

## Target
Must 1 de la alpha (smoke en builds Windows y Linux). Hoy `tools/export.sh` exporta (PUL-010) pero Windows
nunca se ha ejecutado, los tamaños son de la escena de arranque de 2026-10-03 y no hay icono, metadatos ni
paquete. Esta ficha **solo prepara** la tubería; los builds que se prueban y publican los genera PUL-176 desde
el commit final. Formato de créditos/licencias: `features/creditos-y-version.md` (PUL-160).

## Change
1. Fijar `config/version` en `project.godot` a la versión de la alpha **decidida en G0** (P4), antes de cualquier
   export que se vaya a probar; en `project.godot` solo se toca esa clave (va en O2, antes de PUL-168).
2. Presets Linux y Windows de release: nombre, icono de la app (marca PulpaSA, `docs/art/brand.md`), metadatos de
   Windows (producto, compañía, versión leída de `config/version`), exclusiones de tests y sandboxes.
3. `tools/export.sh` genera por plataforma `build/<plat>/pulpasa-<versión>-<plat>.zip` con el fichero de licencias
   del formato de PUL-160 y un `MANIFEST.txt` con versión, `git rev-parse HEAD`, árbol limpio sí/no y SHA-256
   de cada `.zip`; **se niega a exportar en modo release con el árbol sucio** (salvo `--dry-run`).
4. Ensayo con `--dry-run` para comprobar la tubería. Esos artefactos **no valen** para QA ni publicación.

## Constraints
- No cambia el renderizador de escritorio (Forward+) ni el preset web; Android es de PUL-15x.
- Sin versión decidida en G0, la ficha no pasa a `ready`.

## Acceptance
- [ ] AC1 Given el árbol limpio, When se ejecuta `tools/export.sh linux` y `tools/export.sh windows`, Then salen con 0 y dejan
  `pulpasa-<versión>-<plat>.zip` y `MANIFEST.txt` con el hash del commit y el SHA-256 del `.zip` (que coincide con `sha256sum`) → log en `docs/evidence/PUL-170/`.
- [ ] AC2 Given un fichero modificado sin commit, When se ejecuta `tools/export.sh linux` sin `--dry-run`, Then sale con código ≠ 0 y no
  genera `.zip` → log en la evidencia.
- [ ] AC3 Given el build Linux del ensayo, When se lanza con `--quit-after 300`, Then llega al menú en ≤ 5 s y hay 0 líneas `ERROR`;
  se registran tamaño (MB) de ambos `.zip` → log y tabla en la evidencia y en `export.md`.
- [ ] AC4 Given `project.godot`, When se compara con `main`, Then la única línea cambiada es `config/version` (= valor de G0) → `git diff` en la evidencia.
- [ ] AC5 Given la rama de la ficha, When se ejecutan `tools/verify.sh` y `python3 tools/check_owns.py <rama>`, Then ambos salen con código 0 y 0 rutas fuera de `owns` → salida pegada en `docs/evidence/PUL-170/README.md`.

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
