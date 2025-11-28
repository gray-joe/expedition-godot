class_name GearManager
extends RefCounted

var game_data_ref

func _init(game_data: Node = null):
	game_data_ref = game_data if game_data else game_data

func calculate_gear_weight(gear: Dictionary) -> float:
	var total_weight: float = 0.0

	for gear_type in gear.keys():
		var item = gear[gear_type]

		match gear_type:
			"extras":
				total_weight += _calculate_extras_weight(item)
			"tent":
				total_weight += _find_item_weight(item, game_data_ref.tents)
			"sleeping_bag":
				total_weight += _find_item_weight(item, game_data_ref.sleeping_bags)
	
	return total_weight

func calculate_movement_speed(base_speed: float, gear_weight: float) -> float:
	return max(0.0, base_speed - gear_weight)

func _calculate_extras_weight(extras_array: Array) -> float:
	var weight: float = 0.0
	for extra_name in extras_array:
		weight += _find_item_weight(extra_name, game_data_ref.extras)
	return weight

func _find_item_weight(item_name: String, items_dict: Dictionary) -> float:
	for item_id in items_dict.keys():
		if items_dict[item_id].has("name") and items_dict[item_id]["name"] == item_name:
			if items_dict[item_id].has("weight"):
				return items_dict[item_id]["weight"]
			break
	return 0.0
