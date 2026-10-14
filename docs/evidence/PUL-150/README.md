# PUL-150 · Guía del playtest humano de M3e

Entregable: `docs/design/m3e-gate.md`. Solo documentación: no se toca código, escenas, datos, contratos,
`roadmap.md`, `decisions.md` ni las features. Cifras de `docs/evidence/PUL-152/README.md` (vigentes, con
H-05) y de la QA de D26 (`docs/backlog/PUL-132-qa-de-d26.md`).

## Estado por AC
| AC | Resultado | Evidencia |
|---|---|---|
| AC1 | **PASA** | 6 secciones de Change en orden (encabezados abajo); «Lo que ya sabías» con **17** medidas con valor y estado (16 OK, 1 limitación) |
| AC2 | **PASA (11 de 11)** | Tabla de trazabilidad abajo |
| AC3 | **PASA (9 de 9)** | Tabla P1-P9 abajo; la guía añade P10-P13 (H-05 de PUL-152 y preguntas de PUL-140) |
| AC4 | **PASA** | PC 29 min (≤ 30), teléfono 15 min (≤ 15); 26 rutas de captura citadas, 0 ausentes (`ls` abajo) |
| AC5 | **PASA** | `tools/verify.sh --quick` → `✓ verify OK`; `tools/check_owns.py jrmougan/pul-150 main` limpio (salida abajo) |

## AC1 · Encabezados (`grep -n '^#' docs/design/m3e-gate.md`)
```
1:# Puerta humana de M3e: lenguaje de acciones y móvil (D26, D27)
14:## Lo que ya sabías antes de jugar
58:## Antes de empezar
73:## Qué mirar y qué responder (PC, ~29 min)
76:### A. Verbos y prompt [D26.1, D26.2] (~5 min)
85:### B. Ninguna pulsación muda [D26.3] (~5 min)
91:### C. Objetivo estable [D26.4] (~2 min)
96:### D. Simplificaciones [D26.5] (~5 min)
103:### E. Estado legible en el mundo [D26.6] (~4 min)
110:### F. Iconografía [D26.7] (~2 min)
116:### G. Local 2P y perfil táctil en PC [D26.8, D27.1, D27.2, D27.3] (~6 min)
126:## Parte de teléfono (condicionada a PUL-151 o PUL-153, ~15 min)
140:## Qué medir y cómo anotar
156:### Resultado del gate
160:## Qué decidir
```
Correspondencia con Change: 1 «Lo que ya sabías» (l. 14) · 2 «Antes de empezar» (l. 58) · 3 «Qué mirar y
qué responder» (l. 73, bloques A-G) · 4 «Parte de teléfono» (l. 126) · 5 «Qué medir y cómo anotar» (l. 140,
con «Resultado del gate» vacío) · 6 «Qué decidir» (l. 160).

Medidas de la tabla (17): pulsaciones mudas 0/58 (PUL-132), prompt 64/80, motivo/aspa 32/24, botón de
acción 180/204, cambiar en fila 120/24/0, zona de botones 1818/777, stick 300/150, texto 36, px/m 121,6,
anillo 8/64 y 267,2 (H-01), aros 10/2,5 (H-02), contador 16,7/68,9, muesca 24, tickets 380/16/174,
caso 09 safe nula 0 px, caso 09 safe de diseño 6,6/35,0 px (limitación D27.3), game over (H-03).

## AC2 · Trazabilidad D26/D27 → filas de «Qué mirar»
| # | Punto | Filas |
|---|---|---|
| 1 | D26.1 Verbos | A1 (icono antes de pulsar), A2 (8 siluetas) |
| 2 | D26.2 Prompt OK / BLOQUEADO | A1, A3 (motivo), A4 (SOLTAR al suelo), A5 (lado de pase) |
| 3 | D26.3 Ninguna pulsación muda | B1 (rechazos provocados), B2 (cues propios) |
| 4 | D26.4 Objetivo estable | C1 |
| 5 | D26.5 Simplificaciones | D1 (cuenco solo pone), D2 (entrega por zona), D3 (mantener para cortar) |
| 6 | D26.6 Estado legible | E1 (anillo y aviso), E2 (raciones), E3 (aros) |
| 7 | D26.7 Iconografía | F1 (aliños), F2 (rack/caja sin S/M/L, HUD) |
| 8 | D26.8 Móvil | G1 (Local 2P, dos prompts), G2 (`--touch`, UI escalada), G6 (stick y acción en PC táctil), T1-T5 |
| 9 | D27.1 Botones en fila | G3, T1 |
| 10 | D27.2 Zona de botones (safe area) | G4 (caso 09 safe nula), T6 |
| 11 | D27.3 Limitación con safe area inferior | G5 (captura con safe de diseño), T6 (teléfono real), P9 |

11 de 11.

## AC3 · «Qué decidir» (9 de 9)
| # | Origen | Pregunta | Opciones en la guía |
|---|---|---|---|
| P1 | `controles-tactiles.md` 1 | Zurdos | dejar / ficha Could con layout espejado |
| P2 | `controles-tactiles.md` 2 | Tamaño ajustable | fijo / deslizador 0,8–1,3 |
| P3 | `controles-tactiles.md` 3 | Háptica 20 / 20 + 20 ms | patrón actual / solo rechazo / otro tras PUL-151 |
| P4 | `controles-tactiles.md` 4 | Texto de 36 px | dejar / subir `text_min_px` (p. ej. 42) |
| P5 | `controles-tactiles.md` 5 | Entrega por zona en móvil | confirmar zona / añadir toque ENTREGAR |
| P6 | `controles-tactiles.md` 6 | Notch superior | a PUL-151 / margen superior ya |
| P7 | `lenguaje-acciones.md` 1 | Soltar al suelo por accidente | pulsación simple / mantener 0,3 s / solo en móvil |
| P8 | `lenguaje-acciones.md` 2 | Dispensador desde el lado de pase | sin objetivo / 7.º motivo «otro lado» |
| P9 | D27, ADR-005 D27.3 | Limitación D27.3 | mantener / cámara que descuenta la safe area inferior |

Añadidas por el brief del coordinador: P10 corregir ADR-005 D27.3 y el residuo de D27 con las cifras de
PUL-152 (H-05); P11 perfil de escritorio que ignore la safe area del sistema (H-05); P12 build web en el
teléfono (PUL-140 pregunta 2); P13 perfil táctil en PC sin pantalla táctil (PUL-140 pregunta 1 = pregunta 1
de esta ficha).

## AC4 · Tiempos y rutas
| Parte | Bloques | Suma |
|---|---|---|
| PC | A 5 + B 5 + C 2 + D 5 + E 4 + F 2 + G 6 | **29 min** (≤ 30) |
| Teléfono | T1 3 + T2 3 + T3 2 + T4 3 + T5 1 + T6 3 | **15 min** (≤ 15) |

Las dos rondas de 300 s de «Antes de empezar» son el soporte de los bloques A-G (se miran mientras se
juega), no tiempo añadido.

`ls -1` de cada captura citada (26, 0 ausentes; `xargs ls` salió con 0):
```
docs/evidence/PUL-122/pause_touch_2340x1080.png
docs/evidence/PUL-123/contact_sheet_64px_gray.png
docs/evidence/PUL-123/rack_in_game.png
docs/evidence/PUL-126/bowl_stock_2.png
docs/evidence/PUL-126/tickets_stickers.png
docs/evidence/PUL-127/local_2p_two_prompts_1920x1080.png
docs/evidence/PUL-127/prompts_station_1920x1080.png
docs/evidence/PUL-128/1920x1080_stick_and_press.png
docs/evidence/PUL-131/desktop_1920x1080_2_suelo_soltar.png
docs/evidence/PUL-134/2340x1080-despues-01-flecha-inactivo-bajo-la-banda.jpg
docs/evidence/PUL-152/1920x1080-desktop-01-vista-general.jpg
docs/evidence/PUL-152/1920x1080-desktop-03-prompt-ok-coger.jpg
docs/evidence/PUL-152/1920x1080-desktop-04-prompt-bloqueado-caja-a-medias.jpg
docs/evidence/PUL-152/1920x1080-desktop-05-cuenco-2-raciones.jpg
docs/evidence/PUL-152/1920x1080-desktop-06-contador-3-de-6.jpg
docs/evidence/PUL-152/1920x1080-desktop-08-anillo-listo.jpg
docs/evidence/PUL-152/1920x1080-desktop-09-aviso-de-quemado.jpg
docs/evidence/PUL-152/1920x1080-desktop-10-aros-activo-e-inactivo.jpg
docs/evidence/PUL-152/1920x1080-desktop-11-zona-de-entrega-encendida.jpg
docs/evidence/PUL-152/2340x1080-caso09-diseno-este-z3_4.jpg
docs/evidence/PUL-152/2340x1080-caso09-diseno-oeste-z3_4.jpg
docs/evidence/PUL-152/2340x1080-caso09-nula-oeste-z3_4.jpg
docs/evidence/PUL-152/2340x1080-touch-01-vista-general.jpg
docs/evidence/PUL-152/2340x1080-touch-02-stick-activo-y-botones.jpg
docs/evidence/PUL-152/2340x1080-touch-04-prompt-bloqueado-caja-a-medias.jpg
docs/evidence/PUL-152/2340x1080-touch-12-pausa.jpg
```

## AC5 · Verificación
```
$ tools/verify.sh --quick
...
✓ verify OK
$ python3 tools/check_owns.py jrmougan/pul-150 main
check_owns: 3 rutas dentro de owns de PUL-150.
```
