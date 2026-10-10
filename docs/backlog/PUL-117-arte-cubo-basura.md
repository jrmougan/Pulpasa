---
id: PUL-117
title: Arte del cubo de basura (dirección A, D22)
status: todo
milestone: M3d
role: asset-pipeline
deps: [PUL-112]
orca_task: null
unity_sources: []
owns: [godot/assets/models/trash_bin/**, godot/entities/stations/trash_bin.tscn, docs/evidence/PUL-117/**, docs/backlog/PUL-117-arte-cubo-basura.md]
touches_scenes: [godot/entities/stations/trash_bin.tscn]
---

## Target
Sustituir el modelo provisional del cubo (PUL-112) por uno propio con la estética de D22 (diorama de romería, franquicia PulpaSA) y la señalética de pase de D23, con la tapa que reacciona al tirar (≥ 0,3 s, `cubo-basura.md` T4).

## Acceptance
- [ ] AC1 Modelo importado con colisión igual a la provisional
- [ ] AC2 Se lee como cubo de basura a 1080p desde la cámara (captura)
- [ ] AC3 `tools/verify.sh` en verde

## Plan

## Evidence
