class_name SeasoningRules
extends RefCounted
## Reglas puras de condimento de la estación (D4, D18; ADR-003 §8.3): alternar un condimento sobre
## una caja llena, intercambio de exclusivos (pimentón dulce/picante) y orden canónico que comparten
## la fila de pegatinas de la caja y el ticket. No muta nada: devuelve copias.

## Por qué se consume una pulsación sin cambiar nada (señales locales `rejected`, signals.md §4).
enum Rejection {
	NONE,
	NO_BOX,
	BOX_NOT_FULL,
	# En desuso desde PUL-064: con la mano ocupada el dispensador no es objetivo.
	HAND_BUSY,
	EXCLUSIVE_TAKEN,
	BOWL_EMPTY,
	BOWL_FULL,
	NOT_ACCEPTED,
}


## Resultado de `toggle()`. Con `rejection` distinto de `NONE`, `removed` y `added` son nulos y
## `seasonings` es una copia de la lista de entrada.
class Toggle:
	extends RefCounted
	var rejection: SeasoningRules.Rejection = SeasoningRules.Rejection.NONE
	## Lo que sale de la caja: el mismo condimento (quitar) o el exclusivo intercambiado.
	var removed: SeasoningData
	## Lo que entra en la caja.
	var added: SeasoningData
	## Lista resultante, en orden de aplicación.
	var seasonings: Array[SeasoningData] = []


## Alterna `seasoning` sobre `current`: si ya lo lleva, lo quita; si no, lo añade al final. Si la
## caja lleva otro del mismo `exclusivity_group`, con `swap_exclusive` lo sustituye (sale el viejo
## y entra el nuevo) y sin él se rechaza con `EXCLUSIVE_TAKEN`. Sin llenar: `BOX_NOT_FULL`.
static func toggle(
	current: Array[SeasoningData], seasoning: SeasoningData, is_full: bool, swap_exclusive: bool
) -> Toggle:
	var result: Toggle = Toggle.new()
	result.seasonings = current.duplicate()
	if seasoning == null:
		result.rejection = Rejection.NOT_ACCEPTED
		return result
	if not is_full:
		result.rejection = Rejection.BOX_NOT_FULL
		return result
	var existing: SeasoningData = find(current, seasoning)
	if existing != null:
		result.seasonings.erase(existing)
		result.removed = existing
		return result
	var exclusive: SeasoningData = find_in_group(current, seasoning.exclusivity_group)
	if exclusive != null:
		if not swap_exclusive:
			result.rejection = Rejection.EXCLUSIVE_TAKEN
			return result
		result.seasonings.erase(exclusive)
		result.removed = exclusive
	result.seasonings.append(seasoning)
	result.added = seasoning
	return result


## El condimento de `current` equivalente a `seasoning` (`SeasoningData.same_as`), o `null`.
static func find(current: Array[SeasoningData], seasoning: SeasoningData) -> SeasoningData:
	if seasoning == null:
		return null
	for existing: SeasoningData in current:
		if existing != null and existing.same_as(seasoning):
			return existing
	return null


## El condimento de `current` del grupo de exclusividad `group`, o `null` (grupo vacío: ninguno).
static func find_in_group(current: Array[SeasoningData], group: StringName) -> SeasoningData:
	if group.is_empty():
		return null
	for existing: SeasoningData in current:
		if existing != null and existing.exclusivity_group == group:
			return existing
	return null


## Copia de `current` sin `seasoning` (igual si no lo lleva).
static func remove(current: Array[SeasoningData], seasoning: SeasoningData) -> Array[SeasoningData]:
	var result: Array[SeasoningData] = current.duplicate()
	var existing: SeasoningData = find(current, seasoning)
	if existing != null:
		result.erase(existing)
	return result


## Copia ordenada por `SeasoningData.sort_order` (pimentón → sal → aceite → cachelos). Estable:
## a igual `sort_order` se respeta el orden de entrada. Los nulos se descartan.
static func canonical_order(seasonings: Array[SeasoningData]) -> Array[SeasoningData]:
	var result: Array[SeasoningData] = []
	for seasoning: SeasoningData in seasonings:
		if seasoning == null:
			continue
		var index: int = result.size()
		while index > 0 and result[index - 1].sort_order > seasoning.sort_order:
			index -= 1
		result.insert(index, seasoning)
	return result


## Si el cuenco admite otro cachelo: con `stock` ya en `max_stock` se rechaza (`BOWL_FULL`).
static func can_restock(stock: int, max_stock: int) -> bool:
	return stock < max_stock


## Raciones tras echar un cachelo cocido: suma `per_item` y se recorta a `max_stock`
## (con 3 de 4 queda en 4, D23). Con el cuenco ya lleno devuelve `stock` sin cambios.
static func restocked(stock: int, per_item: int, max_stock: int) -> int:
	if not can_restock(stock, max_stock):
		return stock
	return mini(stock + per_item, max_stock)
