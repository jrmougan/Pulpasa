# Hoja de ruta

Propuesta completa (privada): https://claude.ai/artifact/PstRxmwwgejjsphmEXCkJe

| Hito | Contenido | Puerta humana |
|------|-----------|---------------|
| B | Bootstrap de entorno y sistema agéntico | MCP funciona (hecho) |
| F0 | Inventario (PUL-001), GDD de trabajo (PUL-002), ADRs (PUL-003) | Aprobar ADRs y alcance |
| M0 | Migración hasta paridad con Unity, sin sus bugs — **cerrado 2026-10-04** (smoke automático PUL-025 en verde; puerta humana descartada por el responsable, D17; PUL-013 sigue bloqueada por licencia) | Archivar Unity (pendiente de decidir) |
| M1 | Paciencia, puntuación y estrellas, aceite y cachelos, iconos en tickets — **cerrado 2026-10-04** (PUL-027..033) | — |
| M2 | Coop local 2P, mando, cambio de personaje, menú por modo — **técnico cerrado 2026-10-04** (PUL-034..037; guía en `m2-gate.md`) | Playtest de game feel (hecho 2026-10-05: bug de entrega PUL-039; rediseños D18 condimentos PUL-040, D19 mapa PUL-041; D20 arte PUL-042). Rediseños hechos (PUL-038..064); segundo playtest con `m2b-gate.md` pendiente |
| M3 | **Técnico cerrado 2026-10-06** (PUL-043..071): arte propio en Blender (D20), audio completo, feedback, olla que se pasa, dificultad por fases | — |
| M3b | Estética v2 según la referencia elegida (`docs/art/style-refs/referencia-elegida-2026-10-06.png`): biblia v2, luz, materiales, todos los assets, HUD y QA (PUL-072..087) | Revisión del responsable (biblia v2 y D21; resultado final) |
| M4 | Balanceo, opciones, gallego, builds Win/Linux, playtests | Publicar alpha |

## Fases de M0

| # | Contenido | Verificación |
|---|-----------|--------------|
| 0 | Esqueleto: InputMap, autoloads, GUT, CI | Import y tests en verde |
| 1 | Datos: Resources + `.tres` de los ScriptableObjects | Test que carga las 3 comandas |
| 2 | Lógica pura: OrderService, RoundManager | Tests de todas las ramas de validación |
| 3 | Assets: FBX, materiales, audio, fuentes; escena de escala | Captura + revisión humana |
| 4 | Jugador: movimiento, AnimationTree, coger/soltar | Integración con input simulado |
| 5 | Interacción: detector, slots, resaltado | Tests de selección de objetivo |
| 6 | Estaciones: spawner, olla, caja, especias, entrega | Flujo completo = comanda completada una vez |
| 7 | UI: tickets, HUD, pausa, game over, menú | Tests de UI + prueba con teclado y mando |
| 8 | `level_01.tscn`, iluminación, export Linux/Web | Partida lado a lado con Unity |

Coop, audio completo y pulido no son M0.

## Alcance aprobado de la alpha (MoSCoW)

**Must**
1. Paridad con el prototipo Unity (sin sus bugs): smoke checklist en builds Windows y Linux.
2. Ciclo de comandas sin bugs: 20 entregas seguidas sin puestos vacíos; +1 exacto por entrega.
3. Paciencia por comanda: barra que se vacía en `max_time` (40–90 s en datos); al caducar penaliza y se regenera.
4. Puntuación y objetivo: base + bonus por tiempo; recaudación en HUD; 0–3 estrellas por umbrales en datos (D2).
5. Coop local 2P y mando Xbox: teclado + mando o dos mandos; flujo menú → game over completable sin teclado.
6. Modo individual: cambio entre 2 personajes en < 0,2 s (D3).
7. Menú principal: Individual, Local 2P y Salir llevan al nivel en el modo correcto.
8. Comanda reducida (D4): pimentón dulce/picante, sal sí/no, aceite sí/no, cachelos opcionales; iconos en el ticket.
9. Feedback mínimo: sonido y respuesta visual en coger, cocer, condimentar, entrega correcta y errónea; música y ambiente.

**Should**: olla que se pasa, dificultad por fases, opciones de volumen, textos en gallego, tutorial breve.
**Could**: barro, gaiteros, 2 personajes con habilidad, lavado de platos.
**Won't**: mapa de niveles, online, 4 personajes, NPC animados, móvil.

## Flujo de cocina (prototipo, se mantiene por D1)
Nevera → pulpo crudo → olla (cocción) → el jugador lleva el pulpo **cocido** y lo corta sobre una
caja (cada pulsación llena la caja y gasta pulpo) → condimentos sobre la caja llena → entrega en el puesto.

## Pendientes detectados para la fase 8 (montaje del nivel)
- La caja de colisión `interactable` de cada `slot.tscn` (1,37 m) detiene al jugador ~0,7 m delante de los muebles (PUL-017). Revisar tamaño de colisión vs. alcance al colocar el nivel.
- Colocar Mueblecajas con la rotación de Level_01 (−90° en Unity) sobre el envoltorio con frente −Z (PUL-008).
- Con un bote en la mano, el detector prefiere un bote u objeto suelto al slot vacío de la estantería; devolver especias cuesta (PUL-019). Revisar colocación y, si hace falta, prioridad del slot vacío en `InteractionScoring` (decisión de diseño).
- La caja pequeña del `SmallSpawner` no coincide en color con su cajón de la estantería (PUL-019). Solo visual.

## Pendientes detectados en M1
- PUL-029: el test FIFO no distingue orden de finalización de orden por índice (caso: A en plaza 0, B en plaza 1 a t=2,5, recoger A, C en plaza 0 → debe salir B). Sin test del cambio de material crudo/cocido del cachelo ni de la posición de las plazas. El cachelo no se ve en la captura.

## Pendientes detectados en el arte (M3) — resueltos en PUL-067
- Retirar el placeholder `cachelera*` y su comprobación en `tests/unit/test_assets_m1.gd` (PUL-050), y los demás placeholders que queden sin uso al terminar PUL-055.
- Colisión del plato grande menor que el modelo (PUL-047).
- Quitar la escala 0,78×0,975 de las instancias de `OrderStand` en `level_01.tscn` (y su aserción en `test_level_01`) y retirar `order_stand.fbx` de `scale_check.tscn` (PUL-053).

## Pendientes detectados en M3
- Escucha humana del audio: BG celta (no gaita), FOL de multitud, `cook_start`/`cook_done` reutilizan `fx_drop`/`fx_ui_click` (PUL-068, PUL-071).
- Balance de la fase 3: `order_2` (80 s × 0,7 = 56 s) frente a ~54 s de ruta óptima (PUL-070) → M4.
- El POP del puesto tapa un instante el número del puesto (PUL-071).
- Segundo playtest de M2b (`m2b-gate.md`) pendiente; ahora con arte y audio.
