# Decisiones de diseño de la alpha

Tomadas el 2026-10-03 por el responsable del proyecto. Fuente de verdad frente al GDD
(`pulpasa_docs/main.tex`) cuando discrepen. Cambiarlas requiere un gate humano.

| # | Tema | Decisión | Nota |
|---|------|----------|------|
| D1 | Corte del pulpo | Sobre la caja, como el prototipo | Sin estación de corte en la alpha |
| D2 | Métrica de éxito | Recaudación + 0–3 estrellas | Base por receta + bonus por tiempo restante − penalización por caducada. Umbrales en datos |
| D3 | Modo individual | Cambio de personaje (estilo Overcooked) | El no controlado se queda quieto. Cambio < 0,2 s |
| D4 | Condimento | Sí/no | Pimentón dulce o picante, sal sí/no, aceite sí/no, cachelos opcionales |
| D5 | Duración de partida | 5 minutos | Configurable en datos |
| D6 | Repositorio | Privado | Puede que no se usen los modelos de Pandazole; si se usan, pueden versionarse |
| D7 | Erratas del GDD | Se corrigen solo en `docs/design/gdd.md` | `main.tex` queda intacto como entrega académica |

## Decisiones técnicas

| # | Tema | Decisión |
|---|------|----------|
| T1 | Motor | Godot 4.7.2 estable |
| T2 | Lenguaje | GDScript con tipado estático (`untyped_declaration` = error) |
| T3 | Ubicación | `godot/` en este repo; Unity (`Assets/`) queda como especificación hasta la paridad |
| T4 | Tests | GUT 9.7.1 en headless vía `tools/verify.sh` |
| T5 | MCP | `godot-mcp-runtime@3.8.1` (`.mcp.json`) |
| T6 | Orquestación | Orca es el único orquestador; subagentes de Claude Code solo dentro de un worker |
