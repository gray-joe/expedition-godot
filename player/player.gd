extends Node3D
class_name Player

@export var player_name: String = "Player"
@export var movement_speed: float = 8.0
@export var starting_tile_type: String = "starting"
@export var player_id: int = 0
@export var max_turn_duration: float = 0.0
@export var player_gear: Dictionary

var player_data: PlayerData
var movement_validator: MovementValidator
var turn_manager: TurnManager
var movement_controller: MovementController
var hex_grid: Node3D

var movement_cost_spent_this_turn: int = 0

signal player_moved(new_position: Vector2i)
signal player_action_completed(action_type: String)
signal player_turn_started()
signal player_turn_ended()

func _ready() -> void:
	_initialize_components()

func _initialize_components() -> void:
	if not player_data:
		player_data = PlayerData.new(player_name, player_id, movement_speed, starting_tile_type)
	
	turn_manager = TurnManager.new(max_turn_duration)
	
	turn_manager.turn_started.connect(_on_turn_started)
	turn_manager.turn_ended.connect(_on_turn_ended)
	turn_manager.turn_timeout.connect(_on_turn_timeout)

func initialize(grid: Node3D) -> void:
	hex_grid = grid
	
	if not player_data:
		print("Player: ", player_name, " - player_data not initialized, creating now")
		player_data = PlayerData.new(player_name, player_id, movement_speed, starting_tile_type)
	
	movement_validator = MovementValidator.new(hex_grid)
	movement_controller = MovementController.new(player_data, hex_grid)

func set_player_name(new_name: String) -> void:
	player_name = new_name
	if player_data:
		player_data.name = new_name

func set_player_id(new_id: int) -> void:
	player_id = new_id
	if player_data:
		player_data.player_id = new_id

func move_to(target_position: Vector2i) -> bool:
	if not turn_manager or not turn_manager.can_perform_action():
		print("Player: ", player_name, " cannot move - not their turn")
		return false
	
	if not movement_controller or not movement_controller.move_to(target_position, movement_cost_spent_this_turn, movement_speed):
		print("Player: ", player_name, " cannot move to: ", target_position)
		return false
	
	if hex_grid:
		var target_world_pos = hex_grid.grid_to_world_position(target_position)
		global_position = target_world_pos
		# Accumulate movement cost for the tile we landed on
		if hex_grid.has_method("get_tile_config_at"):
			var tile_config = hex_grid.get_tile_config_at(target_position)
			if tile_config:
				movement_cost_spent_this_turn += tile_config.movement_cost
	
	player_moved.emit(target_position)
	player_action_completed.emit("move")
	return true

func can_move_to(target_position: Vector2i) -> bool:
	if movement_validator and player_data:
		var adjacent_tiles = player_data.get_adjacent_tiles()
		return movement_validator.can_move_to(target_position, adjacent_tiles, movement_cost_spent_this_turn, movement_speed)
	return false

func start_turn() -> void:
	if turn_manager:
		turn_manager.start_turn()
	else:
		print("Player: ", player_name, " - turn_manager not initialized!")

func end_turn() -> void:
	if turn_manager:
		turn_manager.end_turn()
	else:
		print("Player: ", player_name, " - turn_manager not initialized!")

func is_turn_active() -> bool:
	if turn_manager:
		return turn_manager.get_turn_active()
	return false

func get_turn_info() -> Dictionary:
	if turn_manager:
		return turn_manager.get_turn_info()
	return {}

func get_turn_manager() -> TurnManager:
	return turn_manager

func set_turn_duration(duration: float) -> void:
	if turn_manager:
		turn_manager.set_max_turn_duration(duration)

func _on_turn_started() -> void:
	movement_cost_spent_this_turn = 0
	player_turn_started.emit()

func _on_turn_ended() -> void:
	print("Player: ", player_name, " total movement cost this turn: ", movement_cost_spent_this_turn)
	player_turn_ended.emit()

func _on_turn_timeout() -> void:
	print("Player: ", player_name, " turn timed out!")

func get_grid_position() -> Vector2i:
	if player_data:
		return player_data.get_grid_position()
	return Vector2i(-1, -1)

func set_grid_position(new_position: Vector2i) -> void:
	if player_data:
		player_data.set_position(new_position)
		player_moved.emit(new_position)

func get_movement_info() -> Dictionary:
	return {
		"movement_speed": movement_speed,
		"movement_cost_spent": movement_cost_spent_this_turn
	}

func get_player_info() -> Dictionary:
	var info = {
		"name": player_name,
		"id": player_id,
		"position": Vector2i(-1, -1),
		"movement_speed": movement_speed,
		"is_active": false,
		"turn_active": false,
		"player_gear": player_gear,
	}
	
	if player_data:
		info.name = player_data.name
		info.id = player_data.player_id
		info.position = player_data.get_grid_position()
		info.movement_speed = player_data.movement_speed
		info.is_active = player_data.is_active
		info.player_gear = player_data.player_gear
	
	if turn_manager:
		info.turn_active = turn_manager.get_turn_active()
		var turn_info = turn_manager.get_turn_info()
		info.turn_duration = turn_info.duration
		info.remaining_time = turn_info.remaining_time
	
	return info
