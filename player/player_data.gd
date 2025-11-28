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
var gear_manager: GearManager

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
	gear_manager = GearManager.new(game_data)

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
	gear_weight = gear_manager.calculate_gear_weight(gear)

func calculate_movement_speed() -> void:
	movement_speed = gear_manager.calculate_movement_speed(base_movement_speed, gear_weight)
