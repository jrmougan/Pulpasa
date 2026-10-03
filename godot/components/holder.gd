class_name Holder
extends Node
## API de la mano (ADR-003 §3). Base abstracta común a 3D y 2D.
##
## Contrato para implementaciones: el único camino para coger o soltar es llamar a
## `on_picked_up(holder)` / `on_dropped()` del objeto (B4), y se valida ANTES de mutar
## nada (B5): si `pick_up` devuelve `false`, el estado no ha cambiado.

## Tras `on_picked_up` del objeto.
signal item_picked_up(item: Node)
## Tras `on_dropped` del objeto.
signal item_dropped(item: Node)


func get_held_item() -> Node:
	push_error("Holder.get_held_item() es abstracto")
	return null


func can_hold(_item: Node) -> bool:
	push_error("Holder.can_hold() es abstracto")
	return false


## Devuelve `true` si coge el objeto; `false` sin cambios si no puede.
func pick_up(_item: Node) -> bool:
	push_error("Holder.pick_up() es abstracto")
	return false


## Suelta y devuelve el objeto; `null` si no llevaba nada.
func drop() -> Node:
	push_error("Holder.drop() es abstracto")
	return null
