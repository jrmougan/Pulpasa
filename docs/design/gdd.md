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
1. Aparecen comandas (tickets) con el pulpo y su condimento.
2. Se coge un pulpo de la caja de almacén y se **corta sobre la caja** (D1).
3. Se **cuece** en el caldero hasta que esté cocido.
4. Se **condimenta** (D4) la caja con el pulpo cocido.
5. Se **entrega** en el puesto de la comanda; se valida y puntúa (D2).
6. A los 5 minutos (D5) acaba la partida: recaudación y 0–3 estrellas.

## 3. Decisiones de diseño aplicadas

| # | Decisión | Cómo queda en el GDD de trabajo |
|---|----------|----------------------------------|
| D1 | Corte sobre la caja | No hay estación de corte. El corte es una acción sobre la caja que lleva el jugador (como el prototipo). La «zona de preparación con mesas para cortar» del original pasa a ser mesa de apoyo/entrega. Ver `features/corte-pulpo.md` |
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
| Preparación | Secundaria | Cortar el pulpo sobre la caja (D1) |
| Cocción | Secundaria | El pulpo crudo se cuece en el caldero; temporizador visible; solo cocido es válido |
| Condimentación | Secundaria | Decisiones sí/no (D4) aplicadas a la caja |
| Dificultad | Sistema | La cadencia de comandas aumenta con el tiempo transcurrido |
| Valoración | Sistema | Recaudación + estrellas (D2) |

### Comandas
Una comanda = pulpo + condimento pedido (pimentón dulce/picante, sal sí/no, aceite sí/no, cachelos
sí/no) + tiempo máximo. Una caja entregada es válida solo si coincide exactamente con alguna comanda
del puesto de entrega (tipo de caja, pulpo cocido y cortado, y todos los condimentos pedidos).

### Controles
Teclado y ratón + mando Xbox (Should). Jugador 1 y 2 con esquemas separados en `InputMap`.

## 5. Nivel de la alpha (un nivel)
Una romería con un puesto semiabierto sobre terreno de tierra y césped. Zonas:
- **Almacén**: cajas con pulpo crudo, cachelos, sal, aceite, pimentón dulce y picante.
- **Cocción**: caldero de cobre.
- **Condimentación y entrega**: aplicar condimentos y entregar en los puestos de comanda.
- Mesas de apoyo para dejar objetos.

**Objetivo del nivel (corregido, D7):** conseguir la mayor recaudación posible en 5 minutos sirviendo
comandas dentro de su plazo, y alcanzar al menos 1 estrella. El nivel enseña en este orden: coger/soltar,
cortar, cocer, condimentar, entregar y coordinarse.

## 6. Alcance de la alpha (MoSCoW)

**Must (8)** — sin ellas no hay alpha jugable:
1. `features/movimiento-e-interaccion.md`
2. `features/corte-pulpo.md`
3. `features/coccion-pulpo.md`
4. `features/condimentacion.md`
5. `features/comandas.md`
6. `features/entrega-y-puntuacion.md`
7. `features/partida-5-min.md`
8. `features/jugadores-y-cambio.md`

**Should** (entran si el tiempo lo permite):
- `features/dificultad-progresiva.md`
- `features/audio-y-fx.md`
- `features/eventos-de-entorno.md` (gaiteros)
- `features/mando-y-reasignacion.md` (Xbox)

**Could**: habilidades distintas por personaje (John Cea, Bill Gatos, Vanessa Poconcho, Natalie Newport),
barro que resbala, selección de personaje, localización galego/castelán, idioma inglés.

**Won't (alpha)**: multijugador online, móvil, cinemáticas de inicio/final, más de un nivel, niveles de
sal/aceite «poco/mucho», combate o golpes entre jugadores, bebidas (`DrinkSO` del prototipo), tienda/DLC.

## 7. Presentación y tono
Cartoon low-poly colorido; toldo blanco, madera, platos de madera. Humor satírico sobre la
globalización (franquía vs. pulpeiros tradicionales). Textos de la alpha en castellano; galego como Could.

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

## 9. Preguntas abiertas
1. **Estrellas**: umbrales exactos de recaudación para 1/2/3 estrellas (propuesta provisional en
   `entrega-y-puntuacion.md`, hay que validarla jugando).
2. **Comanda caducada**: ¿desaparece el ticket y penaliza una sola vez, o bloquea el puesto unos segundos?
3. **Caja mal entregada**: ¿se devuelve al jugador, se descarta, o penaliza?
4. **Cachelos**: ¿se cuecen también en el caldero o son un ingrediente listo? (el prototipo no los modela;
   se asume ingrediente listo hasta decidir).
5. **Caldero**: ¿admite un pulpo a la vez (prototipo) o varios en la alpha?
6. **Puestos de entrega**: ¿cuántos hay en el nivel y cada comanda se asigna a un puesto (prototipo) o a cualquiera?
7. **Modo individual**: ¿el cambio de personaje es una tecla fija o cambia al más cercano al objetivo?
8. **Modelos Pandazole (D6)**: ¿se usan o se sustituyen? Afecta a asset-pipeline, no a las features.
9. **Dificultad progresiva** (Should): ¿intervalo de comandas decreciente o más comandas simultáneas?
