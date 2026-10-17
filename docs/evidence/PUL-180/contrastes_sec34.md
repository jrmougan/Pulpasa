# Verificación de contrastes WCAG 2.1 para §3.4 (AC2 — PUL-180)

Cálculo reproducible de luminancia relativa ($L$) y razón de contraste WCAG 2.1
$(L_{\max} + 0.05) / (L_{\min} + 0.05)$ generado por `docs/evidence/PUL-180/build_evidence.py`
para los 5 colores normativos de condimentos (§3.4 de `docs/art/art-bible.md` y D26) frente a
las superficies donde aparecen en las 3 direcciones minimalistas propuestas.

## 1. Colores normativos de §3.4 y redundancia forma + color (D26)

| ID (`OrderItem`) | Condimento | Hex (§3.4) | Luminancia ($L$) | Polaridad | Forma de pegatina (D26) |
|---|---|---|---:|---|---|
| `paprika_sweet` | Pimentón dulce | `#D6361F` | 0.1703 | Oscuro (sobre soporte claro) | Círculo |
| `paprika_hot` | Pimentón picante | `#8F1A14` | 0.0663 | Oscuro (sobre soporte claro) | Octógono |
| `salt` | Sal gruesa | `#F7F4EC` | 0.9053 | Claro (sobre soporte oscuro / pulpo) | Cuadrado |
| `oil` | Aceite de oliva | `#F2C230` | 0.5767 | Claro (sobre soporte oscuro / pulpo) | Gota |
| `cachelos` | Cachelos | `#F2D56B` | 0.6753 | Claro (sobre soporte oscuro / pulpo) | Óvalo |

## 2. Contraste frente a la superficie donde aparecen (requisito AC2: ≥ 3.0000 : 1)

### Dirección A · «Feira Clara» (`direccion-a-color-plano.md`)

| Condimento (§3.4) | Hex | $L$ cond. | Superficie donde aparece | Hex sup. | $L$ sup. | Contraste exacto | Contraste (2 dec.) | ≥ 3:1 |
|---|---|---:|---|---|---:|---:|---:|:---:|
| **Pimentón dulce** (`paprika_sweet`) | `#D6361F` | 0.1703 | Encimera / interior de caja (`surface_top`) | `#EDE8DF` | 0.8105 | **3.9052 : 1** | 3.91 : 1 | SÍ |
| **Pimentón picante** (`paprika_hot`) | `#8F1A14` | 0.0663 | Encimera / interior de caja (`surface_top`) | `#EDE8DF` | 0.8105 | **7.3993 : 1** | 7.40 : 1 | SÍ |
| **Sal gruesa** (`salt`) | `#F7F4EC` | 0.9053 | Cuenco / pastilla HUD / zócalo (`brand_navy`) | `#1D3557` | 0.0350 | **11.2449 : 1** | 11.24 : 1 | SÍ |
| **Sal gruesa** (`salt`) | `#F7F4EC` | 0.9053 | Anillo `StickerInk` / pozo oscuro (`state_burnt`) | `#2A2320` | 0.0180 | **14.0517 : 1** | 14.05 : 1 | SÍ |
| **Sal gruesa** (`salt`) | `#F7F4EC` | 0.9053 | Pulpo cocido en caja (`octopus_cooked`) | `#B8283D` | 0.1204 | **5.6047 : 1** | 5.60 : 1 | SÍ |
| **Aceite de oliva** (`oil`) | `#F2C230` | 0.5767 | Cuenco / pastilla HUD / zócalo (`brand_navy`) | `#1D3557` | 0.0350 | **7.3773 : 1** | 7.38 : 1 | SÍ |
| **Aceite de oliva** (`oil`) | `#F2C230` | 0.5767 | Anillo `StickerInk` / pozo oscuro (`state_burnt`) | `#2A2320` | 0.0180 | **9.2187 : 1** | 9.22 : 1 | SÍ |
| **Aceite de oliva** (`oil`) | `#F2C230` | 0.5767 | Pulpo cocido en caja (`octopus_cooked`) | `#B8283D` | 0.1204 | **3.6770 : 1** | 3.68 : 1 | SÍ |
| **Cachelos** (`cachelos`) | `#F2D56B` | 0.6753 | Cuenco / pastilla HUD / zócalo (`brand_navy`) | `#1D3557` | 0.0350 | **8.5371 : 1** | 8.54 : 1 | SÍ |
| **Cachelos** (`cachelos`) | `#F2D56B` | 0.6753 | Cuenco de barro (`potato_raw`) | `#8E6B47` | 0.1672 | **3.3390 : 1** | 3.34 : 1 | SÍ |
| **Cachelos** (`cachelos`) | `#F2D56B` | 0.6753 | Pulpo cocido en caja (`octopus_cooked`) | `#B8283D` | 0.1204 | **4.2551 : 1** | 4.26 : 1 | SÍ |

- **Mínimo en soportes primarios de estación/UI:** **3.9052 : 1** (3.91 : 1, `paprika_sweet` sobre `#EDE8DF`).
- **Mínimo sobre cama de pulpo cocido (`#B8283D`):** **3.6770 : 1** (3.68 : 1, `oil` sobre `#B8283D`).
- **Mínimo absoluto de todas las combinaciones de la tabla:** **3.3390 : 1** (3.34 : 1, `cachelos` sobre `#8E6B47`).

### Dirección B · «Bloques de Romería» (`direccion-b-geometrica.md`)

| Condimento (§3.4) | Hex | $L$ cond. | Superficie donde aparece | Hex sup. | $L$ sup. | Contraste exacto | Contraste (2 dec.) | ≥ 3:1 |
|---|---|---:|---|---|---:|---:|---:|:---:|
| **Pimentón dulce** (`paprika_sweet`) | `#D6361F` | 0.1703 | Losa de piedra / interior de caja (`surf_stone_block`) | `#EFECE6` | 0.8405 | **4.0418 : 1** | 4.04 : 1 | SÍ |
| **Pimentón picante** (`paprika_hot`) | `#8F1A14` | 0.0663 | Losa de piedra / interior de caja (`surf_stone_block`) | `#EFECE6` | 0.8405 | **7.6580 : 1** | 7.66 : 1 | SÍ |
| **Sal gruesa** (`salt`) | `#F7F4EC` | 0.9053 | Cuenco / pastilla HUD (`play_box_navy`) | `#1D3557` | 0.0350 | **11.2449 : 1** | 11.24 : 1 | SÍ |
| **Sal gruesa** (`salt`) | `#F7F4EC` | 0.9053 | Vacío / soporte oscuro (`bg_void_navy`) | `#18222C` | 0.0152 | **14.6519 : 1** | 14.65 : 1 | SÍ |
| **Sal gruesa** (`salt`) | `#F7F4EC` | 0.9053 | Pulpo cocido en caja (`state_octopus_cooked`) | `#B8283D` | 0.1204 | **5.6047 : 1** | 5.60 : 1 | SÍ |
| **Aceite de oliva** (`oil`) | `#F2C230` | 0.5767 | Cuenco / pastilla HUD (`play_box_navy`) | `#1D3557` | 0.0350 | **7.3773 : 1** | 7.38 : 1 | SÍ |
| **Aceite de oliva** (`oil`) | `#F2C230` | 0.5767 | Vacío / soporte oscuro (`bg_void_navy`) | `#18222C` | 0.0152 | **9.6125 : 1** | 9.61 : 1 | SÍ |
| **Aceite de oliva** (`oil`) | `#F2C230` | 0.5767 | Pulpo cocido en caja (`state_octopus_cooked`) | `#B8283D` | 0.1204 | **3.6770 : 1** | 3.68 : 1 | SÍ |
| **Cachelos** (`cachelos`) | `#F2D56B` | 0.6753 | Cuenco / pastilla HUD (`play_box_navy`) | `#1D3557` | 0.0350 | **8.5371 : 1** | 8.54 : 1 | SÍ |
| **Cachelos** (`cachelos`) | `#F2D56B` | 0.6753 | Vacío / soporte oscuro (`bg_void_navy`) | `#18222C` | 0.0152 | **11.1237 : 1** | 11.12 : 1 | SÍ |
| **Cachelos** (`cachelos`) | `#F2D56B` | 0.6753 | Pulpo cocido en caja (`state_octopus_cooked`) | `#B8283D` | 0.1204 | **4.2551 : 1** | 4.26 : 1 | SÍ |

- **Mínimo en soportes primarios de estación/UI:** **4.0418 : 1** (4.04 : 1, `paprika_sweet` sobre `#EFECE6`).
- **Mínimo sobre cama de pulpo cocido (`#B8283D`):** **3.6770 : 1** (3.68 : 1, `oil` sobre `#B8283D`).
- **Mínimo absoluto de todas las combinaciones de la tabla:** **3.6770 : 1** (3.68 : 1, `oil` sobre `#B8283D`).

### Dirección C · «Maqueta de Papel» (`direccion-c-maqueta-papel.md`)

| Condimento (§3.4) | Hex | $L$ cond. | Superficie donde aparece | Hex sup. | $L$ sup. | Contraste exacto | Contraste (2 dec.) | ≥ 3:1 |
|---|---|---:|---|---|---:|---:|---:|:---:|
| **Pimentón dulce** (`paprika_sweet`) | `#D6361F` | 0.1703 | Encimera de papel blanco / interior caja (`paper_counter_white`) | `#F7F4EC` | 0.9053 | **4.3358 : 1** | 4.34 : 1 | SÍ |
| **Pimentón picante** (`paprika_hot`) | `#8F1A14` | 0.0663 | Encimera de papel blanco / interior caja (`paper_counter_white`) | `#F7F4EC` | 0.9053 | **8.2150 : 1** | 8.21 : 1 | SÍ |
| **Sal gruesa** (`salt`) | `#F7F4EC` | 0.9053 | Bandeja de grafito (`ink_graphite_dark`) | `#2A2320` | 0.0180 | **14.0517 : 1** | 14.05 : 1 | SÍ |
| **Sal gruesa** (`salt`) | `#F7F4EC` | 0.9053 | Pastilla HUD / cabecera (`brand_navy`) | `#1D3557` | 0.0350 | **11.2449 : 1** | 11.24 : 1 | SÍ |
| **Sal gruesa** (`salt`) | `#F7F4EC` | 0.9053 | Pulpo cocido en caja (`state_octopus_cooked`) | `#B8283D` | 0.1204 | **5.6047 : 1** | 5.60 : 1 | SÍ |
| **Aceite de oliva** (`oil`) | `#F2C230` | 0.5767 | Bandeja de grafito (`ink_graphite_dark`) | `#2A2320` | 0.0180 | **9.2187 : 1** | 9.22 : 1 | SÍ |
| **Aceite de oliva** (`oil`) | `#F2C230` | 0.5767 | Pastilla HUD / cabecera (`brand_navy`) | `#1D3557` | 0.0350 | **7.3773 : 1** | 7.38 : 1 | SÍ |
| **Aceite de oliva** (`oil`) | `#F2C230` | 0.5767 | Pulpo cocido en caja (`state_octopus_cooked`) | `#B8283D` | 0.1204 | **3.6770 : 1** | 3.68 : 1 | SÍ |
| **Cachelos** (`cachelos`) | `#F2D56B` | 0.6753 | Bandeja de grafito (`ink_graphite_dark`) | `#2A2320` | 0.0180 | **10.6680 : 1** | 10.67 : 1 | SÍ |
| **Cachelos** (`cachelos`) | `#F2D56B` | 0.6753 | Pastilla HUD / cabecera (`brand_navy`) | `#1D3557` | 0.0350 | **8.5371 : 1** | 8.54 : 1 | SÍ |
| **Cachelos** (`cachelos`) | `#F2D56B` | 0.6753 | Pulpo cocido en caja (`state_octopus_cooked`) | `#B8283D` | 0.1204 | **4.2551 : 1** | 4.26 : 1 | SÍ |

- **Mínimo en soportes primarios de estación/UI:** **4.3358 : 1** (4.34 : 1, `paprika_sweet` sobre `#F7F4EC`).
- **Mínimo sobre cama de pulpo cocido (`#B8283D`):** **3.6770 : 1** (3.68 : 1, `oil` sobre `#B8283D`).
- **Mínimo absoluto de todas las combinaciones de la tabla:** **3.6770 : 1** (3.68 : 1, `oil` sobre `#B8283D`).

## 3. Distinción entre los 5 condimentos de §3.4 (par a par: color + soporte + forma D26)

| Par de condimentos | Contraste exacto | Contraste (2 dec.) | Mecanismo de distinción en las 3 direcciones |
|---|---:|---:|---|
| `paprika_sweet` (`#D6361F`) vs. `paprika_hot` (`#8F1A14`) | **1.8947 : 1** | 1.89 : 1 | Doble codificación obligatoria D26: forma distinta (Círculo vs. Octógono), contorno interior oscuro/claro de ≥ 3.9052:1 y posición fija en puesto/HUD |
| `paprika_sweet` (`#D6361F`) vs. `salt` (`#F7F4EC`) | **4.3358 : 1** | 4.34 : 1 | Contraste cromático directo ≥ 3:1 (4.3358:1 / 4.34:1) + formas distintas (Círculo vs. Cuadrado) |
| `paprika_sweet` (`#D6361F`) vs. `oil` (`#F2C230`) | **2.8445 : 1** | 2.84 : 1 | Doble codificación obligatoria D26: forma distinta (Círculo vs. Gota), contorno interior oscuro/claro de ≥ 3.9052:1 y posición fija en puesto/HUD |
| `paprika_sweet` (`#D6361F`) vs. `cachelos` (`#F2D56B`) | **3.2917 : 1** | 3.29 : 1 | Contraste cromático directo ≥ 3:1 (3.2917:1 / 3.29:1) + formas distintas (Círculo vs. Óvalo) |
| `paprika_hot` (`#8F1A14`) vs. `salt` (`#F7F4EC`) | **8.2150 : 1** | 8.21 : 1 | Contraste cromático directo ≥ 3:1 (8.2150:1 / 8.21:1) + formas distintas (Octógono vs. Cuadrado) |
| `paprika_hot` (`#8F1A14`) vs. `oil` (`#F2C230`) | **5.3895 : 1** | 5.39 : 1 | Contraste cromático directo ≥ 3:1 (5.3895:1 / 5.39:1) + formas distintas (Octógono vs. Gota) |
| `paprika_hot` (`#8F1A14`) vs. `cachelos` (`#F2D56B`) | **6.2368 : 1** | 6.24 : 1 | Contraste cromático directo ≥ 3:1 (6.2368:1 / 6.24:1) + formas distintas (Octógono vs. Óvalo) |
| `salt` (`#F7F4EC`) vs. `oil` (`#F2C230`) | **1.5243 : 1** | 1.52 : 1 | Doble codificación obligatoria D26: forma distinta (Cuadrado vs. Gota), contorno interior oscuro/claro de ≥ 3.9052:1 y posición fija en puesto/HUD |
| `salt` (`#F7F4EC`) vs. `cachelos` (`#F2D56B`) | **1.3172 : 1** | 1.32 : 1 | Doble codificación obligatoria D26: forma distinta (Cuadrado vs. Óvalo), contorno interior oscuro/claro de ≥ 3.9052:1 y posición fija en puesto/HUD |
| `oil` (`#F2C230`) vs. `cachelos` (`#F2D56B`) | **1.1572 : 1** | 1.16 : 1 | Doble codificación obligatoria D26: forma distinta (Gota vs. Óvalo), contorno interior oscuro/claro de ≥ 3.9052:1 y posición fija en puesto/HUD |

## 4. Pares adicionales de estado y UI citados en los documentos de dirección

| Par evaluado | Hex 1 ($L_1$) | Hex 2 ($L_2$) | Contraste exacto | Contraste (2 dec.) |
|---|---|---|---:|---:|
| Dir. A: Pulpo crudo vs. cocido | `#E0AFB2` (0.4972) | `#B8283D` (0.1204) | **3.2104 : 1** | 3.21 : 1 |
| Dir. A: Pulpo crudo vs. quemado | `#E0AFB2` (0.4972) | `#2A2320` (0.0180) | **8.0490 : 1** | 8.05 : 1 |
| Dir. A: Pulpo cocido vs. quemado | `#B8283D` (0.1204) | `#2A2320` (0.0180) | **2.5071 : 1** | 2.51 : 1 |
| Dir. A: Pulpo cocido vs. encimera `#EDE8DF` | `#B8283D` (0.1204) | `#EDE8DF` (0.8105) | **5.0482 : 1** | 5.05 : 1 |
| Dir. A: Pulpo quemado vs. encimera `#EDE8DF` | `#2A2320` (0.0180) | `#EDE8DF` (0.8105) | **12.6564 : 1** | 12.66 : 1 |
| Dir. A: Patata cruda vs. cachelo cocido | `#8E6B47` (0.1672) | `#F2D56B` (0.6753) | **3.3390 : 1** | 3.34 : 1 |
| Dir. A: Cachelo cocido vs. quemado | `#F2D56B` (0.6753) | `#2A2320` (0.0180) | **10.6680 : 1** | 10.67 : 1 |
| Dir. A: Patata cruda vs. quemado | `#8E6B47` (0.1672) | `#2A2320` (0.0180) | **3.1949 : 1** | 3.19 : 1 |
| Dir. A: Caja roja `#C8402F` vs. interior `#EDE8DF` | `#C8402F` (0.1615) | `#EDE8DF` (0.8105) | **4.0681 : 1** | 4.07 : 1 |
| Dir. B: Pulpo cocido `#B8283D` vs. losa `#EFECE6` | `#B8283D` (0.1204) | `#EFECE6` (0.8405) | **5.2247 : 1** | 5.22 : 1 |
| Dir. C: Pulpo crudo `#E0AFB2` (prototipo) vs. encimera `#F7F4EC` | `#E0AFB2` (0.4972) | `#F7F4EC` (0.9053) | **1.7458 : 1** | 1.75 : 1 |
| Dir. C: Pulpo crudo `#9E7B9B` (variante conceptual) vs. encimera `#F7F4EC` | `#9E7B9B` (0.2380) | `#F7F4EC` (0.9053) | **3.3169 : 1** | 3.32 : 1 |
| Dir. C: Pulpo cocido `#B8283D` vs. encimera `#F7F4EC` | `#B8283D` (0.1204) | `#F7F4EC` (0.9053) | **5.6047 : 1** | 5.60 : 1 |
| Dir. C: Pulpo quemado `#2A2320` vs. encimera `#F7F4EC` | `#2A2320` (0.0180) | `#F7F4EC` (0.9053) | **14.0517 : 1** | 14.05 : 1 |
| Dir. C: Pastilla `#1D3557` vs. suelo/fondo `#E4DFD5` (prototipo) | `#1D3557` (0.0350) | `#E4DFD5` (0.7407) | **9.3076 : 1** | 9.31 : 1 |
| Dir. C: Pastilla `#1D3557` vs. cartulina `#E6DFD3` (variante conceptual) | `#1D3557` (0.0350) | `#E6DFD3` (0.7430) | **9.3345 : 1** | 9.33 : 1 |
