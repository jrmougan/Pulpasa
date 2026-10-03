# ADR-005 — Dimensión: 3D o 2D

- **Estado:** propuesto (decide el responsable; resuelve D14)
- **Fecha:** 2026-10-03
- **Ficha:** PUL-003
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

Pendiente del responsable (D14). Hasta entonces:
1. Fases 0–2 avanzan con la capa común (sin tipos 3D/2D ni clases específicas en `autoload/`,
   `core/`, `resources/`, `ui/`, componentes comunes ni firmas de `EventBus`; ADR-002 regla 10,
   ADR-003 §0).
2. Ninguna ficha de fases 3–8 pasa a `ready` sin D14 resuelta; los spikes de medición sí pueden.
3. Si se acepta A: `scene-tree.md` §2–§3 rige tal cual; la fase 3 incluye la prueba de export web
   con Compatibility.
4. Si se acepta B: `scene-tree.md` §6 rige para la capa específica; se reescribe el gate de M0 y se
   crea la ficha de arte según la fuente elegida (B1, B2 o B3, con revisión humana de licencias).

## Consecuencias
- (+) La decisión queda acotada a la capa específica; no reabre ADR-002 ni ADR-004 ni el catálogo
  de señales.
- (+) La comparación separa hechos del prototipo de hipótesis y propone cómo medirlas.
- (−) Mantener la capa común "neutral" impone pequeñas conversiones en 3D (`Vector2(x, z)`).
- (−) Mientras D14 siga pendiente, las fases 3–8 no se pueden planificar en detalle; los spikes
  cuestan 1–2 fichas antes del gate.
