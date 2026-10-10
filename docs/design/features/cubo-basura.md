# Cubo de basura (Must, D25)

**Slug:** cubo-basura · **Prototipo:** ninguno (nuevo en D25). Sustituye la propuesta de GDD §10
«Devolver la caja errónea a su origen».

## Descripción
Con el aliño sin quitar (D25) y la caja única, el error se arregla **tirando**: una caja mal
aliñada, un pulpo equivocado o unos cachelos que sobran van al **cubo**. Hay **2 cubos**: uno en la
**cocina** y otro en el **lado de servicio, cerca del rack**, ninguno pegado a una estación o spawner
(ollas, nevera, rack…) para no competir con ellos como objetivo al llevar algo en la mano. Las
posiciones concretas y su razón están en el contrato (ADR-003 §10 y `scene-tree.md`, PUL-111). Los dos
aceptan todo. El cubo es objetivo **solo con algo en la mano**; pulsar interactuar lo **destruye** y
la mano queda vacía. **Sin penalización** (`trash_penalty` = 0, en datos): tirar cuesta el tiempo de
rehacer, no puntos. El pulpo **quemado** se sigue desechando en la olla (`olla-que-se-pasa.md`).

| Lo que lleva en la mano | ¿El cubo es objetivo? | Resultado |
|---|---|---|
| Nada | No (no se resalta) | — |
| Caja (vacía, a medias o llena, con lo que lleve) | Sí | Caja destruida y liberada del rack/pool |
| Pulpo crudo o cocido (entero o a medias) | Sí | Pulpo destruido |
| Cachelos (crudos o cocidos) | Sí | Cachelos destruidos |

Los cachelos **ya repuestos en el cuenco** no se tiran (se quitan de una caja pulsando el cuenco y
vuelven al cuenco, D23). Lo que haya en un pasaplatos se recoge primero.

```
  COCINA: 1 cubo, apartado de ollas y nevera      SERVICIO: 1 cubo, cerca del rack pero sin pegarse
  Posiciones exactas: scene-tree.md. Ambos a ≥ 1,5 m de cualquier pasaplatos y del hueco
```

## Criterios de aceptación
- **T1** Given una caja llena y condimentada en la mano a ≤ 1,5 m de un cubo, When pulsa interactuar, Then la mano queda vacía en el mismo frame, la caja se libera (no queda nodo huérfano), se emite `trashed` 1 vez y la recaudación no cambia. *Test:* `test_trash_bin.gd`.
- **T2** Given pulpo crudo, pulpo cocido o cachelos en la mano, When pulsa interactuar frente al cubo, Then ocurre lo mismo que en T1 con ese objeto. Given un pulpo quemado en la olla, Then el cubo no lo ve (sigue desechándose en la olla con la mano vacía). *Test:* `test_trash_bin.gd`.
- **T3** Given la mano vacía, When el jugador está a ≤ 1,5 m del cubo, Then el cubo no es objetivo (no se resalta, pulsar no hace nada y no suena ningún cue). *Test:* `test_trash_bin.gd` (candidatos del detector).
- **T4** Given una tirada, Then suena 1 cue `trash` (ni 0 ni 2) y hay una respuesta visual (tapa que se sacude o puf) de ≥ 0,3 s. *Test:* `test_trash_bin.gd` (contador del servicio de audio y estado del efecto) + captura.
- **T5** `trash_penalty` vive en datos con valor 0 (`TrashBinData` en `data/config/trash_bin.tres`); aplicar > 0 requiere enmienda de contrato (nota de contrato: el cubo no lo aplica en la alpha). Given el dato, Then `trash_penalty` = 0 y, tras una tirada, la recaudación no cambia. *Test:* test de datos + `test_trash_bin.gd`.
- **T6** Given `level_01.tscn`, Then hay exactamente 2 cubos; cada uno está a ≥ 1,5 m de cualquier pasaplatos y del hueco de la barra, el hueco conserva ≥ 1,0 m libre de paso, y ninguno queda bajo el HUD a 1280×720. *Test:* `test_level_01.gd` (distancias) + captura a 1280×720.
- **T7** Given una caja errónea en la mano frente a un puesto, When el jugador va al cubo, tira y rehace una caja correcta, Then no se emitió `delivery_rejected`, la recaudación no bajó y la comanda sigue viva (tirar no consume ni rechaza la comanda). *Test:* `test_trash_bin.gd` + `test_order_stand.gd`.
- **T8** Given un jugador con algo en la mano a ≤ 1,5 m de un cubo y de un pasaplatos libre a la vez, Then solo uno es objetivo (el más cercano al frente del jugador) y no se resaltan los dos. *Test:* `test_trash_bin.gd` con el detector real.
- **T9** Given Local 2P, When J1 y J2 tiran a la vez en el mismo cubo, Then ambos objetos se destruyen, se emiten 2 `trashed` y suenan 2 cues `trash` (uno por tirada). *Test:* `test_trash_bin.gd`.

## Datos (`.tres`)
`TrashBinData` (`data/config/trash_bin.tres`): `trash_penalty` (0; ver T5). Posiciones de los cubos
en `level_01.tscn` (`TrashBinKitchen`, `TrashBinService`). Qué se puede tirar (todo lo que se
puede llevar en la mano) lo fijan los contratos, no los datos.

## Verificación
GUT para T1–T3, T5, T7–T9 (núcleo de la regla + estación instanciada con el detector real); T6 por test
de nivel con distancias y captura; T4 con captura de la respuesta visual en `docs/evidence/<ficha>/`.

## Preguntas abiertas
1. **Cubo de cachelos en cocina vs. servicio.** Los cachelos sobrantes están en la cocina; si el
   playtest muestra que se tiran en el cubo equivocado no se cambia la regla (los dos cubos aceptan todo).
2. **Recuperar lo tirado.** No se recupera nada. Un coste (`trash_penalty` > 0) exige además una
   enmienda de contrato: hoy el cubo no resta recaudación.
