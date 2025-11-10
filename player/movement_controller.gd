class_name MovementController
extends RefCounted

var player_data: PlayerData
var hex_grid: Node3D
var movement_validator: MovementValidator

func _init(data: PlayerData, grid: Node3D):
	player_data = data
	hex_grid = grid
	movement_validator = MovementValidator.new(grid)
	
	if not player_data:
		print("MovementController: Warning - player_data is null in constructor!")

func move_to(target_position: Vector2i, current_movement_cost_spent: int = 0, movement_speed: float = INF) -> bool:
	var adjacent_tiles = player_data.get_adjacent_tiles()
	if not movement_validator.can_move_to(target_position, adjacent_tiles, current_movement_cost_spent, movement_speed):
		return false
	
	if player_data:
		player_data.set_position(target_position)
		return true
	else:
		print("MovementController: player_data is null!")
		return false

