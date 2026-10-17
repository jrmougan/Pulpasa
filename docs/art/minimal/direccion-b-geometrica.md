# Dirección B · «Bloques de Romería» (Formas geométricas puras y paleta reducida)

![Prototipo en el motor — Dirección B (1920×1080 sin HUD)](direccion-b-geometrica.png)

> **Cómo se obtuvo la imagen:** **Prototipo en el motor** ejecutado en tiempo de ejecución mediante
> `docs/evidence/PUL-180/capture_boot.gd` → `docs/evidence/PUL-180/capture_minimal.gd` (estilo `dir_b`)
> sobre la escena `godot/scenes/levels/level_01.tscn`, sin modificar ninguna escena ni recurso
> versionado. Capturas adicionales (con HUD a `1920×1080` y vista móvil a `800×370`) en
> `docs/evidence/PUL-180/direccion_b/`.

---

## 1. Nombre y frase de intención

**Dirección B — «Bloques de Romería»:** *Abstraer la cocina del pulpo en volúmenes geométricos puros
de juguete arquitectónico sobre un escenario azul noche de contraste extremo, reduciendo la escena a
siluetas primarias donde solo hablan la geometría y el código cromático de los pedidos.*

---

## 2. Paleta cerrada en hex (14 colores)

Paleta estricta de **14 colores** (dentro del rango de 8 a 16 colores de AC2), diseñada para que el
escenario funcione como una caja azul noche profundo sobre la que destacan las encimeras de piedra
clara y los 5 colores normativos de §3.4. Luminancias relativas ($L$) calculadas con `docs/evidence/PUL-180/build_evidence.py`:

| # | Rol / Categoría | Token | Hex | Luminancia rel. ($L$) | Uso principal |
|---:|---|---|---|---:|---|
| 1 | Fondo / Entorno | `bg_void_navy` | `#18222C` | 0.0152 | Cielo/vacío exterior, zócalos oscuros, quemado y fondo de tarjeta HUD en prototipo |
| 2 | Superficie | `surf_slate_floor` | `#D4DAE0` | 0.6952 | Losa geométrica del suelo de la cocina (`kitchen_floor_dirt`) y luz ambiental (`capture_minimal.gd:401, 567`) *(variante conceptual oscura: `#243240`, $L = 0.0303$)* |
| 3 | Superficie | `surf_stone_block` | `#EFECE6` | 0.8405 | Bloque superior de encimeras, barra, interior de bandeja y borde de tarjetas HUD |
| 4 | Superficie / Jugable / UI | `play_box_navy` | `#1D3557` | 0.0350 | Frentes de encimeras/ollas/puestos en prototipo (`capture_minimal.gd:572`), cuenco, cabecera/pozos HUD y pantalón de cocineros *(variante conceptual de bastidor: `#465666`, $L = 0.0892$)* |
| 5 | Jugable (personaje / puesto) | `play_cook_1_blue` | `#2F6FB5` | 0.1531 | Cocinero 1 (`mat_cloth_player_1`, gorra/delantal y aro P1), puesto 2 y agua (`capture_minimal.gd:508, 579`) *(variante conceptual coral: `#E63946`, $L = 0.2019$)* |
| 6 | Jugable / Estado | `stand_4_green` | `#4FA05A` | 0.2754 | Toldillo del puesto 4 (`mat_canvas_stand_4`) y anillo de cocción lista (`capture_minimal.gd:585`) *(variante conceptual cian P2: `#2A9D8F`, $L = 0.2659$; verde timer: `#2E9E5B`, $L = 0.2579$)* |
| 7 | Jugable / Estado | `state_octopus_raw` | `#E0AFB2` | 0.4972 | Pulpo crudo (`mat_food_octopus_raw`) y piel clara en el prototipo (`capture_minimal.gd:499`) |
| 8 | Jugable / Estado | `state_octopus_cooked` | `#B8283D` | 0.1204 | Pulpo cocido y ración lista (`cooked_cut`) en caja (`capture_minimal.gd:500`) |
| 9 | Jugable / Estado | `potato_raw` | `#8E6B47` | 0.1672 | Patata cruda, saco de la cachelera (`mat_burlap`) y piel oscura (`capture_minimal.gd:503, 588`) |
| 10 | §3.4 Condimento / Jugable | `sec34_paprika_sweet` | `#D6361F` | 0.1703 | **Pimentón dulce** (§3.4: círculo, dispensador y etiqueta), caja roja y puesto 1 (`capture_minimal.gd:578`) |
| 11 | §3.4 Condimento | `sec34_paprika_hot` | `#8F1A14` | 0.0663 | **Pimentón picante** (§3.4: octógono, dispensador y etiqueta) |
| 12 | §3.4 Condimento / UI | `sec34_salt` | `#F7F4EC` | 0.9053 | **Sal gruesa** (§3.4: cuadrado), camisa de cocineros y texto HUD |
| 13 | §3.4 Condimento / Jugable | `sec34_oil` | `#F2C230` | 0.5767 | **Aceite de oliva** (§3.4: gota), Cocinero 2 (`mat_cloth_player_2`, gorro/delantal P2, `capture_minimal.gd:509`), puesto 3 y marcas de pasaplatos |
| 14 | §3.4 Condimento | `sec34_cachelos` | `#F2D56B` | 0.6753 | **Cachelos** (§3.4: óvalo y gajos en caja/cuenco) |

> **Nota sobre alineación entre documento y prototipo (`capture_minimal.gd`):** La tabla recoge los 14 colores hex exactos que aplica `capture_minimal.gd` en `dir_b` (compartiendo `#2F6FB5` azul y `#F2C230` amarillo para los dos cocineros y `#E0AFB2` para el pulpo crudo en `common`), dejando anotadas entre paréntesis las variantes conceptuales alternativas si en producción se remodelaran las mallas en Blender. El pulpo y la patata quemados caen directamente al carbón `bg_void_navy` (`#18222C`).

---

## 3. Reglas de forma, material, luz y post-proceso

- **Forma:**
  - **En producción (con remodelado Blender):** primitivas puras sin biseles decorativos (paralelepípedos limpios para puestos, cilindros ortogonales para ollas e ingredientes sintetizados en esferas, cilindros cortos y prismas octogonales).
  - **En el prototipo (`capture_minimal.gd`):** se recorta el suelo jugable a un `PlaneMesh` exacto (`15.6 × 10.6 m`, `capture_minimal.gd:490-493`), se ocultan las tapas de las ollas y las rejillas de suelo (`:478-480`) y se elimina todo el perímetro exterior Z3.
- **Material:**
  - `StandardMaterial3D` de color plano (`specular_mode = SPECULAR_DISABLED`, `roughness = 0.85–0.98`, `metallic = 0.0`).
  - Al eliminarse la carpa (`Environment/Model/Tent`), tampoco aparece `env_plate`, quedando únicamente las texturas de iconos/pegatinas D26 y §3.4.
- **Luz:**
  - **Una única `DirectionalLight3D`** (`#FFFFFF`, `light_energy = 1.15`) con sombras duras y nítidas (`shadow_blur = 0.15`, `capture_minimal.gd:395-397`).
  - **0 `OmniLight3D`** de entorno (`bulbs.visible = false`). Fondo `#18222C` y luz ambiental `#D4DAE0` (`ambient_light_energy = 0.78`, `capture_minimal.gd:398-402`).
- **Post-proceso (`capture_minimal.gd:367-407`):**
  - Se desactivan el **SSAO** (`ssao_enabled = false`), el `glow` (`glow_enabled = false`), el DoF (`camera_attributes = null`), el mapa de corrección tonal y la capa `Vignette` (`vignette.visible = false`). Solo permanece activo el ajuste de contraste/saturación del entorno (`adjustment_enabled = true`, `contrast = 1.12`, `saturation = 1.08`).

---

## 4. Qué atrezo desaparece o se simplifica

| Elemento actual (v2) | Destino en Dirección B | Justificación de diseño |
|---|---|---|
| **Todo el perímetro exterior (16 props de fondo + muralla + árboles + colinas + mesas)** | **Eliminado por completo** | La cocina flota como un diorama/tablero aislado sobre `#18222C`, eliminando el 100 % del ruido periférico. |
| **Carpa a rayas y estructura de postes (`Tent`)** | **Eliminado** | Desaparecen las columnas, la lona superior y el cartel superior; nada compite con la parte alta de la cocina. |
| **Guirnalda (`Garlands`) y farolillos (`Bulbs`)** | **Eliminado** | Sin luces puntuales ni cables que crucen el encuadre. |
| **Tapas de ollas (`lid`), rejillas de suelo (`Grates`) y atrezo secundario Z1/Z2** | **Eliminados en el prototipo** | Deja la isla de cocina reducida a planos limpios y volúmenes funcionales. |

---

## 5. Cómo se leen los estados y los colores de §3.4

### 5.1 Lectura de estados de juego
- **Pulpo crudo (`raw`):** rosa pálido `#E0AFB2` ($L = 0.4972$) en el prototipo (`capture_minimal.gd:499`), o gris pizarra `#465666` ($L = 0.0892$) si se adopta la variante conceptual fría.
- **Pulpo cocido (`cooked` / `cooked_cut`):** rojo burdeos (`#B8283D`, $L = 0.1204$) de silueta rotunda; en la olla se acompaña del anillo verde `#4FA05A` y en la caja contrasta contra el interior `#EFECE6`.
- **Pulpo quemado (`burnt`):** bloque negro azulado (`#18222C`, $L = 0.0152$) que destaca sobre la encimera `#EFECE6` ($L = 0.8405$) con un contraste de **13.6580 : 1** (13.66 : 1).
- **Caja vacía vs. caja llena:** la caja vacía muestra su interior blanco piedra (`#EFECE6`,
  $L = 0.8405$); al llenarse con ración (`#B8283D`, $L = 0.1204$), el centro pasa de claro a oscuro
  con un **contraste exacto de 5.2247 : 1** (5.22 : 1).
- **Aliños (§3.4):** cada condimento se representa en el puesto, en la caja y en el HUD con **la
  misma forma geométrica y color hex** (D26): círculo `#D6361F`, octógono `#8F1A14`, cuadrado
  `#F7F4EC`, gota `#F2C230` y óvalo `#F2D56B`.

### 5.2 Contraste WCAG 2.1 de los 5 colores de §3.4 (AC2: requisito ≥ 3:1)

En la Dirección B, los condimentos oscuros se apoyan sobre el bloque de piedra clara (`#EFECE6`) y
los condimentos claros se apoyan sobre los soportes oscuros (`#1D3557` / `#18222C`) o sobre el
pulpo cocido (`#B8283D`). Tabla exacta calculada por `docs/evidence/PUL-180/build_evidence.py` en [`docs/evidence/PUL-180/contrastes_sec34.md`](../../evidence/PUL-180/contrastes_sec34.md):
- **Mínimos reales en Dirección B:** **4.0418 : 1** (4.04 : 1) en soportes primarios de estación/UI/vacío (`#EFECE6`, `#1D3557`, `#18222C`); **3.6770 : 1** (3.68 : 1) sobre cama de pulpo cocido (`#B8283D`).

| Condimento (§3.4) | Hex | $L$ condimento | Superficie donde aparece | Hex superficie | $L$ superficie | Contraste exacto (2 dec.) | Cumple ≥ 3:1 |
|---|---|---:|---|---|---:|---:|:---:|
| **Pimentón dulce** (`paprika_sweet`) | `#D6361F` | 0.1703 | Losa de encimera / interior de caja | `#EFECE6` | 0.8405 | **4.0418 : 1** (4.04 : 1) | Sí |
| **Pimentón picante** (`paprika_hot`) | `#8F1A14` | 0.0663 | Losa de encimera / interior de caja | `#EFECE6` | 0.8405 | **7.6580 : 1** (7.66 : 1) | Sí |
| **Sal gruesa** (`salt`) | `#F7F4EC` | 0.9053 | Cuenco / pastilla HUD (`play_box_navy`) | `#1D3557` | 0.0350 | **11.2449 : 1** (11.24 : 1) | Sí |
| **Sal gruesa** (`salt`) | `#F7F4EC` | 0.9053 | Fondo oscuro (`bg_void_navy`) / pulpo (`#B8283D`) | `#18222C` / `#B8283D` | 0.0152 / 0.1204 | **14.6519 : 1** (14.65 : 1) / **5.6047 : 1** (5.60 : 1) | Sí |
| **Aceite de oliva** (`oil`) | `#F2C230` | 0.5767 | Cuenco / pastilla HUD (`play_box_navy`) | `#1D3557` | 0.0350 | **7.3773 : 1** (7.38 : 1) | Sí |
| **Aceite de oliva** (`oil`) | `#F2C230` | 0.5767 | Fondo oscuro (`bg_void_navy`) / pulpo (`#B8283D`) | `#18222C` / `#B8283D` | 0.0152 / 0.1204 | **9.6125 : 1** (9.61 : 1) / **3.6770 : 1** (3.68 : 1) | Sí |
| **Cachelos** (`cachelos`) | `#F2D56B` | 0.6753 | Cuenco / pastilla HUD (`play_box_navy`) | `#1D3557` | 0.0350 | **8.5371 : 1** (8.54 : 1) | Sí |
| **Cachelos** (`cachelos`) | `#F2D56B` | 0.6753 | Fondo oscuro (`bg_void_navy`) / pulpo (`#B8283D`) | `#18222C` / `#B8283D` | 0.0152 / 0.1204 | **11.1237 : 1** (11.12 : 1) / **4.2551 : 1** (4.26 : 1) | Sí |

---

## 6. Impacto en la UI y el HUD

- **Separación entre fondo y HUD:** al ser el exterior del escenario `#18222C`, las tarjetas de
  pedidos en la franja superior y los marcadores de puntuación se apoyan sobre un fondo oscuro
  sin elementos 3D detrás del HUD superior.
- **Lenguaje geométrico unificado 3D ↔ 2D:** en el prototipo (`capture_minimal.gd:798-826`), las tarjetas de pedido usan bloques ortogonales sin redondeo (`corner_radius = 0 px`) con borde `#EFECE6`, fondo `#18222C` y cabecera/pozos `#1D3557`.
- **Números de puesto (`#1..#4`) en móvil (`800×370`):** aunque el par `#F7F4EC` / `#1D3557` tiene un contraste teórico de **11.2449 : 1** (11.24 : 1), en el prototipo móvil (`comparativa_movil_800x370.png`) el estilizado de `OrderLabel` con texto blanco `#F7F4EC` y contorno oscuro (`outline_size = 14`) sobre la placa clara produce números delineados/huecos que pierden nitidez respecto a la partida (y el número inferior `StandNumber` queda oscuro sobre `#1D3557`), por lo que requeriría glifos sólidos sin contorno hueco.
