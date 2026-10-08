# PUL-096 · Kioscos con placa y zona de entrega

Arte de producción realizado por Codex el 2026-10-07, dirección A.

## Capturas y materiales

[Zona apagada](zone_off_1080.png) y [encendida](zone_on_1080.png): los cuatro puestos a 1920x1080, ortográfica, ampliada 2x respecto a la cámara de juego (6,37 m de alto de vista en lugar de 12,74 m; inclinación aprox. 37 grados), de modo que a escala nativa las cifras miden la mitad (aun así de unos 25 px de alto, legibles), con el kiosco girado PI como en el nivel y un solo toldillo visible por puesto. IDs de ejemplo #17/#28/#39/–. El ID variable es un `Label3D` (Liberation Sans 96, `pixel_size=0.00439`) sobre la placa de papel con borde marino, separado de las rayas. Las capturas no incluyen el `Label3D` del número fijo (1-4) del disco inferior, que sigue en `order_stand.tscn`. Esto no verifica iluminación ni oclusión del nivel integrado.

`delivery_zone` es una alfombrilla/recuadro de suelo de perfil máximo 2 cm: base de goma, marco de papel y chevron. `DeliveryFrame` es la malla de marco+chevron y recibe **`delivery_zone_off.tres`** (papel blanco/marino) o **`delivery_zone_on.tres`**. El encendido combina `albedo_color` (tinte multiplicativo, imprescindible: el marco es blanco y una emisión sola no lo tiñe) y `emission` en el color del puesto con `emission_energy_multiplier=0.35`. Los `.tres` traen el rojo del puesto 1 por defecto; PUL-100 duplica el material por puesto y asigna **ambos** `albedo_color` y `emission` desde `StandPalette`. No cambiar el material de la base de goma al alternar.

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

[Presupuesto](budget.json): **3.032 / 6.000 tris**, incluyendo los cuatro toldillos superpuestos; gameplay muestra uno. Atlas nuevo 512², biblioteca v2 y marca existentes conservadas.

Reproducción del arte: `blender -b --python docs/evidence/PUL-096/build_art.py --python-exit-code 1` (requiere `art_helpers.py` de PUL-094, que vive en su rama). Capturas: `capture_zone.gd` (cabecera con el comando; `godot --audio-driver Dummy`, sin MCP). No se usó el puerto 9876 ni procesos ajenos.

Fila propuesta para el coordinador: kiosco/placa/zona/atlas · **propia, equipo Pulpasa**, Montserrat SIL OFL 1.1 e iconos/marca existentes con sus créditos vigentes. No se modifica `CREDITS.md`.
