---
id: PUL-093
title: Enmendar los contratos para la estación sin bandeja y los pasaplatos marcados
status: review
milestone: M3c
role: godot-architect
deps: []
orca_task: null
unity_sources: []
owns: [docs/arch/scene-tree.md, docs/arch/ADR-003-arbol-escenas-composicion.md, docs/arch/signals.md, docs/arch/README.md, docs/evidence/PUL-093/**, docs/backlog/PUL-093-contratos-estacion-al-paso.md]
touches_scenes: []
---

## Target
Contratos afectados por D23: `scene-tree.md` (`seasoning_station.tscn` sin `Tray`; dispensadores y cuenco actúan sobre la caja **en la mano** del actor; 6 `PassSlot` en el nivel con su marca visual; zona de entrega con indicador en `order_stand.tscn`; hueco de la barra a x≈3,2), ADR-003 §8 y, si hace falta, `signals.md`. Pendiente del QA de M3b: `Bulbs` y `Vignette` no aparecen en `scene-tree.md`.

## Change
Enmienda ADR-003 (sección nueva fechada) y `scene-tree.md` para D23: nodos que desaparecen o se añaden, quién es objetivo con qué en la mano (dispensador: caja llena en mano y lado de servicio; cuenco: cachelos cocidos para reponer y caja en mano para alternar), nuevos campos de `BoxData` (`short_label: String`, `icon: Texture2D`), recurso de colores de puesto (`StandPalette`, `data/config/stand_palette.tres`, `slot_id` 1–4 → color) y el indicador de la zona de entrega. Confirma que **no hace falta ninguna señal nueva** (`seasoned`/`seasoning_removed`/`order_*` existentes) o justifícala. Añade `Bulbs` y `Vignette` al árbol del nivel.

## Constraints
Solo documentación. El responsable aprobó el diseño (D23); el producer revisa la enmienda antes de la oleada 2. InputMap sin cambios (tecla única).

## Acceptance
- [x] AC1 ADR-003 y `scene-tree.md` describen la estación sin `Tray`, los 6 `PassSlot`, el indicador de entrega y el hueco nuevo
- [x] AC2 Contratos de datos `BoxData.short_label/icon` y `StandPalette` definidos con tipos
- [x] AC3 `signals.md` sin cambios o con la señal justificada; `Bulbs`/`Vignette` añadidos

## Plan
1. Fuentes: D23 (con la aclaración del cuenco del producer, `80a1cb1`), `rediseno-estaciones.md`
   §3–§4 (C-B, B-A, E-A, N-A, R1–R17), fichas PUL-094..PUL-101 y el código actual de la estación,
   el puesto, `Slot`, `BoxData` y `environment.tscn`.
2. ADR-003: sección nueva **§9 Enmienda D23 (2026-10-07, PUL-093)** que sustituye las partes de §8
   que dependían de la bandeja (tabla de §8.1, `accepted_group` de §8.2, `get_box()` de §8.3, bajas de
   §8.4): matriz de objetivos por lo que hay en la mano, antirrebote con reloj de juego, datos
   (`BoxData.short_label/icon`, `StandPalette`, `seasoning_station.tres`), pasaplatos marcados,
   indicador de entrega y hueco. Notas «→ §9» en §8 y estado/cabecera.
3. `scene-tree.md`: cabecera de enmienda; §2 (planta con hueco a x ≈ 3,2, 6 `PassSlot`,
   `Environment` con `Bulbs`/`Vignette`); §3 (estación sin `Tray`, dispensador, cuenco, `slot.tscn`
   con la marca, `order_stand.tscn` con `%DeliveryMark`/`%ProximityArea`, `environment.tscn`); §5
   (datos); §7 bajas D23.
4. `signals.md`: sin señales nuevas; se actualizan las filas locales y la secuencia del dispensador
   y del cuenco (caja en la mano), `NO_BOX` en desuso, y la justificación de por qué no hace falta
   nada en `EventBus`. `README.md`: estado de la enmienda.
5. Evidencia en `docs/evidence/PUL-093/` (trazabilidad D23/R → contrato y decisiones abiertas);
   `tools/verify.sh` en verde.

## Evidence
- AC1: ADR-003 §9 (enmienda D23, 2026-10-07) §9.1 matriz de objetivos por lo que hay en la mano,
  §9.2 sin `Tray`/`get_box()` y antirrebote con reloj de juego, §9.4 indicador de entrega
  (`%DeliveryMark`, `%ProximityArea` 2,0 m, `is_zone_lit()`), §9.5 6 `PassSlot` con `pass_mark` en
  `slot.tscn` y hueco x ≈ 3,2. `scene-tree.md` §2 (mapa y árbol del nivel), §3 (estación, dispensador,
  cuenco, `slot.tscn`, `order_stand.tscn`) y §7.1 (bajas D23).
- AC2: ADR-003 §9.3 y `scene-tree.md` §5: `BoxData.short_label: String`, `BoxData.icon: Texture2D`;
  `StandPalette` (`colors: Array[Color]`, `fallback: Color`, `color_for(slot_id: int) -> Color`) en
  `data/config/stand_palette.tres`; `seasoning_station.tres` 2 raciones / máx. 4.
- AC3: `signals.md` sin señales nuevas ni cambios de firma (justificación en §4; `NO_BOX` y
  `NOT_ACCEPTED` en desuso; receptores M3c en §2). `Bulbs`/`Vignette` en `scene-tree.md` §2, §3
  (`environment.tscn`) y §6.
- Trazabilidad, decisiones para la revisión y huecos de propiedad: `docs/evidence/PUL-093/trazabilidad.md`.
  A resolver por el producer: PUL-101 necesita `slot.tscn` en `owns`/`touches_scenes`; 8 tests de
  integración que usan `Tray` no tienen dueño en M3c.
- `tools/verify.sh`: OK (gdformat, gdlint, import, GUT 735/735, smoke) el 2026-10-07.
