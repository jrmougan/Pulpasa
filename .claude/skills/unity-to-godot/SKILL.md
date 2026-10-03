---
name: unity-to-godot
description: Tabla de correspondencias Unity 6 → Godot 4.7 aplicada a Pulpasa (QFramework, ScriptableObjects, prefabs, Input System, Animator, uGUI/TMP, URP). Úsala al portar cualquier pieza de Assets/.
---
# Unity → Godot en Pulpasa

| Unity | Godot 4.7 |
|---|---|
| MonoBehaviour `Awake/Start/Update/FixedUpdate` | `_ready/_process/_physics_process` en un Node |
| `GetComponent<T>()` | `@export` tipado o `%UniqueName` |
| Prefab | `PackedScene` `.tscn` + `instantiate()` |
| ScriptableObject + `Resources.LoadAll` | `Resource` con `class_name` + `.tres`; lista `@export var x: Array[T]` |
| QFramework Architecture/System | Autoload de servicio (`OrderService`) sin acceso a escena |
| QFramework Event / Command | Señal en `EventBus` / método del servicio |
| Tags y Layers | Grupos y capas de colisión con nombre |
| `CharacterController.Move` | `CharacterBody3D.velocity` + `move_and_slide()` |
| `Physics.OverlapSphere` | `Area3D.get_overlapping_bodies()` |
| `OnTriggerEnter` | `Area3D.body_entered` |
| Input System (PlayerInput, SendMessages) | InputMap + `Input.get_vector()`; acciones por jugador `p1_*`, `p2_*` |
| Animator (`Speed`, `IsHolding`) | `AnimationTree` StateMachine + BlendSpace1D |
| uGUI Canvas + TMP | `CanvasLayer` + `Control` + `Label` |
| Canvas world space + FaceToCamera | `Label3D` / `Sprite3D` con billboard |
| `Image.fillAmount` | `TextureProgressBar` |
| `Time.timeScale = 0` | `get_tree().paused = true` |
| `SceneManager.LoadScene` | `get_tree().change_scene_to_file()` |
| `AudioSource` | `AudioStreamPlayer` / `AudioStreamPlayer3D` |
| Material URP Lit | `StandardMaterial3D` |
| Resaltado (malla ×1.05 transparente) | Shader inverted hull como `material_overlay` |

## Ejes y escala
Unity: +Z adelante, Y arriba, zurdo. Godot: −Z adelante, Y arriba, diestro. Si un modelo mira
hacia atrás, gira la raíz 180° en Y en la escena contenedora, no en el import.

## No portar
Bugs y código muerto listados en `docs/migration/inventory.md` (doble `CompleteOrder`,
temporizadores duplicados, `OrderTicketSpawner`, `DrinkSO`, `IRandomUtility`).
