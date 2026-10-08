# PUL-094 · Línea de condimentos

Arte de producción realizado por Codex el 2026-10-07, dirección A adaptada a D23.

## Entrega y lectura

- [Cámara nativa 1920×1080](native_1080.png) y [frente contrario](rear_1080.png): mostrador sin bandeja ni tabla, faja marino y alfombrilla con chevrones en servicio; pase despejado.
- [Escala de grises](grayscale_1080.png): lata dulce ancha/baja, picante estrecho/facetado con lengüeta y llama, salero con tapa perforada oscura, botella con cuello y pico lateral. Botones circulares con iconos canónicos.
- La lámina muestra también los cinco estados exclusivos del cuenco: `Portions0` tiene el fondo vacío de barro; `Portions1..4`, una a cuatro raciones. Seleccionar exactamente una malla; no son capas acumulativas.
- Cámara de Godot: inclinación 38°, tamaño vertical 12,74 m, 84,772 px/m, sin agrandar assets. El icono de botón ocupa ≈15,85 px de ancho de tinta, por encima de 12 px. Captura de estudio en Compatibility; no sustituye QA de iluminación, oclusiones o rendimiento del nivel integrado.

## Contrato para PUL-097

Tres GLB conservan sus nombres y raíces. `seasoning_dispenser` conserva `paprika_sweet`, `paprika_hot`, `salt`, `oil`; escoger una variante. `Anchor_Front` conserva la orientación −Z de Godot.

**Cambios intencionados de anclajes y dimensiones**, en ejes locales de Godot:

| Elemento | Posición (X, Y, Z), m |
|---|---|
| `Anchor_Dispenser_SweetPaprika` | (−2, 1,10, 0,35) |
| `Anchor_Dispenser_HotPaprika` | (−1, 1,10, 0,35) |
| `Anchor_Dispenser_Salt` | (0, 1,10, 0,35) |
| `Anchor_Dispenser_Oil` | (1, 1,10, 0,35) |
| `Anchor_Bowl` | (2, 1,10, 0,15) |

Separación entre centros: 1,00 m. Mostrador: ancho exterior 5,20 m, profundidad de acero 1,12 m, altura 1,10 m. La alfombrilla llega hasta Z≈1,195 y tiene relieve máximo 2 cm. Se retiraron `tray`, `cutting_board` y `Anchor_Tray`; `Anchor_PassSide` y `Anchor_OperatorSide` permanecen. PUL-097 debe retirar `Tray`, actualizar posiciones de instancias y ampliar su colisión de 4 m al ancho final; esta entrega no cambia colisiones ni `.tscn`.

El cuenco conserva el volumen cerrado `OutlineHull` de su escena para el resaltado; no aplicar contorno sobre la boca abierta ni sobre las raciones.

## Datos y validación

Colores armonizados en los `.tres`: dulce `#D6361F`, picante `#8F1A14`, cachelos `#F2D56B`. Sal `#F7F4EC` y aceite `#F2C230` se conservan. El responsable autorizó ampliar `owns` para actualizar `test_data_integrity.gd`: comprueba los cinco hex con tolerancia de precisión y mantiene opacidad/diferencia entre pimentones.

[Presupuesto](budget.json): mostrador 1.100, conjunto de cuatro variantes de dispensador 1.032 y cuenco con todos los estados 780; total conservador **2.912 / 6.000 tris**. Cuenco ≤800 incluso exportando todos los estados.

[Auditoría](validation.json), [suites específicas](final_asset_tests.log) y [gate completo](verify.log). La auditoría usa los patrones de `tools/check_owns.py` sobre el árbol de trabajo conjunto de las tres fichas; las ramas individuales `jrmougan/pul-094..096` no existen en este checkout. No se editó ninguna escena.

Reproducción desde la raíz: `blender -b --python docs/evidence/PUL-094/build_art.py --python-exit-code 1`, importar en Godot y ejecutar `validate_art.py`. Captura: `godot --audio-driver Dummy --path godot --resolution 1920x1080 --rendering-method gl_compatibility -s <ruta absoluta a capture_art.gd> -- <raíz absoluta> PUL-094`. Biblioteca v2 enlazada; atlas original empaquetado; no se usó el puerto 9876 ni procesos ajenos. Los avisos del exportador sobre tangentes en UV constantes no afectan los materiales planos del atlas.

Fila propuesta para el coordinador: modelos/atlas `seasoning_station`, `seasoning_dispenser`, `cachelos_bowl` · **propia, equipo Pulpasa**. Iconos existentes conservan sus atribuciones; Montserrat conserva SIL OFL 1.1. No se modifica `CREDITS.md`.
