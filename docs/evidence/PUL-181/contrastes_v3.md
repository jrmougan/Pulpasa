# Verificación de contrastes WCAG 2.1 — Biblia de arte v3 «Feira Clara» (AC2 — PUL-181)

Cálculo reproducible de luminancia relativa ($L$) y razón de contraste WCAG 2.1
$(L_{\max} + 0.05) / (L_{\min} + 0.05)$ generado por `docs/evidence/PUL-181/calc_contrasts_v3.py`
para la paleta cerrada de 16 colores de la v3 (`docs/art/art-bible.md`) y los 5 colores
normativos de §3.4 frente a cada superficie donde aparecen.

## 1. Paleta cerrada v3 «Feira Clara» (16 colores) y luminancia relativa ($L$)

| # | ID de paleta | Hex | $L$ (WCAG 2.1) | Material compartido (`.tres`) | Roughness | Uso principal |
|---:|---|---|---:|---|---:|---|
| 1 | `ground_sand` | `#C4A882` | 0.4135 | `mat_ground_sand.tres` | 0.95 | Suelo interior de cocina, arena exterior y sacos de arpillera |
| 2 | `wall_granite` | `#9A948C` | 0.2994 | `mat_wall_granite.tres` | 0.92 | Muro perimetral de granito, postes exteriores, acero estructural de olla y arcón |
| 3 | `meadow_green` | `#4FA05A` | 0.2754 | `mat_meadow_green.tres` | 0.95 | Prado exterior, fondo de cámara, vegetación lejana, toldo del puesto 4 y barra de paciencia (>60 %) |
| 4 | `surface_top` | `#EDE8DF` | 0.8105 | `mat_surface_top.tres` | 0.85 | Tableros de encimera, tabla de corte, interior de caja (`box_inside`), alfombrilla `ServiceMat`, collar de botes y borde de paneles UI |
| 5 | `brand_navy` | `#1D3557` | 0.0350 | `mat_brand_navy.tres` | 0.90 | Faldones de encimera y puestos, rayas pares del toldo, marco `OrderPlateFrame`, glifo `#1..#4`, zócalo `ServiceFascia`, cuenco de cachelos, pantalones y paneles UI (`UiPanel`) |
| 6 | `brand_red` | `#C8402F` | 0.1615 | `mat_brand_red.tres` | 0.80 | Exterior de caja de reparto (`box_outside`), toldo del puesto 1, acento de marca PulpaSA y barra de paciencia (<30 %) |
| 7 | `ui_cream` | `#F7F4EC` | 0.9053 | `mat_ui_cream.tres` | 0.90 | Sal gruesa (§3.4), placa `OrderPlatePaper`, dígito frontal `StandNumber` (`1..4`), rayas impares del toldo, camisa/gorro de cocinero, papel de ticket y texto principal HUD |
| 8 | `octopus_raw` | `#E0AFB2` | 0.4972 | `mat_octopus_raw.tres` | 0.88 | Pulpo crudo (cuerpo y tentáculos en arcón, mano, encimera y olla) y piel de personajes |
| 9 | `octopus_cooked` | `#B8283D` | 0.1204 | `mat_octopus_cooked.tres` | 0.65 | Pulpo cocido entero y rodajas (`FillHalf`, `FillFull`) dentro de la caja |
| 10 | `potato_raw` | `#8E6B47` | 0.1672 | `mat_potato_raw.tres` | 0.92 | Patata cruda con piel, madera cálida secundaria y borde histórico de cachelos (§3.4) |
| 11 | `cachelos_cooked` | `#F2D56B` | 0.6753 | `mat_cachelos_cooked.tres` | 0.80 | Cachelos cocidos (§3.4), icono/pegatina de cachelos y flecha/etiqueta `potato` en la estación de condimentos |
| 12 | `state_burnt` | `#2A2320` | 0.0180 | `mat_state_burnt.tres` | 0.95 | Ingrediente quemado (pulpo o cachelos), boca interior de olla y cubo de basura, tinta `StickerInk` (`#2A2320`) y pozos oscuros HUD (`UiHeader`, `DisplayWell`) |
| 13 | `paprika_sweet` | `#D6361F` | 0.1703 | `mat_paprika_sweet.tres` | 0.75 | Pimentón dulce (§3.4): cuerpo del dispensador `SweetDressing`, pegatina circular D26, flecha/etiqueta `sweet` y partículas |
| 14 | `paprika_hot` | `#8F1A14` | 0.0663 | `mat_paprika_hot.tres` | 0.75 | Pimentón picante (§3.4): cuerpo del dispensador `HotDressing`, pegatina octogonal D26, flecha/etiqueta `hot` y partículas |
| 15 | `p1_blue` | `#2F6FB5` | 0.1531 | `mat_p1_blue.tres` | 0.75 | Delantal y aro de suelo de J1, toldo del puesto 2 y agua del tanque de pulpo |
| 16 | `p2_amber` | `#F2C230` | 0.5767 | `mat_p2_amber.tres` | 0.75 | Aceite de oliva (§3.4), delantal y aro de suelo de J2, toldo del puesto 3, cifras/reloj del HUD y barra de paciencia (30–60 %) |

## 2. Los 5 colores normativos de §3.4 y redundancia forma + color (D26)

| ID (`OrderItem`) | Condimento | Hex (§3.4) | Luminancia ($L$) | Polaridad | Forma de pegatina D26 y estado en D25 |
|---|---|---|---:|---|---|
| `paprika_sweet` | Pimentón dulce | `#D6361F` | 0.1703 | Oscuro (sobre soporte claro) | Círculo (activo D25) |
| `paprika_hot` | Pimentón picante | `#8F1A14` | 0.0663 | Oscuro (sobre soporte claro) | Octógono (activo D25) |
| `salt` | Sal gruesa | `#F7F4EC` | 0.9053 | Claro (sobre soporte oscuro / pulpo) | Cuadrado (reserva §3.4; integrado en aliño D25) |
| `oil` | Aceite de oliva | `#F2C230` | 0.5767 | Claro (sobre soporte oscuro / pulpo) | Gota (reserva §3.4; integrado en aliño D25) |
| `cachelos` | Cachelos | `#F2D56B` | 0.6753 | Claro (sobre soporte oscuro / pulpo) | Óvalo (activo D25) |

## 3. Contraste de los 5 colores de §3.4 frente a cada superficie donde aparecen (AC2: todos ≥ 3:1)

| Condimento (§3.4) | Hex cond. | $L$ cond. | Superficie donde aparece en v3 | Hex sup. | $L$ sup. | Contraste exacto | Contraste (2 dec.) | ≥ 3:1 |
|---|---|---:|---|---|---:|---:|---:|:---:|
| **Pimentón dulce** (`paprika_sweet`) | `#D6361F` | 0.1703 | Encimera (`ServiceMat`), interior de caja (`box_inside`) y collar del dispensador (`mat_surface_top`) | `#EDE8DF` | 0.8105 | **3.9052 : 1** | 3.91 : 1 | SÍ |
| **Pimentón dulce** (`paprika_sweet`) | `#D6361F` | 0.1703 | Tarjeta/soporte crema claro (`mat_ui_cream`) | `#F7F4EC` | 0.9053 | **4.3358 : 1** | 4.34 : 1 | SÍ |
| **Pimentón dulce** (`paprika_sweet`) | `#D6361F` | 0.1703 | Anillo e icono interior `StickerInk` en pegatina D26 y ticket (`mat_state_burnt`) | `#2A2320` | 0.0180 | **3.2409 : 1** | 3.24 : 1 | SÍ |
| **Pimentón picante** (`paprika_hot`) | `#8F1A14` | 0.0663 | Encimera (`ServiceMat`), interior de caja (`box_inside`) y collar del dispensador (`mat_surface_top`) | `#EDE8DF` | 0.8105 | **7.3993 : 1** | 7.40 : 1 | SÍ |
| **Pimentón picante** (`paprika_hot`) | `#8F1A14` | 0.0663 | Anillo claro / soporte crema (`mat_ui_cream`) | `#F7F4EC` | 0.9053 | **8.2150 : 1** | 8.21 : 1 | SÍ |
| **Sal gruesa** (`salt`) | `#F7F4EC` | 0.9053 | Zócalo de estación (`ServiceFascia`), pastilla de ticket HUD y faldón (`mat_brand_navy`) | `#1D3557` | 0.0350 | **11.2449 : 1** | 11.24 : 1 | SÍ |
| **Sal gruesa** (`salt`) | `#F7F4EC` | 0.9053 | Anillo `StickerInk` / pozo oscuro (`mat_state_burnt`) | `#2A2320` | 0.0180 | **14.0517 : 1** | 14.05 : 1 | SÍ |
| **Sal gruesa** (`salt`) | `#F7F4EC` | 0.9053 | Cama de pulpo cocido en la caja y partículas de aliño sobre pulpo (`mat_octopus_cooked`) | `#B8283D` | 0.1204 | **5.6047 : 1** | 5.60 : 1 | SÍ |
| **Sal gruesa** (`salt`) | `#F7F4EC` | 0.9053 | Borde exterior rojo de la caja (`mat_brand_red`) | `#C8402F` | 0.1615 | **4.5166 : 1** | 4.52 : 1 | SÍ |
| **Aceite de oliva** (`oil`) | `#F2C230` | 0.5767 | Zócalo de estación (`ServiceFascia`), pastilla de ticket HUD y faldón (`mat_brand_navy`) | `#1D3557` | 0.0350 | **7.3773 : 1** | 7.38 : 1 | SÍ |
| **Aceite de oliva** (`oil`) | `#F2C230` | 0.5767 | Anillo `StickerInk` / pozo oscuro (`mat_state_burnt`) | `#2A2320` | 0.0180 | **9.2187 : 1** | 9.22 : 1 | SÍ |
| **Aceite de oliva** (`oil`) | `#F2C230` | 0.5767 | Cama de pulpo cocido en la caja y partículas de aliño sobre pulpo (`mat_octopus_cooked`) | `#B8283D` | 0.1204 | **3.6770 : 1** | 3.68 : 1 | SÍ |
| **Cachelos** (`cachelos`) | `#F2D56B` | 0.6753 | Cuenco de cachelos (`CachelosBowl`), zócalo `ServiceFascia` y pastilla HUD (`mat_brand_navy`) | `#1D3557` | 0.0350 | **8.5371 : 1** | 8.54 : 1 | SÍ |
| **Cachelos** (`cachelos`) | `#F2D56B` | 0.6753 | Anillo e icono interior `StickerInk` en pegatina D26 y ticket (`mat_state_burnt`) | `#2A2320` | 0.0180 | **10.6680 : 1** | 10.67 : 1 | SÍ |
| **Cachelos** (`cachelos`) | `#F2D56B` | 0.6753 | Cama de pulpo cocido en la caja (`mat_octopus_cooked`) | `#B8283D` | 0.1204 | **4.2551 : 1** | 4.26 : 1 | SÍ |
| **Cachelos** (`cachelos`) | `#F2D56B` | 0.6753 | Borde exterior rojo de la caja (`mat_brand_red`) | `#C8402F` | 0.1615 | **3.4290 : 1** | 3.43 : 1 | SÍ |
| **Cachelos** (`cachelos`) | `#F2D56B` | 0.6753 | Piel de patata cruda / madera secundaria (`mat_potato_raw`) | `#8E6B47` | 0.1672 | **3.3390 : 1** | 3.34 : 1 | SÍ |

- **Contraste mínimo en toda la tabla de §3.4:** **3.2409 : 1** (3.24 : 1, `paprika_sweet` (`#D6361F`) sobre Anillo e icono interior `StickerInk` en pegatina D26 y ticket (`mat_state_burnt`) (`#2A2320`)).
- **Resultado AC2:** **17/17 combinaciones cumplen ≥ 3.0000 : 1**.

## 4. Estados de cocción, números de puestos de entrega (AC3) y UI/HUD

| Par evaluado | Color 1 (`hex`, $L_1$) | Color 2 (`hex`, $L_2$) | Contraste exacto | Contraste (2 dec.) |
|---|---|---|---:|---:|
| Pulpo crudo vs. pulpo cocido | `octopus_raw` (`#E0AFB2`, 0.4972) | `octopus_cooked` (`#B8283D`, 0.1204) | **3.2104 : 1** | 3.21 : 1 |
| Pulpo crudo vs. pulpo quemado | `octopus_raw` (`#E0AFB2`, 0.4972) | `state_burnt` (`#2A2320`, 0.0180) | **8.0490 : 1** | 8.05 : 1 |
| Pulpo cocido vs. tablero de encimera | `octopus_cooked` (`#B8283D`, 0.1204) | `surface_top` (`#EDE8DF`, 0.8105) | **5.0482 : 1** | 5.05 : 1 |
| Pulpo cocido vs. boca oscura de la olla | `octopus_cooked` (`#B8283D`, 0.1204) | `state_burnt` (`#2A2320`, 0.0180) | **2.5071 : 1** | 2.51 : 1 |
| Cachelo crudo vs. cachelo cocido | `potato_raw` (`#8E6B47`, 0.1672) | `cachelos_cooked` (`#F2D56B`, 0.6753) | **3.3390 : 1** | 3.34 : 1 |
| Cachelo crudo vs. tablero de encimera | `potato_raw` (`#8E6B47`, 0.1672) | `surface_top` (`#EDE8DF`, 0.8105) | **3.9614 : 1** | 3.96 : 1 |
| Cachelo cocido vs. cama de pulpo cocido | `cachelos_cooked` (`#F2D56B`, 0.6753) | `octopus_cooked` (`#B8283D`, 0.1204) | **4.2551 : 1** | 4.26 : 1 |
| Cachelo cocido vs. cuenco azul marino | `cachelos_cooked` (`#F2D56B`, 0.6753) | `brand_navy` (`#1D3557`, 0.0350) | **8.5371 : 1** | 8.54 : 1 |
| Ingrediente quemado vs. tablero de encimera | `state_burnt` (`#2A2320`, 0.0180) | `surface_top` (`#EDE8DF`, 0.8105) | **12.6564 : 1** | 12.66 : 1 |
| Puesto de entrega (AC3): `%OrderLabel` (`#1..#4`) sólido sobre `OrderPlatePaper` | `brand_navy` (`#1D3557`, 0.0350) | `ui_cream` (`#F7F4EC`, 0.9053) | **11.2449 : 1** | 11.24 : 1 |
| Puesto de entrega (AC3): `StandNumber` (`1..4`) sólido sobre faldón frontal | `ui_cream` (`#F7F4EC`, 0.9053) | `brand_navy` (`#1D3557`, 0.0350) | **11.2449 : 1** | 11.24 : 1 |
| HUD: texto principal crema sobre panel `UiPanel` | `ui_cream` (`#F7F4EC`, 0.9053) | `brand_navy` (`#1D3557`, 0.0350) | **11.2449 : 1** | 11.24 : 1 |
| HUD: texto principal crema sobre cabecera/pozo `UiHeader` | `ui_cream` (`#F7F4EC`, 0.9053) | `state_burnt` (`#2A2320`, 0.0180) | **14.0517 : 1** | 14.05 : 1 |
| HUD: cifras y reloj ámbar sobre panel `UiPanel` | `p2_amber` (`#F2C230`, 0.5767) | `brand_navy` (`#1D3557`, 0.0350) | **7.3773 : 1** | 7.38 : 1 |
| HUD: cifras y reloj ámbar sobre pozo `DisplayWell` | `p2_amber` (`#F2C230`, 0.5767) | `state_burnt` (`#2A2320`, 0.0180) | **9.2187 : 1** | 9.22 : 1 |
| J1 azul vs. suelo de arena | `p1_blue` (`#2F6FB5`, 0.1531) | `ground_sand` (`#C4A882`, 0.4135) | **2.2823 : 1** | 2.28 : 1 |
| J2 ámbar vs. faldón azul marino | `p2_amber` (`#F2C230`, 0.5767) | `brand_navy` (`#1D3557`, 0.0350) | **7.3773 : 1** | 7.38 : 1 |

## 5. Matriz par a par entre los 5 colores de §3.4 y doble codificación D26

| Par de condimentos | Contraste exacto | Contraste (2 dec.) | Mecanismo de distinción en v3 |
|---|---:|---:|---|
| `paprika_sweet` (`#D6361F`) vs. `paprika_hot` (`#8F1A14`) | **1.8947 : 1** | 1.89 : 1 | Doble codificación obligatoria D26: forma distinta (Círculo vs. Octógono), anillo interior `StickerInk` (#2A2320 / #F7F4EC con contraste ≥ 3.24:1) y posición fija en estación/HUD |
| `paprika_sweet` (`#D6361F`) vs. `salt` (`#F7F4EC`) | **4.3358 : 1** | 4.34 : 1 | Contraste directo ≥ 3:1 (4.34:1) + formas distintas (Círculo vs. Cuadrado) |
| `paprika_sweet` (`#D6361F`) vs. `oil` (`#F2C230`) | **2.8445 : 1** | 2.84 : 1 | Doble codificación obligatoria D26: forma distinta (Círculo vs. Gota), anillo interior `StickerInk` (#2A2320 / #F7F4EC con contraste ≥ 3.24:1) y posición fija en estación/HUD |
| `paprika_sweet` (`#D6361F`) vs. `cachelos` (`#F2D56B`) | **3.2917 : 1** | 3.29 : 1 | Contraste directo ≥ 3:1 (3.29:1) + formas distintas (Círculo vs. Óvalo) |
| `paprika_hot` (`#8F1A14`) vs. `salt` (`#F7F4EC`) | **8.2150 : 1** | 8.21 : 1 | Contraste directo ≥ 3:1 (8.21:1) + formas distintas (Octógono vs. Cuadrado) |
| `paprika_hot` (`#8F1A14`) vs. `oil` (`#F2C230`) | **5.3895 : 1** | 5.39 : 1 | Contraste directo ≥ 3:1 (5.39:1) + formas distintas (Octógono vs. Gota) |
| `paprika_hot` (`#8F1A14`) vs. `cachelos` (`#F2D56B`) | **6.2368 : 1** | 6.24 : 1 | Contraste directo ≥ 3:1 (6.24:1) + formas distintas (Octógono vs. Óvalo) |
| `salt` (`#F7F4EC`) vs. `oil` (`#F2C230`) | **1.5243 : 1** | 1.52 : 1 | Doble codificación obligatoria D26: forma distinta (Cuadrado vs. Gota), anillo interior `StickerInk` (#2A2320 / #F7F4EC con contraste ≥ 3.24:1) y posición fija en estación/HUD |
| `salt` (`#F7F4EC`) vs. `cachelos` (`#F2D56B`) | **1.3172 : 1** | 1.32 : 1 | Doble codificación obligatoria D26: forma distinta (Cuadrado vs. Óvalo), anillo interior `StickerInk` (#2A2320 / #F7F4EC con contraste ≥ 3.24:1) y posición fija en estación/HUD |
| `oil` (`#F2C230`) vs. `cachelos` (`#F2D56B`) | **1.1572 : 1** | 1.16 : 1 | Doble codificación obligatoria D26: forma distinta (Gota vs. Óvalo), anillo interior `StickerInk` (#2A2320 / #F7F4EC con contraste ≥ 3.24:1) y posición fija en estación/HUD |
