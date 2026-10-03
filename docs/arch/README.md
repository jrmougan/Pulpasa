# Arquitectura Godot de Pulpasa

Contratos de arquitectura. No se cambian sin ADR (nuevo o enmienda) y gate humano.

La dimensión (3D/2D, D14) está pendiente: ADR-003 §0 separa la capa común (no depende de D14)
de la específica; ADR-005 recoge la comparación para decidir.

| Documento | Tema | Estado |
|---|---|---|
| [ADR-001](ADR-001-gdscript-convenciones.md) | Lenguaje, convenciones GDScript y estructura de carpetas | propuesto |
| [ADR-002](ADR-002-eventbus-autoloads.md) | `EventBus` y autoloads (`GameState`, `OrderService`, `RoundManager`); sustituto de QFramework | propuesto |
| [ADR-003](ADR-003-arbol-escenas-composicion.md) | Árbol de escenas, composición y contrato de interacción | propuesto |
| [ADR-004](ADR-004-input-coop-local.md) | InputMap por jugador y dispositivo; cambio de personaje | propuesto |
| [ADR-005](ADR-005-dimension-3d-2d.md) | Dimensión 3D o 2D (D14): comparación y recomendación | propuesto (decide el responsable) |
| [signals.md](signals.md) | Catálogo de señales con firma, emisor y receptores | propuesto |
| [scene-tree.md](scene-tree.md) | Árbol de escenas objetivo de M0 | propuesto |

## Ciclo de un ADR
`propuesto` → `aceptado` (gate humano del responsable) → `sustituido por ADR-xxx` si se reemplaza.
Una enmienda a un ADR aceptado se añade como sección `## Enmienda N (fecha)` con su propio gate.
Cada ADR tiene: contexto, decisión, alternativas consideradas y consecuencias.
