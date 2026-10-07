---
id: PUL-090
title: Diagnosticar y proponer el rediseño jugable de las estaciones de condimento y bandejas
status: done
milestone: M3c
role: game-designer
deps: []
orca_task: task_473ef05cacf2
unity_sources: []
owns: [docs/design/rediseno-estaciones.md, docs/evidence/PUL-090/**]
touches_scenes: []
---

## Target
El responsable quiere revisar **todo lo relacionado con las estaciones** para facilitar la jugabilidad
(2026-10-07): la estación de condimentos (`entities/stations/seasoning_station*`, dispensadores, cuenco
de cachelos, bandeja de pase, lado de pase/lado de condimentar) y el circuito de los **platos/bandejas**
(rack `box_shelf`, elección de tamaño S/M/L, corte sobre la bandeja con 5/10/20 pulsaciones, encimeras
y `slot`, distintivos `badge_row`, transporte y entrega en los kioscos `order_stand`).
Referencias: `docs/design/features/estacion-condimentos.md`, `condimentacion.md`, `corte-pulpo.md`,
`entrega-y-puntuacion.md`, `comandas.md`, `movimiento-e-interaccion.md`, decisiones D1, D3, D4, D10,
D11, D18, D19 en `docs/design/decisions.md`, y el nivel `scenes/levels/level_01.tscn` (planta B).

## Change
Solo diseño (sin código). Escribe `docs/design/rediseno-estaciones.md`:
1. **Diagnóstico medido** del flujo actual de un pedido (pulpo → olla → corte → condimento → entrega)
   en Individual y en Coop 2P: pulsaciones, metros recorridos y segundos por pedido S/M/L, cambios de
   personaje, puntos de error (selección ambigua, rechazos, esperas) y cuellos de botella. Mide jugando
   (MCP de Godot, input simulado) o con un script de escena; datos en `docs/evidence/PUL-090/`.
2. **Problemas priorizados** (impacto en diversión/claridad × frecuencia), separando reglas, distribución
   del nivel, interacción e información (qué no se entiende al mirar).
3. **2–3 alternativas** de rediseño por bloque (condimento; bandejas y corte; entrega), cada una con
   boceto cenital (ASCII o SVG propio), cómo se juega en Individual y en Coop 2P, qué gana, qué pierde y
   coste estimado (fichas, contratos afectados: `signals.md`, `scene-tree.md`, InputMap, `.tres`).
4. **Recomendación** coherente entre bloques y criterios de aceptación borrador (Given/When/Then con
   números) para las fichas de implementación.
5. **Necesidades de arte** derivadas (qué debe comunicar visualmente cada estación), para la ficha de
   arte PUL-091 que trabaja en paralelo con Codex.
6. **Preguntas para el gate humano** (opciones cerradas, con recomendación).

## Constraints
- Solo documentación y evidencia; no toques `godot/` ni las features existentes (se actualizan tras el gate).
- Mantén D3 (el personaje inactivo no actúa) y una sola tecla de acción salvo que propongas cambiarlo
  como pregunta explícita de gate (afecta al InputMap, contrato).
- Todo `godot` que lances va con `--audio-driver Dummy`; con el MCP, silencia los buses al arrancar
  (`AudioServer.set_bus_mute`). No toques Blender ni el puerto 9876.
- **Gate humano** antes de crear las fichas de implementación.

## Acceptance
- [ ] AC1 Diagnóstico con métricas del flujo actual en Individual y Coop 2P (tabla + evidencia reproducible)
- [ ] AC2 Problemas priorizados y 2–3 alternativas por bloque con bocetos y costes
- [ ] AC3 Recomendación con AC borrador e impacto en contratos
- [ ] AC4 Sección de necesidades de arte y preguntas de gate con recomendación

## Plan
1. Leer features, decisiones y el código real de estación, caja, slot, detector, olla y puestos.
2. Medir jugando: bot con teclado simulado y detector real sobre `level_01.tscn`
   (`docs/evidence/PUL-090/measure_flow.gd`) en Solo, Individual con cambio y Coop 2P, S/M/L y con
   cachelos; y mapa de objetivos del detector a lo largo de la barra (`target_map.gd`).
3. Diagnóstico, problemas priorizados, 2–3 alternativas por bloque con boceto y coste,
   recomendación con AC borrador, necesidades de arte y preguntas de gate en
   `docs/design/rediseno-estaciones.md`. Sin tocar `godot/` ni las features.

## Evidence
- Documento: `docs/design/rediseno-estaciones.md` (AC1 §1, AC2 §2–3, AC3 §4, AC4 §5–6).
- Medidas reproducibles: `docs/evidence/PUL-090/` (`metrics.json`, `target_map.txt`, scripts y
  README con los comandos). 24 pedidos completados por el bot; 0 rechazos.
- Hallazgos clave: bandeja única = emplatador quieto 49 % en coop; rodeo de 16–17 m frente a los
  6–10 m de la feature; el corte es el 69 % de las pulsaciones de una L; cuenco que roba el objetivo
  con cualquier cosa en la mano; tamaño S/M/L ausente del ticket.
- `tools/verify.sh` en verde (la 1.ª ejecución dio un fallo intermitente en
  `test_level_01.gd::test_ac3_retry_after_round_finished_leaves_clean_state`, 299,83 frente a 300 ± 0,1
  de `time_left`; sin tocar `godot/`, la 2.ª pasó entera).
