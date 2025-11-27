extends Node3D

enum GameState {
	SETUP,
	IN_GAME,
	END
}

enum TurnPhase {
	MORNING,
	AFTERNOON,
	NIGHT
}

@export var hex_grid_scene: PackedScene
@export var player_scene: PackedScene

var current_state: GameState = GameState.SETUP
var players: Array[Player] = []
var current_player_index: int = 0
var hex_grid: Node3D
var in_game_ui: InGameUI = null
var current_turn: int = 1
var current_phase: TurnPhase = TurnPhase.MORNING

func _ready() -> void:
	_initialize_game()

func _initialize_game() -> void:
	_setup_ui()
	
	if hex_grid_scene:
		hex_grid = hex_grid_scene.instantiate()
		add_child(hex_grid)
	else:
		print("GameManager: Error - No hex grid scene assigned!")
		return
	
	start_game()

func _setup_ui() -> void:
	in_game_ui = InGameUI.new()
	add_child(in_game_ui)
	
	in_game_ui.end_turn_requested.connect(_on_end_turn_requested)

func start_game() -> void:
	current_state = GameState.SETUP
	current_turn = 1
	current_phase = TurnPhase.MORNING
	current_player_index = 0
	
	await get_tree().process_frame
	_spawn_players()
	
	current_state = GameState.IN_GAME
	_start_turn()

func _spawn_players() -> void:
	if not player_scene:
		print("GameManager: Error - No player scene assigned!")
		return
	
	if not hex_grid:
		print("GameManager: Error - No hex grid reference!")
		return
	
	var starting_tiles = hex_grid.get_starting_tiles()
	if starting_tiles.size() == 0:
		print("GameManager: Error - No starting tiles found!")
		return
	
	for i in range(game_data.player_count):
		var player_node = player_scene.instantiate()
		
		# Cast to Player type - ensure the scene instantiates a Player
		if not player_node is Player:
			print("GameManager: Error - Player scene does not instantiate a Player node!")
			continue
		
		var player: Player = player_node as Player
		player.name = "Player_" + str(i + 1)
		
		player.set_player_name("Player " + str(i + 1))
		player.set_player_id(i + 1)
		player.set_turn_duration(30.0)
		player.initialize(hex_grid)
		player.get_gear_weight()
		player.calculate_movement_speed()

		players.append(player)
		
		var success = hex_grid.spawn_player_on_starting_tile(player, starting_tiles[i])
		if success:
			print('Player created with data: ', player.get_player_info())
			pass
		else:
			print("GameManager: Failed to place player ", i + 1, " on starting tile")
			players.pop_back()
			player.queue_free()

func end_game() -> void:
	current_state = GameState.END
	print("GameManager: Game ended! Final state: ", GameState.keys()[current_state])

func _start_turn() -> void:
	if current_state != GameState.IN_GAME:
		return
	
	var current_player = get_current_player()
	if current_player:
		if hex_grid and hex_grid.has_method("set_current_player"):
			hex_grid.set_current_player(current_player)
		else:
			print("GameManager: Hex grid or set_current_player method not found!")
		
		current_player.start_turn()
		
		if in_game_ui:
			in_game_ui.update_current_player(current_player.name, current_turn, current_phase)
			in_game_ui.set_end_turn_enabled(true)
			
			var turn_manager = current_player.get_turn_manager()
			in_game_ui.set_turn_manager(turn_manager)
			in_game_ui.reset_turn_timer()
			
			var movement_info = current_player.get_movement_info()
			in_game_ui.update_movement_remaining(movement_info.movement_speed, movement_info.movement_cost_spent)
			
			if not current_player.player_moved.is_connected(_on_player_moved):
				current_player.player_moved.connect(_on_player_moved)
		
	else:
		print("GameManager: Error - No current player found!")

func next_turn() -> void:
	if current_state != GameState.IN_GAME:
		return
	
	var current_player = get_current_player()
	
	if current_player:
		if current_player.player_moved.is_connected(_on_player_moved):
			current_player.player_moved.disconnect(_on_player_moved)
		current_player.end_turn()
	
	if hex_grid and hex_grid.has_method("set_current_player"):
		hex_grid.set_current_player(null)
	
	current_player_index = (current_player_index + 1) % players.size()
	
	if current_player_index == 0:
		current_phase = ((current_phase + 1) % TurnPhase.size()) as TurnPhase
		if current_phase == TurnPhase.MORNING:
			current_turn += 1
	
	_start_turn()

func _on_end_turn_requested() -> void:
	next_turn()

func _on_player_moved(_new_position: Vector2i) -> void:
	var current_player = get_current_player()
	if current_player and in_game_ui:
		var movement_info = current_player.get_movement_info()
		in_game_ui.update_movement_remaining(movement_info.movement_speed, movement_info.movement_cost_spent)

func get_current_player() -> Player:
	if players.is_empty():
		return null
	return players[current_player_index]

func get_current_state() -> GameState:
	return current_state

func get_phase_name() -> String:
	match current_phase:
		TurnPhase.MORNING:
			return "Morning Move"
		TurnPhase.AFTERNOON:
			return "Afternoon Move"
		TurnPhase.NIGHT:
			return "Night Action"
		_:
			return "Unknown"

func is_game_active() -> bool:
	return current_state == GameState.IN_GAME
