# PUL-140 · Fichas de cierre de M3e

Cierre de M3e (D26, D27; `roadmap.md`: «Playtest humano del lenguaje de acciones en PC y, cuando haya
export, en teléfono»; Must 11: export Android y renderizador móvil en ficha aparte). Solo se crean fichas;
no se escribe la guía ni código. `README.md` del backlog y `roadmap.md` los actualiza el coordinador.

## Fichas creadas
| Id | Título | Estado | Rol | Deps | Por qué |
|---|---|---|---|---|---|
| PUL-150 | Escribir la guía del playtest humano de M3e (`m3e-gate.md`) | draft | game-designer | PUL-152 | La puerta de M3e no tiene guía. Estructura de `m3d-gate.md`; cubre los 8 puntos de D26 y D27 (trazabilidad 11/11), parte de teléfono condicionada a PUL-151 o PUL-153, plantilla de resultados y las 9 preguntas por decidir |
| PUL-151 | Exportar a Android, elegir renderizador móvil y verificar en un teléfono real | **blocked** | godot-architect | — | Must 11 y ADR-005 E2 lo dejan para «ficha futura». Incluye D27.3 (safe area inferior real frente a 21-23 / 51 px a 1080), AC17 en dispositivo, mm físicos de 72 / 48 dp y las preguntas 3, 4 y 6 de `controles-tactiles.md` |
| PUL-152 | Recapturar medidas y capturas de D26 con el estado final de M3e | draft | qa-tester | — | Las 14 escenas de PUL-132 son anteriores a PUL-133/134/138; la guía necesita un juego vigente. Añade el caso 09 con la safe area de diseño (hoy solo calculado en D27.3, no capturado) |
| PUL-153 | Probar el perfil táctil en un teléfono con el build web (antes del APK) | draft (pregunta) | qa-tester | — | `export.md` ya prevé el web en el teléfono (`web_android` → `MOBILE`): permite la parte de teléfono del gate sin esperar al toolchain. Lista qué no puede comprobar el web (safe area, Atrás, háptica…) para PUL-151 |
| PUL-154 | Que el panel de salida de GUT no se quede con el puntero en los tests de UI | draft | qa-tester | — | H-04 de PUL-132, vivo (apaño en `test_d26_touch_flow.gd`) y sin ficha. No bloquea el gate; hito M4 (prescindible si el coordinador prefiere dejarlo en el triaje) |

`owns` disjuntos: PUL-150 `docs/design/m3e-gate.md`; PUL-151 `export_presets.cfg`, `tools/export.sh`,
`project.godot`, `docs/arch/export.md` (los de PUL-010); PUL-152 y PUL-153 solo su evidencia; PUL-154
`.gutconfig.json` y dos tests. Ninguna toca escenas.

Orden sugerido: PUL-152 → PUL-150 → playtest en PC; PUL-153 (si el responsable lo acepta) para la parte
de teléfono; PUL-151 cuando se desbloquee. PUL-154 cuando convenga.

## Lo revisado de D26 y D27
| Punto | Estado | Ficha que lo cierra |
|---|---|---|
| D26.1-D26.7 (verbos, prompt, ninguna pulsación muda, histéresis, simplificaciones, estado legible, iconografía) | Implementado (PUL-121..131) y verificado por bot en PUL-132 (58 combinaciones, 0 mudas) | Falta el juicio humano → PUL-150 (guía) |
| D26.8 móvil en PC (`--touch`, safe area simulada) | Implementado; H-01..H-03 de PUL-132 corregidos en PUL-133; PUL-134/135 zonas tapadas | PUL-152 (recaptura), PUL-150 |
| D26.8 en teléfono real (rendimiento, multitáctil real, ciclo de vida, pantalla encendida, háptica, orientación) | Código presente (`game_state.gd`: foco, Atrás, pantalla encendida; `touch_config.tres`: háptica; `project.godot`: `orientation=4`, `quit_on_go_back=false`), sin probar en dispositivo | PUL-151 (y en parte PUL-153) |
| D26: renderizador móvil y export Android | Fuera de M3e por decisión | PUL-151 |
| D27.1-D27.2 botones en fila y zona anclada a la safe area | Implementado y probado en PUL-138 (tests con safe nula y de diseño; capturas solo con safe nula) | PUL-152 (capturas con ambas) |
| D27.3 limitación con safe area inferior > 0 | Aceptada; calculada en ADR-005, no capturada ni medida en un teléfono | PUL-152 (simulada), PUL-151 (real), PUL-150 (decidir si se mantiene) |
| Residuo ≤ 8 px a 800×370 (D27) | Aceptado; medido 6,4 px en PUL-138 | PUL-152 (sin regresión) |
| Preguntas abiertas de `controles-tactiles.md` (1 zurdos, 2 tamaño ajustable, 3 háptica, 4 texto 36 px, 5 entrega por zona, 6 muesca) | Abiertas; 1 y 2 son Could | Decisión en el gate (PUL-150 AC3); 3, 4 y 6 se miden en PUL-151 AC5 |
| Preguntas de `lenguaje-acciones.md` (1 soltar al suelo por accidente, 2 dispensador desde el lado de pase) | Abiertas «para el playtest»; 3-5 ya cerradas por D26/contrato | PUL-150 AC3 |
| H-04 de PUL-132 (panel de GUT) | Vivo | PUL-154 |

## Preguntas para el coordinador o el responsable
1. **Perfil táctil en PC sin pantalla táctil** (PUL-150, pregunta 1): `emulate_touch_from_mouse` está
   desactivado, así que con ratón el responsable no puede manejar el stick ni los botones en PC. ¿Tiene
   pantalla táctil? Si no, ¿la parte táctil se juega solo en teléfono (PUL-153/151) o se pide una bandera
   de desarrollo que emule un toque con el ratón (sin multitáctil; ficha aparte)?
2. **Teléfono por web** (PUL-153): ¿se acepta el build web en el teléfono, en red local, como vía
   provisional para la parte de teléfono del gate?
3. **Toolchain Android** (PUL-151): ¿quién lo instala y cómo se versiona (fuera de `mise.toml`, como
   Godot)? Hoy faltan el SDK y las plantillas de exportación 4.7.2 (también las de escritorio: el
   directorio `~/.local/share/godot/export_templates/` no existe en esta máquina).
4. **Estado de los contratos**: `docs/arch/README.md` sigue marcando como «propuesta» las enmiendas D25 y
   D26 (ADR-002/003/004/005/006) y la D27 de ADR-005, aunque el commit 5affabc dice «gate aprobado» para
   PUL-137. ¿Se aceptan en el gate de M3e? No lo cubre ninguna ficha: es trabajo del coordinador.
