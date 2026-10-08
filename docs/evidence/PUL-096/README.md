# PUL-096 · Kioscos con placa y zona de entrega

Arte de producción realizado por Codex el 2026-10-07, dirección A.

## Capturas y materiales

[Cuatro puestos a 1080p, apagados](native_1080.png) y [encendidos](delivery_on_1080.png). IDs de ejemplo #17/#28/#39/–, distintos de los números fijos 1–4 del disco inferior. El ID variable sigue siendo `Label3D`, no está horneado. Placa de papel y borde marino separan las cifras de las rayas.

Cámara de estudio en Godot: inclinación 38°, 12,74 m, 84,772 px/m, giro PI del kiosco como en el nivel, sin agrandar objetos. Los IDs usan Montserrat Bold, tamaño 96 y `pixel_size=0.00439`; las cifras son legibles a escala nativa. Esta captura no verifica rendimiento ni iluminación del nivel integrado.

`delivery_zone` es una alfombrilla/recuadro de suelo de perfil máximo 2 cm, con marco y chevron. Bajo ella, `DeliveryFrame` recibe **`delivery_zone_off.tres`** o **`delivery_zone_on.tres`**, ambos exportados junto al GLB y con el mismo atlas para conservar el dibujo. El material encendido tiene `emission_energy_multiplier=0.35`; PUL-100 duplica el material por puesto y asigna `emission` desde `StandPalette`. No cambiar el material de la base de goma al alternar el estado.

## Contrato para PUL-099 y PUL-100

`order_stand.glb` conserva raíz, cuerpo, TPV, bandeja, `awning_1..4`, `Anchor_Number`, `Anchor_Sign` y orientación de `Anchor_Front`. No se cambia `order_stand.tscn`, el disco fijo ni su colisión/hull.

**Nuevos anclajes / colocación**, ejes locales de Godot, detalle también en [integration.json](integration.json):

| Pieza | Centro y dimensiones |
|---|---|
| Placa | centro ≈(0, 1,88, −0,20), 1,02 × 0,50 m, inclinada para cámara |
| `Anchor_OrderLabel` | (0, 1,905, −0,23); reposicionar aquí el ID variable |
| `delivery_zone` | centro (0, 0,008, **3,40**), base 1,45 × 1,05 m, grosor 0,016 m |
| `Anchor_DeliveryZone` | (0, 0,020, 3,40) |
| Material a alternar | `order_stand/delivery_zone/DeliveryFrame` |

**Z=3,40 es intencionado:** el ensayo a Z≈2,50 ocultaba el recuadro completo bajo la proyección del toldillo. PUL-100 debe usar el centro final para el `Area3D` de entrega y validar acceso/oclusiones en su layout; no reutilizar el centro antiguo Z=1,17 ni el aproximado 2,5 de la ficha. El recuadro se ve por encima del kiosco en la lámina debido a la proyección del suelo; no es una placa elevada.

Paleta normativa del toldillo para `StandPalette`: **1 `#D2473F`, 2 `#3F7CC8`, 3 `#E8C23A`, 4 `#4FA05A`**. Se conservan los cuatro materiales enlazados `mat_canvas_stand_1..4`.

## Validación y reproducción

[Presupuesto](budget.json): **3.032 / 6.000 tris**, incluyendo los cuatro toldillos superpuestos; gameplay muestra uno. Atlas nuevo 512², biblioteca v2 y marca existentes conservadas. [Tests finales](../PUL-094/final_asset_tests.log), [gate completo](../PUL-094/verify.log) y [auditoría de alcance](../PUL-094/validation.json).

Reproducción: `blender -b --python docs/evidence/PUL-096/build_art.py --python-exit-code 1`; importar en Godot y ejecutar `capture_art.gd` de PUL-094 con `<raíz absoluta> PUL-096`, `--audio-driver Dummy --resolution 1920x1080`. El script muestra ambos estados y aplica los cuatro colores. No se usó puerto 9876 ni procesos ajenos.

Fila propuesta para el coordinador: kiosco/placa/zona/atlas · **propia, equipo Pulpasa**, Montserrat SIL OFL 1.1 e iconos/marca existentes con sus créditos vigentes. No se modifica `CREDITS.md`.
