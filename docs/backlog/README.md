# Backlog

Una ficha por tarea: `PUL-<nnn>-<slug>.md`, a partir de `_TEMPLATE.md`.

- **Ciclo:** draft → ready (la marca el producer) → in_progress → review → done.
- **owns / touches_scenes** limitan lo que el worker puede editar. Un `.tscn` tiene un solo
  dueño por oleada.
- Cada criterio de aceptación enlaza con un test o con una captura en `docs/evidence/<id>/`.
- El cuerpo sigue el contrato de Orca (Target, Change, Constraints, Ownership, Acceptance),
  así que la ficha se pasa tal cual a `worker-start --spec`.

## Fichas actuales

| Id | Hito | Rol | Estado | Título |
|----|------|-----|--------|--------|
| PUL-001 | F0 | migration-analyst | done | Inventario Unity → Godot |
| PUL-002 | F0 | game-designer | done | GDD de trabajo y backlog de la alpha |
| PUL-003 | F0 | godot-architect | done | ADR-001..004 y contratos |
| PUL-004 | M0·0 | godot-architect | done | Esqueleto: EventBus, GameState, InputMap |
| PUL-005 | M0·1 | gameplay-engineer | done | Resources y .tres del prototipo |
| PUL-006 | M0·2 | gameplay-engineer | done | Núcleos OrderBoard y RoundState |
| PUL-007 | M0·2 | gameplay-engineer | done | Autoloads OrderService y RoundManager |
| PUL-008 | M0·3 | asset-pipeline | done | Placeholders 3D, muebles propios y escena de escala |
| PUL-009 | M0·3 | asset-pipeline | done | Audio, fuentes e iconos libres (CC0/OFL) |
| PUL-010 | M0·3 | godot-architect | done | Exportación Linux, Windows y Web |
| PUL-011 | M0·4 | gameplay-engineer | done | Componentes comunes: Control, Holder, PlayerInput |
| PUL-012 | M0·4 | gameplay-engineer | done | Escena del jugador, HoldComponent y cámara |
| PUL-013 | M0·4 | asset-pipeline | superseded (→ PUL-044, D20) | Modelo y AnimationTree del jugador |
| PUL-014 | M0·5 | gameplay-engineer | done | Interacción común: scoring, componente y contrato |
| PUL-015 | M0·5 | gameplay-engineer | done | Detector 3D, resaltado por shader y slots |
| PUL-016 | M0·6 | gameplay-engineer | done | Objetos: pulpo, caja y condimento |
| PUL-017 | M0·6 | gameplay-engineer | done | Estaciones: nevera, olla y estanterías |
| PUL-018 | M0·6 | gameplay-engineer | done | Puesto de entrega conectado a OrderService |
| PUL-019 | M0·6 | qa-tester | done | Sandbox de cocina y flujo completo |
| PUL-020 | M0·7 | ui-engineer | done | HUD y panel de tickets |
| PUL-021 | M0·7 | ui-engineer | done | Menú de pausa y fin de partida |
| PUL-022 | M0·7 | ui-engineer | done | Menú principal y flujo de escenas |
| PUL-023 | M0·7 | ui-engineer | done | Pulido de UI con hallazgos de revisión |
| PUL-024 | M0·8 | gameplay-engineer | done | Montaje de level_01 con UI integrada |
| PUL-025 | M0·8 | qa-tester | done | Smoke de paridad M0 y guía de la puerta humana |
| PUL-026 | M0·8 | ui-engineer | done | Layout de HUD y tickets como Unity + menores de level_01 |
| PUL-027 | M1 | gameplay (antigravity → kimi) | done | Paciencia, recaudación, penalizaciones y estrellas |
| PUL-028 | M1 | gameplay (antigravity · flash) | done | Aceite, exclusividad de pimentones y validación exacta |
| PUL-029 | M1 | gameplay (antigravity → kimi) | done | Cachelos y olla con varias plazas |
| PUL-030 | M1 | ui (kimi → Claude) | done | Recaudación, estrellas, iconos y paciencia en la UI |
| PUL-031 | M1 | asset-pipeline (kimi) | done | Iconos y placeholders de aceite, cachelos y estrellas |
| PUL-032 | M1 | qa (Claude) | done | Novedades de M1 en level_01 y QA de M1 |
| PUL-033 | M1 | gameplay (Claude) | done | Comandas con cachelos y legibilidad de cachelos |
| PUL-034 | M2 | gameplay-engineer | done | Asignar mandos a jugadores y gestionar su conexión |
| PUL-035 | M2 | gameplay-engineer | done | Cambiar de personaje en modo individual y marcar el activo |
| PUL-036 | M2 | ui-engineer | done | Menú por modo, avisos de mando y UI navegable solo con mando |
| PUL-037 | M2 | qa-tester | done | Integrar dos personajes en level_01 y pasar el QA de M2 |
| PUL-038 | M2 | ui-engineer | done | Evitar que el aviso de mando desconectado tape los tickets |
| PUL-039 | M2 | gameplay-engineer | done | Reproducir y arreglar que no se pueda entregar en level_01 |
| PUL-040 | M2 | game-designer | done | Diseñar la estación de condimentos y los distintivos de la caja |
| PUL-041 | M2 | game-designer | done | Proponer dos o tres distribuciones de la cocina |
| PUL-042 | M2 | game-designer | done | Escribir la biblia de arte y la lista de assets |
| PUL-043 | M2 | asset-pipeline | done | Preparar el MCP de Blender y el pipeline Blender → glTF → Godot |
| PUL-044 | M3 | asset-pipeline | done | Modelar y animar el personaje (dos variantes) |
| PUL-045 | M3 | asset-pipeline | done | Modelar el pulpo crudo, cocido y troceado |
| PUL-046 | M3 | asset-pipeline | done | Modelar los cachelos crudos y cocidos |
| PUL-047 | M3 | asset-pipeline | done | Modelar las tres cajas/platos de madera y sus distintivos |
| PUL-048 | M3 | asset-pipeline | done | Modelar el caldero de cobre y el fogón |
| PUL-049 | M3 | asset-pipeline | done | Modelar el arcón de pulpo |
| PUL-050 | M3 | asset-pipeline | done | Modelar la cachelera (saco o cesto de patatas) |
| PUL-051 | M3 | asset-pipeline | done | Modelar la estantería de cajas |
| PUL-052 | M3 | asset-pipeline | done | Modelar la estación de condimentos |
| PUL-053 | M3 | asset-pipeline | done | Modelar el puesto de entrega |
| PUL-054 | M3 | asset-pipeline | done | Modelar las encimeras modulares |
| PUL-055 | M3 | asset-pipeline | done | Modelar el entorno de romería |
| PUL-056 | M2 | godot-architect | done | Enmendar los contratos para la estación de condimentos |
| PUL-057 | M2 | gameplay-engineer | done | Implementar las reglas de condimento como núcleo |
| PUL-058 | M2 | gameplay-engineer | done | Crear la escena de la estación de condimentos |
| PUL-059 | M2 | gameplay-engineer | done | Mostrar los distintivos de condimento sobre la caja |
| PUL-060 | M2 | ui-engineer | done | Ordenar los iconos del ticket y darles estilo de pegatina |
| PUL-061 | M2 | gameplay-engineer | done | Montar level_01 con la planta B y la estación, y retirar los botes |
| PUL-062 | M2 | qa-tester | done | Pasar el QA de la estación y la planta B y preparar el playtest |
| PUL-063 | M2 | gameplay-engineer | done | Hacer inequívoca la selección de dispensadores y bandeja en la estación |
| PUL-064 | M2 | gameplay-engineer | done | Ignorar los dispensadores cuando el jugador lleva algo en la mano |
| PUL-065 | M3 | gameplay-engineer | superseded | Encender fuego y vapor de la olla solo al cocinar |
| PUL-066 | M3 | godot-architect | done | Enmendar los contratos para audio, quemado y fases |
| PUL-067 | M3 | gameplay-engineer | done | Retirar placeholders y escalas heredadas tras el arte |
| PUL-068 | M3 | asset-pipeline | done | Conseguir música, ambiente y efectos libres para M3 |
| PUL-069 | M3 | gameplay-engineer | done | Quemar el pulpo que se deja en la olla y encender sus efectos |
| PUL-070 | M3 | gameplay-engineer | done | Subir la dificultad por fases |
| PUL-071 | M3 | gameplay-engineer | done | Integrar música, ambiente y feedback de las acciones |
| PUL-072 | M3b | game-designer | done | Reescribir la biblia de arte con la estética de referencia |
| PUL-073 | M3b | asset-pipeline | done | Ajustar luz, sombras y post-proceso a la estética de referencia |
| PUL-074 | M3b | asset-pipeline | done | Crear la biblioteca de materiales estilizados |
| PUL-075 | M3b | asset-pipeline | done | Rehacer el personaje con la estética de referencia |
| PUL-076 | M3b | asset-pipeline | done | Rehacer pulpo, cachelos y raciones con la estética de referencia |
| PUL-077 | M3b | asset-pipeline | done | Rehacer platos/cajas como bandejas de la referencia |
| PUL-078 | M3b | asset-pipeline | done | Rehacer las ollas como cocedores de acero |
| PUL-079 | M3b | asset-pipeline | done | Convertir el arcón en tanque de pulpos |
| PUL-080 | M3b | asset-pipeline | done | Rehacer la cachelera como sacos de patatas |
| PUL-081 | M3b | asset-pipeline | done | Rehacer la estantería como rack de bandejas |
| PUL-082 | M3b | asset-pipeline | done | Rehacer la estación de condimentos |
| PUL-083 | M3b | asset-pipeline | done | Rehacer los puestos de entrega como kioscos |
| PUL-084 | M3b | asset-pipeline | done | Rehacer encimeras y suelo de la cocina |
| PUL-085 | M3b | asset-pipeline | done | Rehacer el entorno con la estética de referencia |
| PUL-086 | M3b | ui-engineer | done | Adaptar HUD y tickets a la estética de referencia |
| PUL-087 | M3b | qa-tester | done | Pasar el QA visual y de rendimiento de la estética v2 |
| PUL-088 | M3b | asset-pipeline | done | Diseñar la identidad de la marca PulpaSA |
| PUL-089 | M3b | asset-pipeline | done | Ajustar el cielo y los reflejos para que el acero se lea claro |
| PUL-090 | M3c | game-designer | done | Diagnosticar y proponer el rediseño jugable de las estaciones de condimento y bandejas |
| PUL-091 | M3c | asset-pipeline | done | Auditar la lectura visual de estaciones y bandejas y proponer su rediseño artístico |
| PUL-092 | M3c | game-designer | done | Reescribir las features de estaciones según D23 |
| PUL-093 | M3c | godot-architect | done | Enmendar los contratos para la estación sin bandeja y los pasaplatos marcados |
| PUL-094 | M3c | asset-pipeline | done | Rehacer la estación de condimentos como línea al paso (arte, Codex) |
| PUL-095 | M3c | asset-pipeline | done | Rehacer rack, bandejas S/M/L y marcas de pasaplatos (arte, Codex) |
| PUL-096 | M3c | asset-pipeline | done | Rehacer los kioscos con placa de comanda y zona de entrega (arte, Codex) |
| PUL-097 | M3c | gameplay-engineer | done | Implementar la estación de condimentos al paso |
| PUL-098 | M3c | gameplay-engineer | done | Aplicar los cortes 4/6/10 y el tamaño legible de las bandejas |
| PUL-099 | M3c | ui-engineer | done | Mostrar el tamaño y el color del puesto en el ticket |
| PUL-100 | M3c | gameplay-engineer | done | Encender la zona de entrega del kiosco con la caja correcta |
| PUL-101 | M3c | gameplay-engineer | done | Montar level_01 con la línea al paso, el hueco nuevo y 6 pasaplatos |
| PUL-102 | M3c | qa-tester | done | Medir el rediseño de estaciones y preparar el playtest |
| PUL-103 | M3c | godot-architect | done | Enmendar los contratos con lo que cambió al implementar M3c |
| PUL-104 | M3c | gameplay-engineer | done | Contar cortes en enteros y agotar ingredientes con épsilon |
| PUL-105 | M3c | gameplay-engineer | done | Dar superficie a los pasaplatos de los sandboxes |
| PUL-106 | M3c | godot-architect | done | Enmendar contratos y diseño con presses_to_fill |
| PUL-107 | M3c | game-designer | done | Poner al día el GDD §9 (reglas vigentes) con decisions.md y el código |
| PUL-108 | M3c | game-designer | done | Limpiar el diseño superado y registrar D24 (entrega en el tick de caducidad) |
| PUL-109 | M3c | gameplay-engineer | done | Test de caja errónea entregada en el tick de caducidad (D24) |
| PUL-110 | M3d | game-designer | done | Registrar D25 (simplificación de mecánicas) y poner el diseño al día |
| PUL-111 | M3d | godot-architect | done | Enmendar los contratos para D25 (caja única, aliño, cubo de basura) |
| PUL-112 | M3d | gameplay-engineer | done | Implementar el cubo de basura y colocar 2 en level_01 |
| PUL-113 | M3d | gameplay-engineer | done | Quitar los tamaños de caja (caja única de 6 cortes) |
| PUL-114 | M3d | gameplay-engineer | done | Aliño de una pulsación y catálogo de 4 comandas |
| PUL-115 | M3d | gameplay-engineer | done | Escalar mecánicas por fase (comandas por fase) |
| PUL-116 | M3d | qa-tester | done | Re-medir R15/R17 tras D25 y preparar el playtest de M3d |
| PUL-117 | M3d | asset-pipeline | done | Arte del cubo de basura (dirección A, D22) |
| PUL-118 | M3d | gameplay-engineer | done | Estabilizar test_level_01_r16 (intermitente bajo carga) |
| PUL-119 | M3e | game-designer | done | Registrar D26 (lenguaje de acciones y móvil) y poner el diseño al día |
| PUL-120 | M3e | godot-architect | done | Enmendar los contratos para D26 (verbo de acción, prompt, táctil, cámara móvil) |
| PUL-121 | M3e | gameplay-engineer | done | Núcleo del lenguaje de acciones, histéresis y bus |
| PUL-122 | M3e | ui-engineer | done | Escala de UI, safe area, perfil de plataforma y menús móviles |
| PUL-123 | M3e | asset-pipeline | done | Iconos de verbos, motivos y marcas; aliño picante propio; rack y caja sin S/M/L |
| PUL-124 | M3e | asset-pipeline | done | Cues de D26 |
| PUL-125 | M3e | gameplay-engineer | done | Verbo en cocina y objetos; anillo de cocción, contador de corte y aviso de quemado |
| PUL-126 | M3e | gameplay-engineer | done | Verbo en la estación de condimentos y cuenco que solo pone |
| PUL-127 | M3e | gameplay-engineer | done | Prompt de acción en el mundo, respuesta del jugador, aro activo y contorno |
| PUL-128 | M3e | ui-engineer | done | Controles táctiles |
| PUL-129 | M3e | ui-engineer | done | HUD y tickets para móvil |
| PUL-130 | M3e | gameplay-engineer | done | Cámara con perfiles, seguimiento móvil y flecha de borde |
| PUL-131 | M3e | gameplay-engineer | done | Entrega solo por zona, montaje D26 en `level_01` y limpieza de contrato |
| PUL-132 | M3e | qa-tester | done | QA de D26 |
| PUL-133 | M3e | gameplay-engineer | done | Cámara móvil bajo la banda superior, aro inactivo fino y game over sin cajas/minuto |
| PUL-134 | M3e | gameplay-engineer | done | Flecha de borde y zona de botones como zonas tapadas en la cámara móvil |
| PUL-135 | M3e | gameplay-engineer | done | Comprobar la zona de botones de la cámara con safe area derecha |
| PUL-136 | M3e | game-designer | done | Decidir cómo evitar que los botones táctiles tapen los contadores del pasaplatos este |
| PUL-137 | M3e | godot-architect | done | Enmendar ADR-005 E4 para los botones en fila y la zona de botones con safe area |
| PUL-138 | M3e | ui-engineer | done | Colocar los botones táctiles en fila y bajar la zona de botones |
| PUL-139 | M4 | qa-tester | done | Triar los pendientes sueltos del roadmap y crear sus fichas |
| PUL-140 | M3e | game-designer | done | Crear las fichas de cierre de M3e (guía de playtest y export Android) |
| PUL-141 | M4 | game-designer | done | Planificar M4 (alpha) en fichas |
| PUL-142 | M4 | gameplay-engineer | in_progress | Hacer que el POP del puesto no tape su número |
| PUL-143 | M4 | gameplay-engineer | in_progress | Cubrir con un test la posición de las plazas de la olla |
| PUL-144 | M4 | asset-pipeline | draft | Hacer visible el vapor de la olla y apoyar su tapa abierta |
| PUL-145 | M4 | asset-pipeline | draft | Ajustar el ambiente y el brillo del acero delantero a la referencia |
| PUL-146 | M4 | asset-pipeline | draft | Compartir materiales y texturas entre los .glb y retirar la fuente v1 |
| PUL-150 | M3e | game-designer | draft | Escribir la guía del playtest humano de M3e (m3e-gate.md) |
| PUL-151 | M3e | godot-architect | blocked | Exportar a Android, elegir renderizador móvil y verificar en un teléfono real |
| PUL-152 | M3e | qa-tester | in_progress | Recapturar medidas y capturas de D26 con el estado final de M3e |
| PUL-153 | M3e | qa-tester | draft | Probar el perfil táctil en un teléfono con el build web (antes del APK) |
| PUL-154 | M4 | qa-tester | in_progress | Que el panel de salida de GUT no se quede con el puntero en los tests de UI |
| PUL-160 | M4 | game-designer | done | Especificar la pantalla de opciones, los créditos y la versión visible |
| PUL-161 | M4 | game-designer | in_progress | Poner al día los textos en gallego y escribir el glosario |
| PUL-162 | M4 | game-designer | done | Cerrar el diseño del tutorial breve para la alpha |
| PUL-163 | M4 | godot-architect | draft | ADR-007 de ajustes persistentes, localización y tutorial |
| PUL-164 | M4 | qa-tester | in_progress | Medir el balance de la alpha con el bot y proponer valores |
| PUL-165 | M4 | game-designer | draft | Registrar los valores de balance aprobados en el diseño |
| PUL-166 | M4 | gameplay-engineer | draft | Aplicar el balance aprobado en los datos |
| PUL-167 | M4 | gameplay-engineer | draft | Núcleo de ajustes persistentes y volumen guardado |
| PUL-168 | M4 | ui-engineer | draft | Pasar los textos de la UI a claves de traducción (castellano) |
| PUL-169 | M4 | gameplay-engineer | draft | Núcleo del tutorial y su fase en datos |
| PUL-170 | M4 | godot-architect | draft | Preparar presets, versión y empaquetado de los builds de Windows y Linux |
| PUL-171 | M4 | ui-engineer | draft | Pantalla de opciones desde el menú principal y la pausa |
| PUL-172 | M4 | ui-engineer | draft | Pantalla de créditos con licencias y versión visible |
| PUL-173 | M4 | ui-engineer | draft | Completar la traducción al gallego y el cambio de idioma en caliente |
| PUL-174 | M4 | ui-engineer | draft | Panel del tutorial con icono del verbo y «Saltar» |
| PUL-175 | M4 | gameplay-engineer | draft | Montar el tutorial en level_01 y el flujo de primera partida |
| PUL-176 | M4 | qa-tester | draft | Exportar los builds finales de la alpha y pasar el smoke en Windows y Linux |
| PUL-177 | M4 | qa-tester | draft | QA de M4 (opciones, gallego, tutorial y balance) y preparar el playtest |
| PUL-178 | M4 | game-designer | draft | Escribir la guía del playtest y el criterio de publicación de la alpha |
| PUL-179 | M4 | producer | draft | Publicar la alpha (notas y subida de los builds verificados) |
