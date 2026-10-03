# ADR-005 — Dimensión: 3D o 2D

- **Estado:** propuesto (decide el responsable; resuelve D14)
- **Fecha:** 2026-10-03
- **Ficha:** PUL-003
- **Relacionado:** D6 y D14 (`docs/design/decisions.md`), roadmap (fases y gate de M0), ADR-003 §0
  (capa común / específica), ADR-004 §0, `scene-tree.md` §6, inventario §3 y §5

## Contexto

El prototipo Unity es 3D. El responsable duda entre seguir en 3D o pasar a 2D (D14, pendiente).
D14 bloquea las fases 3–8 de M0, no las 0–2: ADR-002, ADR-003 y ADR-004 ya separan una capa común
(autoloads, `core/`, datos, UI de pantalla, InputMap) que no cambia con la decisión.

Datos del prototipo relevantes para decidir:
- **Cámara**: `Main Camera` de `Level_01.unity` es **ortográfica** (`orthographic: 1`, tamaño
  6,37), inclinada unos 38° hacia abajo (`m_LocalRotation.x = 0.323`), en (0,7; 7,49; −5,86).
  Es decir, una vista 3/4 fija sin perspectiva, ya cercana a la lectura de un juego 2D.
- **Assets 3D existentes** (inventario §5): personaje `freakycapucha.fbx` con sus clips
  (Idle/Walk/Pick/WalkWhileHolding), `Octopus.fbx`, `Condiment.obj`, caja (`Boite Hamburger.fbx`,
  licencia por verificar), muebles propios (`Mueblecajas.fbx`, `order_stand.fbx`) y 6 modelos de
  Pandazole (olla, fogón, nevera, 3 mesas; uso incierto por D6). Candidato a 2.º personaje:
  `BillGatos.fbx`. No hay ningún sprite de juego; solo iconos (`octopus`, `salt`, `pepper-hot`,
  `selection`), logo y fondo de ticket.
- **Gate de M0**: "partida lado a lado con Unity" (roadmap).
- **Export**: la fase 8 pide Linux/Web y el Must 1 builds Windows/Linux. `project.godot` usa
  `forward_plus`; en web Godot 4 solo dispone del renderizador Compatibility (WebGL 2).
- **Agentes**: no modelan ni dibujan; verifican con capturas del MCP y tests GUT headless.

## Opciones

- **A. 3D con cámara ortográfica fija** (como el prototipo): reaprovecha FBX y layout.
- **B. 2D** (top-down u oblicua con orden por Y): sprites nuevos para todo.
- **C. Híbrido 2,5D**: modelos 3D renderizados a sprites (pre-render) y juego en 2D.

## Comparación para Pulpasa

| Criterio | A. 3D ortográfica | B. 2D | C. 2,5D pre-render |
|---|---|---|---|
| **Coste de migrar desde el prototipo** | Bajo: posiciones de `Level_01.unity` reutilizables (ejes: −Z adelante), cámara equivalente, `AnimationTree` desde los clips del FBX | Alto en la capa específica: rehacer layout, colisiones, animación por direcciones. La capa común no cambia | Medio-alto: pipeline de render a sprites (Blender por direcciones) + todo lo de B |
| **Assets disponibles** | Casi todos existen (≈ 8 modelos propios + 6 Pandazole); faltan materiales Godot y verificar licencias (caja, condimento) | Ninguno: personaje × ≥ 4 direcciones × 4 animaciones × 2 personajes (M2), ~10 props, suelo/tiles, barras. Requiere artista humano | Se generan desde los FBX, pero cualquier cambio de modelo exige re-render |
| **Cámara cenital / 3/4** | Directa: `Camera3D` `PROJECTION_ORTHOGONAL`, ~38°. Oclusión posible tras muebles altos (se mitiga con altura de muebles) | Top-down sin oclusión; vista oblicua necesita Y-sort y cuidado con objetos en la mano | Como B |
| **Detección de interacción** | `Area3D` esfera + `InteractionScoring` en el plano XZ (`Vector2`) | `Area2D` círculo + el mismo `InteractionScoring` | Como B |
| **Legibilidad del caos coop** | Buena con cámara ortográfica y contorno (`material_overlay`); los objetos pequeños (botes de condimento) pueden leerse peor que en 2D | Mejor por defecto: siluetas e iconos claros, sin perspectiva ni sombras ambiguas | Como B si el pre-render es nítido a la escala final |
| **Rendimiento / export web** | Sobrado en escritorio. En web exige probar con renderizador Compatibility (sin algunos efectos de Forward+) y un `.pck` mayor por mallas y texturas | El más ligero; Compatibility sin pérdidas visibles; descarga pequeña | Como B; atlas de sprites grandes si hay muchas direcciones |
| **Trabajo para agentes (capturas)** | Capturas dependen de luz/sombra y ángulo; aserciones de posición requieren proyectar a pantalla. Iteración visual más lenta | Capturas deterministas y fáciles de comparar; coordenadas de mundo ≈ píxeles | Como B en ejecución; el pre-render queda fuera del alcance de los agentes |
| **Gate M0 "lado a lado con Unity"** | Comparación casi 1:1 | La paridad pasa a ser de reglas y flujo, no visual; habría que redefinir el gate | Como B |
| **Riesgo de plazo** | Bajo: lo que falta es conversión (fase 3) | Bloqueado por arte: las fases 3–8 esperan a los sprites | Medio: depende del pipeline de render |

## Recomendación

**Opción A: 3D con cámara ortográfica fija**, manteniendo la separación de capas de ADR-003 §0.

Motivos: todos los assets necesarios para M0 existen ya en 3D; el prototipo ya usa una cámara
ortográfica de lectura casi 2D; el gate de M0 es una comparación visual con Unity; y ni agentes ni
el flujo actual producen arte 2D. Los puntos débiles de 3D (legibilidad de objetos pequeños,
capturas menos deterministas, web) se atacan con medidas acotadas: contorno de resaltado, escala de
props legible a tamaño ortográfico 6–7, iconos sobre los objetos (como en los tickets, M1), y una
prueba temprana de export web con Compatibility.

Cuándo elegir B en su lugar: si el responsable cuenta con un artista 2D (o un pack con licencia)
para personaje con 4 direcciones y ~10 props antes de la fase 3, y acepta redefinir el gate de M0
como paridad de reglas. La capa común y las fases 0–2 sirven igual.

C no se recomienda: suma el coste de B y un pipeline de render sin ventaja clara frente a A con
cámara ortográfica.

## Decisión

Pendiente del responsable (D14). Hasta entonces:
1. Fases 0–2 avanzan con la capa común (sin tipos 3D/2D en `autoload/`, `core/`, `resources/`,
   `ui/` ni en firmas de `EventBus`; ADR-002 regla 10).
2. Ninguna ficha de fases 3–8 pasa a `ready` sin D14 resuelta.
3. Si se acepta A: `scene-tree.md` §2–§3 rige tal cual; la fase 3 añade una ficha de prueba de
   export web con Compatibility.
4. Si se acepta B: `scene-tree.md` §6 rige para la capa específica; se reescribe el gate de M0 y se
   crea una ficha de producción de sprites (rol humano o asset-pipeline con assets externos).

## Consecuencias
- (+) La decisión queda acotada a la capa específica; no reabre ADR-002 ni ADR-004 ni el catálogo
  de señales.
- (+) La comparación queda escrita con datos del prototipo para que el responsable decida.
- (−) Mantener la capa común "neutral" impone pequeñas conversiones en 3D (`Vector2(x, z)`).
- (−) Mientras D14 siga pendiente, las fases 3–8 no se pueden planificar en detalle.
