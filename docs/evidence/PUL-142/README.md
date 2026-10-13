# PUL-142 — El POP del puesto ya no tapa su número

| Ruta | Qué es |
|---|---|
| `capture_stand_pop.gd` | Copia de `docs/evidence/PUL-139/capture_stand_pop.gd` (mismo método): `order_new` y `deliver_ok` en `OrderStand1` de `level_01`, fotogramas al 0, 15, 35, 55 y 100 % de `visual_time` parando el `Tween` |
| `deliver_ok_strip.png` | Tira de los 5 fotogramas del POP del puesto: el «1» se ve en todos y crece con su placa (antes: `docs/evidence/PUL-139/deliver_ok_strip.png`, desaparecía en 15–55 %) |
| `order_new_strip.png` | Tira de `order_new` (POP de `%OrderLabel`): sin cambios, el número no se mueve |
| `pop/full_deliver_ok_0.png` | Captura completa 1920×1080 (Xvfb); los fotogramas sueltos no se versionan |

Uso, desde la raíz: `xvfb-run -a godot --path godot --audio-driver Dummy --resolution 1920x1080 -s
"$PWD/docs/evidence/PUL-142/capture_stand_pop.gd" -- "$PWD/docs/evidence/PUL-142/pop"`; tiras con
`montage pop/<cue>_{0..4}.png -tile 5x1 -geometry +4+0 <cue>_strip.png`.
