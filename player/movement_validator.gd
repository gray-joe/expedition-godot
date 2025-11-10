class_name MovementValidator

var hex_grid: Node3D

func _init(grid: Node3D):
	hex_grid = grid

func can_move_to(target_position: Vector2i, adjacent_tiles: Array[Vector2i], current_movement_cost_spent: int = 0, movement_speed: float = INF) -> bool:
	if not hex_grid:
		return false
	
	# Check if target is adjacent to current position
	if target_position not in adjacent_tiles:
		return false
	
	var grid_dims = hex_grid.get_grid_dimensions()
	if target_position.x < 0 or target_position.x >= grid_dims.x:
		return false
	if target_position.y < 0 or target_position.y >= grid_dims.y:
		return false
	
	var tile_type = hex_grid.get_tile_type_at(target_position)
	if tile_type == "":
		return false
	
	var tile_config = hex_grid.get_tile_config(tile_type)
	if not tile_config or not tile_config.is_walkable:
		return false
	
	# Check if this move would exceed movement speed
	if hex_grid.has_method("get_tile_config_at"):
		var target_tile_config = hex_grid.get_tile_config_at(target_position)
		if target_tile_config:
			var total_cost_after_move = current_movement_cost_spent + target_tile_config.movement_cost
			if total_cost_after_move > movement_speed:
				return false
	
	return true
