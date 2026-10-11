# Tutorial breve (Should; D25)

**Slug:** tutorial-breve

## Descripción
Con D25 el tutorial enseña **solo la fase 1** (`dificultad-progresiva.md`): una sola receta, «Á feira»
(pulpo + aliño dulce, sin cachelos). El aliño picante y los cachelos se descubren en las fases 2 y 3
de la partida, con su comanda en el ticket. El cubo de basura se menciona al paso en el paso 4.

## Criterios de aceptación
- **AC1** *(reescrito por D25)* Given la primera partida, Then se muestran 6 pasos en orden: coger pulpo, cocer, cortar sobre la caja única (6 pulsaciones), aliñar con el aliño dulce (una pulsación; si te equivocas de aliño, pulsa el otro), entregar, cooperar. No se mencionan cachelos, aliño picante ni tamaños de caja.
- **AC2** Given cada paso, When se completa la acción, Then avanza al siguiente en ≤ 0,5 s.
- **AC3** Given la tecla «Saltar», Then el tutorial termina y no vuelve a aparecer en el perfil.
- **AC4** Given el tutorial completo, Then dura ≤ 90 s con comandas de 90 s de paciencia y sin penalización.
- **AC5 (D25)** Given el tutorial, Then la única comanda que genera es «Á feira» y las comandas del tutorial usan una configuración de fase 1 (aliño dulce, sin cachelos). *Test:* `test_tutorial.gd`.
- **AC6 (D25)** Given el paso de aliñar, When el jugador pulsa el aliño picante, Then el paso no avanza, la caja pasa a picante y el texto del paso le indica que el dulce sustituye al picante (sin penalizar, sin cubo obligatorio). *Test:* `test_tutorial.gd`.
- **AC7 (D26, el tutorial enseña el verbo)** Given cada uno de los 6 pasos, Then el panel del paso muestra el **icono del verbo** que toca (COGER, COCER, CORTAR, ALIÑAR DULCE, —entrega por zona: sin verbo, se señala la zona iluminada—, y para el paso 6 el botón de cambiar), igual que el prompt del mundo, y el objetivo del paso se resalta. En el paso de cortar, el texto dice que se puede **mantener pulsado** como atajo (pulsar 6 veces sigue valiendo). *Test:* `test_tutorial.gd`.
- **AC8 (D26, móvil)** Given el perfil táctil, Then el paso 1 señala el stick flotante y el botón de acción (con la mano vacía y sin objetivo, gris); el panel usa texto ≥ 36 px a 1080 de alto y el botón «Saltar» mide ≥ 120 px de alto; el paso de cooperar se sustituye por «cambia de personaje» (Individual; no hay Local 2P en móvil). *Test:* `test_tutorial.gd` + `test_ui_scale.gd`.
- **AC1' (D26, matiz)** El paso «entregar» enseña la **zona iluminada** («entra con la caja correcta en la zona del puesto»); el puesto ya no se pulsa. *Test:* `test_tutorial.gd`.
