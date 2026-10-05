# art/

Fuentes de arte propio (D20). Los exportados viven en `godot/assets/models/`.

- `blender/_template.blend`: plantilla de partida (unidades en metros, colección `export`,
  referencias de escala de 1,8 m y 1 m, materiales `mat_*` de la paleta). Cópiala como
  `blender/<asset>.blend`; un `.blend` por ficha.
- Reglas de arte: [`docs/art/art-bible.md`](../docs/art/art-bible.md).
- Pipeline (MCP de Blender, export headless, import en Godot, test):
  [`docs/art/pipeline.md`](../docs/art/pipeline.md).

Exportar desde la raíz del repo:

```sh
blender -b art/blender/<asset>.blend --python tools/blender_export.py -- --category <cat>
```
