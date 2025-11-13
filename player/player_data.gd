class_name PlayerData
extends RefCounted

var name: String
var position: Vector2i
var adjacent_tiles: Array[Vector2i]
var movement_speed: float
var starting_tile_type: String
var is_active: bool = false
var player_id: int
var player_gear: Dictionary

func _init(p_name: String, p_id: int, p_speed: float = 8.0, p_starting_type: String = "starting"):
	name = p_name
	player_id = p_id
	position = Vector2i(-1, -1)
	movement_speed = p_speed
	starting_tile_type = p_starting_type
	player_gear = game_data.player_gear[p_id]

func set_position(new_position: Vector2i) -> void:
	position = new_position

func get_grid_position() -> Vector2i:
	return position

func get_adjacent_tiles() -> Array[Vector2i]:
	print("Current position is: ", position)
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
	print("Adjacent tiles are: ", adjacent_tiles)
	return adjacent_tiles
