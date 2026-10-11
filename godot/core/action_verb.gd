class_name ActionVerb
extends RefCounted
## Verbo de una pulsación de interactuar (ADR-003 §11.1, D26). Conjunto cerrado: un verbo nuevo
## exige enmienda (constante + icono + test). `NONE` = sin verbo.

const NONE: StringName = &""
## COGER: pasa a la mano un objeto, o saca de un spawner o de la olla.
const PICK_UP: StringName = &"pick_up"
## SOLTAR: en un pasaplatos o al suelo.
const DROP: StringName = &"drop"
## COCER: mete crudo en una plaza de la olla.
const COOK: StringName = &"cook"
## CORTAR: un corte del pulpo cocido sobre una caja.
const CUT: StringName = &"cut"
## ALIÑAR DULCE.
const SEASON_SWEET: StringName = &"season_sweet"
## ALIÑAR PICANTE.
const SEASON_HOT: StringName = &"season_hot"
## CACHELOS: reponer el cuenco o poner cachelos en la caja.
const CACHELOS: StringName = &"cachelos"
## TIRAR: al cubo, o desechar el quemado de la olla.
const TRASH: StringName = &"trash"

## Los 8 verbos, sin `NONE`.
const ALL: Array[StringName] = [PICK_UP, DROP, COOK, CUT, SEASON_SWEET, SEASON_HOT, CACHELOS, TRASH]
## Verbos que se repiten al mantener pulsado (ADR-003 §11.4).
const REPEATABLE: Array[StringName] = [CUT]


## `true` si `verb` es uno de `ALL` (`NONE` no lo es).
static func is_valid(verb: StringName) -> bool:
	return verb in ALL
