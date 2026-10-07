# PUL-093 · Trazabilidad D23 → contratos

Fecha: 2026-10-07. Rol: godot-architect. Solo documentación.

Fuentes: D23 en `docs/design/decisions.md` (con la aclaración del cuenco, `80a1cb1` de la rama
base, y el mensaje del producer `msg_b49a26eeef24`), `docs/design/rediseno-estaciones.md` §3–§4
(C-B, B-A, E-A, N-A, R1–R17) y §7, fichas PUL-094..PUL-101, y el código de la rama
(`seasoning_station.gd`, `seasoning_dispenser.gd`, `cachelos_bowl.gd`, `order_stand.gd`, `slot.gd`,
`box_data.gd`, `environment.tscn`, `level_01.tscn`).

## Qué pide D23 y dónde queda en el contrato

| D23 / R | Contrato | Ficha que lo implementa |
|---|---|---|
| Sin bandeja; caja llena en la mano (C-B), R7 | ADR-003 §9.2; `scene-tree.md` §3 (estación, `Tray` BAJA) y §7.1 | PUL-097 |
| Dispensador: caja en mano, lado de servicio; R1–R4 | ADR-003 §9.1 (matriz); `scene-tree.md` §3 (`seasoning_dispenser.tscn`); `signals.md` §4 | PUL-097 |
| Cuenco: cachelos cocidos (cualquier lado) / caja llena (servicio); R5–R6 | ADR-003 §9.1; `scene-tree.md` §3 (`cachelos_bowl.tscn`, `Portions0..4`) y §5 (`seasoning_station.tres` 2 / 4) | PUL-097 (modelo PUL-094) |
| Antirrebote con reloj de juego (pregunta abierta 4) | ADR-003 §9.2 | PUL-097 |
| `operator_side_only` se mantiene (pregunta abierta 3) | ADR-003 §9.1, `scene-tree.md` §5 | — (dato sin cambio) |
| Corte 4/6/10, tamaño S/M/L en ticket y rack; R9–R10 | ADR-003 §9.3: `BoxData.short_label: String`, `BoxData.icon: Texture2D`; `scene-tree.md` §5 | PUL-098 (iconos PUL-095), ticket PUL-099 |
| Color de puesto en el ticket; R13 | ADR-003 §9.3: `StandPalette` (`colors: Array[Color]`, `fallback: Color`, `color_for(slot_id: int) -> Color`), `data/config/stand_palette.tres` | PUL-099 (hex PUL-096) |
| Zona de entrega iluminada; R12 | ADR-003 §9.4; `scene-tree.md` §3 (`%DeliveryMark`, `%ProximityArea` 2,0 m, `is_zone_lit()`) | PUL-100 (modelo PUL-096) |
| 6 pasaplatos marcados; resto de la barra sin `Slot`; R11 | ADR-003 §9.5; `scene-tree.md` §2 (`PassSlot01..06`) y §3 (`slot.tscn` con `pass_mark`) | PUL-101 (marca PUL-095) |
| Hueco de la barra a x ≈ 3,2; R14 | ADR-003 §9.5; `scene-tree.md` §2 (mapa y `KitchenLayout`) | PUL-101 (umbral PUL-095; posición exacta en `level-layouts.md`, PUL-092) |
| Tecla única / InputMap (G9) | ADR-003 §9 (contexto): sin cambios | — |
| Señales | `signals.md`: ninguna nueva ni cambio de firma; `NO_BOX` y `NOT_ACCEPTED` en desuso; receptores M3c en §2 | — |
| QA M3b: `Bulbs` y `Vignette` | `scene-tree.md` §2 (`Environment`) y §3 (`environment.tscn`), §6 (2D) | — (ya existen, PUL-073) |

## Decisiones de contrato tomadas aquí (para la revisión del producer)

1. **Dispensador con caja a medio cortar = objetivo que rechaza** (`BOX_NOT_FULL`), porque R3 pide
   rechazo con `season_error`. El cuenco, en cambio, no es objetivo con una caja a medio cortar
   (aclaración del producer). Si se quiere simetría, cambia R3 (PUL-092) o la aclaración.
2. **La marca del pasaplatos va en `slot.tscn`** (su `Model` pasa a `pass_mark`), no en
   `kitchen_layout.tscn`: marca y `Slot` no pueden separarse. Hoy nadie es dueño de `slot.tscn`:
   **PUL-101 necesita `godot/entities/stations/slot.tscn` en `owns` y `touches_scenes`**.
3. **Radio de 2,0 m del indicador como geometría de la escena** (`%ProximityArea`), no como dato
   `.tres`: es una regla de lectura (R12), no de balance; lo fija el test de PUL-100.
4. **R11 «no suelta nada» fuera de los pasaplatos**: el contrato de soltar sin objetivo (ADR-003 §6)
   no cambia; si el test de PUL-101 muestra que lo soltado queda sobre la barra, la corrección
   (soltar a los pies si el punto cae dentro de la capa `world`) va en `HoldComponent` con una
   ficha que asigne el producer.
5. **Posiciones de los 6 `PassSlot` y del hueco** orientativas (4 al oeste de la estación como hoy,
   2 al este del hueco); manda `level-layouts.md` de PUL-092 con R14.

## Huecos de propiedad detectados (para el producer)

Usan `Tray` / `get_tray()` / `get_box()` y no están en el `owns` de ninguna ficha de M3c:
`tests/integration/test_m2b_station_selection.gd`, `test_m2b_flow.gd`, `test_station_level.gd`,
`test_delivery_e2e.gd`, `test_kitchen_flow.gd`, `test_m1_flow.gd`, `test_m2_flow.gd`,
`test_parity_smoke.gd` (comprobado con
`grep -rln "get_tray\|get_box()\|Tray" godot --include=*.gd --include=*.tscn`). Se rompen al
quitar `Tray` en PUL-097: hay que dárselos a PUL-097 (o a PUL-101 los de flujo de nivel).

## Verificación

`tools/verify.sh` en verde (ver la Evidence de la ficha). No hay cambios en `godot/`.
