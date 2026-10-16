# Verificación de contrastes WCAG 2.1 para §3.4 (AC2 — PUL-180)

Cálculo reproducible de luminancia relativa ($L$) y razón de contraste WCAG 2.1
$(L_{\max} + 0.05) / (L_{\min} + 0.05)$ para los 5 colores normativos de condimentos
(§3.4 de `docs/art/art-bible.md` y D26) frente a las superficies donde aparecen en las
3 direcciones minimalistas propuestas.

## 1. Colores normativos de §3.4 y redundancia forma + color (D26)

| ID (`OrderItem`) | Condimento | Hex (§3.4) | Luminancia ($L$) | Polaridad | Forma de pegatina (D26) |
|---|---|---|---:|---|---|
| `paprika_sweet` | Pimentón dulce | `#D6361F` | 0.1703 | Oscuro (sobre soporte claro) | Círculo |
| `paprika_hot` | Pimentón picante | `#8F1A14` | 0.0663 | Oscuro (sobre soporte claro) | Octógono |
| `salt` | Sal gruesa | `#F7F4EC` | 0.9053 | Claro (sobre soporte oscuro / pulpo) | Cuadrado |
| `oil` | Aceite de oliva | `#F2C230` | 0.5767 | Claro (sobre soporte oscuro / pulpo) | Gota |
| `cachelos` | Cachelos | `#F2D56B` | 0.6753 | Claro (sobre soporte oscuro / pulpo) | Óvalo |

## 2. Contraste frente a la superficie donde aparecen (requisito AC2: ≥ 3.00 : 1)

### Dirección A · «Feira Clara» (`direccion-a-color-plano.md`)

| Condimento (§3.4) | Hex | $L$ cond. | Superficie donde aparece | Hex sup. | $L$ sup. | Contraste | ≥ 3:1 |
|---|---|---:|---|---|---:|---:|:---:|
| **Pimentón dulce** (`paprika_sweet`) | `#D6361F` | 0.1703 | Encimera / interior de caja (`surf_counter_cream`) | `#EDE8DF` | 0.8105 | **3.91 : 1** | SÍ |
| **Pimentón picante** (`paprika_hot`) | `#8F1A14` | 0.0663 | Encimera / interior de caja (`surf_counter_cream`) | `#EDE8DF` | 0.8105 | **7.40 : 1** | SÍ |
| **Sal gruesa** (`salt`) | `#F7F4EC` | 0.9053 | Cuenco / pastilla HUD / caja (`play_box_navy`) | `#1D3557` | 0.0350 | **11.24 : 1** | SÍ |
| **Sal gruesa** (`salt`) | `#F7F4EC` | 0.9053 | Pulpo cocido en caja (`state_octopus_cooked`) | `#B8283D` | 0.1204 | **5.60 : 1** | SÍ |
| **Aceite de oliva** (`oil`) | `#F2C230` | 0.5767 | Cuenco / pastilla HUD / caja (`play_box_navy`) | `#1D3557` | 0.0350 | **7.38 : 1** | SÍ |
| **Aceite de oliva** (`oil`) | `#F2C230` | 0.5767 | Pulpo cocido en caja (`state_octopus_cooked`) | `#B8283D` | 0.1204 | **3.68 : 1** | SÍ |
| **Cachelos** (`cachelos`) | `#F2D56B` | 0.6753 | Cuenco / pastilla HUD / caja (`play_box_navy`) | `#1D3557` | 0.0350 | **8.54 : 1** | SÍ |
| **Cachelos** (`cachelos`) | `#F2D56B` | 0.6753 | Pulpo cocido en caja (`state_octopus_cooked`) | `#B8283D` | 0.1204 | **4.26 : 1** | SÍ |

### Dirección B · «Bloques de Romería» (`direccion-b-geometrica.md`)

| Condimento (§3.4) | Hex | $L$ cond. | Superficie donde aparece | Hex sup. | $L$ sup. | Contraste | ≥ 3:1 |
|---|---|---:|---|---|---:|---:|:---:|
| **Pimentón dulce** (`paprika_sweet`) | `#D6361F` | 0.1703 | Losa de piedra / interior de caja (`surf_stone_block`) | `#EFECE6` | 0.8405 | **4.04 : 1** | SÍ |
| **Pimentón picante** (`paprika_hot`) | `#8F1A14` | 0.0663 | Losa de piedra / interior de caja (`surf_stone_block`) | `#EFECE6` | 0.8405 | **7.66 : 1** | SÍ |
| **Sal gruesa** (`salt`) | `#F7F4EC` | 0.9053 | Cuenco / pastilla HUD (`play_box_navy`) | `#1D3557` | 0.0350 | **11.24 : 1** | SÍ |
| **Sal gruesa** (`salt`) | `#F7F4EC` | 0.9053 | Vacío / soporte oscuro (`bg_void_navy`) | `#18222C` | 0.0152 | **14.65 : 1** | SÍ |
| **Sal gruesa** (`salt`) | `#F7F4EC` | 0.9053 | Pulpo cocido en caja (`state_octopus_cooked`) | `#B8283D` | 0.1204 | **5.60 : 1** | SÍ |
| **Aceite de oliva** (`oil`) | `#F2C230` | 0.5767 | Cuenco / pastilla HUD (`play_box_navy`) | `#1D3557` | 0.0350 | **7.38 : 1** | SÍ |
| **Aceite de oliva** (`oil`) | `#F2C230` | 0.5767 | Vacío / soporte oscuro (`bg_void_navy`) | `#18222C` | 0.0152 | **9.61 : 1** | SÍ |
| **Aceite de oliva** (`oil`) | `#F2C230` | 0.5767 | Pulpo cocido en caja (`state_octopus_cooked`) | `#B8283D` | 0.1204 | **3.68 : 1** | SÍ |
| **Cachelos** (`cachelos`) | `#F2D56B` | 0.6753 | Cuenco / pastilla HUD (`play_box_navy`) | `#1D3557` | 0.0350 | **8.54 : 1** | SÍ |
| **Cachelos** (`cachelos`) | `#F2D56B` | 0.6753 | Vacío / soporte oscuro (`bg_void_navy`) | `#18222C` | 0.0152 | **11.12 : 1** | SÍ |
| **Cachelos** (`cachelos`) | `#F2D56B` | 0.6753 | Pulpo cocido en caja (`state_octopus_cooked`) | `#B8283D` | 0.1204 | **4.26 : 1** | SÍ |

### Dirección C · «Maqueta de Papel» (`direccion-c-maqueta-papel.md`)

| Condimento (§3.4) | Hex | $L$ cond. | Superficie donde aparece | Hex sup. | $L$ sup. | Contraste | ≥ 3:1 |
|---|---|---:|---|---|---:|---:|:---:|
| **Pimentón dulce** (`paprika_sweet`) | `#D6361F` | 0.1703 | Encimera de papel blanco / interior caja (`paper_counter_white`) | `#F7F4EC` | 0.9053 | **4.34 : 1** | SÍ |
| **Pimentón picante** (`paprika_hot`) | `#8F1A14` | 0.0663 | Encimera de papel blanco / interior caja (`paper_counter_white`) | `#F7F4EC` | 0.9053 | **8.21 : 1** | SÍ |
| **Sal gruesa** (`salt`) | `#F7F4EC` | 0.9053 | Bandeja de grafito (`ink_graphite_dark`) | `#2A2320` | 0.0180 | **14.05 : 1** | SÍ |
| **Sal gruesa** (`salt`) | `#F7F4EC` | 0.9053 | Pastilla HUD / caja (`play_box_navy`) | `#1D3557` | 0.0350 | **11.24 : 1** | SÍ |
| **Sal gruesa** (`salt`) | `#F7F4EC` | 0.9053 | Pulpo cocido en caja (`state_octopus_cooked`) | `#B8283D` | 0.1204 | **5.60 : 1** | SÍ |
| **Aceite de oliva** (`oil`) | `#F2C230` | 0.5767 | Bandeja de grafito (`ink_graphite_dark`) | `#2A2320` | 0.0180 | **9.22 : 1** | SÍ |
| **Aceite de oliva** (`oil`) | `#F2C230` | 0.5767 | Pastilla HUD / caja (`play_box_navy`) | `#1D3557` | 0.0350 | **7.38 : 1** | SÍ |
| **Aceite de oliva** (`oil`) | `#F2C230` | 0.5767 | Pulpo cocido en caja (`state_octopus_cooked`) | `#B8283D` | 0.1204 | **3.68 : 1** | SÍ |
| **Cachelos** (`cachelos`) | `#F2D56B` | 0.6753 | Bandeja de grafito (`ink_graphite_dark`) | `#2A2320` | 0.0180 | **10.67 : 1** | SÍ |
| **Cachelos** (`cachelos`) | `#F2D56B` | 0.6753 | Pastilla HUD / caja (`play_box_navy`) | `#1D3557` | 0.0350 | **8.54 : 1** | SÍ |
| **Cachelos** (`cachelos`) | `#F2D56B` | 0.6753 | Pulpo cocido en caja (`state_octopus_cooked`) | `#B8283D` | 0.1204 | **4.26 : 1** | SÍ |

## 3. Distinción entre los 5 condimentos de §3.4 (par a par: color + soporte + forma D26)

| Par de condimentos | Contraste directo | Mecanismo de distinción en las 3 direcciones |
|---|---:|---|
| `paprika_sweet` (`#D6361F`) vs. `paprika_hot` (`#8F1A14`) | 1.89 : 1 | Doble codificación obligatoria D26: forma distinta (Círculo vs. Octógono), contorno interior oscuro/claro de ≥ 3.9:1 y posición fija en puesto/HUD |
| `paprika_sweet` (`#D6361F`) vs. `salt` (`#F7F4EC`) | 4.34 : 1 | Contraste cromático directo ≥ 3:1 (4.34:1) + formas distintas (Círculo vs. Cuadrado) |
| `paprika_sweet` (`#D6361F`) vs. `oil` (`#F2C230`) | 2.84 : 1 | Doble codificación obligatoria D26: forma distinta (Círculo vs. Gota), contorno interior oscuro/claro de ≥ 3.9:1 y posición fija en puesto/HUD |
| `paprika_sweet` (`#D6361F`) vs. `cachelos` (`#F2D56B`) | 3.29 : 1 | Contraste cromático directo ≥ 3:1 (3.29:1) + formas distintas (Círculo vs. Óvalo) |
| `paprika_hot` (`#8F1A14`) vs. `salt` (`#F7F4EC`) | 8.21 : 1 | Contraste cromático directo ≥ 3:1 (8.21:1) + formas distintas (Octógono vs. Cuadrado) |
| `paprika_hot` (`#8F1A14`) vs. `oil` (`#F2C230`) | 5.39 : 1 | Contraste cromático directo ≥ 3:1 (5.39:1) + formas distintas (Octógono vs. Gota) |
| `paprika_hot` (`#8F1A14`) vs. `cachelos` (`#F2D56B`) | 6.24 : 1 | Contraste cromático directo ≥ 3:1 (6.24:1) + formas distintas (Octógono vs. Óvalo) |
| `salt` (`#F7F4EC`) vs. `oil` (`#F2C230`) | 1.52 : 1 | Doble codificación obligatoria D26: forma distinta (Cuadrado vs. Gota), contorno interior oscuro/claro de ≥ 3.9:1 y posición fija en puesto/HUD |
| `salt` (`#F7F4EC`) vs. `cachelos` (`#F2D56B`) | 1.32 : 1 | Doble codificación obligatoria D26: forma distinta (Cuadrado vs. Óvalo), contorno interior oscuro/claro de ≥ 3.9:1 y posición fija en puesto/HUD |
| `oil` (`#F2C230`) vs. `cachelos` (`#F2D56B`) | 1.16 : 1 | Doble codificación obligatoria D26: forma distinta (Gota vs. Óvalo), contorno interior oscuro/claro de ≥ 3.9:1 y posición fija en puesto/HUD |
