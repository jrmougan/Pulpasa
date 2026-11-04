# AC2 PUL-194: `docs/art/pipeline.md` contrastado con `docs/art/art-bible.md` (v3)

Cada fila es una instruccion v2 que `pipeline.md` daba como vigente antes de PUL-194, la regla de la biblia que la contradice y como queda ahora.

| Instruccion v2 (antes) | Regla v3 (art-bible) | `pipeline.md` ahora |
|---|---|---|
| §5: `gltf/embedded_image_handling` = `1` (extraer texturas) | §3.2.1 y §3.3.1, §9.2: obligatorio `0` | §5: `0`, marcado como obligatorio; `blender_export.py` siembra `0` (AC1) |
| §5: `meshes/ensure_tangents` = `true` por los normal maps v2 | §3.2.1 y §1.1: 0 mapas de normales | §5: `false`; el export tampoco escribe tangentes |
| §4: export con «texturas embebidas y tangentes» | §3.2.1: 0 texturas PBR | §4: materiales solo para conservar nombres de slot, sin tangentes |
| §4: textura > 1024 px (art-bible v2 §4.2) | v2 archivada | §4: comprobacion marcada como heredada; en la v3 solo salta con restos v2 |
| §3: «reutilizalos; no crees materiales a mano» con los 45 `mat_*` v2 | §3.1: solo los 18 `.tres` de `materials/v3/` | §3: la plantilla aun enlaza la v2 (dicho tal cual); los `mat_*` solo dan nombre de slot, el color vive en los `.tres` |
| §5: «Godot extrae `<asset>_<imagen>.png`; versionar PNG y `.png.import`» | §3.3.1: no deben regenerarse PNG | §5: ya no se versionan PNG extraidos |
| §5: «materiales embebidos (`StandardMaterial3D` importado)» | §3.3.2: slots a `.tres` v3 por `_subresources` | §5: bloque `_subresources` con `use_external/path`, tabla en art-bible §3.3 y `slots_reales.md` |
| §7: «materiales `mat_*` enlazados de la biblioteca v2 y UV a 1 unidad = 2 m» | §3.2.1: sin texturas | §7: un slot con nombre claro por material v3, sin UV de textura |
| §8 completo: texturas ORM/normal, atlas hornado, UV 1 u = 2 m, `materials/v2` | §3.2 (prohibicion de texturas PBR; excepciones `env_plate` e iconos) | §8 reescrito: materiales v3, texturas prohibidas y solo las 2 excepciones, import con `0` |
| §6: «materiales embebidos» como lo que comprueba `test_assets_models.gd` | el test comprueba `materials/extract == 0` | §6: «`materials/extract` = 0» |
| Referencias `art-bible §2.x` (escala, nombres) que en la v3 ya no existen | §0.2: se conservan en `art-bible-v1.md` §2 | Referencias apuntadas a `art-bible-v1` |
| `--materials-test` presentado como prueba del pipeline | §3.3.5: `_pipeline/**` excluido de la comprobacion; v2 hasta PUL-188 | §4: marcado «heredado de la v2, no es prueba de la v3, no ejecutar» |

## Lo que sigue mencionando la v2 (todo como existente-no-vigente)
Las menciones restantes de «v2» en `pipeline.md` son: cabecera (estado de la migracion: la biblioteca v2 sigue en el repo hasta PUL-188; no se afirma que ya no exista), §3 (la plantilla aun enlaza la v2), §4 (`--materials-test` heredado y comprobacion de 1024 px heredada) y §8.6 (lista de lo que aun existe). Ninguna se presenta como instruccion vigente.

## No verificable / decision pendiente
- `art/blender/_materials_v2.blend`, `_template.blend` y `materials-v2.md` no figuran en la ficha PUL-188: el documento lo dice, no decide quien los retira.
- La parte de macOS no se documenta: no hay maquina para probarla.
