# PUL-090 · Evidencia: diagnóstico del flujo de estaciones

Documento: `docs/design/rediseno-estaciones.md`.

## Ficheros
| Fichero | Qué es |
|---|---|
| `measure_flow.gd` + `run_measure.gd` | Bot que juega `level_01.tscn` con teclado simulado y detector real (`tests/integration/level_walker.gd`): Solo, Individual con cambio y Coop 2P; S/M/L sal+aceite y S aceite+cachelos; 2 pedidos por escenario |
| `metrics.json` | Resultado por pedido: segundos de juego, pulsaciones, cambios, metros y segundos quieto por personaje, recolocaciones, rechazos |
| `measure_flow.log` | Salida de la última ejecución (una línea JSON por escenario) |
| `target_map.gd` + `run_target_map.gd` | Barrido del detector delante de la barra (57 × 6 puntos, 3 estados de mano) |
| `target_map.txt` | Mapa resultante (qué pieza es objetivo desde cada punto) |

## Reproducir (desde la raíz del repo; sin sonido)
```
godot --headless --audio-driver Dummy --path godot --import      # solo si no hay godot/.godot
godot --headless --audio-driver Dummy --fixed-fps 60 --path godot -s "$PWD/docs/evidence/PUL-090/run_measure.gd"
godot --headless --audio-driver Dummy --fixed-fps 60 --path godot -s "$PWD/docs/evidence/PUL-090/run_target_map.gd"
```
Cada uno tarda ≈ 10 s. Los scripts no tocan `godot/`: cargan el nivel y lo juegan. El arranque
(`run_*.gd`) carga el medidor en `_initialize` para que existan los autoloads. El medidor inyecta el
reloj de juego en el antirrebote de dispensadores y cuenco (`clock`), porque con `--fixed-fps` el
juego corre más deprisa que el reloj de pared que usan por defecto.

## Límites
El bot anda en línea recta a 5 m/s, conoce los puntos de uso calibrados en PUL-063 y pulsa a 15 Hz:
los tiempos son cota inferior. Ver §1.1 del documento.
