---
id: PUL-151
title: Exportar a Android, elegir renderizador móvil y verificar en un teléfono real
status: blocked
milestone: M3e
role: godot-architect
deps: []
orca_task: null
unity_sources: []
owns: [godot/export_presets.cfg, tools/export.sh, godot/project.godot, docs/arch/export.md, docs/evidence/PUL-151/**, docs/backlog/PUL-151-export-android-y-renderizador-movil.md]
touches_scenes: []
---

**Bloqueada:** no hay toolchain ni dispositivo. En la máquina de trabajo no están el Android SDK
(`adb`, `sdkmanager`, build-tools, platform-tools) ni las plantillas de exportación 4.7.2 (incluida la de
Android); solo hay `java`. Ningún agente tiene un teléfono conectado. Se desbloquea cuando el responsable
instale el toolchain (o autorice instalarlo, y fije cómo se versiona en `mise.toml` o fuera de él) y
conecte un teléfono Android con depuración USB.

## Target
Alcance de la alpha, Must 11 (`roadmap.md`): «el export Android y el renderizador móvil quedan fuera de
M3e: ficha aparte cuando haya toolchain y dispositivo». D26.8 y D27. Contratos: ADR-005 Enmienda D26 E2
(«Renderizador móvil y export Android: ficha futura (`export.md`)») y Enmienda D27, D27.3 (limitación
aceptada: con safe area inferior > 0 el contador de los pasaplatos 04-06 vuelve a quedar bajo los botones,
21-23 px en la plaza y 51 px en z −3,4 a 1080). `docs/arch/export.md` (sección Móvil).
`features/controles-tactiles.md`: criterios que solo se ven en teléfono (Verificación: «la verificación en
dispositivo real queda para la ficha de export Android») y preguntas 3, 4 y 6.

## Change
1. **Toolchain**: JDK, Android SDK (platform-tools, build-tools, plataforma) y plantillas 4.7.2,
   documentados en `docs/arch/export.md` para Linux, macOS y Windows; keystore de depuración fuera del
   repositorio.
2. **Preset Android** en `export_presets.cfg` (arm64-v8a, apaisado `sensor_landscape`, solo el permiso
   `VIBRATE`, excluye `tests/` y `addons/gut/`) y `tools/export.sh android` (APK de depuración).
3. **Renderizador móvil**: medir Mobile y Compatibility en el teléfono y proponer
   `rendering_method.mobile` en `project.godot`, con capturas para que el responsable compare la estética
   (D21) con Forward+ en PC.
4. **Prueba en el teléfono**: perfil, flujo completo, ciclo de vida, háptica, safe area real y D27.3.

## Constraints
- El renderizador es contrato (ADR-005 E2): la ficha **propone** con medidas; el cambio de
  `project.godot` necesita enmienda de ADR-005 y gate humano antes del merge. Si el gate se alarga, se
  mergea el preset sin tocar el renderizador.
- Escritorio y web no cambian: `rendering_method` (Forward+) y `rendering_method.web` siguen; los presets
  Linux, Windows y Web siguen exportando (`tools/export.sh all` en verde).
- Nada de secretos en el repositorio (keystore, contraseñas): rutas en la configuración del editor o en
  variables de entorno.
- Sin tiendas ni firma de publicación (fuera del alcance, `roadmap.md` Won't). Solo Individual en móvil.
- No se cambia código de juego: si el teléfono destapa un defecto (p. ej. D27.3 peor que lo medido), se
  anota como hallazgo con captura y lo convierte en ficha el coordinador.

## Acceptance
- [ ] AC1 (toolchain y preset) Given el toolchain de `export.md`, When `tools/export.sh android`, Then sale
  con 0, sin líneas `ERROR`, y deja `build/android/pulpasa.apk` (arm64-v8a) con orientación
  `sensor_landscape` y como único permiso `VIBRATE`; `tools/export.sh all` sigue en verde. → salida del
  script y `aapt dump permissions` en `docs/evidence/PUL-151/`.
- [ ] AC2 (renderizador) Given `level_01` en el teléfono, When se juega una ronda Individual de 300 s con
  cada renderizador (Mobile y Compatibility), Then se anotan FPS medio y p95 del tiempo de frame (monitor
  de rendimiento por `adb logcat` o superposición de depuración); el propuesto cumple FPS medio ≥ 30 y p95
  ≤ 33,3 ms; capturas de la misma vista (vista general y cocina con anillo de olla) en PC Forward+ y en el
  teléfono con cada renderizador. → tabla y capturas en la evidencia; elección en el gate.
- [ ] AC3 (perfil y flujo en el teléfono) Given el APK sin argumentos, Then el perfil es `MOBILE` (menú
  solo con «Individual»); When se juega una comanda completa solo con toques (cocer, cortar 6 manteniendo,
  aliñar, entregar por zona) con stick, acción y cambiar a la vez (3 contactos), Then termina sin teclado;
  When se pulsa Atrás o se va a inicio, Then la partida está en pausa al volver; Given 5 min de partida sin
  tocar, Then la pantalla no se apaga; la háptica (20 ms en éxito, 20 + 20 ms en rechazo) se nota y se
  desactiva con `haptics_enabled`. → capturas `adb exec-out screencap` y log en la evidencia.
- [ ] AC4 (safe area real y D27.3) Given cada teléfono probado (≥ 1; con barra de gestos y sin ella si el
  sistema lo permite), Then el log registra tamaño de pantalla y `DisplayServer.get_display_safe_area()`;
  ningún control, texto ni ticket queda fuera de la safe area y los botones están a ≥ 48 px (a 1080) de su
  borde (`controles-tactiles.md` AC17, también con muesca superior, pregunta 6); con una caja con contador
  en los pasaplatos 04-06 y el activo en cada olla (plaza z −3,1 y z −3,4), se mide el solape del contador
  con la zona de botones: con safe area inferior nula ≤ 8 px (D27), y con safe area inferior > 0 se compara
  con 21-23 px y 51 px a 1080 escalados al alto del teléfono (D27.3); si lo supera, hallazgo para el
  responsable. → capturas y tabla en la evidencia.
- [ ] AC5 (criterios solo de teléfono) Given la densidad real del teléfono (ppi), Then el botón de acción
  mide ≥ 72 dp y los de cambiar y pausa ≥ 48 dp en milímetros (dp = px × 160 / ppi), y el texto mínimo de
  36 px a 1080 se mide en mm de altura de la «x»; el responsable responde en la evidencia las preguntas 3
  (patrón de háptica), 4 (¿36 px basta en un 6"?) y 6 (muesca) de `controles-tactiles.md`. → tabla en la
  evidencia.

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
