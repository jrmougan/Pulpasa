# PUL-197 AC3: apariciones de «propuest» y «pendiente» en `docs/arch`

Comando: `grep -inE "propuest|pendiente" docs/arch -r`. Salida literal en `ac3-grep.txt`.

| Aparición | Explicación |
|---|---|
| `docs/arch/ADR-001-gdscript-convenciones.md:96` | Fuera del gate: «rutas propuestas» del inventario |
| `docs/arch/ADR-001-gdscript-convenciones.md:138` | Vigente y correcto: arreglo externo aún sin publicar (godot-mcp-runtime#73) |
| `docs/arch/ADR-002-eventbus-autoloads.md:164` | No es estado: «pendiente» dentro de «independiente» |
| `docs/arch/ADR-003-arbol-escenas-composicion.md:4` | Vigente: G08 pendiente |
| `docs/arch/ADR-003-arbol-escenas-composicion.md:10` | Vigente: G13 pendiente |
| `docs/arch/ADR-003-arbol-escenas-composicion.md:227` | Vigente: G08 pendiente |
| `docs/arch/ADR-003-arbol-escenas-composicion.md:572` | Vigente: G13 pendiente |
| `docs/arch/ADR-003-arbol-escenas-composicion.md:947` | Histórico: alternativa descartada |
| `docs/arch/ADR-003-arbol-escenas-composicion.md:976` | Histórico: alternativa descartada, redactada antes de D14 |
| `docs/arch/ADR-004-input-coop-local.md:32` | Histórico, y lo dice: D14 ya está decidida |
| `docs/arch/ADR-004-input-coop-local.md:139` | No es estado: «pendiente» dentro de «independiente» |
| `docs/arch/ADR-005-dimension-3d-2d.md:13` | Histórico: contexto anterior a la decisión del propio ADR |
| `docs/arch/ADR-005-dimension-3d-2d.md:87` | Histórico: la decisión aceptada viene después en el mismo ADR |
| `docs/arch/ADR-005-dimension-3d-2d.md:118` | Histórico: consecuencia escrita antes de decidir D14 |
| `docs/arch/ADR-006-audio-feedback.md:168` | No es estado: nombre de cue propuesto por el diseño |
| `docs/arch/ADR-006-audio-feedback.md:245` | No es estado: «pendiente» dentro de «independiente» |
| `docs/arch/README.md:6` | No es estado: «pendiente» dentro de «independiente» |
| `docs/arch/README.md:12` | Vigente: G08 y G13 pendientes |
| `docs/arch/README.md:17` | Vigente: G08, G13 y G57 pendientes |
| `docs/arch/README.md:19` | Vigente: G08, G13 y G57 pendientes |
| `docs/arch/README.md:23` | Definición del ciclo de un ADR |
| `docs/arch/scene-tree.md:4` | Vigente: G08, G13 y G57 pendientes |
| `docs/arch/scene-tree.md:113` | Vigente: G13 y G57 pendientes |
| `docs/arch/scene-tree.md:284` | Vigente: G08 pendiente |
| `docs/arch/scene-tree.md:701` | Vigente, fuera del gate: pictogramas a la espera de arte |
| `docs/arch/signals.md:40` | No es estado: «pendiente» dentro de «independiente» |

`docs/arch/gate-enmiendas.md`: 26 apariciones. Las de «Resolución» dicen qué sigue pendiente (G08, G13, G57); todas las demás son el análisis previo al gate, conservado sin cambios a propósito, y no describen el estado actual (lo avisa la resolución al principio del documento). Lista completa en `ac3-grep.txt`.
