# PUL-094 — línea de condimentos al paso

Arte original realizado con Blender CLI; tres GLB conservan sus nombres. No se modifican escenas ni lógica. La integración jugable corresponde a PUL-097.

## Resultado y capturas

- `01_game_camera_1080.png`: montaje temporal de los GLB nuevos en `level_01`, con su cámara real, resolución 1920×1080, sin HUD. El harness sustituye la estación para mostrar los anclajes nuevos: **no es evidencia de integración jugable**. Los módulos adyacentes del layout antiguo siguen presentes y se solapan en los extremos; PUL-097 debe adaptar ese layout según D23.
- `02_native_1080.png` / `02_native_1080_gray.png`: mismo ángulo (38°), tamaño ortográfico 12,74 y 84,77 px/m que el juego, recentrada sobre la estación. Luz direccional y Environment del nivel, sin el resto del mobiliario. Gris mediante saturación 0 en Environment, sin reescalar la imagen. Dulce ancho y bajo, picante estrecho octogonal, salero claro con tapa oscura y botella con cuello/pico lateral.
- `03_detail_1080.png`: detalle ampliado (size 6), para inspección, no para justificar lectura nativa.
- `04_kitchen_side.png`: vista opuesta; rail de acero sin la faja marina de servicio. Los cinco chevrones de papel están sobre la alfombrilla del servicio y apuntan hacia el usuario.
- `05_portions_0_to_4.png`: estados exclusivos 0, 1, 2, 3, 4 de izquierda a derecha. Cada ración es una pieza visible; el vacío muestra barro.
- `06_outline_hull.png`: mismo montaje con Highlightable sobre el proxy cerrado `OutlineHull`, manteniendo visible el interior del cuenco.

Los botones tienen diámetro 0,30 m (25,43 px nativos), plano de icono de 0,22 m (18,65 px) y máscara de hasta 108/128 de ese plano (15,74 px en su eje mayor). La cara se inclina 52° para quedar paralela al plano de imagen con la cámara del juego. La pareja dulce/picante conserva el icono canónico; el picante añade llama, además de su silueta facetada. La llama es detalle secundario, no el único diferenciador.

## Contrato de integración para PUL-097

`seasoning_station.glb` mide 5,10 m de ancho, 1,10 m de encimera y 1,10 m de alto. Alfombrilla plana visual de 5,04×0,56 m al frente; no genera colisión. Se retiran `tray`, `cutting_board` y `Anchor_Tray`: no existe zona gráfica de depósito.

Se conservan los nombres de los anclajes de ingredientes, con **nuevas posiciones locales Godot** para satisfacer el orden y la separación mínima solicitados:

| Anclaje | Antes (x,y,z) | Ahora (x,y,z) |
|---|---|---|
| Anchor_Dispenser_SweetPaprika | −1,25 / 1,10 / 0,45 | −2 / 1,10 / 0 |
| Anchor_Dispenser_HotPaprika | −0,35 / 1,10 / 0,45 | −1 / 1,10 / 0 |
| Anchor_Dispenser_Salt | 0,95 / 1,10 / 0,45 | 0 / 1,10 / 0 |
| Anchor_Dispenser_Oil | 1,85 / 1,10 / 0,45 | 1 / 1,10 / 0 |
| Anchor_Bowl | −1,80 / 1,10 / 0 | 2 / 1,10 / 0 |

Distancia entre centros consecutivos: **1,00 m**. `Anchor_Front`, `Anchor_OperatorSide` (z=+1,2) y `Anchor_PassSide` (z=−1,2) se mantienen. Frente técnico −Z; servicio +Z como en la escena actual.

- El GLB de dispensadores sigue teniendo `seasoning_dispenser/{paprika_sweet,paprika_hot,salt,oil}`; activar exactamente la variante correspondiente, como hacen las escenas actuales. Los botones forman parte de cada malla y no requieren Sprite3D externo para identificarse.
- El cuenco contiene `cachelos_bowl/Portions0` … `Portions4`: activar **exactamente una** según stock. El formato glTF no codifica visibilidad inicial; todas se importan y la escena debe seleccionar su estado inicial. Sustituir las antiguas tres instancias `Model/Portions/Portion1..3` al integrar.
- `cachelos_bowl/OutlineHull/BowlHull` es el proxy cerrado transparente para `Highlightable.root`; no aplicar overlay al cuenco abierto. Desactivar sombras del proxy en la escena si se modifica su material transparente. El harness usa este proxy y no rellena de amarillo la cavidad.
- **No se han editado colisiones.** El collider de mostrador actual sigue midiendo 4×1,1×1,1 y deberá adaptarse a 5,1×1,1×1,1; los cuatro cuerpos físicos y el cuenco deben colocarse en los nuevos anchors. Los botones adelantados alcanzan aproximadamente z=+0,50 local; revisar los volúmenes de interacción en PUL-097. La lata dulce mide 0,36 m de diámetro, sobrepasando el antiguo radio de 0,15 m. No se introduce ninguna colisión embebida en GLB.
- El stock, alcance, input desde ambos lados y acceso junto al hueco x≈3,2 requieren la integración y prueba de gameplay PUL-097; esta entrega es de arte.

## Colores, materiales y presupuesto

Los datos dulce `#D6361F`, picante `#8F1A14` y cachelos `#F2D56B` ahora coinciden con §2.5. Sal y aceite ya coincidían y se mantienen. Los cuerpos y franjas usan esas mismas muestras en un atlas opaco propio 512², con botones papel `#F4EFE6` y tinta marina `#1D3557`; sin material separado por símbolo. El atlas se empaqueta en el Blend y se embebe en los tres GLB. Acero, barro y patata reutilizan materiales enlazados de `_materials_v2.blend`; el proxy usa alfa 0 como el patrón OutlineHull existente.

| Geometría exportada | Tris |
|---|---:|
| Mostrador, señales, patas y alfombrilla | 1544 |
| Cuatro variantes de dispensador juntas | 1712 |
| Cuenco, proxy y todos los estados | 1098 |
| Total conservador (incluye todos los estados) | **4354 / 6000** |
| Cuenco en estado máximo, incluido proxy | **738 / 800** |
| Dulce / picante / sal / aceite individual | 498 / 306 / 370 / 538 (cada uno <800) |

`triangles.json` cuenta geometría evaluada en Blender; `validation.json` verifica los índices triangulados del GLB, nombres, anclajes, estados y los cinco colores de datos. Se mantienen las texturas heredadas sin referencias externas nuevas; las imágenes nuevas son tres extracciones del mismo atlas, VRAM y mipmaps según pipeline. No se afirma deduplicación entre GLB ni rendimiento del nivel final.

## Reproducción y verificaciones

Desde la raíz:

```sh
python docs/evidence/PUL-094/make_atlas.py
blender -b art/blender/seasoning_station.blend --python docs/evidence/PUL-094/build_assets.py
python docs/evidence/PUL-094/validate.py
GODOT_PATH="$PWD/docs/evidence/PUL-094/godot_dummy.sh" tools/verify.sh
xvfb-run -a godot --audio-driver Dummy --path godot --resolution 1920x1080 -s "$PWD/docs/evidence/PUL-094/capture.gd" -- "$PWD/docs/evidence/PUL-094"
tools/check_owns.py jrmougan/pul-094 jrmougan/agentica-migracion-godot-alpha
```

Logs: `blender.log`, `import.log`, `capture.log`, `validation.log`, `verify.log`, `owns.log`. OCIO de Blender usa el fallback conocido de la instalación (2.5/2.4); las capturas de aceptación son de Godot. El warning X11/xim de xvfb es conocido; no afecta al render.

## Fila de licencia propuesta (la incorpora el coordinador)

| Asset (origen) | Destino en godot/ | Licencia | Atribución requerida |
|---|---|---|---|
| Mostrador al paso, dispensadores, cuenco y atlas originales, `art/blender/seasoning_station.blend` (PUL-094); reutiliza iconos y biblioteca ya inventariados | `assets/models/stations/seasoning_station/{seasoning_station,seasoning_dispenser,cachelos_bowl}.glb` y `*_sign_atlas.png` | Propio (equipo Pulpasa) | No adicional; conservar atribuciones preexistentes de los iconos |
