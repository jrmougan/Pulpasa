---
id: PUL-196
title: Corregir el índice de contratos y preparar el gate de enmiendas pendientes
status: review
milestone: M4
role: godot-architect
deps: []
orca_task: null
unity_sources: []
owns: [docs/arch/README.md, docs/arch/gate-enmiendas.md]
touches_scenes: []
---

## Target
`docs/arch/README.md` y documento nuevo `docs/arch/gate-enmiendas.md`.

## Change
- `README.md`: corregir solo hechos ya decididos. D14 ya no está pendiente (decisions.md: 3D, ADR-005 aceptado); ADR-002 está aceptado según su cabecera. Las enmiendas pendientes siguen como pendientes.
- `gate-enmiendas.md`: una tabla con **cada** enmienda propuesta o pendiente de ADR-002 a ADR-006, y el estado «propuesto» de `signals.md` y `scene-tree.md`. Columnas: documento y sección, ficha, qué decide, si el código ya la implementa (con ruta:línea o test comprobado), si hay divergencia entre código y texto, y recomendación (aceptar, aceptar con cambios o rechazar). Añadir la propuesta de marcar T3 de `decisions.md` como «Superada por D17».

## Constraints
**Ningún agente acepta nada**: no cambies estados de ADR, `signals.md`, `scene-tree.md` ni `decisions.md`. Una enmienda sin implementar o divergente no se recomienda aceptar sin más. Cada fila debe estar comprobada contra el código.

## Acceptance
- [x] AC1 Given todas las cabeceras y secciones de docs/arch, When `grep -inE "propuest|pendiente"`, Then cada aparición vigente está en la tabla o se explica por qué no → salida en docs/evidence/PUL-196/
- [x] AC2 Given una fila que dice «implementada», When se abre la ruta citada, Then el código coincide → cada fila cita ruta:línea
- [x] AC3 Given `git diff` de la rama, When se revisa, Then solo cambian `README.md`, `gate-enmiendas.md`, la ficha y la evidencia → salida en docs/evidence/PUL-196/

## Plan
1. Corregir en `docs/arch/README.md` solo hechos ya decididos: D14 cerrada (3D, ADR-005 aceptado) y ADR-002 aceptado. Las enmiendas pendientes siguen pendientes.
2. Recorrer `grep -inE "propuest|pendiente"` en `docs/arch` y clasificar cada aparición: fila de la tabla o motivo por el que queda fuera.
3. Comprobar cada enmienda contra el código (lectura y `grep`; nada se da por bueno por el texto) y redactar `docs/arch/gate-enmiendas.md`, con la propuesta sobre T3.
4. No cambiar ningún estado de ADR, `signals.md`, `scene-tree.md` ni `decisions.md`.
5. Evidencia en `docs/evidence/PUL-196/`: guion que valida la cobertura del grep (AC1), imprime cada `ruta:línea` citada (AC2) y lista el diff (AC3). Después, `tools/verify.sh --quick`.

## Evidence
Evidencia en `docs/evidence/PUL-196/`. Los guiones se ejecutan desde la raíz del repo.

- **AC1**: `python docs/evidence/PUL-196/comprobar_gate.py` → `ac1-ac2.txt`, `RESULTADO: OK`. Son 60 apariciones de `propuest|pendiente` en `docs/arch` (sin contar el propio gate) y las 60 están clasificadas en una fila o con su motivo. El guion es el mismo patrón sin distinguir mayúsculas que pide el AC, sin `grep`.
- **AC2**: el mismo guion imprime cada `ruta:línea` citada con el contenido real de esa línea (`ac1-ac2.txt`, 58 filas). Revisé esa salida a mano contra lo que afirma cada fila y corregí las citas flojas. Las comprobaciones negativas (bajas que no existen, nombres sin apariciones, receptores de `EventBus`) están en `comprobaciones.txt`, generado por `comprobaciones.py`.
- **AC3**: `ac3-diff.txt`: `git diff --name-status` contra la base y `tools/check_owns.py`. Solo cambian `README.md`, `gate-enmiendas.md`, la ficha y la evidencia.
- **Verificación**: `tools/verify.sh --quick` en verde (`verify-quick.txt`). El primer intento falló porque el import inicial de este worktree superó el límite de 300 s de `verify.sh`; lancé el import a mano y el siguiente `verify.sh` pasó. También ejecuté `tools/verify.sh` completo, aunque la ficha no lo pedía: 1378 de 1378 tests y smoke OK; los 30 tests citados por nombre pasan según el `junit.xml` (`verify-completo.txt`).

**Resultado del gate**: 58 filas, 23 para aceptar, 2 para aceptar solo junto con otra fila, 33 para aceptar con cambios y 0 para rechazar. No cambió ningún estado de ADR, `signals.md`, `scene-tree.md` ni `decisions.md`.

**Decisiones mías para revisar**:
- En `README.md` también añadí la Enmienda D27 a la fila de ADR-005, porque su cabecera la da como propuesta y el índice la omitía, y un enlace a `gate-enmiendas.md`. La ficha solo citaba D14 y ADR-002.
- Dividí las enmiendas por subsección (58 filas) para poder recomendar por separado lo que coincide y lo que no.
- Para T3 propongo marcar como «Superada por D17» solo lo que dice de Unity, porque `godot/` en este repo sigue vigente.

**No verificable**: medidas de px y px/m, valor provisional de `presses_to_fill` y comportamiento en teléfono real; requieren medir o un dispositivo, y no se volvieron a medir aquí. La tabla de ramas de ADR-003 §11.6 se comprobó mediante sus tests, no rama a rama. Tampoco se ha medido con qué frecuencia se da al jugar el caso de la decisión 5 (no es una partida completa), y las demás afirmaciones negativas sobre el juego solo están leídas.

**Correcciones tras la revisión** (los cuatro hallazgos son ciertos):
- **`delivery_rejected` (G22, G51)**: reproducido con escenas reales y el autoload `RoundManager` (`repro_lanzador.gd`, `repro_entrega_tras_caducidad.gd`, salida en `repro-entrega.txt`). Con la entrada un tick antes de la caducidad: caduca en el tick 11, `delivery_rejected` con `penalty` 0 en el 12 y entrega a la repuesta en el 13; con la entrada uno antes o uno después no se emite. G22 y G51 pasan a «aceptar con cambios», y la decisión 5 queda para el responsable. La revisión citaba `order_stand.gd:205-208`, pero el fichero tiene 204 líneas; las citas correctas son `:156` y `:202`.
- **G47**: amplía la divergencia y el arreglo con `signals.md:207`, `:209` y la secuencia de `:237-248`. `:209` no estaba en la revisión.
- **G10, G12, G50 y recuento**: G10 pasa a «aceptar con cambios»; G12 y G50 pasan a la categoría nueva «aceptar solo junto con otra fila». `comprobar_gate.py` cuenta esa categoría y ahora falla si una fila con «aceptar» a secas tiene divergencia.
- **G46**: añade quitar `order_stand.gd` de los receptores de `delivery_rejected`. `camera_rig.gd` y `audio_director.gd` salen en `comprobaciones.txt`, pero son falsos positivos: `signals.md:101` declara el primero en una nota y la fila lista el segundo como `AudioDirector`.

**Correcciones tras la segunda revisión** (los cinco hallazgos son ciertos; dos con un matiz):
- **Decisión 5, G22 y G51**: ahora dicen que el núcleo cumple lo decidido y que el conflicto está entre la frase «sin emisión en el juego» y `order_stand.gd:156`. La opción de matizar incluye `signals.md:160` y AC5d, y queda claro que ninguna opción toca el núcleo. **Matiz**: la revisión decía que D24 define la ventana, pero D24 y AC5d hablan del «mismo tick»; quien la escribe es ADR-002:106-110, y D24 remite a `_expired_this_tick`. La «frase de D26» tampoco está en `decisions.md:30`, sino en las enmiendas D26 (`signals.md:25` y `:88`, ADR-003:845). Añadí algo que la revisión no citaba: el «Test:» de AC5d está caducado, porque `test_order_stand.gd:245` comprueba que no se emite.
- **G46**: quité `camera_rig.gd` de los receptores no listados. Los otros cinco los volví a comprobar y no están ni en sus filas ni en notas. También corregí la viñeta anterior de esta ficha.
- **G33**: pasa a «aceptar con cambios» por la firma `set_safe_rect` y por «contenedor raíz», y cita el nodo real de `main_menu.tscn:15`. **Matiz**: «contenedor raíz» sí es cierto en HUD y tickets, que extienden `SafeAreaMargin`; la fila lo dice.
- **G23, G47, G53 y G57**: añaden `ADR-003:884`, `signals.md:217`, `scene-tree.md:393` y `scene-tree.md:239`. La lista no era exhaustiva y sigue sin serlo, así que «Cómo leer» lo avisa y `comprobaciones.txt` tiene una sección nueva, «Residuos», con todas las apariciones.
- **G05 y G24**: citan el emisor de desarrollo `touch_sandbox.gd:48`. `comprobaciones.py` declara la exclusión e imprime lo que excluye.
- **Comprobaciones**: `comprobar_gate.py` sigue mirando solo el prefijo «Sin divergencia», así que no detecta una fila mal clasificada como G33; eso sigue dependiendo de la revisión manual. Volví a ejecutar AC1, AC2, AC3 y `tools/verify.sh --quick`, no la suite completa, porque esta ronda no cambia código de `godot/`.

**Correcciones tras la tercera revisión** (el hallazgo es cierto):
- **G15**: pasa de «aceptar» a «aceptar con cambios». `ADR-003:583` dice «solo `BOX_NOT_FULL`», pero `seasoning_dispenser.gd:74` y `:93` también emiten `ALREADY_APPLIED`, y `test_seasoning_station.gd:203` lo exige. `ADR-003:863` solo sustituye lo dicho en §10.2. De las dos opciones de la revisión elegí cambiar la frase de §10.5 y no ampliar §11.7, porque así G15 no queda a la espera de G22 ni de la decisión 5.
- **G12**: cita `ADR-003:492` y `:493`, que no llevan nota propia y solo quedan sustituidas por `:860` y `:863`. La recomendación no cambia.
- **G50 y G57 (añadido mío)**: busqué la misma afirmación en `docs/arch` (nueva sección de `comprobaciones.txt`). G50 añade `signals.md:53` y `:208`, que corrige la nota D26 de `:212`. G57 añade `scene-tree.md:362`, `:363` y `:368`, que no tienen nota D26 que las corrija. Sus recomendaciones no cambian.
- **Límite nuevo en el gate**: las 27 filas con «aceptar» se comprobaron con las líneas que citan, no frase a frase, y no las he vuelto a repasar. `comprobar_gate.py` tampoco detecta este tipo de error, porque solo mira el prefijo «Sin divergencia».
- **Comprobaciones**: volví a ejecutar AC1, AC2, AC3, `comprobaciones.py` y `tools/verify.sh --quick`. No repetí la suite completa, porque esta ronda no cambia código de `godot/`.

**Correcciones tras la cuarta revisión** (los cinco hallazgos son ciertos; comprobados contra el código):
- **G20**: pasa a «aceptar con cambios». `action_prompt.gd` no tiene ningún Tween y `action_icon_set.gd:29` y `:39` son `int`.
- **G19**: pasa a «aceptar con cambios». TIRAR, COCER y SUSTITUIR aliño dan dos cues, y `_press` no llama a `get_hint()`. La fila dice que un solo cue de verdad necesitaría otra ficha de código. **Añadido mío**: el título de `ADR-006:186` también dice «un cue por pulsación», aunque sus filas admiten los casos dobles. No cambié G43 por esto.
- **G16**: pasa a «aceptar con cambios». **Matiz**: la revisión hablaba de stock 0, pero `action_rules.gd:101` no mira el stock, así que con el cuenco lleno también gana `box_not_full` sobre `full`. Por eso propongo escribir la excepción «con cualquier stock, también 0». Las otras funciones de `action_rules.gd` no contradicen la prioridad.
- **G17 y G18**: anotan la excepción de desarrollo de `sandbox_item.tscn`. Siguen en «aceptar».
- **Recuento**: 24, 2, 32 y 0. `comprobar_gate.py` ahora falla si el recuento escrito en el gate o en esta ficha no coincide con el contado. Las cifras de las correcciones anteriores se quedan como historia de cada ronda.
- **Límite**: el gate dice que solo corregí estas filas y que **las 24 filas con «aceptar» siguen sin repasarse frase a frase**. No hice ese repaso, y `comprobar_gate.py` sigue sin detectar una fila mal clasificada.
- **Comprobaciones**: `comprobaciones.py` añade secciones para G16, G17, G18, G19 y G20. Volví a ejecutar AC1, AC2, AC3, `comprobaciones.py` y `tools/verify.sh --quick`. No repetí la suite completa, porque esta ronda no cambia código de `godot/`.

**Correcciones tras la quinta revisión** (los cuatro hallazgos son ciertos; comprobados contra el código):
- **G25**: pasa a «aceptar con cambios». `ADR-004:163-164` incluye la pausa entre lo que lee `PlayerInput` y `_unhandled_input`, pero `pause_menu.gd:36` usa `_input` y `:39` comprueba `is_action_pressed("pause")`; `player_input.gd:42` lo confirma. La fila lleva la frase pedida. **Matiz**: esa frase solo vale para los tres en conjunto. `player.gd` no usa `_unhandled_input` (dirección de `PlayerInput`, `:132`, y magnitud de `Input.get_vector`, `:157`), `character_switcher.gd:37-38` solo `_unhandled_input` con `p1_switch` (no menciona `PlayerInput`) y solo `interaction_component.gd:45-47` hace ambas cosas. La fila lo dice y pide que la redacción lo deje claro.
- **G14**: anota que `test_order_board.gd:5` usa también el catálogo de paridad de `tests/helpers/m0_data`, como admite `ADR-003:575-577`. **Añadido mío**: `ADR-003:572` lo lista entre los tests que pasan a las comandas nuevas, y `test_round_manager.gd:8` y `test_round_state.gd:7` usan el mismo catálogo. Sigue en «aceptar».
- **G37**: quité `test_arrow_keeps_16px_from_button_zone` de la columna de implementación y lo dejé como matiz: `test_camera_follow.gd:196` compara con el rectángulo fijo anterior (x ≥ 1950, y ≥ 600), no con la zona anclada (x ≥ 1818, y ≥ 777 con esa safe area). **Añadido mío**: `test_camera_follow_math.gd:129` prueba la regla de los 16 px con un rectángulo a mano, así que lo de la zona anclada queda comprobado solo leyendo `camera_rig.gd:231`. La fila propone una ficha aparte para el test y sigue en «aceptar». Añadí ese test a `verify-completo.txt` desde el `junit.xml` del worktree; no repetí la suite.
- **«Qué no se ha comprobado»**: dice que las 23 filas «aceptar» restantes se contrastaron frase a frase por lectura de código en la última revisión, sin ejecutarlas. Ese repaso es de la revisión, tal como consta en su encargo; **no lo repetí**, solo comprobé las filas G14, G25 y G37. También ajusté «Cómo leer» y la definición de «Sin divergencia», que decían lo contrario.
- **Comprobaciones**: `comprobaciones.py` añade secciones para G14, G25 y G37. Volví a ejecutar `comprobar_gate.py`, `comprobaciones.py`, AC3 y `tools/verify.sh --quick`. No repetí la suite completa, porque esta ronda no cambia código de `godot/`.
