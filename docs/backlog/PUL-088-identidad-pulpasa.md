---
id: PUL-088
title: Diseñar la identidad de la marca PulpaSA
status: ready
milestone: M3b
role: asset-pipeline
deps: []
orca_task: null
unity_sources: []
owns: [docs/art/brand.md, art/brand/**, godot/assets/textures/brand/**, docs/evidence/PUL-088/**]
touches_scenes: []
---

## Target
D21: la marca ficticia del juego es **PulpaSA**. Estética de referencia:
`docs/art/style-refs/referencia-elegida-2026-10-06.png` (allí pone «McPULPO»: se sustituye).

## Change
1. `docs/art/brand.md`: logotipo de texto (tipografía libre OFL/CC0, D16), símbolo sencillo (pulpo),
   colores de marca en hex, versiones (horizontal, compacta, monocromo) y usos: cartel luminoso,
   toldo, uniforme (gorra/delantal), bandejas, vasos, ticket/HUD. Lema opcional (el de la referencia
   era «American octopus franchise»: propón uno propio, p. ej. en gallego).
2. Ficheros: SVG fuente en `art/brand/` y PNG/texturas para Godot en `godot/assets/textures/brand/`
   (con `.import`). Puedes partir del logotipo histórico `godot/assets/textures/logo/PulpaSA.png`
   (propio, del prototipo) sin modificarlo.
3. 2–3 propuestas visuales en `docs/evidence/PUL-088/` (lámina con cada una aplicada a cartel,
   toldo y uniforme) para que el responsable elija.

## Constraints
- Nada que imite una marca registrada: sin «Mc», sin arcos, sin la combinación rojo/amarillo de
  esa cadena. Solo fuentes y recursos con licencia libre registrados (el coordinador los pasa a
  `licenses.md`).
- No toques la biblia (`docs/art/art-bible.md`, la escribe PUL-072 en paralelo) ni escenas.
- Si usas Blender (MCP por CLI, no el puerto 9876) o Godot (con `--audio-driver Dummy`) para las
  láminas, no dejes procesos abiertos.
- Antes de cerrar: `tools/verify.sh` verde y `tools/check_owns.py <tu-rama> jrmougan/agentica-migracion-godot-alpha` limpio.

## Acceptance
- [ ] AC1 `brand.md` completo con colores, versiones y usos
- [ ] AC2 2–3 propuestas en láminas y SVG fuente
- [ ] AC3 Fuentes y licencias listadas
- [ ] AC4 `tools/verify.sh` verde, `check_owns` limpio.

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
