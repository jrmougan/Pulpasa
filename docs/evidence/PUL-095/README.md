# PUL-095 · Rack, bandejas y pasaplatos

Arte de producción realizado por Codex el 2026-10-07, dirección A.

## Evidencia

- [Lámina nativa a 1080p](native_1080.png): rack girado −90°, S/M/L derechos sobre cada pila, tres siluetas, esquinas de pasaplatos y umbral de suelo.
- Bandejas llenas sostenidas mediante el `HoldComponent` real por ambos jugadores: [S](hands_small_1080.png), [M](hands_medium_1080.png), [L](hands_large_1080.png). Cámara y orientación reales de `level_01`, simulación congelada para reproducibilidad.
- Iconos PNG 256²: `assets/textures/ui/box_sizes/size_s.png`, `size_m.png`, `size_l.png`. Transparencia exterior, silueta círculo/óvalo/rectángulo y letras Montserrat obtenidas del mismo atlas de las bandejas. Import de UI sin compresión.

Lámina de estudio: cámara 38°, tamaño 12,74 m, 84,772 px/m; no escalado de objetos. El rack tiene placas de letra delanteras y una repetición superior rotada +90° en Blender para compensar el giro −90° del nivel. Las letras superiores tienen 0,28 m de lado; las del borde de bandeja 0,14 m, inclinadas hacia cámara. El papel de relleno y el rótulo de talla son piezas distintas; la barra de progreso permanece en su posición de gameplay.

## Integración para PUL-098 y PUL-101

`box.glb` conserva `box_small/medium/large`, `OutlineHull/hull_small/medium/large`, `Anchor_Fill_<talla>`, todos los `Anchor_Sticker` y `sticker`. No cambian origen, huella nominal, anclajes ni colisiones. Se simplificó el contorno a 16 segmentos S/M y 12 L para cumplir el presupuesto con comida; se mantienen círculo/óvalo/rectángulo con asas y el atlas anterior de plástico/papel/marca. Las letras son hijas de cada variante, de modo que siguen su visibilidad. La altura máxima del rótulo es ≈0,189 m; el cuerpo de bandeja sigue en 0,098 m y su relleno en 0,024 m.

El rack conserva pilas/spawners en X=−0,51 / 0 / 0,536, Z=−0,78, Y=0,31; conserva los hulls cerrados por talla. No aplicar highlight sobre las mallas abiertas de bandejas.

Nuevas piezas independientes de `counters.blend`, sin alterar los módulos anteriores:

| GLB | Huella y colocación local |
|---|---|
| `pass_mark.glb` | 0,72 × 0,52 m; origen sobre superficie de apoyo. Fondo entre Y=−0,032 y 0,018; esquinas alcanzan Y=0,020. Empotrar la base en la encimera. |
| `pass_threshold.glb` | 1,00 × 0,46 m; origen en suelo, base Y=−0,030, cara superior Y=0,020. Sin colisión incorporada. |

Ambas exportan `Anchor_Front` hacia −Z. PUL-101 instancia `pass_mark` en los seis slots y `pass_threshold` en el hueco. Esta entrega no toca `.tscn` ni `.tres` de gameplay. PUL-098 asigna los iconos a `BoxData.icon`; PUL-099 los reutiliza en ticket.

## Presupuestos y comprobaciones

[Exportaciones](budget.json): tres bandejas con hulls, letras y sticker 1.076 tris en total; rack **5.960 / 6.000**; `pass_mark` 140; umbral 70. Módulos anteriores de counters sin cambios.

[Auditoría de caja llena](budget.json): comida visible máxima 1.560 tris, más variante/hull/letra y reserva conservadora de 32 para badges/barra: **S=1.952, M=1.952, L=1.932 / 2.000**. Se cuentan incluso los hulls transparentes. [Tests finales de modelo, datos y bandejas](verify.log); [verificación completa](verify.log). Los avisos de objetos/recursos pendientes al cerrar la escena de captura también aparecen en el gate del proyecto; no se presentan como limpieza de memoria resuelta.

Reproducción: `blender -b --python docs/evidence/PUL-095/build_art.py --python-exit-code 1`; captura de lámina con `capture_art.gd` de PUL-094 (no incluido en esta rama; la lámina ya está capturada) y argumento `PUL-095`; capturas en mano con `capture_hands.gd -- <directorio absoluto de evidencia>`. Godot: `--audio-driver Dummy --resolution 1920x1080`, ventana oculta en Windows; sin puerto de Blender ni cambios en biblioteca v2.

Fila propuesta para el coordinador: rack/bandejas/marcas/iconos · **propia, equipo Pulpasa**; glyphs de Montserrat, SIL OFL 1.1, y marca/iconos existentes con sus atribuciones vigentes. No se modifica `CREDITS.md`.
