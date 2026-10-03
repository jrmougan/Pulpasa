# GDD de trabajo — PulpaSA (alpha)

Resumen operativo en castellano del GDD original (`pulpasa_docs/main.tex`, gallego, solo lectura).
Aplica las decisiones cerradas de `decisions.md` (D1–D7), que mandan sobre el original. Las erratas
del original se corrigen **solo aquí** (D7); `main.tex` no se toca.

## 1. Visión
Cooperativo de cocina para PC, inspirado en Overcooked pero con recetas más simples. Los jugadores
trabajan en un puesto ambulante («carro del pulpo») de una franquía norteamericana de comida rápida
que quiere conquistar las romerías gallegas. Cámara cenital, 3D cartoon low-poly.

Pilares: **caos cooperativo**, **identidad gallega**, **recetas más simples que Overcooked**.

## 2. Bucle de juego
Flujo del prototipo, que se mantiene por D1 (ver `roadmap.md`):
1. Aparecen comandas (tickets) con el condimento pedido y su barra de paciencia.
2. Se coge **pulpo crudo** de la nevera.
3. Se **cuece** en la olla (el pulpo entra crudo).
4. El jugador lleva el pulpo **cocido** y lo **corta sobre una caja** (D1): cada pulsación llena la
   caja y gasta pulpo.
5. Se **condimenta** (D4) la caja llena.
6. Se **entrega** en el puesto de la comanda; se valida y puntúa (D2).
7. A los 5 minutos (D5) acaba la partida: recaudación y 0–3 estrellas.

## 3. Decisiones de diseño aplicadas

| # | Decisión | Cómo queda en el GDD de trabajo |
|---|----------|----------------------------------|
| D1 | Corte sobre la caja | No hay estación de corte. El jugador lleva el pulpo cocido y lo corta sobre la caja (como el prototipo). La «zona de preparación con mesas para cortar» del original pasa a ser mesa de apoyo/entrega. Ver `features/corte-pulpo.md` |
| D2 | Recaudación + 0–3 estrellas | Puntos por comanda = base de la receta + bonus por tiempo restante − penalización por comanda caducada. Estrellas por umbrales de recaudación en datos. Sustituye al ratio «cajas/minuto» del prototipo. Ver `features/entrega-y-puntuacion.md` |
| D3 | Modo individual = cambio de personaje | Un jugador controla un personaje y cambia al otro (< 0,2 s); el no controlado se queda quieto. Sustituye al «control simultáneo de 2 NPC» del original, imposible con un solo mando. Ver `features/jugadores-y-cambio.md` |
| D4 | Condimento sí/no | Pimentón dulce **o** picante; sal sí/no; aceite sí/no; cachelos opcionales (sí/no). Se eliminan los niveles «poco/normal/mucho» del original. Ver `features/condimentacion.md` |
| D5 | Partida de 5 min | 300 s, configurable en datos. Sustituye «5 a 10 minutos» (original) y los 180 s del prototipo. Ver `features/partida-5-min.md` |
| D6 | Repo privado | Puede que no se usen los modelos de Pandazole; si se usan, pueden versionarse. El diseño no depende de ningún asset concreto: se usan placeholders (primitivas) hasta decidirlo |
| D7 | Erratas solo aquí | Ver §8 |

## 4. Mecánicas

| Mecánica | Tipo | Regla (alpha) |
|----------|------|---------------|
| Atender comandas | Primaria | Máx. 4 comandas activas; cada una con límite de tiempo (paciencia) |
| Coordinación cooperativa | Primaria | 2 jugadores locales comparten el puesto; sin combate (ver §8) |
| Cocción | Secundaria | El pulpo **crudo** se cuece en la olla; temporizador visible; solo el cocido se puede cortar |
| Corte | Secundaria | El pulpo **cocido** se corta sobre la caja (D1): cada pulsación llena la caja y gasta pulpo |
| Condimentación | Secundaria | Decisiones sí/no (D4) aplicadas a la caja |
| Dificultad | Sistema | La cadencia de comandas aumenta con el tiempo transcurrido |
| Valoración | Sistema | Recaudación + estrellas (D2) |

### Comandas
Una comanda = pulpo + condimento pedido (pimentón dulce/picante, sal sí/no, aceite sí/no, cachelos
sí/no) + tiempo máximo (paciencia, 40–90 s en datos). Una caja entregada es válida solo si coincide
exactamente con alguna comanda del puesto de entrega (tipo de caja, caja llena de pulpo y todos los
condimentos pedidos, sin extras).

### Controles
Teclado + mando Xbox (Must): teclado y mando, o dos mandos. El flujo menú → game over es completable sin teclado. Jugador 1 y 2 con esquemas separados en `InputMap`.

## 5. Nivel de la alpha (un nivel)
Una romería con un puesto semiabierto sobre terreno de tierra y césped. Zonas:
- **Almacén (nevera)**: pulpo crudo, cachelos, sal, aceite, pimentón dulce y picante.
- **Cocción**: olla/caldero de cobre.
- **Condimentación y entrega**: aplicar condimentos y entregar en los puestos de comanda.
- Mesas de apoyo para dejar objetos.

**Objetivo del nivel (corregido, D7):** conseguir la mayor recaudación posible en 5 minutos sirviendo
comandas dentro de su plazo, y alcanzar al menos 1 estrella. El nivel enseña en este orden: coger/soltar,
cocer, cortar, condimentar, entregar y coordinarse.

## 6. Alcance de la alpha (MoSCoW aprobado)
Alineado con «Alcance aprobado de la alpha» de `roadmap.md`.

**Must** (cada punto del roadmap → feature):
1. Paridad con Unity sin sus bugs → `features/paridad-unity.md`
2. Ciclo de comandas sin bugs; 8. comanda reducida (D4) con iconos en el ticket; 3. paciencia → `features/comandas.md`
4. Puntuación y objetivo (D2) → `features/entrega-y-puntuacion.md`
5. Coop local 2P y mando Xbox → `features/jugadores-y-cambio.md` y `features/mando-y-reasignacion.md`
6. Modo individual con cambio (D3) → `features/jugadores-y-cambio.md`
7. Menú principal (Individual / Local 2P / Salir) → `features/menu-principal.md`
8. Condimentos D4 → `features/condimentacion.md`
9. Feedback mínimo (efectos, música, ambiente) → `features/audio-y-fx.md`

Soporte del flujo Must (también Must): `features/movimiento-e-interaccion.md`,
`features/coccion-pulpo.md`, `features/corte-pulpo.md`, `features/partida-5-min.md`.

**Should**: olla que se pasa (`features/olla-que-se-pasa.md`), dificultad por fases
(`features/dificultad-progresiva.md`), opciones de volumen (`features/opciones-de-volumen.md`),
textos en gallego (`features/textos-gallego.md`), tutorial breve (`features/tutorial-breve.md`).

**Could**: barro, gaiteros (`features/eventos-de-entorno.md`), 2 personajes con
habilidad, lavado de platos.

**Won't (alpha)**: mapa de niveles, online, 4 personajes, NPC animados, móvil; además cinemáticas,
niveles de sal/aceite «poco/mucho», combate entre jugadores, bebidas (`DrinkSO`), tienda/DLC.

## 7. Presentación y tono
Cartoon low-poly colorido; toldo blanco, madera, platos de madera. Humor satírico sobre la
globalización (franquía vs. pulpeiros tradicionales). Textos de la alpha en castellano; galego como Should (`features/textos-gallego.md`).

## 8. Erratas corregidas respecto a `main.tex` (D7)
1. **«Se permite atacar enemigos con un arma o golpe cuerpo a cuerpo»** (tabla de mecánicas,
   «Coordinación cooperativa»): texto copiado de otro juego. No hay enemigos ni combate. La regla pasa a:
   «los jugadores comparten ingredientes y puesto y se pasan objetos para servir a tiempo».
2. **Objetivo del nivel confuso** («as comandas serán o resultado da ausencia presencia de cachelos,
   patacas, pementou ou sal»): «patacas» y «cachelos» son lo mismo; «pementou» es «pimentón»; «ausencia
   presencia» es ambiguo. Pasa a la definición de §4 (Comandas) y al objetivo del §5.
3. **Corte en «zona de preparación con mesas»** contradice el prototipo: se corta sobre la caja (D1).
4. **«Sal/aceite: nada, poco, normal, mucho»** contradice D4: es sí/no.
5. **Modo individual con «2 NPC» simultáneos**: sustituido por cambio de personaje (D3).
6. **Duración «5 a 10 min»**: fijada en 5 min (D5).
7. **Plataforma/motor «Unity 6, C#»**: ahora Godot 4.7.2 y GDScript (decisiones técnicas T1–T2).
8. **Pimentón «pementa, … etc.»** en tabla de mecánicas: condimentos cerrados en D4.

## 9. Reglas vigentes de paridad con Unity
Defaults del prototipo que se mantienen (no son preguntas abiertas). Cualquier cambio va a la sección 10.
- **Caja errónea**: al entregar una caja que no coincide, se conserva en el puesto/mano y no hay penalización
  (`OrderStand`); solo la comanda caducada penaliza.
- **Olla**: admite una cocción a la vez (`KitchenStation`, `isBusy`).
- **Asignación por puesto**: cada comanda pertenece a un puesto de entrega y solo se valida ahí (`OrderSystem`, `deliverySlotId`).
- **Reposición inmediata**: al entregar con éxito (o caducar) se pide otra comanda para ese puesto en el acto
  (`OrderTicketUIController.OnClearTicket`), hasta `max_active_orders` = 4.
- **Corte**: por pulsación, con `fill_per_press` según el tipo de caja (Small 0,2 / Medium 0,1 / Large 0,05).
- **Cocción**: sin quemado (el quemado es el Should `olla-que-se-pasa`).

## 10. Propuestas para gate humano
Cambios sobre los defaults de arriba que NO rigen hasta aprobarse:
1. Penalizar o devolver la caja errónea.
2. Olla con capacidad > 1.
3. Asignar la comanda a cualquier puesto.
4. Corte por «mantener pulsado» en vez de pulsar.

## 11. Preguntas abiertas
1. **Estrellas**: umbrales exactos de recaudación para 1/2/3 estrellas (provisional en
   `entrega-y-puntuacion.md`; validar jugando).
2. **Cachelos**: ¿se cuecen en la olla o son ingrediente listo? (el prototipo no los modela; se asume listo).
3. **Modo individual**: ¿cambio con tecla fija o al personaje más cercano al objetivo?
4. **Modelos Pandazole (D6)**: ¿se usan o se sustituyen? Afecta a asset-pipeline, no a las features.
5. **Fases de dificultad**: valores provisionales de `dificultad-progresiva.md` (límites de fase, puestos activos, `max_time`) a validar en playtest.
6. **Número de puestos de entrega** del nivel: 4 asumidos por `max_active_orders`; confirmar con el inventario (PUL-001).
