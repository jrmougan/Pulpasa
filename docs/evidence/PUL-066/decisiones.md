# PUL-066 — Decisiones para el responsable (gate humano antes de PUL-069..071)

Contratos: `docs/arch/ADR-006-audio-feedback.md`, `ADR-002` Enmienda 1, `signals.md` (Enmienda M3,
§2, §3, §4, §5) y `scene-tree.md` (Enmienda M3, §1–§3, §5, §6, §8). Para cada punto: lo que
propongo y la alternativa. Basta con «OK» o el número de la alternativa.

## Arquitectura

| # | Decisión | Propuesta | Alternativa |
|---|---|---|---|
| R1 | Dueño de la mezcla | Autoload nuevo **`AudioDirector`** (#5, `ALWAYS`) + núcleo `AudioMix`: único escritor de volúmenes de bus; baja `Music`/`Ambience` en pausa; sitio para los sliders del Should. **No reproduce sonido** | Sin autoload: la pausa la baja `LevelAudio`; el Should de volumen tendría que resolver luego el choque de dos escritores |
| R2 | Señales del feedback | **Ninguna señal local sube a `EventBus`**: cada escena suena con su `%Feedback` (posicional). Implica leer AC2 de `audio-y-fx` como «su señal (de `EventBus` o local)»; el game-designer enmienda la frase | (B) Promover coger/soltar/cortar/cocer/condimentar al bus con ids, un relé global y audio no posicional |
| R3 | BG y FOL | Nodo **`LevelAudio`** en el nivel; arrancan en `round_started` y siguen sonando en game over hasta salir del nivel | Que paren en `round_finished`, o música continua menú → nivel desde el autoload |
| R4 | Visual de AC5 | `POP` (escala, 0,4 s) para las acciones y la entrega correcta; `SHAKE` para errores y caducada. Datos en `feedback_map.tres` | Destello de color o partículas por acción (más arte, más coste) |

## Audio y datos

| # | Decisión | Propuesta | Alternativa |
|---|---|---|---|
| R5 | Bajada en pausa | `pause_duck_db` = **−12 dB** (el mínimo de AC3), en `audio_mix.tres` | Más margen (−15 / −18 dB) |
| R6 | «Nueva comanda» al reponer | Suena siempre, con `delay` 0,5 s para no pisar `deliver_ok`/`order_expired` (1 sonido por señal, AC2 literal) | No sonar en la reposición (solo comandas iniciales y puestos que abre una fase): menos ruido, pero AC2 se enmienda |
| R7 | Colocar en una estación | Suenan `drop` y la cue de la estación (p. ej. `cook_start`); `drop` suave por datos | Suprimir `drop` cuando el objeto acaba en una estación (exige que el `Holder` sepa adónde va) |

## Olla que se pasa

| # | Decisión | Propuesta | Alternativa |
|---|---|---|---|
| R8 | Desechar el quemado | Mano vacía sobre la olla **desecha primero el quemado más antiguo** (desaparece, la plaza queda libre); nunca llega a la mano | Sacarlo a la mano y tirarlo en un cubo (escena y sitio nuevos en la planta B) |
| R9 | Datos y alcance | `burn_time`/`warn_time` en **`IngredientData`**: pulpo 10/7; **cachelos también 10/7** (las reglas ya hablan de «cachelos quemados») | Cachelos sin quemado (`burn_time` 0), o datos por olla (`KitchenData`) |
| R10 | Nombre de la señal | Local `burnt(ingredient)` de la olla (+ `burn_warned`, `discarded`); la feature dice `octopus_burnt`: el game-designer cambia el nombre en AC1 | Mantener `octopus_burnt` y otra señal para cachelos |

## Dificultad por fases

| # | Decisión | Propuesta | Alternativa |
|---|---|---|---|
| R11 | `max_time` de fase | **Sustituye** al de la receta para las comandas nuevas (90/70/50, AC1 literal). Ojo: hoy las recetas tienen 80–180 s (paciencia ×2 de PUL-039), así que la fase 1 ya es más dura que ahora | Factor por fase sobre el `max_time` de la receta (×1 / ×0,8 / ×0,6): conserva las diferencias entre recetas, pero AC1 se enmienda |
| R12 | Qué puestos abren primero | Los primeros de `level.stands` en su orden. Propongo ordenar `stands` como **2, 3, 1, 4** (los centrales primero) | Orden por `slot_id` (1, 2, 3, 4: el lado izquierdo primero) |
| R13 | Puesto aún cerrado | Se ve como uno sin comanda («–»); entregar ahí da `delivery_rejected` sin penalización (como hoy) | Aspecto «cerrado» (toldo bajado, Could): pediría que el puesto supiera la fase, con una consulta nueva |
| R14 | `phase_changed(1)` al empezar | Sí, una vez en `start_round` (el HUD puede pintar «Fase 1»); AC2 cuenta solo las transiciones | Emitir solo desde la fase 2 |
| R15 | Semilla | `RoundConfig.rng_seed` (0 = aleatoria, como hoy) | Semilla por `@export` en el nivel |

## Para el coordinador (no son de diseño)
- **Owns de PUL-070**: le falta `godot/autoload/event_bus.gd` (declarar `phase_changed`) y el test
  de reenvío de `RoundManager`; `autoload/**` está ahora en PUL-071. Hay que decidir el orden o repartir.
- **Owns de PUL-071**: añadir `godot/core/audio_mix.gd(.uid)`, `godot/tests/unit/test_audio_mix.gd(.uid)`,
  `godot/entities/**/*.gd` de las escenas que conecta (box, order_stand, seasoning_station, player,
  level_audio), `godot/scenes/levels/level_01.tscn` (instancia `LevelAudio`) y
  `godot/entities/environment/level_audio.*`. `kitchen.tscn`/`cooking_station.gd` son de PUL-069: o
  PUL-069 cablea el `%Feedback` de la olla, o PUL-071 va después y lo toca con permiso.
- **`docs/arch/README.md`**: falta la fila de ADR-006 (fuera de mis owns).
