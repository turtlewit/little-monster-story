extends Node

var inventory := []

func add_item(item: Item, amount: int) -> void:
	for _i in range(amount):
		inventory.push_back(item)
