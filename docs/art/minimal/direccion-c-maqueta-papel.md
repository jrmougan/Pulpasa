# Dirección C · «Maqueta de Papel» (Maqueta arquitectónica blanca con acentos en lo jugable)

![Prototipo en el motor — Dirección C (1920×1080 con HUD)](direccion-c-maqueta-papel.png)

> **Cómo se obtuvo la imagen:** **Prototipo en el motor** ejecutado en tiempo de ejecución mediante
> `docs/evidence/PUL-180/capture_boot.gd` → `docs/evidence/PUL-180/capture_minimal.gd` sobre la
> escena `godot/scenes/main/main.tscn`, sin modificar ninguna escena ni recurso versionado. Capturas
> adicionales (sin HUD a `1920×1080` y vista móvil a `800×370`) en
> `docs/evidence/PUL-180/direccion_c/`.

---

## 1. Nombre y frase de intención

**Dirección C — «Maqueta de Papel»:** *Convertir el escenario en una maqueta arquitectónica de
cartulina marfil y grafito suave donde el mundo no interactivo es monocromo y el color está
estrictamente reservado a los cocineros, el pulpo, las cajas y los 5 condimentos de §3.4.*

---

## 2. Paleta cerrada en hex (15 colores)

Paleta cerrada de **15 colores** (dentro del rango de 8 a 16 colores de AC2), dividida en dos
familias: **5 neutros de cartulina/tinta** para todo el mundo estático y **10 colores semánticos**
exclusivos para lo jugable y el HUD:

| # | Rol / Categoría | Token | Hex | Luminancia rel. ($L$) | Uso principal |
|---:|---|---|---|---:|---|
| 1 | Fondo / Maqueta | `paper_bg_ivory` | `#F4EFE6` | 0.8632 | Cartulina de suelo exterior, cielo y entorno periférico |
| 2 | Superficie | `paper_floor_warm` | `#E6DFD3` | 0.7529 | Plancha de suelo de la cocina y volúmenes de carpa en papel plegado |
| 3 | Superficie | `paper_counter_white` | `#F7F4EC` | 0.9053 | Superficie superior de encimeras, barra, interior de caja y **sal gruesa (§3.4)** |
| 4 | Superficie | `paper_cardboard_mid` | `#D5CCB9` | 0.6186 | Cuerpo inferior de puestos, barra y bastidores de cartón pluma |
| 5 | Superficie / Tinta | `ink_graphite_dark` | `#2A2320` | 0.0185 | Ollas en grafito mate, bandejas de aliños claros, quemado y bordes de tinta |
| 6 | Superficie / Tinta | `ink_shadow_taupe` | `#6E655F` | 0.1356 | Aros guía en el suelo, sombras impresas y texto secundario |
| 7 | Jugable (personaje) | `play_cook_1_vermilion` | `#E04836` | 0.2016 | Cocinero 1 (acento de papel coloreado P1) |
| 8 | Jugable (personaje) | `play_cook_2_cobalt` | `#2B72B8` | 0.1620 | Cocinero 2 (acento de papel coloreado P2) |
| 9 | Jugable / Marca | `play_box_navy` | `#1D3557` | 0.0365 | Exterior de la caja de ración y pastillas de número `#1..#4` |
| 10 | Jugable / Estado | `state_octopus_raw` | `#9E7B9B` | 0.2289 | Pulpo crudo (`raw`) sobre encimera o en mano |
| 11 | Jugable / Estado | `state_octopus_cooked` | `#B8283D` | 0.1046 | Pulpo cocido (`cooked` / `cooked_cut`) en olla, tabla y caja |
| 12 | §3.4 Condimento | `sec34_paprika_sweet` | `#D6361F` | 0.1703 | Pimentón dulce (pegatina circular, cuenco y espolvoreado) |
| 13 | §3.4 Condimento | `sec34_paprika_hot` | `#8F1A14` | 0.0663 | Pimentón picante (pegatina octogonal, cuenco y espolvoreado) |
| 14 | §3.4 Condimento | `sec34_oil` | `#F2C230` | 0.5767 | Aceite de oliva (pegatina en gota, aceitera, brillo y alerta) |
| 15 | §3.4 Condimento | `sec34_cachelos` | `#F2D56B` | 0.6753 | Cachelos (pegatina ovalada y gajos sobre caja/puesto) |

*(El color `#F7F4EC` cumple doble función intencionada: blanco hueso del papel de encimera y blanco
sal de §3.4 sobre soporte grafito `#2A2320` o azul `#1D3557`, manteniendo la paleta en 15 hex
únicos.)*

---

## 3. Reglas de forma, material, luz y post-proceso

- **Forma:**
  - **Estética de cartulina plegada / *papercraft* arquitectónico:** los puestos, la barra y la
    carpa se leen como maquetas de cartón pluma de cantos vivos (`#F7F4EC` arriba, `#D5CCB9` en los
    frentes), mientras que las ollas se representan como cilindros de grafito oscuro (`#2A2320`) que
    anclan el centro de la composición.
  - **Jerarquía cromática estricta (regla 90/10):** el 90 % de los píxeles de la pantalla pertenecen
    a la escala marfil-cartón-grafito (`#F4EFE6`, `#E6DFD3`, `#F7F4EC`, `#D5CCB9`, `#2A2320`); el
    10 % restante son los objetos interactivos, que «saltan» a la vista sin esfuerzo cognitivo.
- **Material:**
  - Acabado 100 % mate de papel prensado (`roughness = 0.95`, `metallic = 0.0`, `specular = 0.05`)
    en todos los elementos del escenario y estaciones.
  - Solo el aceite (`#F2C230`) y el pulpo recién cocido (`#B8283D`) tienen un ligero satinado
    (`roughness = 0.45`) para transmitir jugosidad frente al papel seco.
- **Luz:**
  - **Luz de estudio cenital difusa:** 1 `DirectionalLight3D` blanca cálida (`#FFFDF9`,
    `energy = 0.85`) con sombras muy suaves (`shadow_blur = 2.8`, `shadow_opacity = 0.38`) y luz
    ambiental alta (`ambient_light_color = #F4EFE6`, `ambient_light_energy = 0.72`), imitando una
    mesa de luz de estudio fotográfico sobre una maqueta física.
  - **0 `OmniLight3D`** de feria.
- **Post-proceso:**
  - Sin bloom, sin niebla y sin DoF. Opcionalmente en producción: un contorno de tinta muy fino
    (`#2A2320`, 1 px) por diferencia de normales/profundidad para acentuar el corte de cartulina.

---

## 4. Qué atrezo desaparece o se simplifica

| Elemento actual (v2) | Destino en Dirección C | Justificación de diseño |
|---|---|---|
| **Atrezo callejero periférico (16 props: contenedores, vallas, barriles, leña, vegetación)** | **Oculto por completo (o siluetas blancas opcionales)** | En el prototipo se elimina todo el atrezo exterior para dejar el plano de cartulina `#F4EFE6` limpio; si se quisiera contexto en producción, solo se permitirían siluetas recortadas en blanco `#F4EFE6` sin color. |
| **Carpa a rayas rojas (`TentA`)** | **Simplificada a maqueta blanca monocroma** | La carpa pierde sus rayas rojas y pasa a cartulina `#E6DFD3` / `#D5CCB9`: mantiene el encuadre espacial de puesto de feria sin robar ni un ápice de atención al rojo del pimentón (`#D6361F`) ni al Cocinero 1 (`#E04836`). |
| **Guirnalda (`Garland`) y farolillos (`Lanterns`)** | **Eliminados** | No hay iluminación nocturna ni cables aéreos en una maqueta diurna de papel. |
| **Texturas de madera, metal rayado y hormigón** | **Eliminadas** | Sustituidas por los 4 tonos planos de papel/cartón pluma (`#F4EFE6`, `#E6DFD3`, `#F7F4EC`, `#D5CCB9`). |

---

## 5. Cómo se leen los estados y los colores de §3.4

### 5.1 Lectura de estados de juego
- **Dónde mirar de un vistazo:** como ningún objeto estático tiene saturación cromática, **cualquier
  mancha de color en pantalla es un elemento activo de gameplay** (cocinero, ingrediente, caja,
  condimento o indicador de estado).
- **Pulpo crudo (`raw`) → cocido (`cooked`) → quemado (`burned`):**
  - Crudo: malva `#9E7B9B` sobre la encimera blanca `#F7F4EC` (contraste **3.47:1**).
  - Cocido: burdeos `#B8283D` sobre la encimera blanca `#F7F4EC` (contraste **6.14:1**).
  - Quemado: carbón grafito `#2A2320` sobre la encimera `#F7F4EC` (contraste **13.78:1**) más
    triángulo/octógono de alerta `#F2C230`.
- **Caja vacía vs. caja llena:** la caja tiene exterior `#1D3557` (contraste **11.24:1** contra la
  encimera `#F7F4EC`) e interior blanco `#F7F4EC`; al recibir el pulpo `#B8283D`, el interior pasa
  de blanco a burdeos (contraste **6.14:1**).
- **Aliños (§3.4):** en el puesto de especias (`SpiceRack`), los pimentones (`#D6361F`, `#8F1A14`)
  reposan directamente sobre la bandeja blanca `#F7F4EC`, mientras que la sal (`#F7F4EC`), el
  aceite (`#F2C230`) y los cachelos (`#F2D56B`) reposan sobre una bandeja/cuenco de grafito
  `#2A2320` (o azul `#1D3557` en las etiquetas), garantizando contraste extremo en ambos sentidos.

### 5.2 Contraste WCAG 2.1 de los 5 colores de §3.4 (AC2: requisito ≥ 3:1)

Tabla calculada en `docs/evidence/PUL-180/contrastes_sec34.md`:

| Condimento (§3.4) | Hex | $L$ condimento | Superficie donde aparece | Hex superficie | $L$ superficie | Contraste (WCAG) | Cumple ≥ 3:1 |
|---|---|---:|---|---|---:|---:|:---:|
| **Pimentón dulce** (`paprika_sweet`) | `#D6361F` | 0.1703 | Encimera de papel blanco / interior caja | `#F7F4EC` | 0.9053 | **4.34 : 1** | Sí |
| **Pimentón picante** (`paprika_hot`) | `#8F1A14` | 0.0663 | Encimera de papel blanco / interior caja | `#F7F4EC` | 0.9053 | **8.21 : 1** | Sí |
| **Sal gruesa** (`salt`) | `#F7F4EC` | 0.9053 | Bandeja de grafito (`ink_graphite_dark`) | `#2A2320` | 0.0185 | **13.78 : 1** | Sí |
| **Sal gruesa** (`salt`) | `#F7F4EC` | 0.9053 | Pastilla HUD / caja (`#1D3557`) o pulpo (`#B8283D`) | `#1D3557` / `#B8283D` | 0.0365 / 0.1046 | **11.24 : 1** / **6.14 : 1** | Sí |
| **Aceite de oliva** (`oil`) | `#F2C230` | 0.5767 | Bandeja de grafito (`ink_graphite_dark`) | `#2A2320` | 0.0185 | **9.04 : 1** | Sí |
| **Aceite de oliva** (`oil`) | `#F2C230` | 0.5767 | Pastilla HUD (`#1D3557`) o pulpo (`#B8283D`) | `#1D3557` / `#B8283D` | 0.0365 / 0.1046 | **7.38 : 1** / **4.03 : 1** | Sí |
| **Cachelos** (`cachelos`) | `#F2D56B` | 0.6753 | Bandeja de grafito (`ink_graphite_dark`) | `#2A2320` | 0.0185 | **10.46 : 1** | Sí |
| **Cachelos** (`cachelos`) | `#F2D56B` | 0.6753 | Pastilla HUD (`#1D3557`) o pulpo (`#B8283D`) | `#1D3557` / `#B8283D` | 0.0365 / 0.1046 | **8.54 : 1** / **4.67 : 1** | Sí |

---

## 6. Impacto en la UI y el HUD

- **Comandas como «tickets de papel» de taberna:** las tarjetas de pedido del HUD superior pueden
  mantener el fondo oscuro `#1D3557` actual o invertirse a **tickets de papel marfil `#F7F4EC` con
  borde de tinta `#2A2320`**, integrando una pastilla oscura `#2A2320` / `#1D3557` para la fila de
  pegatinas de condimentos claros.
- **Cero competencia entre carpa y etiquetas `#1..#4`:** como la carpa pasa a cartulina neutra
  `#E6DFD3` sin rayas rojas, las pastillas `#1D3557` con texto `#F7F4EC` de la barra de entrega
  destacan con **9.29:1** frente al fondo de papel sin necesidad de cambiar el encuadre.
- **Claridad en móvil (`800×370`):** es la dirección con menor fatiga visual y mayor separación
  figura-fondo para daltónicos o pantallas pequeñas con brillo bajo, porque satura únicamente los
  elementos que el jugador puede tocar o leer.
