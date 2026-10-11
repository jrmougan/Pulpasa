# Textos en gallego (Should)

**Slug:** textos-gallego

## Criterios de aceptación
- **AC1** Given el idioma «Galego», Then el 100 % de las cadenas de menú, HUD, tickets y game over aparecen traducidas (0 claves sin traducir en el informe de traducción).
- **AC2** Given el cambio de idioma en opciones, Then la UI se actualiza en ≤ 0,5 s sin reiniciar.
- **AC3** Given el idioma por defecto, Then es castellano.
- **AC4** Given textos largos, Then ninguno se corta ni desborda en 1920×1080 ni 1280×720.

- **AC5 (D26)** Given los rótulos de verbos y motivos de `lenguaje-acciones.md` (COGER, SOLTAR, COCER, CORTAR, ALIÑAR DULCE, ALIÑAR PICANTE, CACHELOS, TIRAR; caja a medias, ocupado, vacío, lleno, ya aplicado, sin cocer) y los textos del tutorial táctil, Then tienen clave de traducción en castellano y gallego y caben sin recortarse a ≥ 36 px de alto de texto en 2340×1080. Los iconos no llevan texto. *Test:* informe de traducción + `test_ui_scale.gd`.

## Datos
Ficheros de traducción (`.po`/`.csv`) por idioma.
