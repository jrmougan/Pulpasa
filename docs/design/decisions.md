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
| D8 | Caja errónea | Se penaliza (cantidad en datos) | Cambio respecto a Unity: entra en M1, M0 mantiene paridad |
| D9 | Capacidad de la olla | Más de 1 pulpo a la vez (capacidad en datos) | M1 |
| D10 | Cachelos | Se cuecen en la olla, compitiendo con el pulpo | M1. Depende de D9 |
| D11 | Cambio de personaje | Tecla fija que alterna entre los dos | Concreta D3 |
| D12 | Asignación de comandas | Cada comanda va a su puesto, como en Unity | Se rechaza «cualquier puesto» |
| D13 | Corte | Pulsación repetida, como en Unity | Se rechaza «mantener pulsado» |
| D14 | 3D o 2D | 3D con cámara ortográfica fija | ADR-005 aceptado. La capa común sigue siendo independiente de la dimensión |
| D15 | Modelos de Pandazole | No se usan en M0: placeholders con primitivas | Olla, fogón, nevera y mesas. Sustitución definitiva en una ficha de arte posterior |
| D17 | Paridad con Unity | No es requisito más allá de M0 | El prototipo era rudimentario: se renuncia a la puerta humana «lado a lado» (2026-10-04). Desde M1 el diseño (`gdd.md`, `decisions.md`) manda sobre el comportamiento de Unity; `Assets/` queda solo como referencia |
| D16 | Assets con licencia sin confirmar | Solo se usa lo confirmado | Lo dudoso se sustituye por alternativas libres (CC0, CC BY, OFL o MIT) o primitivas. Registro en `docs/assets/licenses.md` |
| D21 | Marca ficticia | **PulpaSA** (no «McPulpo» ni nada que imite una marca registrada) | Decidido por el responsable el 2026-10-06 al elegir la estética de referencia (`docs/art/style-refs/referencia-elegida-2026-10-06.png`). Sustituye el «McPULPO» de la imagen en cartel, toldos, uniformes y UI |
| D22 | Estética v2 | Diorama de puesto callejero según `docs/art/style-refs/referencia-elegida-2026-10-06.png`; tono **franquicia satírica** PulpaSA con raíz de romería; identidad **A · Mariña** (`docs/art/brand.md`, lema «Franquicia galega de polbo»); muro de **granito**; **tilt-shift opcional**; objetivo **60 fps a 1080p en la RTX 3090** | Decidido por el responsable el 2026-10-06 (PUL-072, PUL-088). Sustituye la estética low-poly plana de D20 (D20 sigue: arte propio en Blender) |
| D18 | Condimentos | Estación de condimentos en lugar de botes: la caja se deja en la estación y cada condimento se aplica allí; la caja muestra distintivos (pegatinas) con lo que lleva. Debe forzar coordinación entre jugadores | Playtest de M2 (2026-10-05). Sustituye a los botes del prototipo; D4 (sí/no) sigue. Diseño aprobado el 2026-10-05: mostrador de pase con dos lados, dispensadores que alternan, intercambio de pimentón en una pulsación (`paprika_swap`), pegatinas en el orden del ticket (`features/estacion-condimentos.md`) |
| D19 | Mapa de la cocina | Se rediseña la distribución: el game-designer propone 2–3 plantas y el responsable elige | Elegida la **planta B · barra partida** (2026-10-05, `level-layouts.md`). PUL-041 |
| D20 | Dirección de arte | Modelos propios hechos en Blender por un agente con MCP de Blender, uno por ficha, a partir de una biblia de arte | Playtest de M2 (2026-10-05). Sustituye a D15 (placeholders) y desbloquea por otra vía PUL-013. Licencia: propia |

## Decisiones técnicas

| # | Tema | Decisión |
|---|------|----------|
| T1 | Motor | Godot 4.7.2 estable |
| T2 | Lenguaje | GDScript con tipado estático (`untyped_declaration` = error) |
| T3 | Ubicación | `godot/` en este repo; Unity (`Assets/`) queda como especificación hasta la paridad |
| T4 | Tests | GUT 9.7.1 en headless vía `tools/verify.sh` |
| T5 | MCP | `godot-mcp-runtime@3.8.1` (`.mcp.json`) |
| T6 | Orquestación | Orca es el único orquestador; subagentes de Claude Code solo dentro de un worker |
