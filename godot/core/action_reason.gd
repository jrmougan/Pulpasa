class_name ActionReason
extends RefCounted
## Motivo por el que una pulsación está BLOQUEADA (ADR-003 §11.1, D26). Conjunto cerrado: uno
## nuevo exige enmienda (constante + icono + test). `NONE` = sin motivo.

const NONE: StringName = &""
## Caja a medias (vacía o sin llenar del todo).
const BOX_NOT_FULL: StringName = &"box_not_full"
## Ocupado: olla sin plaza, soltar donde no cabe.
const BUSY: StringName = &"busy"
## Vacío (cuenco sin raciones).
const EMPTY: StringName = &"empty"
## Lleno (caja llena, cuenco sin hueco para reponer).
const FULL: StringName = &"full"
## Ya aplicado / ya lleva.
const ALREADY_APPLIED: StringName = &"already_applied"
## Sin cocer (cortar con pulpo crudo).
const NOT_COOKED: StringName = &"not_cooked"

## Los 6 motivos, sin `NONE`.
const ALL: Array[StringName] = [BOX_NOT_FULL, BUSY, EMPTY, FULL, ALREADY_APPLIED, NOT_COOKED]


## `true` si `reason` es uno de `ALL` (`NONE` no lo es).
static func is_valid(reason: StringName) -> bool:
	return reason in ALL
