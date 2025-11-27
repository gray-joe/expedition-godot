class_name PlayerData
extends RefCounted

var name: String
var position: Vector2i
var adjacent_tiles: Array[Vector2i]
var movement_speed: float
var base_movement_speed: float
var starting_tile_type: String
var is_active: bool = false
var player_id: int
var gear: Dictionary
var gear_weight: float = 0.0
var max_turn_duration: float = 0.0

func _init(p_name: String, p_id: int, p_speed: float = 8.0, p_starting_type: String = "starting", p_turn_duration: float = 0.0):
	name = p_name
	player_id = p_id
	position = Vector2i(-1, -1)
	starting_tile_type = p_starting_type
	max_turn_duration = p_turn_duration
	gear = game_data.player_gear[p_id] if p_id in game_data.player_gear else {}
	gear_weight = 0.0
	base_movement_speed = p_speed
	movement_speed = p_speed

func set_position(new_position: Vector2i) -> void:
	position = new_position

func get_grid_position() -> Vector2i:
	return position

func get_adjacent_tiles() -> Array[Vector2i]:
	if position.x % 2 == 0:
		adjacent_tiles = [
			position + Vector2i(0, -1),
			position + Vector2i(1, -1),
			position + Vector2i(1, 0),
			position + Vector2i(0, 1),
			position + Vector2i(-1, 0),
			position + Vector2i(-1, -1)
		]
	else:
		adjacent_tiles = [
			position + Vector2i(0, -1),
			position + Vector2i(1, 0),
			position + Vector2i(1, 1),
			position + Vector2i(0, 1),
			position + Vector2i(-1, 1),
			position + Vector2i(-1, 0)
		]
	return adjacent_tiles

func calculate_gear_weight() -> void:
	var total_weight: float = 0.0

	for gear_type in gear.keys():
		var item = gear[gear_type]

		match gear_type:
			"extras":
				for extra_name in item:
					for extra_id in game_data.extras.keys():
						if game_data.extras[extra_id]["name"] == extra_name:
							total_weight += game_data.extras[extra_id]["weight"]
							break
			"tent":
				for tent_id in game_data.tents.keys():
					if game_data.tents[tent_id]["name"] == item:
						total_weight += game_data.tents[tent_id]["weight"]
						break
			"sleeping_bag":
				for sleeping_bag_id in game_data.sleeping_bags.keys():
					if game_data.sleeping_bags[sleeping_bag_id]["name"] == item:
						total_weight += game_data.sleeping_bags[sleeping_bag_id]["weight"]
						break

	gear_weight = total_weight

func calculate_movement_speed() -> void:
	movement_speed = max(0.0, base_movement_speed - gear_weight)
