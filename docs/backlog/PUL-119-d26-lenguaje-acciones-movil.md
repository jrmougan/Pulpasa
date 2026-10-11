---
id: PUL-119
title: Registrar D26 (lenguaje de acciones y móvil) y poner el diseño al día
status: done
milestone: M3e
role: game-designer
deps: []
orca_task: null
unity_sources: []
owns: [docs/design/decisions.md, docs/design/roadmap.md, docs/design/gdd.md, docs/design/level-layouts.md, docs/design/m3d-gate.md, docs/design/features/**, docs/evidence/PUL-119/**, docs/backlog/PUL-119-d26-lenguaje-acciones-movil.md]
touches_scenes: []
---

## Target
Diseño (`docs/design/`). Tras el playtest de M3d (2026-10-11) el responsable dice: «sigo viendo problemas de
diseño de UI, porque no se distinguen muy bien las acciones, y esto es crítico si quiero llevar el juego a
teléfonos móviles». Encargó un estudio a un equipo de agentes (QA empírico, diseño UX, auditoría técnica de UI)
y autorizó implementar los cambios de UI/UX y de mecánicas necesarios. Diagnóstico común de los tres:
el contorno solo dice «esto es objetivo», no «esto va a pasar»; hay pulsaciones sin respuesta (cortar con
pulpo crudo, 7.º corte, mismo aliño, caja que no encaja); los dos aliños no se distinguen; el objetivo depende
de la orientación sin pista; el jugador tapa lo que apunta; «listo / quemándose / lleno» casi sin señal; varios
cues comparten el mismo sonido; y el juego no tiene escalado ni controles táctiles.

## Change
Registrar **D26** en `decisions.md` (y nota en `roadmap.md`: móvil pasa de Won't a alcance de la alpha, solo
Individual) y reflejarla en GDD y features. Contenido decidido por el producer con autorización del responsable:

1. **Lenguaje de verbos.** Cada pulsación con objetivo tiene un verbo visible antes de pulsar: COGER, SOLTAR,
   COCER, CORTAR, ALIÑAR DULCE, ALIÑAR PICANTE, CACHELOS, TIRAR (incluye desechar el quemado). Silueta propia
   por verbo (distinguibles en gris a 64 px), no solo color.
2. **Prompt de acción.** Un único icono del verbo sobre el objetivo activo de cada jugador, sobre placa oscura,
   ≥ 64 px a 1080 de alto. Estados: OK (blanco) y BLOQUEADO (ámbar con ×, con icono de motivo: caja a medias,
   ocupado, vacío, lleno, ya aplicado). Un objetivo cuya pulsación no haría nada no se resalta ni muestra prompt
   (fin de los `can_interact` que «consumen sin hacer nada»), salvo que el motivo sea útil (BLOQUEADO).
3. **Ninguna pulsación muda.** Toda pulsación con objetivo da exactamente una respuesta ≥ 0,3 s: éxito (el icono
   salta + cue propio) o rechazo (× + motivo + sacudida + cue de error único). Cues con sonido distinto para
   tirar, cocción lista, aviso de quemado, caja llena y cambio de personaje.
4. **Objetivo estable.** Histéresis: un candidato sustituye al activo solo si lo supera en `hysteresis_margin`
   (20 %, en datos) o si el activo deja de ser válido.
5. **Simplificaciones de mecánica.**
   - Cuenco: con caja llena solo **pone** cachelos; si ya lleva, BLOQUEADO «ya lleva» (lo mal hecho, al cubo,
     como el aliño en D25). Se va el toggle y su antirrebote.
   - Entrega: **solo automática por zona** iluminada. El puesto deja de ser objetivo de la pulsación; una caja
     que no encaja no enciende la zona y no penaliza (modifica D8: la penalización de caja errónea desaparece; la
     caja errónea se tira).
   - Corte: mantener pulsado repite el corte cada `cut_repeat_interval` (0,2 s, datos) como atajo; pulsar sigue
     valiendo (D13 se mantiene: es atajo, no mecánica). Contador visible N/6 sobre la caja.
6. **Estado legible en el mundo.** Barras de cocción y corte legibles a escala móvil (anillo o barra ≥ 8 px de
   grosor a 1080), aviso de quemado claro (parpadeo ámbar/rojo + cue) ≥ 3 s antes de quemarse; raciones del
   cuenco legibles; anillo del personaje activo distinto del inactivo.
7. **Iconografía.** Icono propio para el aliño picante (dispensador, ticket y pegatina) distinguible sin color;
   rack y caja sin letras S/M/L; HUD sin «Cajas / minuto» (texto vigente con D25).
8. **Móvil (solo Individual con cambio de personaje).** Apaisado. Controles táctiles: stick flotante en la
   mitad izquierda, botón de acción ≥ 72 dp que muestra el icono del verbo del objetivo (gris sin objetivo,
   ámbar si BLOQUEADO), botones de cambiar y pausa ≥ 48 dp; multitáctil. Perfil de cámara móvil con más zoom
   (≥ 120 px por metro a 1080 de alto) y seguimiento suave del personaje activo. UI escalada: texto ≥ 36 px a
   1080 de alto, tickets sin recortar con 4 comandas, HUD fuera de la zona del stick y respetando safe area.
   Local 2P sigue siendo de PC/mando. Export Android y renderizador móvil: fuera de esta oleada (ficha aparte
   cuando haya toolchain y dispositivo).

D26 modifica D8 (penalización de caja errónea), D23/D25 (toggle de cachelos en el cuenco) y aclara D13.
Fecha: 2026-10-11.

## Constraints
- Mapa completo mano × objetivo → verbo/estado (tabla) en `features/movimiento-e-interaccion.md` o feature
  nueva `features/lenguaje-acciones.md`: es la especificación que implementarán las estaciones y que el test
  exhaustivo comprobará (≥ 40 combinaciones).
- Feature nueva `features/controles-tactiles.md` (y perfil de cámara/escala) con criterios Given/When/Then
  medibles (px a 2340×1080 y 1080 de alto, dp con 1 dp ≈ 2,5 px a 1080).
- Actualizar las features afectadas (estacion-condimentos, corte-pulpo, entrega-y-puntuacion, coccion-pulpo /
  olla-que-se-pasa, audio-y-fx, jugadores-y-cambio, tutorial-breve, mando-y-reasignacion, hud) marcando lo
  superado como superado, sin borrar.
- Sin código ni contratos (`docs/arch/` es de PUL-120, en paralelo).

## Acceptance
- [x] AC1 D26 en `decisions.md` con notas cruzadas en D8, D13, D23, D25; `roadmap.md` con móvil en alcance
- [x] AC2 Tabla mano × objetivo → verbo/estado/motivo completa y sin huecos
- [x] AC3 Feature de controles táctiles, cámara móvil y escala de UI con ACs medibles
- [x] AC4 Features afectadas al día (cuenco solo pone, entrega solo por zona, corte con mantener + contador, cues)
- [x] AC5 Iconos: lista de verbos y motivos con descripción de silueta para el asset-pipeline

## Plan
1. Leer ficha, estudio (`docs/evidence/PUL-119/README.md`), decisiones, GDD, features y el código de las
   estaciones (`can_interact`/`interact`, `InteractionComponent`) para que la tabla refleje lo que
   hacen hoy las pulsaciones y no invente casos.
2. `decisions.md`: fila D26 + notas cruzadas en D8, D13, D23 y D25. `roadmap.md`: fila M3e, Must 10 y 11,
   móvil fuera de Won't.
3. Feature nueva `features/lenguaje-acciones.md`: vocabulario (8 verbos, estados, 6 motivos), prompt,
   respuesta, histéresis, SOLTAR sin objetivo, tabla mano (M0…M9) × objetivo (A–F), estado en el mundo,
   lista de iconos, 21 AC, datos.
4. Feature nueva `features/controles-tactiles.md`: stick, botones, multitáctil, cámara móvil, escala de
   UI y maquetación a 2340×1080 y 1920×1080, 21 AC medibles en px.
5. Actualizar features afectadas (marcando lo superado sin borrar): movimiento-e-interaccion,
   estacion-condimentos, condimentacion, corte-pulpo, entrega-y-puntuacion (incluye HUD), coccion-pulpo,
   olla-que-se-pasa, audio-y-fx, jugadores-y-cambio, tutorial-breve, mando-y-reasignacion,
   menu-principal, partida-5-min, comandas, cubo-basura, textos-gallego; y `gdd.md`, `level-layouts.md`,
   `m3d-gate.md`.

## Evidence
Solo diseño; sin código ni capturas nuevas. Entregables:
- `docs/design/decisions.md` (D26; notas en D8, D13, D23, D25) y `docs/design/roadmap.md`.
- `docs/design/features/lenguaje-acciones.md`: tabla mano × objetivo (10 manos × 9 familias de objetos;
  >250 combinaciones con las variantes de estado), 8 verbos, 6 motivos y la lista de iconos con silueta
  (AC2, AC5).
- `docs/design/features/controles-tactiles.md` (AC3).
- Features y documentos al día (AC4) enumerados en el Plan.
- Decisiones de concreción tomadas por el diseñador (no cambian el contenido de D26): motivo extra
  `sin cocer` (cortar con pulpo crudo), BLOQUEADO `caja a medias` también en el cuenco, prompt SOLTAR en
  el punto de soltar, contorno blanco cálido en vez de amarillo, `wrong_delivery_penalty` = 0, mantener
  repite solo si el verbo inicial es CORTAR. Nombres de cues y recursos marcados *(propuesta)*, a decidir
  por PUL-120.
- Preguntas abiertas en `lenguaje-acciones.md` (soltar al suelo por accidente, dispensador desde el lado
  de pase, háptica) y `controles-tactiles.md` (zurdos, tamaño ajustable, 36 px a 420 ppi).
