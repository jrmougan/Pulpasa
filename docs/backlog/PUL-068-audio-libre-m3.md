---
id: PUL-068
title: Conseguir música, ambiente y efectos libres para M3
status: ready
milestone: M3
role: asset-pipeline
deps: []
orca_task: null
unity_sources: []
owns: [godot/assets/audio/**, docs/evidence/PUL-068/**, docs/assets/audio-sources.md]
touches_scenes: []
---

## Target
`features/audio-y-fx.md`: BG (música de romería, gaita/pandereta), FOL (ambiente de feria) y FX
que faltan (coger, soltar, nueva comanda, comanda caducada, aviso de quemado, quemado, cambio de
fase, botón de UI). Ya hay: hervir, corte, molinillo, entrega OK y error.

## Change
Buscar e importar audio **CC0** (preferible) o CC BY (D16): OpenGameArt, Freesound (solo CC0),
Kenney, etc. Convertir a `.ogg`, normalizar volumen (−16 LUFS aprox. música/ambiente, FX
coherentes entre sí), loops sin corte para BG/FOL. `docs/assets/audio-sources.md` con URL, autor,
licencia y atribución exacta de cada archivo (el coordinador lo pasa a `licenses.md`).

## Constraints
- Nada sin licencia confirmada (D16). No conectar los sonidos a escenas (es PUL-071).
- Antes de cerrar: `tools/verify.sh` verde y `tools/check_owns.py <tu-rama> jrmougan/agentica-migracion-godot-alpha` limpio.

## Acceptance
- [ ] AC1 Un archivo por necesidad de la lista, importado sin errores y con loop donde toca
- [ ] AC2 `audio-sources.md` completo y verificable
- [ ] AC3 `tools/verify.sh` verde, `check_owns` limpio.

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
