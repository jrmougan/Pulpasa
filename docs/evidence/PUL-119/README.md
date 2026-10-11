# Estudio de UX de acciones y móvil (2026-10-11)

Encargado por el responsable tras el playtest de M3d: «no se distinguen muy bien las acciones, y esto es
crítico si quiero llevar el juego a teléfonos móviles». Tres agentes en paralelo: QA empírico (capturas en
`qa-capturas/`, 1280×720 salvo indicación), diseño UX y auditoría técnica de UI/input. Resultado: D26
(PUL-119) y contratos (PUL-120).

## Hallazgos de QA (empíricos)
| Acción | Antes de pulsar | Después | Problema | Grav. |
|---|---|---|---|---|
| Cortar con pulpo crudo / 7.º corte | Contorno igual que válido | Nada (Box consume la pulsación) | Pulsación muda (`a6-cut-raw-after.png`) | Crítico |
| Aliño dulce/picante | Contorno amarillo que tapa el color; botes ~20 px, casi idénticos | `season` + destello diminuto | No se distingue cuál es cuál; mismo aliño = silencio (`a9-dispensers-between-before.png`) | Crítico |
| Dispensador con caja a medias | Resaltado normal | `season_error`, nada visual | No dice el motivo | Alto |
| Cocción | Barra 27×4 px a 720p | Fin = clic UI; aviso de quemado = barra pálida | Listo/quemándose casi sin señal (`a3-cook-7at13s.png`) | Alto |
| Tirar al cubo | Cubo tapado por el jugador | `drop` + `trash`, mismo sample | Suena igual que soltar/cocer/descartar (`e2-trash-withitem-before.png`) | Alto |
| Entrega errónea / puesto sin comanda | Puesto resaltado aunque no tenga comanda | Mismo `deliver_error` | No distingue motivos (`c2-stand1-wrong-after100ms.png`) | Alto |
| Cambio de personaje | Ambos con anillo azul | Sin sonido | Contorno amarillo = gorro de P2; no se ve quién está activo (`f1-switch-before.png`) | Alto |
| Coger/soltar caja en pasaplatos | Contorno | `pick_up`/`drop` | La misma tecla alterna sin aviso | Medio |
| Olla: descartar quemado | Contorno | `discard`, oculto tras el jugador | No se entiende que se tira | Medio |

Las 5 peores ambigüedades: (1) pulsaciones mudas con el mismo resaltado que las válidas; (2) aliños
indistinguibles; (3) el objetivo depende de la orientación (cono ±30°, radio 2,2 m) sin pista, con puntos sin
objetivo entre olla 2 y cubo (`e3-between-pot-bin.png`); (4) el jugador tapa lo que apunta (cámara desde el sur,
`b1-held-box-4-facings.png`); (5) «listo / quemándose / lleno» casi sin señal y cues con el mismo sonido.

Legibilidad (sin `window/stretch`; `UiScale` = alto/720 entre 1 y 2; cámara ortográfica de 12,74 m de alto):

| Elemento | 1280×720 | 2340×1080 | 800×370 |
|---|---|---|---|
| px por metro | 44,5 | 66,8 | 22,9 |
| Personaje (1,6 m) | 71 px | 107 px | 37 px |
| Texto de receta del ticket | 19 px | 28,5 px | 19 px |
| Captions del HUD | 13 px | 19,5 px | 13 px |
| Barras de cocción/caja | 27×4 px | 40×6 px | 14×2 px |

En 800×370 (proxy de teléfono, `m2-800x370-full.png`) HUD y tickets ocupan el 75 % y el 66 % del alto y se
pisan. En un 6" a 2340×1080 (~420 ppi) el texto de receta mide ~1,7 mm y un dispensador ~1,2 mm. No hay ningún
soporte táctil.

## Diagnóstico de diseño
1. Sin preaviso del verbo: ≥ 12 verbos detrás de un único contorno binario.
2. Selección ambigua entre cercanos y sin histéresis.
3. Feedback de resultado desigual; pulsaciones sin respuesta.
4. Iconografía débil (mismo icono de aliño, rack con S/M/L, sin iconos de verbo).
5. Densidad: ~20 objetivos en la cocina; con caja en mano compiten 3 a la vez (cubo, pasaplatos, puesto).
6. Tamaño en pantalla insuficiente para móvil con la cámara actual.
7. Local 2P no es viable en un teléfono: móvil = Individual con cambio.

Puntos donde la misma pulsación hace cosas distintas sin verse: pasaplatos con pulpo cocido (cortar o soltar),
cuenco con caja (poner o quitar, con antirrebote), cuenco con cachelos (reponer) frente a con caja (alternar),
dispensador (aplicar, sustituir, nada, rechazo), olla con mano vacía (coger cocido o tirar quemado), puesto
(entrega sola por zona frente a pulsar con −2 €), lado equivocado del dispensador/cuenco (no es objetivo sin
explicación), 6 cortes sin contador.

Referentes (de memoria): Overcooked (objetivo = casilla delante, estado sobre el objeto), PlateUp (icono de qué
acepta la máquina), juegos móviles con botón contextual que cambia de icono (Zelda/Genshin/Stardew móvil),
Cooking Fever (tocar el objeto). Conclusión: prompt del verbo sobre el objetivo + botón contextual con el mismo
icono + objetivo estable, y el resto como refuerzo.

## Auditoría técnica
- Selección: `components/interaction_detector.gd` + `core/interaction_scoring.gd` (`dot*2 + 1/dist`, cono ±30°,
  `near_distance` 0,7, bonus de cocina con mano vacía, cogible suelto gana con mano vacía). Emite
  `target_changed` local.
- Resaltado: `components/highlightable.gd` (contorno por `material_overlay`, conteo de propietarios, retícula
  opcional). Sin verbo ni icono.
- `can_interact` miente a propósito en Box, CookingStation, Slot e ItemSpawner (true y luego `interact` no hace
  nada). Un icono derivado de `can_interact` mentiría: el verbo debe salir de la misma rama que `interact`.
- Verbos por estación: CookingStation (cocer, tirar quemado, recoger), Slot (dejar, recoger), Box (coger,
  cortar), Ingredient (coger), ItemSpawner (sacar), OrderStand (entregar), SeasoningDispenser (aliñar,
  sustituir), CachelosBowl (rellenar, poner/quitar), TrashBin (tirar).
- EventBus: 14 señales de ronda/comandas/sesión; nada de interacción. La UI necesitaría una señal nueva.
- UI: píxeles fijos, `UiScale` casero solo en HUD y tickets; menús, pausa y game over sin escalar; sin safe
  area; HUD abajo a la izquierda choca con el stick virtual. Tema: 13–34 px.
- Input: `p1_*`/`p2_*`, `p1_switch`, `pause`; reasignación por `GameState.apply_devices()`. Nada táctil. La
  puerta natural es alimentar las acciones existentes por código (`Input.parse_input_event`).
- Render Forward+, sin preset Android (`export_presets.cfg`: Linux, Windows, Web). Móvil figuraba como Won't en
  `roadmap.md`.
