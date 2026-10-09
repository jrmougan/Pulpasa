---
id: PUL-103
title: Enmendar los contratos con lo que cambió al implementar M3c
status: draft
milestone: M3c
role: godot-architect
deps: [PUL-101]
orca_task: null
unity_sources: []
owns: [docs/arch/scene-tree.md, docs/arch/ADR-003-arbol-escenas-composicion.md, docs/design/level-layouts.md, docs/evidence/PUL-103/**, docs/backlog/PUL-103-contratos-tras-m3c.md]
touches_scenes: []
---

## Target
`docs/arch/scene-tree.md`, ADR-003 §9.4 y §9.5, `docs/design/level-layouts.md`. Gate humano: los contratos no cambian sin el visto bueno del responsable.

## Change
Reflejar lo que las revisiones de PUL-097…PUL-101 aceptaron y el código ya hace:
- §9.4: la marca de entrega es `DeliveryFrame` dentro de `Model` (glb de PUL-096), localizada con `find_child`; no hay nodo `%DeliveryMark`. Radio de proximidad 2,0 m medido al borde de la cápsula (~2,21 m al centro).
- §9.5: soltar sin objetivo con el punto delante bloqueado por la capa `world` **no suelta nada** (la mano no cambia): `Holder.can_drop_freely()` + `InteractionComponent`; `drop()` no cambia para transferencias. Sustituye a «se suelta a los pies».
- `scene-tree.md`: 6 `PassSlot` repartidos 3+3 (x −5,3/−4,3/−3,3 y 4,7/5,7/6,7), no 4+2; raíz de dispensadores y cuenco 0,45/0,25 m hacia el pase respecto al arte (anclar al `Model`); antirrebote con reloj de juego.
- `level-layouts.md`: hueco de la barra de 1,4 m (x 2,8…4,2, centro 3,5); el de x 7,7 cerrado.

## Constraints
Solo documentación. No cambia código ni escenas. Si algún punto no debería aceptarse, se abre ficha de código en vez de enmendar.

## Acceptance
- [ ] AC1 Los cuatro puntos de Change están en los documentos, con referencia a la ficha que los implementó.
- [ ] AC2 Ninguna contradicción restante entre `rediseno-estaciones.md` (R11), ADR-003 §9.5 y `level-layouts.md` (L1) sobre soltar frente a la barra.

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
