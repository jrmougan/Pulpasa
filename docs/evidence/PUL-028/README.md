# Evidencia de PUL-028: Añadir el aceite, la exclusividad de pimentones y la validación exacta

## Resumen de cambios
1. **`SeasoningData` (`godot/resources/seasoning_data.gd`)**:
   - Incorporado tipo `OIL` al enum `SeasoningType`.
   - Regla única de identidad `same_as(other: SeasoningData) -> bool` compartida por toda la base de código.
   - Añadida propiedad `exclusivity_group: StringName = &""` para grupos de exclusividad mutua.
   - Añadida propiedad `icon: Texture2D` (vacía hasta PUL-031).
2. **Datos de condimentos (`godot/data/seasonings/`)**:
   - `paprika.tres`: asignado `exclusivity_group = &"paprika"`.
   - `hot_paprika.tres`: asignado `exclusivity_group = &"paprika"`.
   - `oil.tres`: creado con tipo `OIL` (3), `display_name = "Aceite"`, `translation_key = "SEASONING_OIL"`.
3. **Caja (`godot/entities/items/box.gd`)**:
   - `has_seasoning`: comprueba pertenencia mediante `SeasoningData.same_as`.
   - `has_seasoning_in_group(group: StringName)`: comprueba si la caja ya contiene un condimento del grupo de exclusividad.
   - `can_season(seasoning: SeasoningData)`: verifica que la caja esté llena, no tenga ya el condimento (idempotencia) y no tenga otro condimento del mismo grupo de exclusividad (exclusión mutua entre pimentón dulce y picante).
   - `_season`: aplica condimento solo si `can_season` es verdadero.
   - Eliminado método no utilizado `get_seasonings()`.
4. **Validación exacta (`godot/core/order_validator.gd`)**:
   - Adiós a la regla de inclusión parcial ⊆ de M0 (B15).
   - Comprobación de coincidencia exacta del conjunto de condimentos: tamaño igual y todos los condimentos pedidos presentes en la caja sin condimentos extra, usando `SeasoningData.same_as`.
5. **Estantería de especias (`godot/entities/stations/spice_shelf.tscn`)**:
   - Añadido 4º slot `OilSlot` con `res://data/seasonings/oil.tres`.
   - Redistribución equidistante de los 4 slots separados 0,45 m para evitar solapamiento entre sus colisiones (0,43 m): SaltSlot (-0.675), PaprikaSlot (-0.225), HotPaprikaSlot (0.225), OilSlot (0.675).

## Criterios de aceptación

### AC1 — Condimentación AC1–AC4 (exclusividad, idempotencia, caja sin llenar)
- **Exclusividad**: `test_ac1_condimentacion_ac2_paprika_exclusivity_rejects_hot_paprika` y `test_ac1_condimentacion_ac2_hot_paprika_exclusivity_rejects_sweet_paprika` en `test_box.gd` demuestran que tener un pimentón rechaza el otro sin modificar la caja ni emitir señal.
- **Idempotencia**: `test_ac1_condimentacion_ac3_salt_is_idempotent` en `test_box.gd` demuestra que aplicar el mismo condimento dos veces mantiene una única entrada y no reemite `seasoned`.
- **Caja sin llenar**: `test_ac1_condimentacion_ac4_empty_box_rejects_seasoning` y `test_ac1_condimentacion_ac4_half_filled_box_rejects_seasoning` demuestran el rechazo antes de que la caja esté llena.
- **Aceite**: `test_ac1_full_box_can_receive_oil` en `test_box.gd` y `test_pul028_ac1_seasoning_data_oil_and_exclusivity_groups` en `test_data_catalog.gd`.

### AC2 — Validación exacta (más -> inválida, menos -> inválida, exacta -> válida)
- `test_order_validator.gd`:
  - `test_ac2_correct_box_matches`: coincidencia exacta es válida.
  - `test_ac2_missing_seasoning_does_not_match`: condimento de menos es rechazada.
  - `test_ac2_extra_seasoning_is_rejected_in_m1`: condimento de más es rechazada (D17, adiós a B15).
  - `test_ac2_exact_validation_with_oil`: comanda con aceite validada exactamente.
  - `test_ac2_seasoning_order_does_not_matter`: el orden en el array no afecta la validación del conjunto.
- `test_kitchen_flow.gd`:
  - `test_ac2_missing_seasoning_rejected_extra_seasoning_rejected`: flujo de cocina completo verificando rechazo tanto de condimento de menos como de condimento de más.

### AC3 — Estantería con 4 condimentos y slots reversibles
- `test_shelves.gd`:
  - `test_ac3_spice_slots_are_preloaded`: verifica precarga de los 4 slots (`SaltSlot`, `PaprikaSlot`, `HotPaprikaSlot`, `OilSlot`).
  - `test_ac3_spice_can_be_taken_and_returned_to_its_slot`: cada uno de los 4 condimentos puede ser recogido y devuelto a su slot.
  - `test_ac3_spices_sit_on_the_shelf_in_order`: orden estricto de izquierda a derecha sobre el estante.
  - `test_ac3_spice_shelf_contract`: contrato de interacción limpio.
- `test_parity_smoke.gd`:
  - `SPICE_JARS = 4` verificado en flujo completo de 20 entregas.
- Captura visual: `ac3-spice-shelf-4-slots.png` renovada mostrando los 4 botes alineados en el mueble con separación de 0,45 m.

### AC4 — Verificación y `check_owns`
- `tools/verify.sh` en verde: 393 tests pasando, 0 fallos, smoke run OK.
- `tools/check_owns.py` limpio: 0 cambios fuera de `owns`.
