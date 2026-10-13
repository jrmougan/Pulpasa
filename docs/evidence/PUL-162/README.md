# PUL-162 · Evidencia: cerrar el diseño del tutorial breve

Feature: [`docs/design/features/tutorial-breve.md`](../../design/features/tutorial-breve.md).
Estado de G0 al cerrar: **P5 sin responder** (no hay decisión D28+ en `decisions.md`; el coordinador no
envió respuesta). Por eso la entrada va como 3 opciones marcadas **propuesta**.

## AC1 · Tabla de pasos
Sección [«Pasos»](../../design/features/tutorial-breve.md#pasos): 6 filas con texto, verbo
(`ActionVerb`), objetivo resaltado, señal y avance ≤ 0,5 s.

| # | Señal | Origen |
|---|---|---|
| 1 | `held_item_changed(p, &"octopus_raw")` | **Propuesta S1 para ADR-007**; alternativa con el catálogo actual: `interaction_resolved(p, &"pick_up", 1, &"")` (falso positivo documentado) |
| 2 | `interaction_resolved(p, &"cook", 1, &"")` | `signals.md` §2 Interacción |
| 3 | `interaction_resolved(p, &"cut", 1, &"")` × `presses_to_fill`, y después `interaction_resolved(p, &"drop" \| &"trash", 1, &"")` para dejar las 50 u sobrantes (con S1: `held_item_changed(p, &"")`) | `signals.md` §2 Interacción |
| 4 | `interaction_resolved(p, &"season_sweet", 1, &"")` | `signals.md` §2 Interacción |
| 5 | `order_completed(order, points)` | `signals.md` §2 Comandas |
| 6 | Individual: `character_switched(1, c)`; Local 2P: `item_handed_over(a, b, pass_slot_id, kind)`, `a ≠ b` | Individual: `signals.md` §2 Sesión y jugadores. Local 2P: **propuesta S2 para ADR-007** (hecho de transferencia emitido por el `PassSlot`); sin S2 no hay condición honesta y el sustituto («entregad otra caja entre los dos») arriesga AC4 |

Avance: el núcleo cambia en el mismo frame; el panel en `step_transition_time` = 0,3 s (≤ 0,5 s).
Otras propuestas para PUL-163: señales de paso del tutorial, acción `tutorial_skip`, sin quemado en el tutorial.

## AC2 · Entrada y salida
Sección [«Entrada y salida»](../../design/features/tutorial-breve.md#entrada-y-salida-p5-de-g0-sin-responder-las-3-opciones-son-propuesta):
tabla de las opciones (a) automático en la primera partida, (b) botón «Tutorial», (c) ambas, con
disparador, modo, saltar, repetir y coste, y un AC por opción (E-a, E-b, E-c), todo marcado
**propuesta**. Salida recomendada: partida normal desde 0 s tras un cartel de 2 s (alternativa: volver
al menú); tope de 180 s; «Repetir tutorial» en Opciones solo si se elige (a).

Coste que afecta a otras fichas (para el producer):
- (b)/(c) obligan a enmendar `menu-principal.md` AC6 y `controles-tactiles.md` AC1 (menú táctil con
  2 botones). No los toco: no son de esta ficha.
- **Discrepancia con PUL-175 AC1** (draft): dice «a: perfil sin tutorial hecho y partida Individual».
  La feature propone que (a) salte también en Local 2P (la ficha pide definir el tutorial en 2P). Si G0
  elige (a), PUL-175 AC1 debe decir «Individual o Local 2P», o G0 lo restringe a Individual.

## AC3 · Perfiles cruzados con `controles-tactiles.md` (D26, D27)
AC numéricos por perfil:
- **Individual (escritorio):** AC9: paso 6 termina ≤ 0,5 s tras cambiar; el `character_switched` de inicio no cuenta; panel ≤ 900 × 220 px, texto ≥ 28 px a 1080.
- **Local 2P:** AC10: J2 avanza los pasos 1–5 igual que J1 en ≤ 0,5 s; paso 6 solo con el mismo objeto pasado de J1 a J2 por un pasaplatos (S2); soltar al suelo y coger otra cosa, o dejar y recoger el mismo jugador, no lo completa.
- **Táctil:** AC8: fantasma del stick de 300 px en (585, 756); texto ≥ 36 px; «Saltar» ≥ 120 px; panel en x ∈ [50 % + 24, safe area − 48], y ∈ [224, 576], ≤ 300 px de alto; aros anclados al botón real: cambiar en (2028, 972) sin safe area y (1896, 909) con la de diseño; acción en (2202, 942) y (2070, 879).

AC cruzados (0 contradicciones):

| AC de `controles-tactiles.md` | Qué dice | Cómo lo cumple el tutorial |
|---|---|---|
| Tabla de escala, «Texto de UI … tutorial» | 36 px a 1080 (24 a 720) | AC8 (2): texto ≥ 36 px |
| Tabla de escala, «Botones del tutorial («Saltar»)» | 120 px de alto | AC8 (2): ≥ 120 px |
| Menús, «Tutorial: el paso 1 señala el stick y el botón de acción» | — | AC8 (1): fantasma del stick + aro en el botón de acción |
| AC1 (perfil: solo «Individual» en el menú táctil) | Menú táctil con 1 botón | (a) no toca el menú. (b)/(c) lo cambian: está declarado como **coste y enmienda**, no como contradicción |
| AC3 (D27: cambiar a la izquierda del de acción) + ADR-005 D27.1 (tabla de centros) | Cambiar en (2028, 972) con safe area nula y en (1896, 909) con la de diseño 132/0/132/63 a 2340×1080 | AC8 (4): el aro del paso 6 se ancla al centro real del botón (± 2 px), con los dos casos; ídem el aro del botón de acción del paso 1 ((2202, 942) / (2070, 879), = AC2 de `controles-tactiles.md`) |
| D27 / ADR-005 D27.2: zona de botones anclada a la safe area | Safe area nula: x ≥ ancho − 390, y ≥ 840. Diseño: x ≥ 1818, y ≥ 777 | AC8 (3): panel con y ≤ 576 en los dos casos |
| AC16 (zonas reservadas: stick x < 50 %, y ≥ 200; botones x ≥ ancho − 390, y ≥ 600) | Nada de UI encima | AC8 (3): panel en x ≥ 50 % + 24 e y ∈ [224, 576] (por debajo de 600, así vale con la zona antigua y la de D27) |
| AC15 (banda superior ≤ 200 px) | Tickets y HUD arriba | AC8 (3): el panel empieza en y = 224 (24 px de hueco) |
| AC17 (safe area, 48 px de margen) | Todo dentro | AC8 (3): borde derecho = safe area − 48 |
| AC14 (`test_ui_scale.gd` recorre los `Label` del tutorial) | ≥ 36 px | AC8 cita `test_ui_scale.gd` |
| D26 (8) / AC1 (no hay Local 2P en móvil) | Solo Individual | Tabla «Perfiles»: táctil solo Individual; paso 6 = cambiar |
| `lenguaje-acciones.md` AC13 (mantener = atajo, repetición cada 0,2 s) | Cada repetición emite `interaction_resolved` | Paso 3 cuenta repeticiones igual que pulsaciones; texto del paso lo dice (AC7) |
| `jugadores-y-cambio.md` AC10/AC11 | Botón de cambiar = `p1_switch`; prompt por jugador en 2P | Paso 6 Individual escucha `character_switched`; en 2P el prompt de cada jugador sigue (AC11 del tutorial) |

Cambio respecto a la versión anterior: el AC8 antiguo decía que en táctil el paso de cooperar «se
sustituye» por cambiar de personaje. Ahora Individual (escritorio y táctil) usa siempre cambiar y Local
2P usa pasarse algo por un pasaplatos, lo que cuadra con AC7 («paso 6: el botón de cambiar»).

## AC4 · Verificación
Salida pegada abajo, ejecutada sobre el commit de la ficha.

### `tools/verify.sh --quick`
```
== gdformat --check
235 files would be left unchanged

== gdlint
Success: no problems found

== import

✓ verify OK
# código de salida: 0
```

### `python3 tools/check_owns.py jrmougan/pul-162 main`
```
check_owns: 3 rutas dentro de owns de PUL-162.
# código de salida: 0
```
