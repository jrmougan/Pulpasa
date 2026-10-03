> **No se realizó.** El responsable descartó la comparación lado a lado el 2026-10-04 (D17): el
> prototipo Unity era rudimentario y la paridad no es requisito. Se conserva como referencia.

# Puerta humana de M0: partida lado a lado con Unity

Última comprobación de M0 (`roadmap.md`, fase 8; feature `features/paridad-unity.md`). El smoke
automático (`godot/tests/integration/test_parity_smoke.gd`) y el informe de QA
(`docs/evidence/PUL-025/report.md`) ya cubren AC1–AC8 en lo verificable por máquina. Esta sesión
la hace **el responsable**, jugando las dos versiones seguidas o en dos pantallas, y decide si M0
se cierra.

Duración estimada: 30–40 min (dos partidas de 3 min por versión más las comprobaciones sueltas).

## 1. Preparar las dos versiones

### Unity (referencia)
1. Unity Hub → abrir la raíz del repositorio con **Unity 6000.0.44f1** (`ProjectSettings/ProjectVersion.txt`).
   No guardes cambios: `Assets/` es solo lectura (si Unity reimporta y deja ficheros modificados,
   descártalos con `git checkout -- Assets ProjectSettings` al terminar).
2. Abrir `Assets/Scenes/MainMenu/MainMenu.unity` (única escena de Build Settings) y pulsar Play.
   Desde el menú, «Individual» carga `Assets/Scenes/Levels/Level_01.unity`.
3. Opcional: Game view a 1280×720 (16:9) para comparar encuadre con el build de Godot.

### Godot (candidata)
Usa el **build de release**, no el editor:
```sh
tools/export.sh linux                    # genera build/linux/ (ignorado por git)
build/linux/pulpasa.x86_64 --resolution 1280x720
```
Alternativa sin exportar: `cd godot && godot` (ejecuta la escena principal, el menú).
En Windows: `tools/export.sh windows` en Linux y copiar `build/windows/` (`pulpasa.exe` +
`pulpasa.pck`) a la máquina Windows. **El build de Windows no se ha ejecutado nunca** (ver informe
de PUL-025); si hay una máquina Windows a mano, esta sesión es la ocasión de repetir allí la tabla.

### Controles (los dos)
| Acción | Unity | Godot |
|---|---|---|
| Mover | WASD | WASD |
| Interactuar / coger / soltar | E | E |
| Pausa | Esc | Esc (también Start en mando) |
| Menús | ratón | ratón, flechas + Enter, mando |

## 2. Guion de la partida
Haz lo mismo en las dos versiones y anota diferencias:
1. Arranque → menú. Cronometra a ojo el tiempo hasta el menú.
2. Menú → jugar (Unity: «Individual»; Godot: «Jugar», con el rótulo «Individual · Un personaje»).
3. Una comanda **con condimentos**: nevera → olla → esperar cocción → caja del tamaño del ticket →
   cortes hasta llenarla → condimentos del ticket → entrega en su puesto.
4. Una entrega **mal** (caja de otro tamaño o sin un condimento): debe rechazarse.
5. Una entrega con un condimento **de más**: en M0 se acepta (B15, regla ⊆).
6. Pausa con Esc durante la cocción, esperar ~10 s, reanudar.
7. Seguir jugando hasta el final de la ronda (Godot: 180 s; Unity: su `timeLimit`) y pulsar
   «Reintentar».
8. Salir al menú desde la pausa y desde el fin de partida.

## 3. Qué comparar
Marca **=** (igual), **≈** (diferente pero aceptable), **≠** (regresión: bloquea M0) y anota.
Las diferencias **esperadas** (son bugs del prototipo que no se portan, `inventory.md` §4, o
decisiones de `decisions.md`) no son regresiones; están en la columna «Esperado».

| # | Punto | Esperado en Godot | Unity | Godot | Marca | Nota |
|---|---|---|---|---|---|---|
| F1 | Arranque → menú | ≤ 5 s, sin errores | | | | |
| F2 | Menú: opciones y navegación | Jugar / Salir; foco con teclado y mando; hover nativo (B14) | | | | |
| F3 | Jugar carga el nivel con 1 personaje | Cápsula azul (PUL-013, modelo pendiente) | | | | |
| F4 | Distribución del nivel | Nevera, olla, estantes de cajas y especias, 4 puestos en las mismas posiciones | | | | |
| C1 | Cámara: ángulo y encuadre | Ortográfica, mismo picado (~37,7°) y tamaño | | | | |
| C2 | Cámara: la UI no tapa estaciones | Tickets arriba, HUD abajo a la izquierda | | | | |
| K1 | Movimiento: velocidad y giro | Igual sensación (velocidad 5) | | | | |
| K2 | Objetivo de interacción y resaltado | Un solo objeto resaltado; la sal también se resalta (B3, B7) | | | | |
| K3 | Coger / soltar | Soltar delante; nada se queda «pegado» en la mano (B4, B5) | | | | |
| P1 | Cocción | 5 s; barra de progreso; la olla devuelve el pulpo cocido | | | | |
| P2 | Cortes por caja | Pequeña 5, mediana 10, grande 20; un pulpo llena 2 cajas y desaparece (B9) | | | | |
| P3 | Condimentar | Solo con la caja llena; el bote no se gasta y vuelve a su sitio (B6) | | | | |
| O1 | Tickets: contenido y orden | 4 tickets #1–#4 con caja y condimentos; etiqueta del puesto = id | | | | |
| O2 | Entrega correcta | Suma exactamente **+1** y el puesto recibe comanda nueva (B1: Unity suma 2) | | | | |
| O3 | Entrega estando ya en el puesto | Entrega al pulsar E sin salir y entrar (B12) | | | | |
| O4 | Entrega incorrecta | Rechazo con sonido, la caja sigue en la mano, la comanda no cambia | | | | |
| O5 | Condimento de más | Se acepta (B15) | | | | |
| T1 | Reloj del HUD | Empieza en 180,0 s y baja de forma continua | | | | |
| T2 | Pausa | Reloj, cocción y jugador congelados; menú Reanudar / Salir (B13) | | | | |
| T3 | Fin de ronda | Exactamente cuando el HUD marca 0,0 s y siempre sale el game over (B2) | | | | |
| G1 | Game over: texto y ratio | Texto de rendimiento y cajas/minuto del prototipo | | | | |
| G2 | Reintentar | Comandas nuevas, olla libre, reloj a 180 s, contador a 0 | | | | |
| G3 | Salir al menú | Desde pausa y game over | | | | |
| A1 | Sonido | Cortes, condimento, entrega OK / error | | | | |
| A2 | Rendimiento | Fluido, sin tirones ni avisos en consola | | | | |

## 4. Decisión
- [ ] Ningún **≠** → M0 cerrado: el producer pasa PUL-025 a `done` y abre M1.
- [ ] Hay **≠** → por cada uno, una ficha nueva (rol según el sistema) con la fila de esta tabla
  como reproducción; M0 sigue abierto hasta resolverlas.

Responsable: ____________ · Fecha: ____________ · Build/commit de Godot: ____________
