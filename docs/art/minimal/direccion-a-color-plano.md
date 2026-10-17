# Dirección A · «Feira Clara» — Color plano cálido y sombras suaves

Ficha: `PUL-180` (exploración de estética minimalista, M3f). Restricciones vigentes: D14 (3D, cámara ortográfica fija), D16 (licencia propia, sin assets ni imágenes de terceros), D20 (arte propio en Blender), D21 (marca **PulpaSA**), D26/D27 (lenguaje de acciones y perfil móvil a 800×370) y §3.4 de la biblia v1 (colores de condimentos y distintivos).

![Prototipo en el motor — Dirección A (1920×1080 sin HUD)](direccion-a-color-plano.png)

> **Cómo se obtuvo la imagen:** **prototipo en el motor** (`docs/evidence/PUL-180/capture_boot.gd` → `capture_minimal.gd`, estilo `dir_a`) ejecutado en tiempo de ejecución sobre `godot/scenes/levels/level_01.tscn` en Godot 4.7.2, sustituyendo en caliente los materiales por `StandardMaterial3D` de color plano sin texturas de ruido ni desgaste, ajustando `WorldEnvironment` y `DirectionalLight3D` y ocultando el atrezo secundario sin modificar ninguna escena ni recurso versionado. Capturas con HUD y móvil (800×370) en [`docs/evidence/PUL-180/direccion_a/`](../../evidence/PUL-180/direccion_a/).

---

## 1. Nombre y frase de intención

- **Nombre:** **Dirección A · «Feira Clara»** (Color plano cálido y sombras suaves).
- **Frase de intención:** *«La romería de PulpaSA limpia de ruido: materiales mates de color plano sin texturas de desgaste, luz diurna cálida con sombras suaves y siluetas amables que priorizan la lectura en PC y móvil.»*

---

## 2. Paleta cerrada en hex (16 colores)

Paleta cerrada de **16 colores en hex sRGB** (dentro del rango de 8 a 16 colores de AC2), repartida por función (`fondo`, `superficies`, `jugables`, `acentos de estado`, `UI`) e integrando los 5 colores de condimentos de §3.4. Luminancias relativas ($L$) calculadas de forma exacta con `docs/evidence/PUL-180/build_evidence.py`:

| # | Token | Hex | Luminancia ($L$) | Rol | Uso en el nivel y la UI |
|---|---|---|---|---|---|
| 1 | `ground_sand` | `#C4A882` | 0.4135 | **Fondo** | Suelo jugable de tierra de albero cálido liso (Z0) y cajas de cartón secundarias |
| 2 | `stone_steel` | `#8C96A0` | 0.2993 | **Fondo / Superficie** | Muro de sillares de granito liso (Z3) y frentes metálicos mates de encimeras, ollas y estantería (Z2) |
| 3 | `surface_top` | `#EDE8DF` | 0.8105 | **Superficie** | Tablero superior de encimeras (Z1), placa clara de la estación de condimentos, fondo interior de la bandeja (`tray_liner`) y borde de paneles UI |
| 4 | `brand_navy` | `#1D3557` | 0.0350 | **Superficie / Jugable / UI** | Color principal **PulpaSA**: cuerpo de kioscos, zócalos oscuros, pantalón de cocineros y panel/cabecera de UI |
| 5 | `brand_red` | `#C8402F` | 0.1615 | **Jugable / UI** | Acento **PulpaSA**: bandeja/caja jugable, rayas rojas del toldo, toldillo del puesto 1 y barra de paciencia en UI |
| 6 | `player_blue` | `#2F6FB5` | 0.1531 | **Jugable** | Gorra/delantal y aro activo de J1, toldillo del puesto 2 y tanque/agua de pulpo |
| 7 | `fair_green` | `#4FA05A` | 0.2754 | **Jugable / Fondo** | Toldillo del puesto 4 y bloques planos de vegetación y pradera exterior (Z3) |
| 8 | `octopus_raw` | `#E0AFB2` | 0.4972 | **Acento de estado** | Pulpo crudo en tanque, mano y encimera (rosa pálido) |
| 9 | `octopus_cooked` | `#B8283D` | 0.1204 | **Acento de estado** | Pulpo cocido entero y rodajas cortadas dentro de la caja (rojo-morado saturado) |
| 10 | `potato_raw` | `#8E6B47` | 0.1672 | **Acento de estado / Superficie** | Patata cruda con piel, saco de la cachelera, cuenco de barro y bancos de madera exteriores |
| 11 | `state_burnt` | `#2A2320` | 0.0180 | **Acento de estado / UI** | Pulpo y cachelo quemados (carbón), rejillas de suelo, pozos de cifras (`DisplayWell`) y tinta `StickerInk` |
| 12 | `paprika_sweet` | `#D6361F` | 0.1703 | **Jugable / §3.4** | **Pimentón / aliño dulce** (§3.4): cuerpo de dispensador dulce, etiqueta, pegatina de caja e icono de ticket |
| 13 | `paprika_hot` | `#8F1A14` | 0.0663 | **Jugable / §3.4** | **Pimentón / aliño picante** (§3.4): cuerpo de dispensador picante, etiqueta, pegatina de caja e icono de ticket |
| 14 | `salt_paper` | `#F7F4EC` | 0.9053 | **Jugable / §3.4 / UI** | **Sal gorda** (§3.4), camisa de cocineros, rayas claras del toldo, placa de número de puesto y texto principal de UI |
| 15 | `oil_amber` | `#F2C230` | 0.5767 | **Jugable / §3.4 / Estado** | **Aceite** (§3.4), gorro/delantal y aro de J2, toldillo del puesto 3, marcas de pasaplatos y aviso ámbar |
| 16 | `cachelos_cooked` | `#F2D56B` | 0.6753 | **Jugable / §3.4 / Estado** | **Cachelo cocido y pegatina de cachelos** (§3.4) en cuenco, interior de caja y ticket |

---

## 3. Reglas de forma, material, luz y post-proceso

- **Forma y geometría:**
  - Se conserva la silueta redondeada y estilizada de los objetos de gameplay (cocineros, pulpos, cachelos, ollas, cajas y puestos), con biseles amplios (2–3 cm) para que las caras superior (`+Y`) y frontal (`-Z`) se separen por cambio de plano de luz.
  - Presupuesto objetivo (hipótesis de producción al limpiar mallas y nodos ocultos): **≤ 45 000 triángulos** en pantalla (frente a los 80 100 medidos en la auditoría `PUL-087`), eliminando geometría de cables, bombillas, charcos y desorden perimetral.
- **Materiales (`StandardMaterial3D` de color plano):**
  - **Cero texturas PBR de ruido, desgaste, arañazos, mapas de normales u ORM en superficies 3D.** Cada superficie 3D usa `albedo_color` de la tabla de §2 con `specular_mode = SPECULAR_DISABLED` y `metallic = 0.0` (`roughness` entre `0.55–0.65` en comida/bandejas y `0.88–0.92` en suelo/muros).
  - Esto permite erradicar en producción los problemas D5/D6 (239 recursos de material duplicados y PNGs de texturas PBR en v2) y D7 (manchas blancas especulares sobre las encimeras delanteras) detectados en `PUL-087`.
  - **Texturas conservadas deliberadamente:** los iconos de señalética/acciones D26 y condimentos §3.4, y la lona de marca `env_plate` (`capture_minimal.gd:685`) con el logotipo **PulpaSA** en el faldón del toldo. *(Nota del prototipo para resolver en la biblia v3: al sustituir `env_sign` y `env_board` por color plano `#1D3557` en `capture_minimal.gd:556-557`, el cartel superior sobre el toldo y las dos pizarras pequeñas del muro trasero quedan como rectángulos azul marino vacíos; en producción debe retirarse el cartel superior redundante o unificarse con la lona del toldo).*
- **Luz y post-proceso:**
  - **Sol (`DirectionalLight3D`):** cálido suave (`#FFF4E0`), energía `1.18`, sombras activadas y blandas (`shadow_blur = 3.2`).
  - **Ambiente (`WorldEnvironment`):** fondo `#4FA05A` y luz ambiental uniforme `#EDE8DF` con energía `0.72` para levantar las caras en sombra y mantener el aspecto de feria de día.
  - **Luces puntuales (`OmniLight3D`):** **0 luces puntuales activas** (se apagan las 5 bombillas de `Bulbs`).
  - **Post-proceso (`capture_minimal.gd:367-392`):** se desactivan el DoF (`camera_attributes = null`), el `glow` (`glow_enabled = false`), el mapa de corrección tonal y la capa `Vignette` (`vignette.visible = false`), pero **se mantienen activos el SSAO suave de contacto** (`ssao_enabled = true`, `radius = 0.45`, `intensity = 1.1`) y el **ajuste de color del entorno** (`adjustment_enabled = true`, `contrast = 1.05`, `saturation = 1.05`).

---

## 4. Qué atrezo desaparece o se simplifica

| Zona | Qué desaparece por completo | Qué se conserva simplificado en color plano |
|---|---|---|
| **Z0 · Suelo jugable** | Decals de charcos (`env_puddle`), rodadas de neumático (`env_track`), piedrecitas y hojas pintadas (`ground_w_decals`, `ground_e_decals`). | Losa continua de albero `#C4A882` y las 3 rejillas de desagüe en `#2A2320`. |
| **Z1 · Superficies de juego** | Tablas de corte y cuchillos decorativos (`props_board`), jarras/cuncas sobre encimeras (`props_crock`), etiquetas obsoletas de sal/aceite sueltos en la estación de condimentos (`*_oil`, `*_salt`) y paneles S/M/L de la estantería (`SizePanel_*`, `labels`). | Tableros limpios en `#EDE8DF`, marcas de los 6 pasaplatos en `#F2C230` y los 3 puntos activos de la estación (aliño dulce `#D6361F`, aliño picante `#8F1A14` y cuenco de cachelos `#F2D56B`). |
| **Z2 · Frentes y estaciones** | Bombonas y mangueras de gas traseras (`gas_bottle`), bomba exterior del tanque (`pump`), cajas de cartón bajo el rack (`cartons`). | Frentes lisos en `#8C96A0` con zócalo `#1D3557`, toldillos de puestos en color plano (`#C8402F`, `#2F6FB5`, `#F2C230`, `#4FA05A`) y placa de comanda en papel `#F7F4EC` con marco `#1D3557`. |
| **Z3 · Fondo y entorno** | Guirnaldas y cables (`*_garlands`, `tent_bulbs`), valla metálica (`*_fence`), generador, bidones, bombonas y montones de sacos/cajas (`back_*_props`, `props_*_props`). *(En la biblia v3 se eliminará también el cartel superior vacío sobre el toldo).* | Toldo a rayas `#C8402F`/`#F7F4EC` con la placa `env_plate` **PulpaSA**, muro de granito liso `#8C96A0`, bloques de vegetación en `#4FA05A` y mesas laterales de romería en `#8E6B47`. |

---

## 5. Cómo se leen los estados y los colores de §3.4

### 5.1 Lectura de estados de comida y caja
- **Pulpo crudo (`#E0AFB2`, $L = 0.4972$) → cocido (`#B8283D`, $L = 0.1204$) → quemado (`#2A2320`, $L = 0.0180$):**
  - Contraste **crudo / cocido = 3.2104 : 1** (3.21 : 1, $\ge 3:1$) + cambio de silueta (patas extendidas vs rizadas).
  - Contraste **crudo / quemado = 8.0490 : 1** (8.05 : 1, $\ge 3:1$) y **cocido / quemado = 2.5071 : 1** (2.51 : 1) + humo oscuro y silueta encogida.
  - Sobre el tablero claro de encimera (`#EDE8DF`, $L = 0.8105$), el cocido destaca a **5.0482 : 1** (5.05 : 1) y el quemado a **12.6564 : 1** (12.66 : 1); el crudo se separa por saturación rosada, sombra de contacto SSAO y el anillo/barra de mundo.
- **Patata cruda (`#8E6B47`, $L = 0.1672$) → cachelo cocido (`#F2D56B`, $L = 0.6753$) → quemado (`#2A2320`, $L = 0.0180$):**
  - Contraste **crudo / cocido = 3.3390 : 1** (3.34 : 1, $\ge 3:1$), **cocido / quemado = 10.6680 : 1** (10.67 : 1) y **crudo / quemado = 3.1949 : 1** (3.19 : 1).
- **Caja vacía, a medias y llena:**
  - El cuerpo exterior rojo (`#C8402F`, $L = 0.1615$) enmarca el fondo interior claro (`#EDE8DF`, $L = 0.8105$, contraste **4.0681 : 1** / 4.07 : 1). Al cortar pulpo (1..6 cortes, contador `%CutCounter` visible sobre la caja), las capas de rodajas `#B8283D` ($L = 0.1204$) llenan el fondo claro con **5.0482 : 1** (5.05 : 1) de contraste; al añadir cachelos (`#F2D56B`, $L = 0.6753$), estos descansan sobre la cama de pulpo `#B8283D` con **4.2551 : 1** (4.26 : 1) de contraste.

### 5.2 Contraste de los 5 colores de §3.4 (requisito AC2 ≥ 3:1)

En la Dirección A, cada color de §3.4 aparece sobre una superficie de soporte de polaridad opuesta (valores exactos calculados en [`docs/evidence/PUL-180/contrastes_sec34.md`](../../evidence/PUL-180/contrastes_sec34.md)):
- Los **2 condimentos oscuros** (`paprika_sweet` `#D6361F` y `paprika_hot` `#8F1A14`) se apoyan siempre sobre la **superficie clara** `#EDE8DF` (alfombrilla y collar de dispensador en la estación, fondo de la bandeja y pastilla clara en UI/pegatinas).
- Los **3 condimentos claros** (`salt_paper` `#F7F4EC`, `oil_amber` `#F2C230` y `cachelos_cooked` `#F2D56B`) se apoyan siempre sobre **superficie oscura** (`#1D3557` zócalo/panel UI, `#8E6B47` cuenco de barro, `#B8283D` cama de pulpo cocido en la caja o `#2A2320` anillo `StickerInk`).
- **Mínimos reales en Dirección A:** **3.9052 : 1** (3.91 : 1) en soportes primarios de estación/UI (`#EDE8DF` y `#1D3557`); **3.6770 : 1** (3.68 : 1) sobre cama de pulpo cocido (`#B8283D`); **3.3390 : 1** (3.34 : 1) incluyendo el interior del cuenco de barro (`#8E6B47`).

| Color de §3.4 | Hex | $L$ | Superficie donde aparece en Dirección A | Hex superficie ($L$) | Contraste exacto (2 dec.) | Cumple ≥ 3:1 | Cómo se distingue del resto de §3.4 |
|---|---|---:|---|---|---:|:---:|---|
| **Pimentón dulce** | `#D6361F` | 0.1703 | Placa/tablero claro de estación y bandeja | `#EDE8DF` (0.8105) | **3.9052 : 1** (3.91 : 1) | Sí | Rojo vivo ($L=0.1703$) + icono circular (sin llama); 3.2917:1 vs cachelos y 4.3358:1 vs sal |
| **Pimentón picante** | `#8F1A14` | 0.0663 | Placa/tablero claro de estación y pastilla UI | `#EDE8DF` (0.8105) | **7.3993 : 1** (7.40 : 1) | Sí | Granate oscuro ($L=0.0663$) + octógono/guindilla + `hot_mark` (D26.7); 5.3895:1 vs aceite, 6.2368:1 vs cachelos y 8.2150:1 vs sal |
| **Sal gorda** | `#F7F4EC` | 0.9053 | Panel/zócalo marino, anillo `StickerInk` y cama de pulpo | `#1D3557` (0.0350) / `#2A2320` (0.0180) / `#B8283D` (0.1204) | **11.2449 : 1** (11.24 : 1) / **14.0517 : 1** (14.05 : 1) / **5.6047 : 1** (5.60 : 1 en caja) | Sí | Blanco cálido ($L=0.9053$) con anillo oscuro `#2A2320` (14.0517:1) + cuadrado/copos |
| **Aceite** | `#F2C230` | 0.5767 | Zócalo marino, pozo oscuro y cama de pulpo | `#1D3557` (0.0350) / `#2A2320` (0.0180) / `#B8283D` (0.1204) | **7.3773 : 1** (7.38 : 1) / **9.2187 : 1** (9.22 : 1) / **3.6770 : 1** (3.68 : 1 en caja) | Sí | Ámbar dorado ($L=0.5767$) + icono de gota |
| **Cachelos** | `#F2D56B` | 0.6753 | Zócalo marino, cuenco `#8E6B47` y cama de pulpo `#B8283D` | `#1D3557` (0.0350) / `#8E6B47` (0.1672) / `#B8283D` (0.1204) | **8.5371 : 1** (8.54 : 1) / **3.3390 : 1** (3.34 : 1 en cuenco) / **4.2551 : 1** (4.26 : 1 en caja) | Sí | Amarillo patata ($L=0.6753$) + trozos facetados + óvalo |

---

## 6. Impacto en la UI y el HUD

- **Tickets de comanda (`OrderTicketsPanel`) y HUD (`HUD`):**
  - El cuerpo del panel usa `brand_navy` (`#1D3557`, opacidad 100 %, sin transparencias borrosas) con borde limpio de 2 px en `#EDE8DF` y radio de esquina de 4 px.
  - La cabecera (`UiHeader`) y los pozos de reloj/recaudación (`DisplayWell`) usan `#2A2320` para dar un contraste de **14.0517 : 1** (14.05 : 1) al texto `#F7F4EC` y **9.2187 : 1** (9.22 : 1) a las cifras en `#F2C230`.
  - La franja superior de cada ticket (`%Stripe`) usa exactamente el color plano del toldillo de su puesto (`#C8402F`, `#2F6FB5`, `#F2C230`, `#4FA05A`).
- **Móvil a 800×370 (D26/D27) y regresiones del prototipo a corregir en la biblia v3:**
  - Al desaparecer el ruido de suelo (charcos y rodadas) y los brillos especulares de las encimeras, los anillos de cocción (`%CookRing`), el contador de corte (`3/6`) y los prompts de acción D26 se recortan sobre fondos uniformes.
  - **Regresión visual detectada en los números de puesto en móvil (`800×370`):** en el prototipo (`capture_minimal.gd:758-765`), al estilizar `OrderLabel` (`#1..#4`) con relleno claro `#F7F4EC` y contorno grueso oscuro (`outline_size = 14` en `#1D3557`) sobre la placa blanca `#F7F4EC`, los números quedan huecos/delineados y se degradan a `800×370` respecto a la captura de partida; además, el número inferior `StandNumber` (`1..4`) en `#1D3557` pierde contraste sobre el frontal `#1D3557`. En la `art-bible.md` v3 debe resolverse usando glifos macizos `#1D3557` sin contorno (`outline_size = 0`) sobre la placa `#F7F4EC` (y `#F7F4EC` para el `StandNumber` sobre `#1D3557`), además de eliminar el cartel superior vacío (`env_sign`/`env_board`) sobre el toldo.
