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
- **Verificación**: `tools/verify.sh --quick` en verde (`verify-quick.txt`). El primer intento falló porque el import inicial de este worktree superó el límite de 300 s de `verify.sh`; lancé el import a mano y el siguiente `verify.sh` pasó. También ejecuté `tools/verify.sh` completo, aunque la ficha no lo pedía: 1378 de 1378 tests y smoke OK; los 29 tests citados por nombre pasan según el `junit.xml` (`verify-completo.txt`).

**Resultado del gate**: 58 filas, 29 para aceptar, 2 para aceptar solo junto con otra fila, 27 para aceptar con cambios y 0 para rechazar. No cambió ningún estado de ADR, `signals.md`, `scene-tree.md` ni `decisions.md`.

**Decisiones mías para revisar**:
- En `README.md` también añadí la Enmienda D27 a la fila de ADR-005, porque su cabecera la da como propuesta y el índice la omitía, y un enlace a `gate-enmiendas.md`. La ficha solo citaba D14 y ADR-002.
- Dividí las enmiendas por subsección (58 filas) para poder recomendar por separado lo que coincide y lo que no.
- Para T3 propongo marcar como «Superada por D17» solo lo que dice de Unity, porque `godot/` en este repo sigue vigente.

**No verificable**: medidas de px y px/m, valor provisional de `presses_to_fill` y comportamiento en teléfono real; requieren medir o un dispositivo, y no se volvieron a medir aquí. La tabla de ramas de ADR-003 §11.6 se comprobó mediante sus tests, no rama a rama. Tampoco se ha medido con qué frecuencia se da al jugar el caso de la decisión 5 (no es una partida completa), y las demás afirmaciones negativas sobre el juego solo están leídas.

**Correcciones tras la revisión** (los cuatro hallazgos son ciertos):
- **`delivery_rejected` (G22, G51)**: reproducido con escenas reales y el autoload `RoundManager` (`repro_lanzador.gd`, `repro_entrega_tras_caducidad.gd`, salida en `repro-entrega.txt`). Con la entrada un tick antes de la caducidad: caduca en el tick 11, `delivery_rejected` con `penalty` 0 en el 12 y entrega a la repuesta en el 13; con la entrada uno antes o uno después no se emite. G22 y G51 pasan a «aceptar con cambios», y la decisión 5 queda para el responsable. La revisión citaba `order_stand.gd:205-208`, pero el fichero tiene 204 líneas; las citas correctas son `:156` y `:202`.
- **G47**: amplía la divergencia y el arreglo con `signals.md:207`, `:209` y la secuencia de `:237-248`. `:209` no estaba en la revisión.
- **G10, G12, G50 y recuento**: G10 pasa a «aceptar con cambios»; G12 y G50 pasan a la categoría nueva «aceptar solo junto con otra fila». `comprobar_gate.py` cuenta esa categoría y ahora falla si una fila con «aceptar» a secas tiene divergencia.
- **G46**: añade quitar `order_stand.gd` de los receptores de `delivery_rejected`. También añade `camera_rig.gd`, que estaba en `comprobaciones.txt` y no en la fila. `audio_director.gd` también sale en esa salida, pero es un falso positivo: la fila lo lista como `AudioDirector`.
