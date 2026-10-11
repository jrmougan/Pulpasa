# ADR-005 — Dimensión: 3D o 2D

- **Estado:** aceptado (2026-10-03): opción A, 3D con cámara ortográfica fija (D14); Enmienda D26
  (escala de UI, perfil de plataforma, safe area y cámara móvil) **propuesta**, pendiente del gate
  humano (PUL-120)
- **Fecha:** 2026-10-03; enmienda 2026-10-11
- **Ficha:** PUL-003; enmienda PUL-120 (D26)
- **Relacionado:** D6 y D14 (`docs/design/decisions.md`), roadmap (fases y gate de M0), ADR-003 §0
  (capa común / específica), ADR-004 §0, `scene-tree.md` §6, inventario §3 y §5

## Contexto

El prototipo Unity es 3D. El responsable duda entre seguir en 3D o pasar a 2D (D14, pendiente).
D14 bloquea las fases 3–8 de M0, no las 0–2: ADR-002, ADR-003 y ADR-004 ya separan una capa común
(núcleos y autoloads, `core/`, datos, UI de pantalla, InputMap, componentes de control) que no
cambia con la decisión.

### Hechos comprobados (prototipo y repositorio)
- **Cámara**: `Main Camera` de `Level_01.unity` es **ortográfica** (`orthographic: 1`, tamaño
  6,37), inclinada unos 38° hacia abajo (`m_LocalRotation.x = 0.323`), en (0,7; 7,49; −5,86).
  Vista 3/4 fija sin perspectiva.
- **Assets 3D existentes** (inventario §5): personaje `freakycapucha.fbx` con sus clips
  (Idle/Walk/Pick/WalkWhileHolding), `Octopus.fbx`, `Condiment.obj`, caja (`Boite Hamburger.fbx`,
  licencia por verificar), muebles propios (`Mueblecajas.fbx`, `order_stand.fbx`) y 6 modelos de
  Pandazole (olla, fogón, nevera, 3 mesas; uso incierto por D6). Candidato a 2.º personaje:
  `BillGatos.fbx`.
- **Assets 2D existentes**: ningún sprite de juego; solo iconos (`octopus`, `salt`, `pepper-hot`,
  `selection`), logo y fondo de ticket.
- **Gate de M0**: "partida lado a lado con Unity" (roadmap).
- **Export**: la fase 8 pide Linux/Web y el Must 1 builds Windows/Linux. `project.godot` usa
  `forward_plus`; en web Godot 4 usa el renderizador Compatibility (WebGL 2), así que una build web
  se verá con ese renderizador.
- **Verificación actual**: capturas del MCP de Godot y tests GUT headless.

### Hipótesis (no medidas en este proyecto)
Las valoraciones de rendimiento, tamaño de descarga, legibilidad y estabilidad de capturas de la
tabla siguiente son **hipótesis** basadas en la escala del juego (una cocina, ~30 objetos, 1–2
personajes) y en el comportamiento general del motor. Se marcan con **(H)** y se validan con las
mediciones de la sección «Mediciones antes del gate».

## Opciones

- **A. 3D con cámara ortográfica fija** (como el prototipo): reaprovecha FBX y layout.
- **B. 2D** (top-down u oblicua con orden por Y), con alguna de estas fuentes de arte:
  - **B1. Packs con licencia** (p. ej. packs top-down CC0 o comerciales de cocina/personajes),
    adaptados; hay que comprobar que cubren olla, cajas, condimentos, pulpo y 2 personajes con
    animación de cargar.
  - **B2. Primitivas y placeholders** (formas, colores e iconos existentes) para M0, sustituidos
    después por arte final. Desbloquea la paridad de reglas pronto, no la visual.
  - **B3. Generación con IA de imagen + revisión humana**: los agentes pueden producir y limpiar
    sprites e iconos con un pipeline (generar, recortar, normalizar tamaño/paleta, montar
    atlas/`SpriteFrames`); un humano aprueba estilo, coherencia entre poses y licencia/términos de
    uso de la herramienta. Las animaciones por direcciones coherentes son el punto débil (H).
- **C. Híbrido 2,5D**: los FBX actuales renderizados a sprites (pre-render por direcciones en
  Blender) y juego en 2D. Pipeline automatizable por script.

## Comparación para Pulpasa

| Criterio | A. 3D ortográfica | B. 2D | C. 2,5D pre-render |
|---|---|---|---|
| **Coste de migrar desde el prototipo** | Bajo: posiciones de `Level_01.unity` reutilizables (ejes: −Z adelante), cámara equivalente, `AnimationTree` desde los clips del FBX | Alto en la capa específica: rehacer layout, colisiones, animación por direcciones. La capa común no cambia | Medio-alto: script de render + todo lo de B salvo dibujar |
| **Assets disponibles** | Casi todos existen (≈ 8 modelos propios + 6 Pandazole); faltan materiales Godot y verificar licencias (caja, condimento) | Ninguno hoy. Necesidad: personaje × ≥ 4 direcciones × 4 animaciones × 2 personajes (M2), ~10 props, suelo, barras. Fuente: B1, B2 o B3 | Se generan desde los FBX; un cambio de modelo exige re-render (automatizable) |
| **Cámara cenital / 3/4** | Directa: `Camera3D` ortográfica a ~38°. Posible oclusión tras muebles altos (H) | Top-down sin oclusión; vista oblicua necesita Y-sort y cuidado con objetos en la mano | Como B |
| **Detección de interacción** | `Area3D` + `InteractionScoring` en el plano XZ (`Vector2`) | `Area2D` + el mismo `InteractionScoring` | Como B |
| **Legibilidad del caos coop** | Buena con contorno y cámara ortográfica; objetos pequeños (botes) quizá peor que en 2D (H) | Siluetas e iconos más claros por defecto (H) | Depende de la nitidez del pre-render a la escala final (H) |
| **Rendimiento / export web** | Holgado en escritorio para esta escena (H). En web, probar con Compatibility: aspecto y FPS sin medir; `.pck` mayor por mallas y texturas (H) | Más ligero y descarga menor (H) | Como B; atlas grandes si hay muchas direcciones (H) |
| **Trabajo para agentes (capturas)** | Capturas sensibles a luz y sombras; aserciones de posición requieren proyectar a pantalla. Estabilidad de capturas sin medir (H) | Capturas probablemente más estables y coordenadas ≈ píxeles (H). B3 añade trabajo de agentes de arte con revisión humana | Como B en ejecución |
| **Gate M0 "lado a lado con Unity"** | Comparación casi 1:1 | La paridad pasa a ser de reglas y flujo, no visual; habría que redefinir el gate | Visualmente cercano (mismos modelos), en otra proyección |
| **Riesgo de plazo** | Bajo: lo que falta es conversión (fase 3) | Depende de la fuente de arte: B2 bajo para M0 pero aplaza el arte; B1 depende de encontrar un pack que encaje; B3 depende de la coherencia entre poses (H) | Medio: pipeline de render |

## Mediciones antes del gate

Para convertir las hipótesis en datos antes de decidir (cada una cabe en una ficha corta de spike,
sin tocar la capa común):
1. **Spike 3D**: escena con la cámara del prototipo, `freakycapucha` y 4–5 props convertidos.
   Medir FPS y tiempo de frame en escritorio y en export web (Compatibility), tamaño del `.pck`/
   descarga web, y tomar capturas.
2. **Spike 2D**: la misma escena con B2 (primitivas + iconos) y, si se encuentra, un pack B1.
   Mismas medidas.
3. **Estabilidad de capturas**: capturar 5 veces la misma escena en headless (`xvfb-run`) para cada
   spike y comparar píxel a píxel; anotar la diferencia máxima.
4. **Legibilidad**: captura con 4 comandas activas, 2 personajes y objetos en mano, a 1280×720;
   revisión humana de si se distinguen pulpo crudo/cocido, cajas S/M/L y los 3 condimentos.
5. **Prueba de B3** (opcional): generar el personaje en 4 direcciones × caminar y valorar
   coherencia y tiempo de limpieza con revisión humana.

## Recomendación (propuesta)

**Opción A: 3D con cámara ortográfica fija**, manteniendo la separación de capas de ADR-003 §0, a
confirmar con las mediciones 1, 3 y 4.

Motivos comprobados: todos los assets necesarios para M0 existen ya en 3D, el prototipo ya usa una
cámara ortográfica 3/4 y el gate de M0 es una comparación visual con Unity. Motivo hipotético:
el coste de producir arte 2D coherente (por cualquiera de B1–B3) supera al de convertir los FBX.
Los riesgos de A (legibilidad de objetos pequeños, capturas menos estables, web) se mitigan con
contorno de resaltado, escala de props legible a tamaño ortográfico 6–7, iconos sobre los objetos
(como en los tickets, M1) y la prueba temprana de export web.

Cuándo elegir B: si las mediciones muestran problemas de legibilidad o web en A, o si aparece una
fuente de arte 2D suficiente (pack B1 que cubra el juego o un pipeline B3 aprobado) y el
responsable acepta redefinir el gate de M0 como paridad de reglas. B2 sirve como paso intermedio en
cualquier caso. La capa común y las fases 0–2 sirven igual.

C es razonable si se quiere 2D sin dibujar, pero suma el pipeline de render a los costes de B sin
ventaja clara frente a A con cámara ortográfica (H).

## Decisión

**Aceptada la opción A (3D con cámara ortográfica fija)** por el responsable el 2026-10-03 (D14).
Rige `scene-tree.md` §2–§3. La fase 3 de M0 incluye una ficha de prueba de export web con el
renderizador Compatibility.

## Consecuencias
- (+) La decisión queda acotada a la capa específica; no reabre ADR-002 ni ADR-004 ni el catálogo
  de señales.
- (+) La comparación separa hechos del prototipo de hipótesis y propone cómo medirlas.
- (−) Mantener la capa común "neutral" impone pequeñas conversiones en 3D (`Vector2(x, z)`).
- (−) Mientras D14 siga pendiente, las fases 3–8 no se pueden planificar en detalle; los spikes
  cuestan 1–2 fichas antes del gate.

## Enmienda D26 (2026-10-11, PUL-120) — Escala de UI, plataforma, safe area y cámara móvil

*Propuesta, pendiente del gate humano.* D26.8 lleva el juego a teléfonos (solo Individual,
apaisado). El estudio de PUL-119 midió que sin `window/stretch` la UI no escala (salvo HUD y tickets
con `UiScale` casero), no hay safe area y la cámara fija da ~85 px/m a 1080 de alto: en un 6" el
texto de receta mide ~1,7 mm. Criterios medibles en `docs/design/features/controles-tactiles.md`
(PUL-119). La cámara ortográfica fija de D14 **se mantiene en PC**; el móvil gana un perfil propio.

### E1. Perfil de plataforma (común)
- `core/platform_profile.gd` (`class_name PlatformProfile extends RefCounted`, puro): `enum Kind {
  DESKTOP, MOBILE }`; `static func detect(has_mobile_feature: bool, has_web_feature: bool,
  touch_available: bool, forced: String) -> Kind`. Regla, en orden: `forced` = `"mobile"` o
  `"desktop"` gana; `has_mobile_feature` (`OS.has_feature("mobile")`) → `MOBILE`; web con pantalla
  táctil (`OS.has_feature("web")` y `DisplayServer.is_touchscreen_available()`) → `MOBILE`; si no,
  `DESKTOP`. `forced` sale del argumento de usuario `--profile=mobile|desktop`
  (`OS.get_cmdline_user_args()`), para probar el perfil móvil en PC y con el MCP.
- `GameState` (adaptador, ADR-002) gana `var platform: PlatformProfile.Kind` (calculado en `_ready`) y
  `set_platform(kind: PlatformProfile.Kind)` (tests); al fijarlo aplica el `UiProfile` del perfil (E3).
  No hay señal: el perfil no cambia durante la sesión.
- Quién lo lee: el menú principal (oculta «Local 2P» en `MOBILE`, ADR-004 §6.5), `CameraRig` (E5) y
  `GameState` (escala y pausa al perder el foco). Los controles táctiles **no** dependen del perfil,
  sino de que haya pantalla táctil (ADR-004 §6.3).

### E2. Escalado del lienzo (`project.godot`)
```
[display]
window/size/viewport_width=1280          (sin cambios: unidades de diseño de la UI)
window/size/viewport_height=720
window/stretch/mode="canvas_items"
window/stretch/aspect="expand"
window/handheld/orientation=4            (sensor_landscape: apaisado, gira con el sensor)
```
- La UI se diseña en unidades de 1280 × 720 y Godot la escala por `min(ancho / 1280, alto / 720)`;
  `expand` da el espacio extra de las pantallas más anchas (19,5:9) o más altas al lienzo. El 3D se
  sigue pintando a la resolución nativa (`canvas_items` no la baja).
- **Baja de la escala casera**: `UiScale.factor()` y las líneas de `hud.gd` y
  `order_tickets_panel.gd` que ponen `scale` con él (con `stretch` escalarían dos veces). Su lugar lo
  ocupan E3–E4.
- Renderizador: sin cambios (`forward_plus`; web en `gl_compatibility`). El renderizador móvil y el
  export Android quedan para una ficha futura con toolchain y dispositivo (`export.md`).

### E3. Escala por perfil y mínimos en datos (común)
- `resources/ui_profile.gd` (`class_name UiProfile extends Resource`): `@export var content_scale:
  float = 1.0` (se aplica a `get_tree().root.content_scale_factor`, multiplica el estiramiento de E2)
  y `@export var min_text_px_1080: float` (mínimo de altura de texto en píxeles reales a 1080 de
  alto). Instancias `data/config/ui_profile_desktop.tres` (`content_scale` 1,0) y
  `data/config/ui_profile_mobile.tres` (`min_text_px_1080` **36**, D26.8; `content_scale` lo ajusta su
  ficha junto con los tamaños del tema).
- Invariante (test sobre el tema y las escenas de `ui/` con el perfil móvil): todo `Label`/`Button`
  visible en partida cumple `font_size × (1080 / 720) × content_scale ≥ min_text_px_1080`. Para no
  inflar el `content_scale`, la ficha sube los tamaños mínimos del tema (`ui/theme/default_theme.tres`,
  hoy 13–34 px).
- Medidas en píxeles reales a cualquier resolución con `UiScale` (`ui/widgets/ui_scale.gd`, común,
  puro; sustituye a `factor()`):
  - `static func dp_to_units(dp: float, px_per_dp_at_1080: float, canvas_height: float) -> float` =
    `dp × px_per_dp_at_1080 × canvas_height / 1080`: unidades de lienzo que miden `dp` dp con 1 dp =
    `px_per_dp_at_1080` px a 1080 de alto (ADR-004 §6.2), con cualquier estiramiento y
    `content_scale` (`canvas_height` = `get_viewport().get_visible_rect().size.y`).
  - `static func px_to_units(px_at_1080: float, canvas_height: float) -> float` = `px_at_1080 ×
    canvas_height / 1080` (para comprobar mínimos «N px a 1080»).
  - `static func safe_margins(window_size: Vector2, safe_rect: Rect2, canvas_size: Vector2) ->
    Vector4` (izquierda, arriba, derecha, abajo, en unidades de lienzo): márgenes de la zona segura
    convertidos con `canvas_size / window_size`; `Vector4.ZERO` si `safe_rect` cubre la ventana o
    está vacío.

### E4. Safe area (común)
- `ui/widgets/safe_area_margin.gd` (`class_name SafeAreaMargin extends MarginContainer`): pone sus
  márgenes con `UiScale.safe_margins(DisplayServer.window_get_size(),
  DisplayServer.get_display_safe_area(), get_viewport().get_visible_rect().size)` en `_ready` y en
  `get_viewport().size_changed`. Inyección para tests: `set_safe_rect(rect: Rect2)`.
- Lo usan como contenedor raíz de su contenido `hud.tscn`, `order_tickets_panel.tscn`,
  `touch_controls.tscn`, `pause_menu.tscn` y `game_over.tscn`.
- Disposición en `MOBILE` (detalle y ACs en la feature): HUD fuera de la zona del stick (mitad
  izquierda, mitad inferior), tickets en la banda superior sin recortar con 4 comandas, botones
  táctiles a la derecha y nada interactivo bajo la muesca.

### E5. Cámara: perfiles por datos (específica + núcleo común)
- `entities/camera/camera_rig.tscn` gana script `entities/camera/camera_rig.gd` (`class_name CameraRig
  extends Camera3D`). La rotación y la posición de reposo siguen siendo las de la escena (D14: vista
  3/4 a ~38°); el nivel solo sobrescribe la transformación y la referencia a los personajes.
  - `@export var desktop_profile: CameraProfile = data/config/camera_desktop.tres`
  - `@export var mobile_profile: CameraProfile = data/config/camera_mobile.tres`
  - `@export var characters: Array[Node3D]` (en `level_01`: `[Player1, Player2]`, índice =
    `character_index − 1`; override de referencia permitido, ADR-003 §2).
  - En `_ready`: perfil = `mobile_profile` si `GameState.platform == MOBILE`, si no `desktop_profile`;
    `set_profile(profile: CameraProfile)` para tests. Aplica `size = profile.ortho_size`.
  - Con `profile.follow`: sigue al personaje activo de J1. Lo sabe por
    `EventBus.character_switched(player_index, character_index)` con `player_index == 1` (empieza en
    `characters[0]`). En `_process` (suavidad visual; el personaje se mueve en física): foco nuevo =
    `CameraFollow.step(foco, suelo(personaje), profile.follow_smoothing, delta, profile.bounds_min,
    profile.bounds_max)` y `position = posición_de_reposo + Vector3(foco.x − foco_reposo.x, 0, foco.y −
    foco_reposo.y)`. `foco_reposo` = punto del suelo (y = 0) al que mira la cámara en reposo (corte
    del eje de la cámara con el suelo, calculado una vez). Se congela en pausa.
  - Sin `follow` (escritorio): no se mueve; idéntico a hoy (test: con el perfil de escritorio la
    transformación y `size` 12,74 no cambian).
- `resources/camera_profile.gd` (`class_name CameraProfile extends Resource`, común: `float`, `bool`,
  `Vector2` del suelo): `@export var ortho_size: float = 12.74`, `@export var follow: bool = false`,
  `@export var follow_smoothing: float = 0.25` (s, constante de tiempo; 0 = sin suavizado), `@export
  var bounds_min: Vector2`, `@export var bounds_max: Vector2` (rango del foco en el suelo, `(x, z)`).
  - `camera_desktop.tres`: `ortho_size` **12,74**, `follow` `false`.
  - `camera_mobile.tres`: `ortho_size` **9,0** (= 1080 / 120: **120 px por metro a 1080 de alto**, D26.8),
    `follow` `true`, `follow_smoothing` 0,25, límites que mantengan la vista dentro de la planta
    (16 × 11 m, `scene-tree.md` §2); los fija su ficha con captura.
- `core/camera_follow.gd` (`class_name CameraFollow extends RefCounted`, puro, plano del suelo):
  `static func step(current: Vector2, target: Vector2, smoothing: float, delta: float, bounds_min:
  Vector2, bounds_max: Vector2) -> Vector2` = `target` recortado a los límites y, si `smoothing > 0`,
  `current.lerp(recortado, 1 − exp(−delta / smoothing))`; `static func px_per_meter(viewport_height_px:
  float, ortho_size: float) -> float` = `viewport_height_px / ortho_size` (cámara ortográfica con
  `keep_aspect` = `KEEP_HEIGHT`, el valor por defecto).
- Test de datos: `px_per_meter(1080, camera_mobile.ortho_size) ≥ 120`.

### E6. Qué no cambia
D14 (3D ortográfica), capas, `InteractionScoring`, el árbol del nivel salvo `CameraRig` (script y
`characters`) y `TouchControls` en `UI` (`scene-tree.md` §2). La capa común sigue sin tipos de mundo:
`PlatformProfile`, `UiProfile`, `UiScale`, `SafeAreaMargin`, `CameraProfile` y `CameraFollow` usan
solo primitivos, `Vector2`, `Vector4`, `Rect2` y `Control`.

**Alternativas descartadas (Enmienda D26).**
1. *Mantener `UiScale.factor()` sin `stretch`.* Solo escalaba HUD y tickets; menús, pausa y game over
   quedaban fijos, sin safe area ni espacio extra en pantallas anchas.
2. *`stretch/mode = "viewport"`.* Pintaría el 3D a 1280 × 720 y lo estiraría: borroso en un 1080p.
3. *Cámara en perspectiva o más alta en móvil.* Cambia la lectura de la planta (D14) y la oclusión;
   el zoom ortográfico + seguimiento conserva la vista 3/4.
4. *Elegir el perfil solo por pantalla táctil.* Un portátil táctil acabaría con la cámara móvil; el
   perfil es de plataforma y la visibilidad del táctil, de la última entrada (ADR-004 §6.3).
5. *Dos escenas de cámara.* El nivel tendría que elegir cuál instanciar; un `Resource` por perfil lo
   resuelve en datos.

**Consecuencias (Enmienda D26).**
- (+) Toda la UI escala igual (menús incluidos) y se puede medir en píxeles reales por resolución.
- (+) La cámara de PC no cambia; el móvil gana zoom sin tocar el nivel.
- (−) Con `expand` el lienzo varía de proporción: HUD y tickets deben anclarse a bordes, no a
  posiciones fijas (lo comprueban los tests de disposición de la ficha de UI).
- (−) Con el perfil móvil la cámara no enseña toda la cocina: el jugador depende del seguimiento y de
  los avisos (tickets, sonidos) para lo que queda fuera.
