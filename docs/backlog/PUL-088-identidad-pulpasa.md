---
id: PUL-088
title: Diseñar la identidad de la marca PulpaSA
status: review
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
- [x] AC1 `brand.md` completo con colores, versiones y usos
- [x] AC2 2–3 propuestas en láminas y SVG fuente
- [x] AC3 Fuentes y licencias listadas
- [x] AC4 `tools/verify.sh` verde, `check_owns` limpio.

## Plan
1. Generador reproducible `art/brand/build_brand.py`: texto a trazados (fontTools + HarfBuzz) con
   fuentes OFL instaladas, símbolo de pulpo dibujado en SVG, rasterizado con ImageMagick/librsvg.
2. Tres propuestas (A Mariña: marino + pimentón, Montserrat; B Romaría: morado + turquesa,
   Comfortaa; C Caldeiro: verde mar + cobre, Inter), todas con la placa «SA» como rasgo común y
   sin amarillo.
3. Por propuesta: SVG horizontal, compacta, monocromo negro/blanco y símbolo; PNG en
   `godot/assets/textures/brand/propuesta_<x>/` importados por Godot; lámina con cartel luminoso,
   toldo, gorra, delantal, bandeja, vaso y ticket/HUD.
4. `docs/art/brand.md` con colores, versiones, usos, fuentes y licencias.

## Evidence
- Ronda 1: tres propuestas (A Mariña, B Romaría, C Caldeiro); comparativa en
  `docs/evidence/PUL-088/propuestas_resumo.png` y láminas `lamina_b_romaria.png`,
  `lamina_c_caldeiro.png` (descartadas, se conservan como registro).
- Ronda 2: el responsable elige **A «Mariña»** con el lema «Franquicia galega de polbo».
  Lámina oficial: `docs/evidence/PUL-088/lamina_oficial.png`. B y C borradas (SVG, PNG, `.import`).
- SVG fuente: `art/brand/pulpasa_{horizontal,compacta,mono_negro,mono_blanco,simbolo}.svg` y
  `art/brand/lamina.svg`; PNG + `.import` en `godot/assets/textures/brand/pulpasa_*.png`.
- Fuente: Montserrat Black/Bold (SIL OFL 1.1), convertida a trazados; fila para
  `licenses.md` en `docs/art/brand.md` § Fuentes y licencias (la añade el coordinador).
- `tools/verify.sh` verde y `tools/check_owns.py` limpio (ver commits).
