---
id: PUL-130
title: Cámara con perfiles, seguimiento móvil y flecha de borde
status: done
milestone: M3e
role: gameplay-engineer
deps: [PUL-122, PUL-123]
orca_task: null
unity_sources: []
owns: [godot/entities/camera/camera_rig.gd*, godot/resources/camera_profile.gd*, godot/core/camera_follow.gd*, godot/data/config/camera_desktop.tres, godot/data/config/camera_mobile.tres, godot/tests/unit/test_camera_follow_math.gd*, godot/tests/integration/test_camera_profile.gd*, godot/tests/integration/test_camera_follow.gd*, docs/evidence/PUL-130/**, docs/backlog/PUL-130-camara-con-perfiles-seguimiento-movil-y-flecha-de.md]
touches_scenes: [godot/entities/camera/camera_rig.tscn]
---

## Target
D26 (`docs/design/decisions.md`), contrato en `docs/arch/` (ADR-003 §11, ADR-004 §6, ADR-005 Enmienda D26,
ADR-006 §4.1, `signals.md`, `scene-tree.md` §9). Partición original y notas de propietarios entre oleadas:
`docs/backlog/PUL-120-contratos-d26.md` («Partición en fichas»). Oleada 2. Diseño:
`docs/design/features/lenguaje-acciones.md` y `controles-tactiles.md`. Touches scenes original: `godot/entities/camera/camera_rig.tscn`

## Change
ADR-005 E5.

## Constraints
- Solo las rutas de `owns`/`touches_scenes`. Si un cambio rompe un test fuera de tus owns, para y avisa al producer.
- Tipado estático, datos en `.tres`, lógica en `core/` RefCounted; no inventes `uid://`.
- Nombres exactos del contrato (manda sobre el diseño; equivalencias en PUL-120).

## Acceptance
- [x] AC1 Escritorio sin cambios: size 12,74, fija, 66,8 px/m (`test_camera_profile.gd`).
- [x] AC2 Móvil: size 7,0, >= 120 px/m a 1080 de alto (2340x1080, 1920x1080, 2400x1000) y personaje >= 192 px.
- [x] AC3 Seguimiento sin oscilación (<= 0,05 m en reposo). Corriendo a 5 m/s durante 2 s el personaje queda en el 60 % central del alto y el 80 % del ancho; al parar, desfase <= 0,1 m a los 0,6 s sin rebasar el objetivo (diseño AC11).
- [x] AC4 Paneo ease-out de 0,35 s al `character_switched(1, c)`; otros jugadores se ignoran.
- [x] AC5 La vista no sale más de 1,0 m del límite del nivel (medido con rayos de las 4 esquinas contra el suelo, en las esquinas del nivel y lejos de ellas).
- [x] AC6 Flecha de borde 48 px para el inactivo fuera de cuadro, dentro de la safe area y a >= 16 px de los botones.

## Plan
- `core/camera_follow.gd` (follow, pan_to, clamp_focus, edge_point), `resources/camera_profile.gd`, `camera_desktop.tres`, `camera_mobile.tres`, `camera_rig.gd` + `camera_rig.tscn` (script y `%OffscreenArrow`).
- Señal consumida: `EventBus.character_switched` (sin cambios de contrato).
- Tests: `test_camera_follow_math.gd` (AC3-AC6 núcleo), `test_camera_profile.gd` (AC1, AC2), `test_camera_follow.gd` (AC3-AC6 con la cámara real en SubViewport).

## Evidence
- 28 tests nuevos en verde (12 unitarios, 6 de perfil, 10 de seguimiento); `tools/verify.sh` completo en verde.
- Capturas en `docs/evidence/PUL-130/`: `desktop.png` (1920x1080, sin cambios), `mobile.png` (2340x1080 siguiendo a J1), `arrow.png` (2340x1080, flecha del inactivo arriba a la izquierda).
- Generadas con un script externo que monta `level_01` y rellena `CameraRig.characters` (el montaje real es PUL-131). La HUD aún tiene la disposición de escritorio (otras fichas).
- Límite: con el margen de 1 m, un personaje en las esquinas del nivel no queda en el 60 % central (la vista no sale del límite); el test del 60 % usa posiciones interiores.
