class_name ActionRules
extends RefCounted
## Reglas puras mano × receptor de la tabla de acciones (ADR-003 §11.6; transcripción de
## `lenguaje-acciones.md`, A–F). Única fuente de ramas de `get_action_hint` e `interact`.
## Solo primitivos, `StringName` y `Held`: sin nodos, sin 3D.

## Qué lleva la mano (M0…M7 del diseño; M8/M9 = `BOX_FULL` más qué aliño lleva, que se pasa
## aparte). `OTHER` = cualquier otra cosa.
enum Held {
	NOTHING,
	OCTOPUS_RAW,
	OCTOPUS_COOKED,
	CACHELOS_RAW,
	CACHELOS_COOKED,
	BOX_EMPTY,
	BOX_PARTIAL,
	BOX_FULL,
	OTHER,
}


## A4: pulpo o cachelos sueltos, o guardados en un pasaplatos. Solo se cogen con la mano vacía.
static func for_loose_item(held: Held, can_hold: bool) -> ActionHint:
	if held == Held.NOTHING and can_hold:
		return ActionHint.ok(ActionVerb.PICK_UP)
	return ActionHint.none()


## B: caja suelta o en un pasaplatos. `fill` es el llenado 0–1 (progreso del corte).
static func for_box(held: Held, box_full: bool, fill: float) -> ActionHint:
	match held:
		Held.NOTHING:
			return ActionHint.ok(ActionVerb.PICK_UP)
		Held.OCTOPUS_RAW:
			if box_full:
				return ActionHint.blocked(ActionVerb.CUT, ActionReason.FULL)
			return ActionHint.blocked(ActionVerb.CUT, ActionReason.NOT_COOKED)
		Held.OCTOPUS_COOKED:
			if box_full:
				return ActionHint.blocked(ActionVerb.CUT, ActionReason.FULL)
			return ActionHint.ok(ActionVerb.CUT, clampf(fill, 0.0, 1.0))
	return ActionHint.none()


## C: olla. Con la mano vacía retira (el quemado primero); con crudo, cuece si hay plaza.
static func for_pot(held: Held, free_places: int, has_burnt: bool, has_ready: bool) -> ActionHint:
	match held:
		Held.NOTHING:
			if has_burnt:
				return ActionHint.ok(ActionVerb.TRASH)
			if has_ready:
				return ActionHint.ok(ActionVerb.PICK_UP)
		Held.OCTOPUS_RAW, Held.CACHELOS_RAW:
			if free_places > 0:
				return ActionHint.ok(ActionVerb.COOK)
			return ActionHint.blocked(ActionVerb.COOK, ActionReason.BUSY)
	return ActionHint.none()


## A5: pasaplatos o mesa **vacíos**. Cualquier cosa en la mano se deja si `accepts`.
static func for_pass_slot(held: Held, accepts: bool) -> ActionHint:
	if held != Held.NOTHING and accepts:
		return ActionHint.ok(ActionVerb.DROP)
	return ActionHint.none()


## A1–A3: nevera, cachelera, rack. Solo con la mano vacía.
static func for_spawner(held: Held) -> ActionHint:
	if held == Held.NOTHING:
		return ActionHint.ok(ActionVerb.PICK_UP)
	return ActionHint.none()


## D: dispensador de aliño, solo desde el lado de aliñar (el lado lo filtra `is_reachable_from`).
## `verb` es el del aliño (`SeasoningData.verb`); `replaces` = la caja lleva el otro aliño.
static func for_dispenser(
	held: Held, verb: StringName, box_has_it: bool, box_has_other: bool
) -> ActionHint:
	match held:
		Held.BOX_EMPTY, Held.BOX_PARTIAL:
			return ActionHint.blocked(verb, ActionReason.BOX_NOT_FULL)
		Held.BOX_FULL:
			if box_has_it:
				return ActionHint.blocked(verb, ActionReason.ALREADY_APPLIED)
			var hint: ActionHint = ActionHint.ok(verb)
			hint.replaces = box_has_other
			return hint
	return ActionHint.none()


## E: cuenco de cachelos. Repone con cachelos cocidos (si caben) y pone cachelos en la caja llena.
## Que la caja a medias o llena solo cuente desde el lado de aliñar lo filtra `is_reachable_from`.
static func for_bowl(
	held: Held, stock: int, stock_max: int, portions_per_item: int, box_has_cachelos: bool
) -> ActionHint:
	match held:
		Held.CACHELOS_COOKED:
			if stock + portions_per_item <= stock_max:
				return ActionHint.ok(ActionVerb.CACHELOS)
			return ActionHint.blocked(ActionVerb.CACHELOS, ActionReason.FULL)
		Held.BOX_EMPTY, Held.BOX_PARTIAL:
			return ActionHint.blocked(ActionVerb.CACHELOS, ActionReason.BOX_NOT_FULL)
		Held.BOX_FULL:
			# Fila E1 del diseño: «ya lleva» gana a «vacío» (excepción de la prioridad de motivos).
			if box_has_cachelos:
				return ActionHint.blocked(ActionVerb.CACHELOS, ActionReason.ALREADY_APPLIED)
			if stock <= 0:
				return ActionHint.blocked(ActionVerb.CACHELOS, ActionReason.EMPTY)
			return ActionHint.ok(ActionVerb.CACHELOS)
	return ActionHint.none()


## A6: cubo de basura. `can_trash` lo decide `TrashRules`.
static func for_trash(held: Held, can_trash: bool) -> ActionHint:
	if held != Held.NOTHING and can_trash:
		return ActionHint.ok(ActionVerb.TRASH)
	return ActionHint.none()


## A8–A9: sin objetivo con la mano llena. Suelta delante si hay sitio; si no, `busy`.
static func for_floor(held: Held, can_drop: bool) -> ActionHint:
	if held == Held.NOTHING:
		return ActionHint.none()
	if can_drop:
		return ActionHint.ok(ActionVerb.DROP)
	return ActionHint.blocked(ActionVerb.DROP, ActionReason.BUSY)
