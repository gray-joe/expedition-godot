extends Node3D
class_name Player

@export var _editor_player_name: String = "Player"
@export var _editor_movement_speed: float = 8.0
@export var _editor_starting_tile_type: String = "starting"
@export var _editor_player_id: int = 0
@export var _editor_max_turn_duration: float = 0.0

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
		player_data = PlayerData.new(_editor_player_name, _editor_player_id, _editor_movement_speed, _editor_starting_tile_type, _editor_max_turn_duration)
	
	turn_manager = TurnManager.new(player_data.max_turn_duration)
	
	turn_manager.turn_started.connect(_on_turn_started)
	turn_manager.turn_ended.connect(_on_turn_ended)
	turn_manager.turn_timeout.connect(_on_turn_timeout)

func initialize(grid: Node3D, data: PlayerData = null) -> void:
	hex_grid = grid
	
	if data:
		player_data = data
	elif not player_data:
		player_data = PlayerData.new(_editor_player_name, _editor_player_id, _editor_movement_speed, _editor_starting_tile_type, _editor_max_turn_duration)
	
	if turn_manager:
		turn_manager.set_max_turn_duration(player_data.max_turn_duration)
	else:
		turn_manager = TurnManager.new(player_data.max_turn_duration)
		turn_manager.turn_started.connect(_on_turn_started)
		turn_manager.turn_ended.connect(_on_turn_ended)
		turn_manager.turn_timeout.connect(_on_turn_timeout)
	
	movement_validator = MovementValidator.new(hex_grid)
	movement_controller = MovementController.new(player_data, hex_grid)

func set_player_name(new_name: String) -> void:
	if not player_data:
		_initialize_components()
	player_data.name = new_name

func set_player_id(new_id: int) -> void:
	if not player_data:
		_initialize_components()
	player_data.player_id = new_id
		
func move_to(target_position: Vector2i) -> bool:
	if not player_data:
		_initialize_components()
	
	if not turn_manager or not turn_manager.can_perform_action():
		print("Player: ", player_data.name, " cannot move - not their turn")
		return false
	
	if not movement_controller or not movement_controller.move_to(target_position, movement_cost_spent_this_turn, player_data.movement_speed):
		print("Player: ", player_data.name, " cannot move to: ", target_position)
		return false
	
	if hex_grid:
		var target_world_pos = hex_grid.grid_to_world_position(target_position)
		global_position = target_world_pos
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
		return movement_validator.can_move_to(target_position, adjacent_tiles, movement_cost_spent_this_turn, player_data.movement_speed)
	return false

func start_turn() -> void:
	if not turn_manager:
		if not player_data:
			_initialize_components()
		else:
			turn_manager = TurnManager.new(player_data.max_turn_duration)
			turn_manager.turn_started.connect(_on_turn_started)
			turn_manager.turn_ended.connect(_on_turn_ended)
			turn_manager.turn_timeout.connect(_on_turn_timeout)
	turn_manager.start_turn()

func end_turn() -> void:
	if not turn_manager:
		print("Player: ", player_data.name if player_data else "Unknown", " - turn_manager not initialized!")
		return
	turn_manager.end_turn()

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
	if not player_data:
		_initialize_components()
	player_data.max_turn_duration = duration
	if turn_manager:
		turn_manager.set_max_turn_duration(duration)

func _on_turn_started() -> void:
	movement_cost_spent_this_turn = 0
	player_turn_started.emit()

func _on_turn_ended() -> void:
	if player_data:
		print("Player: ", player_data.name, " total movement cost this turn: ", movement_cost_spent_this_turn)
	player_turn_ended.emit()

func _on_turn_timeout() -> void:
	if player_data:
		print("Player: ", player_data.name, " turn timed out!")

func get_player_name() -> String:
	if not player_data:
		_initialize_components()
	return player_data.name

func get_player_id() -> int:
	if not player_data:
		_initialize_components()
	return player_data.player_id

func get_movement_speed() -> float:
	if not player_data:
		_initialize_components()
	return player_data.movement_speed

func get_grid_position() -> Vector2i:
	if not player_data:
		_initialize_components()
	return player_data.get_grid_position()

func set_grid_position(new_position: Vector2i) -> void:
	if not player_data:
		_initialize_components()
	player_data.set_position(new_position)
	player_moved.emit(new_position)

func get_gear_weight() -> void:
	if not player_data:
		_initialize_components()
	player_data.calculate_gear_weight()

func calculate_movement_speed() -> void:
	if not player_data:
		_initialize_components()
	player_data.calculate_movement_speed()

func get_movement_info() -> Dictionary:
	if not player_data:
		_initialize_components()
	return {
		"movement_speed": player_data.movement_speed,
		"movement_cost_spent": movement_cost_spent_this_turn
	}

func get_player_info() -> Dictionary:
	if not player_data:
		_initialize_components()
	
	var info = {
		"name": player_data.name,
		"id": player_data.player_id,
		"position": player_data.get_grid_position(),
		"movement_speed": player_data.movement_speed,
		"base_movement_speed": player_data.base_movement_speed,
		"is_active": player_data.is_active,
		"turn_active": false,
		"gear": player_data.gear,
		"gear_weight": player_data.gear_weight
	}
	
	if turn_manager:
		info.turn_active = turn_manager.get_turn_active()
		var turn_info = turn_manager.get_turn_info()
		info.turn_duration = turn_info.duration
		info.remaining_time = turn_info.remaining_time
	
	return info
