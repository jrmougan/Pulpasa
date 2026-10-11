# Menú principal por modo (Must)

**Slug:** menu-principal · **Prototipo:** `MainMenu`.

## Descripción
Tres opciones: **Individual**, **Local 2P** y **Salir**. Cada modo lleva al nivel con la configuración correcta.

## Criterios de aceptación
- **AC1** Given el menú, When se pulsa «Individual», Then el nivel carga en ≤ 3 s con `mode = SINGLE` (1 jugador + cambio, D3).
- **AC2** Given el menú, When se pulsa «Local 2P», Then el nivel carga en ≤ 3 s con `mode = COOP_2P` y 2 personajes controlados por jugadores distintos.
- **AC3** Given el menú, When se pulsa «Salir», Then el proceso termina en ≤ 1 s con código 0.
- **AC4** Given un mando conectado, When se navega por el menú, Then las 3 opciones son seleccionables y activables sin teclado.
- **AC5** Given el foco inicial, Then está en «Individual».
- **AC6 (D26, perfil táctil)** Given el perfil táctil (móvil), Then el menú ofrece **solo «Individual»** (Local 2P es de PC/mando y «Salir» no es una acción móvil), con foco inicial en él; los botones miden ≥ 120 px de alto con 24 px entre ellos y el texto ≥ 36 px a 1080 de alto; Given el perfil de escritorio, Then se mantienen los tres botones (AC1–AC5). *Test:* `test_main_menu_touch.gd` (= `controles-tactiles.md` AC1 y AC18).

## Datos
`mode` como enum compartido por el nivel; textos en el sistema de traducción.

## Verificación
GUT sobre la selección de modo; MCP con input simulado y captura (AC4–AC5).
