# PUL-200: frases de pipeline.md contrastadas con sus fuentes

| Frase de `docs/art/pipeline.md` | Fuente | Resultado |
|---|---|---|
| Cabecera: PUL-188 solo borra `materials/v2/`, `textures/v2/` y `models/**/*.png` (+ `.png.import`) | `owns` de `docs/backlog/PUL-188-integracion-level01-y-limpieza-v2.md` | Coincide |
| Cabecera: `_materials_v2.blend`, `_template.blend`, `materials-v2.md` y `_pipeline/**` no figuran en el `owns` de PUL-188; su destino es PUL-201 | mismo `owns`; ficha PUL-200 (Constraints) | Coincide |
| §3: la tira `ref_materials_v2` de `reference` mantiene vivos los 45 `mat_*` | versión `cac6ac1` de `docs/art/pipeline.md`, §3 (nota original) | Restaurada |
| §4: `--materials-test` no se ejecuta; PUL-188 no borra el `.glb`, solo sus PNG, y `--materials-test` fallaría | art-bible §3.3.5 (`_pipeline/**` banco excluido); `owns` de PUL-188 (`godot/assets/models/**/*.png`) | Coincide |
| §8.4: los PNG existentes los borra PUL-188 | `owns` de PUL-188 | Coincide |
| §8.6: el `.glb` de `materials_v2_test` se queda, sin PNG, excluido por art-bible §3.3.5 | art-bible §3.3.5; `owns` de PUL-188 | Coincide |

Ya no se afirma que PUL-188 borre `_pipeline/materials_v2_test` ni que el `.glb` exista «hasta PUL-188».
