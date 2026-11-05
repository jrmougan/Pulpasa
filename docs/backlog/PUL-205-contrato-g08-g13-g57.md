---
id: PUL-205
title: Corregir las frases de contrato pendientes del gate (G08, G13, G57)
status: done
milestone: M4
role: godot-architect
deps: [PUL-202]
orca_task: null
unity_sources: []
owns: [docs/arch/ADR-003-arbol-escenas-composicion.md, docs/arch/scene-tree.md, docs/arch/README.md, docs/arch/gate-enmiendas.md, docs/arch/signals.md, docs/arch/ADR-006-audio-feedback.md]
touches_scenes: []
---

## Target
Las seis frases de G08 y la atribución a test de G13 y G57.

## Change
Reescribir esas frases según el código (D26): `interact_pressed()`, dispensador, cuenco, `Slot.accepted_group`, la caja guardada y la caja con la mano llena. G13 y G57 citan el test que prueba la regla tras PUL-202. Retirar las salvedades de cabeceras e índice.

Tras PUL-198:
- `signals.md:90` y `:271`: añadir `order_stand.gd` como receptor de `order_patience_changed` (`order_stand.gd:65`).
- Retirar o pasar a pasado las notas de que `order_stand.gd:156` incumple «sin emisión en el juego»: `signals.md` (2), `scene-tree.md`, ADR-003 (2) y ADR-006.

## Constraints
**Requiere gate humano antes del merge**: es contrato. Solo cambia esas frases y sus marcas; no cambia código. Cada frase nueva cita `ruta:línea`.

## Acceptance
- [x] AC1 Given cada frase, When se abre la ruta citada, Then el código coincide → tabla en docs/evidence/PUL-205/
- [x] AC2 Given `docs/arch`, When se busca G08, G13 y G57, Then no queda ninguna salvedad vigente → salida en docs/evidence/PUL-205/

## Plan
Solo documentos de `owns`, la ficha y `docs/evidence/PUL-205/`; sin código ni señales nuevas.
- G08: reescribir en ADR-003 §8.2 `interact_pressed()`, dispensador, cuenco, `Slot.accepted_group` y la caja guardada; en `scene-tree.md` §3, la caja y `accepted_group`. Quitar la nota «Pendiente» y las salvedades de cabecera e índice.
- G13 y G57: citar `test_t6_trash_bins_are_far_from_every_target_and_the_gap`, tras comprobar que mide cada `OrderStand`.
- PUL-198: comprobar con el código y con la reproducción de PUL-196 que no queda camino de emisión; añadir el receptor en `signals.md` y pasar a pasado las seis notas.
- Verificación: tabla con frase antigua, nueva y `ruta:línea`; comprobador de citas; búsqueda de G08, G13 y G57; `tools/verify.sh --quick`; `tools/check_owns.py`.

## Evidence
Todo en `docs/evidence/PUL-205/`.
- AC1: `ac1-frases.md` (frase antigua, frase nueva y `ruta:línea`); `comprobar_citas.py` y `comprobar-citas.txt` (44/44 citas). `repro-entrega.txt`: 0 emisiones con `REPRO_LEAD` 0, 1 y 2. `sonda-segunda-caja.txt`: en `level_01` real, la segunda caja de cara al slot a 0,6-1,2 m da `busy` y sigue en la mano; a 1,5 m o de espaldas, cae al suelo. `sonda-pausa-sin-paciencia.txt`: 1 emisión con `max_time` 0 y pausa, 0 con `max_time` 60. `datos-paciencia.txt`: paciencia en los datos del juego. `tests-afectados.txt`: tests citados.
- AC2: `ac2-busqueda.txt`: lo que queda de G08, G13 y G57 en `docs/arch` es la corrección de PUL-205 o el análisis histórico de `gate-enmiendas.md`.
- `verify-quick.txt`: `tools/verify.sh --quick`.
- **Gate humano pendiente**: la rama no se mergea sin él. Lo que más debe mirar: «no se suelta la segunda caja (AC9)» pasa a decir que se suelta si hay sitio y, si no, da rechazo `busy` (A9), que es lo que hace el código.
- No verificable: partida completa de `level_01`, porque la reproducción y la sonda fuerzan la situación. La ausencia de emisión es un argumento por lectura más tres casos ejecutados. La rama `max_time <= 0` con pausa se ha ejecutado en una sonda con datos forzados, y sí emite; no se alcanza con los datos del juego, y las notas lo declaran como precondición.
- Revisión de PUL-205: H1, H2, H3 y H4 comprobados contra el código; los cuatro son ciertos y están corregidos. H2 y H3 se ejecutaron. El resumen anterior de la segunda caja («cae al suelo») venía de una sonda sin barra y no valía para `level_01`.
- Frases dudosas vistas de pasada, fuera de la ficha y sin tocar:
  - ADR-003 §9.1: «el cuenco no» es objetivo con la caja a medio cortar, y «las dos son de `is_reachable_from`». Hoy `for_bowl` da `BLOCKED` `BOX_NOT_FULL` con esa caja (`godot/core/action_rules.gd:101`), y lo decide `get_action_hint`.
  - `signals.md` §3, «Entrega errónea» y «Entrega en el tick de caducidad»: describen el núcleo sin decirlo, y en el juego no se alcanzan.
