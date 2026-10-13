# Glosario castellano → gallego

Vocabulario del juego para la traducción de la alpha (`features/textos-gallego.md`). Lo usan PUL-168
(claves) y PUL-173 (traducción). **Todo el gallego de este fichero es propuesta**: lo revisa un hablante
nativo en el gate G3 (pregunta P9 del plan de M4, `docs/evidence/PUL-141/README.md`).

## Fuentes
- **`main.tex`**: término que el GDD original en gallego usa, según las citas literales que recoge
  `gdd.md` §8 (`«as comandas serán o resultado da ausencia presencia de cachelos, patacas, pementou ou sal»`).
  *El fichero `main.tex` no estaba accesible en la máquina de PUL-161* (`/home/jeromo/vibedora/dev/pulpasa_docs/`
  no existe): solo se marca `main.tex` lo que el repo cita de él. El resto queda como propuesta hasta que
  alguien con acceso lo coteje (pregunta G-1).
- **`brand.md` (D22)**: identidad de marca decidida por el responsable (lema «Franquicia galega de polbo»,
  «polbo, bandexa…» en los textos de marca).
- **Propuesta**: forma normativa de la RAG (Real Academia Galega) elegida por el game-designer.

## Reglas de estilo (propuesta)
1. Gallego normativo (RAG). Donde el uso popular difiere (*pulpeiro/pulpeira* frente a *polbeiro/polbeira*)
   se elige la normativa y se anota la popular.
2. Rótulos de verbo en **MAYÚSCULAS**, infinitivo (como en castellano, `lenguaje-acciones.md`); motivos en
   minúscula.
3. Tuteo al jugador (*colle*, *preme*), plural *vós* solo en Local 2P (*cooperade*).
4. Sin signo de apertura (¿ ¡) en gallego salvo ambigüedad (la norma lo admite, el uso lo evita). Se mantiene
   en `performance_texts` por simetría con el castellano corregido (pregunta G-3).
5. Números con coma decimal y espacio antes de la unidad en ambos idiomas: `300,0 s`, `12 €` (hoy el HUD
   pinta `300.0s`; lo corrige PUL-173).
6. Las marcas no se traducen: **PulpaSA** (D21) y el lema **«Franquicia galega de polbo»** (D22) salen
   iguales en los dos idiomas.

## Términos obligatorios (22)
Cruzados con D26 (8 verbos y 6 motivos, `features/lenguaje-acciones.md`), los 4 `display_name` de
`godot/data/recipes/*.tres` y los 4 `performance_texts` de `godot/data/config/round_config.tres`.

### Verbos (8, D26 §1)
| Id | Castellano | Gallego | Fuente | Nota |
|---|---|---|---|---|
| `PICK_UP` | COGER | COLLER | propuesta | |
| `DROP` | SOLTAR | DEIXAR | propuesta | *Soltar* también existe en gallego; *deixar* es lo natural para «dejar algo en un sitio» |
| `COOK` | COCER | COCER | propuesta | |
| `CUT` | CORTAR | CORTAR | propuesta | |
| `SEASON_SWEET` | ALIÑAR DULCE | ALIÑAR DOCE | propuesta | *doce* = dulce |
| `SEASON_HOT` | ALIÑAR PICANTE | ALIÑAR PICANTE | propuesta | |
| `CACHELOS` | CACHELOS | CACHELOS | `main.tex` | |
| `TRASH` | TIRAR | BOTAR | propuesta | *botar ao lixo*; *tirar* en gallego es sobre todo «lanzar» |

### Motivos (6, D26 §2)
| Id | Castellano | Gallego | Fuente | Nota |
|---|---|---|---|---|
| `BOX_NOT_FULL` | caja a medias | caixa a medias | propuesta | |
| `BUSY` | ocupado | ocupado | propuesta | |
| `EMPTY` | vacío | baleiro | propuesta | |
| `FULL` | lleno | cheo | propuesta | |
| `ALREADY` | ya aplicado / ya lleva | xa aplicado / xa leva | propuesta | Dos rótulos para el mismo motivo: aliño (*aplicado*) y cachelos (*leva*) |
| `RAW` | sin cocer | sen cocer | propuesta | |

### Recetas (4, D25 §3, `data/recipes/*.tres`)
| `translation_key` | Castellano (hoy) | Gallego | Fuente | Nota |
|---|---|---|---|---|
| `RECIPE_A_FEIRA` | Á feira | Á feira | propuesta | Ya es gallego en los dos idiomas (nombre propio del plato) |
| `RECIPE_PICANTE` | Picante | Picante | propuesta | |
| `RECIPE_CON_CACHELOS` | Con cachelos | Con cachelos | `main.tex` | |
| `RECIPE_BRAVO_CACHELOS` | Bravo cachelos | Bravo cachelos | propuesta | 14 caracteres, el máximo de D25 §3 |

### Textos de resultado (4, `round_config.tres` `performance_texts`)
| Tramo | Castellano (hoy) | Castellano corregido (propuesta) | Gallego | Fuente | Nota |
|---|---|---|---|---|---|
| 0 | Pulpeiro ineficiente | Pulpeiro ineficiente | Polbeiro ineficiente | propuesta | |
| 1 | Pulpeiro aceptable | Pulpeiro aceptable | Polbeiro aceptable | propuesta | |
| 2 | Pulpeiro eficiente | Pulpeiro eficiente | Polbeiro eficiente | propuesta | |
| 3 | !Pulpeiro lexendario! | ¡Pulpeiro legendario! | ¡Polbeiro lendario! | propuesta | Hoy empieza con «!» (errata) y mezcla *lexendario* (no normativo; RAG: *lendario*) |

*Pulpeiro* se queda en castellano como guiño gallego (es préstamo habitual en Galicia); en gallego la forma
normativa es *polbeiro* (pregunta G-2).

**Conteo:** 8 verbos + 6 motivos + 4 recetas + 4 textos de resultado = **22 términos, 22 con fuente,
0 faltantes** (2 `main.tex`, 20 propuesta).

## Vocabulario general
| Castellano | Gallego | Fuente | Dónde sale |
|---|---|---|---|
| pulpo á feira | polbo á feira | `brand.md` (D22: *polbo*) | Lema del menú (`MENU_TAGLINE`) |
| pulpo | polbo | `brand.md` (D22) | Tutorial |
| pulpeiro, pulpeira | polbeiro, polbeira | propuesta | Resultados |
| cachelos (patatas cocidas) | cachelos (tamén *patacas*) | `main.tex` | Recetas, verbo, ticket |
| aliño | aliño | propuesta | Ticket, verbo |
| aliño dulce / picante | aliño doce / picante | propuesta | Ticket (`SEASONING_*`) |
| pimentón | pementón | `main.tex` (corrige *pementou*, `gdd.md` §8) | Gesto del aliño (sin texto hoy) |
| sal gorda | sal grosa | `main.tex` (*sal*) + propuesta (*grosa*) | Sin texto hoy |
| aceite | aceite | propuesta | Sin texto hoy |
| caja | caixa | propuesta | Motivo, tutorial |
| bandeja | bandexa | `brand.md` (D22) | Sin texto hoy |
| comanda | comanda | `main.tex` | Ticket (`TICKET_TITLE`) |
| olla | pota | propuesta | Tutorial |
| nevera | neveira | propuesta | Tutorial |
| cuenco | cunca | propuesta | Sin texto hoy |
| cubo (de basura) | lixo, cubo do lixo | propuesta | Tutorial |
| puesto | posto | propuesta | Tutorial |
| cocina | cociña | propuesta | Menú (errores de carga) |
| romería | romaría | propuesta | Menú, pausa |
| gallego, gallegas | galego, galegas | `brand.md` (D22) | Menú |
| turno | quenda | propuesta | HUD, resultados |
| terminado | rematado/a | propuesta | Resultados |
| recaudación | recadación | propuesta | HUD, resultados |
| tiempo restante | tempo restante | propuesta | HUD |
| personaje | personaxe | propuesta | Menú, tutorial |
| jugador (J1, J2) | xogador (X1, X2) | propuesta | HUD, pausa (pregunta G-4) |
| mando | mando | propuesta | Pausa |
| conectado / desconectado | conectado / desconectado | propuesta | HUD, pausa |
| pausa | pausa | propuesta | Pausa |
| reanudar | continuar | propuesta | Pausa |
| reiniciar | reiniciar | propuesta | Pausa |
| reintentar | tentar de novo | propuesta | Resultados |
| salir | saír | propuesta | Menú, pausa, resultados |
| menú | menú | propuesta | Táctil |
| pulsar, mantener pulsado | premer, manter premido | propuesta | Tutorial |
| saltar (tutorial) | omitir | propuesta | Tutorial |
| tutorial | titorial | propuesta | Opciones / menú, si G0 elige botón (P5) |
| opciones | opcións | propuesta | PUL-160 / PUL-171 |
| idioma | idioma | propuesta | Opciones |
| castellano, gallego (nombres de idioma) | Castellano, Galego | propuesta | Selector de idioma: cada idioma se nombra en su propia lengua |

## Preguntas abiertas
- **G-1** Cotejar con `main.tex` los términos marcados «propuesta» (no estaba accesible en la máquina de
  PUL-161). Va con la revisión nativa de G3 (P9).
- **G-2** ¿*Polbeiro* (normativo) o *pulpeiro* (popular, el que usa hoy el castellano) en la versión gallega?
- **G-3** ¿Se corrige el castellano de `performance_texts[3]` a «¡Pulpeiro legendario!»? Hoy es
  «!Pulpeiro lexendario!» (errata de signo y forma gallega no normativa). Lo aplicaría PUL-168/173 en
  `round_config.tres` (fuera de `docs/design/`).
- **G-4** El castellano mezcla «P1» (HUD «Controlas: P%d», menú «Local 2P») y «J1/J2» (HUD «J%d conectado»,
  pausa «Mando de J%d»). ¿Una sola letra? Propuesta: «J» en castellano y «X» en gallego, también en
  «Local 2J / Local 2X»; o «P» en ambos por ser marca de modo.
