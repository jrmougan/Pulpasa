---
id: PUL-179
title: Publicar la alpha (notas y subida de los builds verificados)
status: draft
milestone: M4
role: producer
deps: [PUL-176, PUL-177, PUL-178]
orca_task: null
unity_sources: []
owns: [docs/release/**, docs/evidence/PUL-179/**, docs/backlog/PUL-179-publicar-la-alpha.md]
touches_scenes: []
---

## Target
Puerta «Publicar alpha» (G4) aprobada con `m4-gate.md` (PUL-178). Se publican **los mismos `.zip`** que pasaron
el smoke de PUL-176 y el playtest: misma versión (fijada en PUL-170 antes de exportar) y mismo SHA-256 del manifiesto.

## Change
1. Comprobar que no hay commits en `godot/` ni `tools/export.sh` posteriores al del manifiesto de PUL-176; si los
   hay, no se publica: se repite PUL-176 (export + smoke) y, si cambió el juego, G4.
2. `docs/release/alpha.md`: notas de la versión (qué hay, controles, problemas conocidos de PUL-176/177, cómo
   enviar feedback) y requisitos mínimos.
3. Etiquetar el commit del manifiesto (`v<versión>`) y publicar los `.zip` donde y para quien decida el
   responsable (P4). Acción hacia fuera: **solo con confirmación explícita del responsable** en el momento de subir (G5).

## Constraints
- No se cambia la versión ni se reexporta en esta ficha: si hace falta, vuelve a PUL-170/176.
- Nada se publica sin G4 aprobado y la confirmación de G5.

## Acceptance
- [ ] AC1 Given el manifiesto de PUL-176, When se ejecuta `git log <commit-manifiesto>..HEAD -- godot tools/export.sh`, Then la salida está
  vacía (0 commits) y la etiqueta `v<versión>` apunta a ese commit → salida en `docs/evidence/PUL-179/README.md`.
- [ ] AC2 Given los `.zip` subidos, When se descargan de la publicación y se pasa `sha256sum`, Then los 2 hashes coinciden con el manifiesto → salida en la evidencia.
- [ ] AC3 Given `docs/release/alpha.md`, When se revisa, Then tiene las 5 secciones (contenido, controles de teclado/mando/táctil, problemas
  conocidos con su ficha, canal de feedback, requisitos mínimos) y la versión coincide con la del menú (captura de PUL-176) → lista en la evidencia.
- [ ] AC4 Given la rama, When se ejecutan `tools/verify.sh` y `python3 tools/check_owns.py <rama>`, Then salen con 0 y 0 rutas fuera de `owns` → salida en la evidencia.

## Plan
(Lo escribe el producer.)

## Evidence
(Lo rellena el producer.)
