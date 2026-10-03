# PUL-020 — HUD y tickets

Implementación de las cinco escenas solicitadas, con scripts tipados y el tema común.
El HUD escucha `round_started`, `round_time_changed` y `score_changed`: muestra segundos y
cajas/minuto sin `_process`, temporizador propio ni arranque de ronda. El nodo
`RevenuePlaceholder` reserva la recaudación de M1 sin mostrarla ni calcularla.
El HUD se monta antes de `start_round`, como en el sandbox y la composición del nivel.

El panel reconstruye una vez desde `get_active_orders`, evita duplicados por id y elimina
inmediatamente del contenedor los tickets completados, caducados o reseteados, liberándolos
al final del frame. Cada ticket muestra receta y condimentos de sus recursos y solo acepta
la señal de paciencia de su propio id; `%PatienceBar` permanece oculta en M0.

Los textos utilizan `tr()` con claves `HUD_*`, `TICKET_ID_FORMAT`, `RECIPE_*` y
`SEASONING_*`, con texto castellano de respaldo mientras no haya catálogo de traducciones.
HUD y tickets son informativos, no contienen botones ni capturan el foco de los menús.
El script del sandbox vive en `ui/hud/hud_sandbox.gd` para respetar el owns de la ficha.
No se modificaron autoloads, señales, recursos de balance ni contratos.

## Comprobaciones

- `tools/verify.sh`: formato, lint, importación, GUT y smoke en verde (log adjunto).
- 337 tests / 1820 aserciones en la suite completa; nueve tests nuevos de integración.
- AC1: montaje sin arrancar ronda, ausencia de avance sin eventos, reloj real detenido
  durante pausa, final a cero, productividad con tiempo/entregas y reinicio de ronda.
- AC2: cuatro tickets únicos, entrega real con sustitución, reset, caducidad y filtrado
  de paciencia por id, incluida la ocultación con `max_time = 0`.
- AC3: montaje tardío desde comandas activas y comprobación de receta/condimentos.
- AC4: `ac4-hud-y-tickets.png`, captura MCP de 1280×720 del sandbox real bajo Xvfb.
  El sandbox llama a `OrderService.setup` y `RoundManager.start_round` por sí mismo;
  no se alteró su estado mediante scripts para la captura.
- El MCP no tenía DISPLAY, por lo que se usó `attach_project` con Godot iniciado bajo
  Xvfb y renderer Compatibility. Se inspeccionó stdout/stderr directamente (adjunto),
  sin ERROR ni SCRIPT ERROR; solo avisos de X11 y V-Sync. Se cerró la sesión al terminar.
- Escenas guardadas por las APIs `PackedScene`/`ResourceSaver` mediante el MCP; `.uid`
  generados por la importación de Godot, no inventados.
