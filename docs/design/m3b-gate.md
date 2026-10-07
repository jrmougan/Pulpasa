# Puerta humana de M3b: estética v2

Revisión visual de la estética v2 (biblia `docs/art/art-bible.md` v2, PUL-072..089) frente a la
referencia elegida. Lo medible ya está en `docs/evidence/PUL-087/` (rendimiento, partidas sin
errores, luminancia y lista de desajustes D1–D9). Esta sesión la hace **el responsable**: mira,
juega una ronda y decide. Unos 20 minutos.

## Antes de empezar
1. Abre a la vez `docs/art/style-refs/referencia-elegida-2026-10-06.png` y
   `docs/evidence/PUL-087/ac1_comparativa_nivel.png` (referencia / v1 / progreso / después).
2. Juega una ronda en **Individual** y otra en **Local 2P** a pantalla completa (1080p) desde el
   menú. Con audio, si quieres oírlo.

## Qué mirar frente a la referencia
| Zona | Mira | Pregunta |
|---|---|---|
| Conjunto | Luz, color y contraste (D4) | ¿Más oscuro y menos amarillo, como la referencia, o así? |
| Cocina | Tanque, cocedores, sacos (D2, D3) | ¿Se ve que las ollas cuecen? ¿La tapa abierta molesta? |
| Encimeras | Acero de la fila delantera (D7) | ¿Brilla demasiado frente al gris mate de la referencia? |
| Condimentos y bandejas | Pegatinas, botes, rack | ¿Distingues los 5 condimentos y la sal sin dudar? |
| Kioscos | Rótulo `#1`/`#2` sobre el toldillo (D1) | ¿Lees la comanda de cada puesto de un vistazo? |
| Fondo | Muro de granito, comensales, árboles, bombillas | ¿Se siente romería gallega? ¿Distrae de lo jugable? |
| Encimeras vacías | Lo jugable limpio (biblia §5) frente a la referencia cargada de atrezo | ¿Falta vida en las encimeras o está bien así? |
| HUD | Panel «Turno» y tickets (D8) | ¿Tapan algo que te importe? |
| Estados | Pulpo crudo / cocido / quemado, bandeja llena | ¿Se distinguen sin leer la barra? |

## Qué anotar
Para cada fila: **ok / cambiar / dudas**, y una línea si es «cambiar». Además:
- D1–D9 de `docs/evidence/PUL-087/README.md`: cuáles se arreglan antes de la alpha y cuáles no.
- Si aceptas el ajuste de ambiente propuesto en D4 (`render_config.tres`).
- Si se hace la ficha de pipeline D5+D6 (materiales y texturas compartidos; no afecta a los fps).
- Tilt-shift (D22, apagado por defecto): pruébalo poniendo `tilt_shift_enabled = true` en
  `godot/data/config/render_config.tres`, juega un rato y deshaz el cambio; ¿se queda apagado?

Rendimiento: no hace falta mirarlo; a 1080p va a ~420 fps (GPU 1,3 ms) con todo activo.
