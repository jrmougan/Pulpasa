# ADR-006 — Audio, feedback de acciones, quemado y fases

- **Estado:** propuesto (2026-10-06), **pendiente del gate humano** (bloquea PUL-069..071)
- **Fecha:** 2026-10-06
- **Ficha:** PUL-066
- **Relacionado:** ADR-002 (Enmienda 1), ADR-003 (capa común / específica), ADR-005 (D14 = 3D),
  `signals.md`, `scene-tree.md`; features `audio-y-fx` (Must 9), `olla-que-se-pasa` (Should),
  `dificultad-progresiva` (Should), `opciones-de-volumen` (Should); fichas PUL-068..071

## Contexto

### Cómo suena hoy el juego
- No hay `default_bus_layout.tres`: todo va a `Master`.
- Seis `AudioStreamPlayer3D` posicionales, cada uno disparado por su propio script:

| Escena | Nodo | Lo dispara | Señal |
|---|---|---|---|
| `kitchen.tscn` | `%BoilAudio` (bucle) | `cooking_station.gd` | mientras alguna plaza cuece |
| `box.tscn` | `%CutAudio` | `box.gd` | cada corte (`fill_changed`) |
| `box.tscn` | `%SeasonAudio` | `box.gd` | `seasoned` |
| `order_stand.tscn` | `%OkAudio` | `order_stand.gd` | `EventBus.order_completed` de su `slot_id` |
| `order_stand.tscn` | `%ErrorAudio` | `order_stand.gd` | `EventBus.delivery_rejected` de su `slot_id` |
| `seasoning_station.tscn` | `%ErrorAudio` | `seasoning_station.gd` | `rejected` de dispensadores y cuenco |

- Coger, soltar, cocer (inicio/fin), nueva comanda y caducada no suenan. No hay música (BG) ni
  ambiente (FOL). La pausa congela los `AudioStreamPlayer3D` (heredan la pausa del árbol).
- Respuesta visual: solo la que ya existe (barras, pegatinas, retícula); ningún destello o "pop".
- Coger, soltar, cortar, cocer y condimentar son **señales locales** (`signals.md` §4); su firma
  lleva `Node` o `Ingredient`, así que no pueden subir tal cual a `EventBus` (D14, ADR-005).

### Qué piden las features
- **audio-y-fx**: BG y FOL en buses `Music` y `Ambience` (AC1); 1 FX por evento (corte, caldero,
  coger, soltar, nueva comanda, entrega, caducada; AC2); 1 sonido + 1 respuesta visual ≥ 0,3 s en
  coger, cocer, condimentar, entrega correcta y errónea, distintas entre sí (AC5); `Music` y
  `Ambience` bajan ≥ 12 dB en pausa (AC3). Datos: mapa evento → sonido y volúmenes por bus en `.tres`.
- **opciones-de-volumen** (Should, sin ficha en M3): sliders por bus, −80 dB a 0 %, persistencia.
  Este ADR deja su sitio para que no tenga que rehacer la mezcla.
- **olla-que-se-pasa**: `BURNT` tras `burn_time` sin recoger, aviso desde `warn_time`, rechazo al
  cortar, desechar libera la plaza, se congela en pausa.
- **dificultad-progresiva**: fases en datos (fracción de la partida, puestos activos, `max_time`),
  `phase_changed`, comandas activas conservan su `max_time`, misma semilla → misma secuencia.

## Decisión

### 1. Buses (`godot/default_bus_layout.tres`)

```
Master
├── Music     BG (música de romería)        bajan pause_duck_db en pausa
├── Ambience  FOL (ambiente de feria)       bajan pause_duck_db en pausa
└── SFX       todos los FX (mundo y UI)     no cambia en pausa
```
Godot carga `res://default_bus_layout.tres` por defecto (sin tocar `project.godot`). Todo
`AudioStreamPlayer*` del juego declara su bus: ninguno queda en `Master` (lo comprueba un test que
recorre las escenas). Los nombres de bus se usan como `StringName` (`&"Music"`, `&"Ambience"`,
`&"SFX"`) en una sola constante por consumidor.

### 2. Quién mezcla, quién reproduce

Principio: **el sonido de un hecho lo reproduce la escena donde ocurre** (posicional, como hoy);
**la mezcla la decide un único dueño global**.

| Qué | Quién | Por qué ahí |
|---|---|---|
| Volumen de cada bus, bajada en pausa (AC3), volúmenes de usuario (Should) | **Autoload `AudioDirector`** (#5, `process_mode` `ALWAYS`) + núcleo `AudioMix` (`core/audio_mix.gd`, `RefCounted`) | Es estado de sesión que sobrevive a los cambios de escena (menú → nivel) y tiene que haber **un solo escritor** de `AudioServer.set_bus_volume_db`: si la pausa y los sliders escribieran por separado, se pisarían. Receptor puro: no emite al bus |
| BG y FOL | **`LevelAudio`** (`entities/environment/level_audio.tscn`, nodo del nivel) con dos `AudioStreamPlayer` (no posicionales) en `Music`/`Ambience`, `process_mode` `ALWAYS` | Pertenecen al nivel (otra romería, otra música); mueren con él sin que nadie las pare. `ALWAYS` para que en pausa sigan sonando atenuadas (AC3) en lugar de cortarse |
| FX sin lugar (cambio de fase) | `LevelAudio` (`%PhaseCue`, `AudioStreamPlayer`, bus `SFX`) | No hay un punto del mundo al que atarlo |
| FX de acciones (coger, soltar, cortar, cocer, condimentar, quemado, entregas, nueva comanda, caducada) | Cada escena, con un **`FeedbackPlayer`** (§4) conectado a su señal **local** o a la señal de `EventBus` filtrada por su id (`slot_id`) | Sonido posicional en coop; las señales locales ya llevan el nodo; sin promover nada al bus |
| FX de UI (botones; Could) | La propia escena de UI, `AudioStreamPlayer` en `SFX` | `ui/` sin tipos de mundo |

`AudioDirector` **no** reproduce música ni FX. Así no necesita saber en qué escena está, no hay que
pararlo al salir del nivel y no reaparece B10 (orden de arranque).

**`AudioMix`** (núcleo, sin árbol ni `AudioServer`):
`AudioMix.new(config: AudioMixConfig)`, `set_volume(bus: StringName, linear: float)`,
`get_volume(bus) -> float`, `set_paused(paused: bool)`, `get_bus_db(bus: StringName) -> float`.
Regla: `linear` = 0 → −80 dB; si no, `linear_to_db(linear)`; si está en pausa y el bus es `Music`
o `Ambience`, se suma `config.pause_duck_db` (≤ −12); el resultado nunca baja de −80.

**`AudioDirector`** (adaptador): en `_ready` crea `AudioMix` con `data/audio/audio_mix.tres`
(`@export` no existe en autoloads: lo carga por `preload` de una constante, igual que
`GameState` con sus escenas), aplica los tres buses y conecta `EventBus.pause_changed` →
`set_paused` → reaplica. API para el Should: `set_volume(bus, linear)`, `get_volume(bus)`
(persistencia en `user://settings.cfg`: la añade la ficha del Should). Inyección para tests con
`set_bus(bus)`, como los demás adaptadores.

### 3. Ninguna señal local sube a `EventBus` por el feedback

El feedback se conecta en cada escena. Única señal nueva del bus: `phase_changed` (§6), que pide la
feature por sí misma. Motivos:
- Las firmas de coger/soltar/cortar/cocer llevan nodos; en el bus habría que cambiarlas a ids y
  **un emisor por señal** (ADR-002 regla 2) obligaría a un relé global que todos los `Holder`,
  ollas y cajas llamaran: un autoload que sabe de entidades, justo lo que ADR-002 evita.
- El sonido perdería la posición (o el relé tendría que pasar `Vector3`, prohibido por D14).
- Ningún sistema de otra escena necesita esos hechos hoy (HUD, tickets y puntuación no).

Consecuencia en la feature: AC2 de `audio-y-fx` dice "se emite su señal de `EventBus`"; con esta
decisión debe leerse "su señal (de `EventBus` o local, `signals.md`)". **Decisión del responsable
(R2)**: aprobar esa lectura o pedir la alternativa B.

### 4. `FeedbackPlayer` y el mapa evento → sonido/visual

**`FeedbackPlayer`** (`components/feedback_player.gd`, `class_name FeedbackPlayer`, capa
**específica**: `extends AudioStreamPlayer3D`; en 2D sería `AudioStreamPlayer2D`, `scene-tree.md` §6):
- `@export map: AudioFeedbackMap` (por defecto `data/audio/feedback_map.tres`), `@export
  pulse_target: Node3D` (opcional; por defecto el padre). `bus` = `SFX`, `max_polyphony` ≥ 2.
- `play_cue(cue: StringName, target: Node3D = null) -> void`: busca el `AudioCue`, asigna
  `stream`/`volume_db`/variación de tono, llama `play()` **una vez**, emite `played(cue)` y lanza
  la respuesta visual sobre `target` (o `pulse_target`). Cue desconocida: `push_warning` y nada.
  Si la cue tiene `delay` > 0, espera con un temporizador que respeta la pausa.
- `signal played(cue: StringName)`: gancho de test (AC2/AC5 cuentan `played`, no nodos de audio).
- Visual: `Tween` ligado al nodo (se congela en pausa) de `visual_time` s (≥ 0,3): `POP` (escala
  1 → `1 + pop_scale` → 1) o `SHAKE` (vaivén lateral). Sin señal nueva por la parte visual.

Los one-shot existentes (`%CutAudio`, `%SeasonAudio`, `%OkAudio`, `%ErrorAudio`) se sustituyen
por un `%Feedback` (`FeedbackPlayer`) por escena. Los bucles (`%BoilAudio`) siguen siendo
`AudioStreamPlayer3D` normales, en `SFX`.

**Datos** (`resources/audio_cue.gd`, `resources/audio_feedback_map.gd`, `resources/audio_mix_config.gd`):

| Resource | Campos |
|---|---|
| `AudioCue` | `stream: AudioStream`, `volume_db: float = 0`, `pitch_jitter: float = 0.05`, `delay: float = 0`, `visual: Visual` (`NONE`, `POP`, `SHAKE`), `visual_time: float = 0.4`, `pop_scale: float = 0.15` |
| `AudioFeedbackMap` (`data/audio/feedback_map.tres`) | `cues: Dictionary[StringName, AudioCue]` |
| `AudioMixConfig` (`data/audio/audio_mix.tres`) | `music_volume: float = 0.7`, `ambience_volume: float = 0.7`, `sfx_volume: float = 1.0` (defaults de `opciones-de-volumen` AC4), `pause_duck_db: float = -12.0` |

**Mapa de eventos** (contrato de PUL-071; las claves son cerradas, un test comprueba que todas
tienen `AudioCue` con `stream`):

| Cue | Señal (tipo) | Escena · nodo | Visual | Feature |
|---|---|---|---|---|
| `pick_up` | `item_picked_up` (local, `Holder`) | `player.tscn` · `%Feedback` | `POP` del objeto cogido | AC2, AC5 coger |
| `drop` | `item_dropped` (local, `Holder`) | `player.tscn` · `%Feedback` | `NONE` | AC2 soltar |
| `cut` | `fill_changed` (local, `Box`) | `box.tscn` · `%Feedback` | `POP` de la caja | AC2 corte |
| `cook_start` | `cooking_started` (local) | `kitchen.tscn` · `%Feedback` | `POP` de la olla + vapor/fuego (PUL-069) | AC2 caldero, AC5 cocer |
| `cook_done` | `cooking_finished` (local) | `kitchen.tscn` · `%Feedback` | `POP` del ingrediente | AC5 cocer |
| `season` | `seasoned` (local, `Box`) | `box.tscn` · `%Feedback` | `POP` de la caja (y la pegatina) | AC5 condimentar |
| `unseason` | `seasoning_removed` (local, `Box`) | `box.tscn` · `%Feedback` | `NONE` | — |
| `season_error` | `rejected` (local, dispensador/cuenco) | `seasoning_station.tscn` · `%Feedback` | `SHAKE` del emisor (ya existe) | — |
| `deliver_ok` | `EventBus.order_completed` (su `slot_id`) | `order_stand.tscn` · `%Feedback` | `POP` del puesto | AC2 entrega, AC5 correcta |
| `deliver_error` | `EventBus.delivery_rejected` (su `slot_id`) | `order_stand.tscn` · `%Feedback` | `SHAKE` del puesto | AC5 errónea |
| `order_new` | `EventBus.order_generated` (su `slot_id`) | `order_stand.tscn` · `%Feedback` | `POP` de `%OrderLabel`; `delay` 0,5 s | AC2 nueva comanda |
| `order_expired` | `EventBus.order_expired` (su `slot_id`) | `order_stand.tscn` · `%Feedback` | `SHAKE` de `%OrderLabel` | AC2 caducada |
| `burn_warning` | `burn_warned` (local, olla) | `kitchen.tscn` · `%Feedback` | parpadeo de la barra hasta quemar | olla AC2 |
| `burnt` | `burnt` (local, olla) | `kitchen.tscn` · `%Feedback` | `SHAKE` de la olla + malla `_burnt` | olla AC1 |
| `discard` | `discarded` (local, olla) | `kitchen.tscn` · `%Feedback` | `POP` de la olla | olla AC3 |
| `phase_up` | `EventBus.phase_changed` (fase ≥ 2) | `LevelAudio` · `%PhaseCue` | (HUD, Could) | fases |

Correcta y errónea son distintas en sonido (`deliver_ok`/`deliver_error`) y en visual
(`POP`/`SHAKE`), como pide AC5. `order_new` lleva `delay` para no pisarse con `deliver_ok` u
`order_expired`, que en la reposición llegan en el mismo frame (`signals.md` §3); sigue siendo
**un** sonido por señal (AC2). Colocar algo en una estación emite `item_dropped` y la señal de la
estación: suenan los dos (`drop` es suave por datos); no se suprime para no romper "1 por señal".

### 5. Quemado (olla)

- **Datos** en `IngredientData` (como `cook_time`): `burn_time: float = 0.0` (s desde que termina
  la cocción; 0 = no se quema, variante de paridad de `coccion-pulpo.md`) y `warn_time: float =
  0.0` (s desde que termina; aviso). Pulpo: 10 / 7. Invariante validada por test sobre los `.tres`:
  `0 < warn_time` y `burn_time − warn_time ≥ 3` cuando `burn_time > 0`. Activar o no el Should es
  un cambio de datos.
- **Reloj**: el de la plaza en `CookingStation._physics_process` (sin `Timer`): tras `cooking_finished`
  la plaza sigue contando mientras el ingrediente siga en ella; se congela en pausa (AC4). Recoger
  a tiempo detiene el reloj: un cocido en la mano o en una caja **no** se quema.
- **Estado**: `Ingredient.set_burnt()` → `CookingState.BURNT` y malla `*_burnt` (ya prevista en
  `_apply_state_variants`). `is_cooked()` es `false` para `BURNT`, así que `Box` lo rechaza al
  cortar sin cambio de API (AC3) y el cuenco ya lo rechaza (`NOT_ACCEPTED`).
- **Señales locales nuevas de `CookingStation`** (no suben al bus: solo las oyen `kitchen.tscn` y
  los tests; ningún sistema global las necesita):
  - `burn_warned(ingredient: Ingredient)`: una vez por plaza al cumplirse `warn_time`; la
    `%CookBar` de la plaza se muestra y parpadea hasta quemar o recoger (AC2).
  - `burnt(ingredient: Ingredient)`: una vez al cumplirse `burn_time` (AC1). Es la señal que la
    feature llama `octopus_burnt`: se generaliza porque los cachelos también pueden quemarse.
  - `discarded(ingredient: Ingredient)`: al desechar un `BURNT`, antes de liberarlo.
- **Desechar** (AC3): con la mano vacía, `interact` sobre la olla **desecha primero el quemado más
  antiguo** (lo libera con `queue_free`, emite `discarded` y la plaza queda libre); si no hay
  quemados, devuelve el cocido FIFO como hoy. Un quemado nunca llega a la mano. Sin escena nueva
  (cubo) ni cambio de planta. Alternativa en R5.
- **Vapor y fuego** (absorbe PUL-065): `Model/Steam` solo con alguna plaza cociendo; `Model/Fire`
  bajo en reposo y vivo al cocer, a partir de las mismas señales locales.

### 6. Fases de dificultad

- **Bus**: `phase_changed(phase: int)` en `EventBus`. Nace en `RoundState` y la reenvía
  `RoundManager` (ADR-002 regla 2). `phase` empieza en 1. Firma independiente de la dimensión.
- **Datos**: `PhaseData` (`resources/phase_data.gd`): `start_fraction: float` (0–1 de
  `duration`), `active_slots: int`, `max_time: float` (0 = el de cada `OrderData`). En
  `RoundConfig`: `phases: Array[PhaseData]` (ordenadas, la primera con `start_fraction` = 0;
  **vacía = sin fases**: todos los puestos, `max_time` de la receta y ninguna `phase_changed`, que
  es como funcionan hoy los flujos M1/M2) y `rng_seed: int = 0` (0 = aleatoria). Los límites se
  calculan como `start_fraction × duration` (AC6). M3: 3 fases a 0, ⅓ y ⅔ con 2/3/4 puestos y
  90/70/50 s (`round_config.tres`).
- **`OrderBoard`** (dos métodos nuevos, sin señales nuevas):
  `set_active_slots(slot_ids: Array[int])`: `request_order` en un puesto fuera de la lista devuelve
  `null`. Sin llamar nunca, todos activos (compatibilidad). Si una fase redujera puestos, la
  comanda viva de un puesto desactivado sigue hasta entregarse o caducar y **no se repone**.
  `set_new_order_max_time(seconds: float)`: `max_time` de las comandas que se creen desde ahora (0 =
  el de `OrderData`). Las vivas conservan el suyo porque `ActiveOrder` lo copia al crearse (AC4).
- **Qué puestos se abren**: los `active_slots` primeros de `slot_ids` en el orden en que el nivel
  los pasa (`level.gd` → `stands`). El diseño del nivel decide el orden; sin dato extra.
- **Orden en `RoundState`**:
  - `start(slot_ids)`: `OrderBoard.reset()` (`orders_reset`) → aplica fase 1 (puestos y
    `max_time`) → `phase_changed(1)` → `fill_slots` de los puestos activos (si
    `first_order_delay` = 0) → `round_time_changed` → `round_started`.
  - `advance(d)`: paso 2 de ADR-002 (paciencia, caducidad, reposición) → resta `d` al reloj →
    **cambio de fase**: mientras haya fase siguiente con `elapsed ≥ start × duration − TIME_EPSILON`
    y `time_left > 0`, aplica sus datos, emite `phase_changed(n)` (una vez por fase, aunque un
    `delta` grande salte dos) y, si las comandas iniciales ya salieron, `fill_slots` de los
    puestos activos (solo rellena los vacíos, sin pasar de `max_active_orders`) → `round_time_changed`
    → fin de ronda. Una fase que empieza en `duration` nunca se activa. Así, al pasar el reloj de
    99,9 a 100,0 s, el tercer puesto recibe comanda en el mismo tick (AC2: "≤ 1 s").
  - `get_phase() -> int` (0 sin fases).
- **Semilla** (AC5): `OrderService.setup(catalog, rng, config)` sin `rng` y con
  `config.rng_seed ≠ 0` crea el `RandomNumberGenerator` con esa semilla. El tablero consume un
  `randi_range` por comanda creada, así que con la misma semilla la secuencia de recetas es la
  misma. Los tests de núcleo siguen inyectando su RNG.

## Alternativas consideradas

1. **(B) Promover coger/soltar/cortar/cocer/condimentar a `EventBus` y un autoload de audio que lo
   reproduce todo.** Cumple AC2 al pie de la letra, pero exige firmas con ids en vez de nodos, un
   relé global para respetar "un emisor por señal" y pierde el sonido posicional (o mete `Vector3`
   en el bus, prohibido por D14). Doble trabajo y acoplamiento global por un beneficio que hoy no
   usa nadie. Descartada; se promueve una señal concreta si un sistema global la necesita (ADR-002
   regla 9).
2. **Sin autoload: mezcla en el nivel** (`LevelAudio` o `pause_menu.gd` bajan los buses en pausa).
   Suficiente para AC3, pero el Should de volumen vive también en el menú principal (fuera del
   nivel) y dos escritores de `set_bus_volume_db` (pausa y sliders) se pisan. Descartada.
3. **`AudioDirector` que también reproduce BG/FOL** (música continua entre menú y nivel). Obliga a
   arrancar y parar la música según la escena (que el autoload no debe conocer) y no hay música de
   menú en el alcance. Descartada; si llega música de menú, se revisa.
4. **Bajada en pausa con `AudioEffectAmplify` en los buses** (sin tocar `volume_db`). Evita el
   choque con los sliders sin núcleo, pero reparte la mezcla entre efectos y volumen y es más
   difícil de testear. Descartada en favor de un único cálculo en `AudioMix`.
5. **Quemado en `Ingredient`** (cada pulpo con su reloj). El reloj de la plaza ya existe en la olla
   y AC1 solo quema "en la olla"; un reloj en el ingrediente habría que pararlo al recogerlo.
   Descartada.
6. **`burn_time`/`warn_time` en `KitchenData`**. Más simple (un dato por olla), pero el pulpo y los
   cachelos no tienen por qué quemarse igual y `cook_time` ya es del ingrediente. Descartada.
7. **Fases en un núcleo propio (`PhaseSchedule`)**. Separaría más, pero el reloj es de `RoundState`
   y el cambio de fase debe ir en un punto exacto de su `advance`. Si crece (eventos de entorno, Could),
   se extrae. Descartada por ahora.
8. **`phase_changed(phase, active_slots, max_time)`** con los datos en la firma. El HUD no los
   necesita y los puestos no escuchan la fase (un puesto inactivo es un puesto sin comanda, «–»).
   Descartada; se mantiene la firma de la feature.

## Consecuencias
- (+) Ningún contrato de señal existente cambia; el bus gana una sola señal (`phase_changed`).
- (+) Mezcla con un único escritor y testeable sin `AudioServer` (`AudioMix`); AC3 es aritmética.
- (+) AC2/AC5 se prueban contando `FeedbackPlayer.played` en el nivel, sin oír nada.
- (+) Sin fases ni quemado en datos, el juego se comporta como hoy: los flujos M1/M2/M2b no cambian.
- (−) Un quinto autoload (ADR-002, Enmienda 1). Es receptor y no tiene reglas de juego.
- (−) La lectura de AC2 de `audio-y-fx` cambia ("su señal de `EventBus`" → "su señal"): R2.
- (−) Colocar en una estación suena doble (`drop` + la de la estación).
- (−) `FeedbackPlayer` es de la capa específica: con 2D habría que duplicarlo (`AudioStreamPlayer2D`).
- Owns de PUL-071 a ajustar: `core/audio_mix.gd(.uid)`, `tests/unit/test_audio_mix.gd(.uid)`,
  `components/feedback_player.gd(.uid)` (ya en `components/**`), `entities/**/*.gd` de las escenas
  que conecta, `scenes/levels/level_01.tscn` (instancia `LevelAudio`), `resources/audio_*.gd`.
  PUL-069 ya cubre el quemado. PUL-070 necesita además `autoload/event_bus.gd` (declara
  `phase_changed`) y su test de reenvío; `autoload/**` está hoy en PUL-071: el coordinador decide
  quién lo toca primero.
