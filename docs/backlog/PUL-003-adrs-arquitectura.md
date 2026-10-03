---
id: PUL-003
title: Redactar ADR-001..004 y contratos de arquitectura
status: review
milestone: F0
role: godot-architect
deps: [PUL-001]
orca_task: null
unity_sources: [Assets/Scripts/Architecture/**, Assets/Scripts/Systems/**, Assets/Scripts/Interfaces/**]
owns: [docs/arch/**]
touches_scenes: []
---

## Target
`docs/arch/` a partir de `docs/migration/inventory.md` y `docs/design/decisions.md`.

## Change
- ADR-001 Lenguaje y convenciones GDScript (tipado, nombres, estructura de carpetas).
- ADR-002 Bus de eventos y autoloads (`EventBus`, `OrderService`, `GameState`), qué sustituye a QFramework.
- ADR-003 Árbol de escenas y composición (escenas pequeñas, `level_01.tscn` solo instancia).
- ADR-004 Input para coop local y cambio de personaje (InputMap por dispositivo).
- `docs/arch/signals.md`: catálogo de señales con firma tipada.
- `docs/arch/scene-tree.md`: árbol objetivo de M0.

## Constraints
No crear código ni escenas. Cada ADR: contexto, decisión, alternativas, consecuencias.

## Acceptance
- [x] AC1 Los 4 ADR existen con estado «propuesto».
- [x] AC2 Cada señal de signals.md tiene emisor, receptores y tipos.
- [ ] AC3 Gate humano: el responsable aprueba los ADR (estado → «aceptado»).

## Plan
1. Leer inventario (PUL-001), decisiones, roadmap, GDD/features de PUL-002 (`jrmougan/pul-002`) y
   `Assets/Scripts/{Architecture,Systems,Interfaces,Events}`.
2. ADR-001 (convenciones y carpetas), ADR-002 (autoloads + mapa QFramework), ADR-003 (escenas,
   componentes, contrato de interacción, capas), ADR-004 (InputMap por jugador/dispositivo, cambio).
3. `signals.md` y `scene-tree.md` coherentes con los ADR; índice en `docs/arch/README.md`.
4. Redirección del coordinador (D14 pendiente): capa común independiente de 3D/2D (ADR-002 regla 10,
   firmas del bus sin nodos), ADR-003/004 separan común y específico, `scene-tree.md` §6 con
   equivalencias 2D y ADR-005 con comparación y recomendación.

## Evidence
### Revisión de codex (CHANGES) aplicada
- [ALTA] Mandos: `DeviceAssignment` puro con `NONE` (−2, solo teclado) distinto de `ANY` (−1, solo
  `SINGLE`); al aplicar se borran solo los eventos de mando del jugador. Casos de test listados
  (teclado + 1 mando, 2 mandos, desconexión, reconexión). ADR-004 §2.
- [ALTA] Paciencia: `RoundManager._physics_process` (prioridad mínima) → `RoundState.advance` →
  `OrderBoard.advance` (único reloj); señal `order_patience_changed(order_id, time_left, max_time)`
  + `get_active_orders()` para tickets; pausa congela; caducar gana a entregar en el mismo tick;
  reposición en la misma llamada; fin de ronda tras la paciencia. ADR-002 «Reloj y paciencia»,
  `signals.md` §2–§3, `scene-tree.md` §4.
- [MEDIA] Testabilidad: lógica en núcleos `RefCounted` (`OrderBoard`, `RoundState`,
  `DeviceAssignment`) con dependencias por constructor y señales propias; autoloads como
  adaptadores con `set_bus()`; dos instancias aisladas sin `SceneTree`. ADR-002.
- [MEDIA] Capa común sin `Player`: `ControlComponent`, `Holder` (base abstracta) e
  `InteractionComponent`; contrato `interact(actor: InteractionComponent)`,
  `on_picked_up(holder: Holder)`; `CharacterSwitcher` usa `Array[ControlComponent]`; tests con
  dobles. ADR-003 §0/§3/§4, ADR-004 §3–§4.
- [MEDIA] ADR-005: hechos separados de hipótesis (H), alternativas 2D B1 packs / B2 primitivas /
  B3 IA + revisión humana, mediciones propuestas antes del gate; recomendación 3D como propuesta.
- Rebase sobre `jrmougan/agentica-migracion-godot-alpha` (D8–D14, gdd.md).

### Entrega inicial
- AC1: `docs/arch/ADR-00{1,2,3,4}-*.md` (+ ADR-005 pedido por el coordinador), todos con `Estado: propuesto` y secciones contexto,
  decisión, alternativas consideradas y consecuencias. Índice en `docs/arch/README.md`.
- AC2: `docs/arch/signals.md` §2 (13 señales de `EventBus`) y §4 (8 locales): cada fila tiene
  firma tipada, emisor, receptores, cuándo y fase; tipos de las firmas en §1.
- AC3: pendiente del gate humano (estado → «aceptado»).
- `tools/verify.sh`: ✓ verify OK (2026-10-03; sin código ni escenas nuevas).
- Decisiones a revisar en el gate: se añade `RoundManager` como 4.º autoload (ADR-002); estructura
  `entities/`/`components/`/`ui/` sustituye las rutas `scenes/...` del inventario (ADR-001);
  contrato de interacción por grupo + métodos (ADR-003 §4); asignación de mandos (ADR-004 §2);
  D11 aplicada (tecla fija, ADR-004 §4); D8 prevista en la firma `delivery_rejected(slot_id, penalty)`;
  **D14 (3D/2D)**: ADR-005 recomienda 3D con cámara ortográfica (la del prototipo ya lo es).
