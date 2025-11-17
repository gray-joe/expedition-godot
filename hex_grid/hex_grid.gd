extends Node3D

var TILE_CONFIGS = {}

const TILE_SIZE := 1.0
const TILE_SCENES = {
	"grass": preload("res://tiles/grass_hex_tile.tscn"),
	"marsh": preload("res://tiles/marsh_hex_tile.tscn"),
	"rock": preload("res://tiles/rock_hex_tile.tscn"),
	"water": preload("res://tiles/water_hex_tile.tscn"),
	"starting": preload("res://tiles/starting_hex_tile.tscn")
}

const PLAYER_SCENE = preload("res://pieces/player_piece.tscn") 

@export var grid_width := 20
@export var grid_height := 10
@export var camera_angle := -70.0
@export var camera_padding := 1.2
var grid_data: Array[Array] = []
var players: Array[Node3D] = []
var starting_tile_positions: Array[Vector2i] = []
var current_player: Node3D = null

func _ready() -> void:
	_setup_tile_configs()
	_setup_lighting()
	_generate_test_grid()
	call_deferred("_setup_camera")

func _setup_tile_configs():
	var grass_config = TileConfig.new()
	grass_config.tile_type = "grass"
	grass_config.movement_cost = 1
	grass_config.is_walkable = true
	grass_config.is_campable = true
	TILE_CONFIGS["grass"] = grass_config
	
	var marsh_config = TileConfig.new()
	marsh_config.tile_type = "marsh"
	marsh_config.movement_cost = 2
	marsh_config.is_walkable = true
	marsh_config.is_campable = false
	marsh_config.special_properties = {}
	TILE_CONFIGS["marsh"] = marsh_config
	
	var rock_config = TileConfig.new()
	rock_config.tile_type = "rock"
	rock_config.movement_cost = 3
	rock_config.is_walkable = true
	rock_config.is_campable = false
	rock_config.special_properties = {}
	TILE_CONFIGS["rock"] = rock_config
	
	var water_config = TileConfig.new()
	water_config.tile_type = "water"
	water_config.movement_cost = 99
	water_config.is_walkable = false
	water_config.is_campable = false
	water_config.special_properties = {"water_resource": 100}
	TILE_CONFIGS["water"] = water_config

	var starting_config = TileConfig.new()
	starting_config.tile_type = "starting"
	starting_config.movement_cost = 1
	starting_config.is_walkable = true
	starting_config.is_campable = true
	starting_config.special_properties = {"starting_tile": true}
	TILE_CONFIGS["starting"] = starting_config

func _setup_lighting():
	var light = DirectionalLight3D.new()
	light.light_energy = 1.0
	light.light_color = Color.WHITE
	light.rotation_degrees = Vector3(-45, 45, 0)
	add_child(light)

func _setup_camera():
	var existing_camera = get_node_or_null("GridCamera")
	if existing_camera:
		existing_camera.queue_free()
	
	var grid_center_x = (grid_width - 1) * TILE_SIZE * cos(deg_to_rad(30)) / 2.0
	var grid_center_z = (grid_height - 1) * TILE_SIZE / 2.0
	
	var grid_width_world = grid_width * TILE_SIZE * cos(deg_to_rad(30))
	var grid_height_world = grid_height * TILE_SIZE
	var max_dimension = max(grid_width_world, grid_height_world)
	
	var fov_radians = deg_to_rad(abs(camera_angle))
	var distance = (max_dimension / 2.0) / tan(fov_radians / 2.0)
	
	distance *= camera_padding
	
	var camera = Camera3D.new()
	camera.name = "GridCamera"
	camera.fov = abs(camera_angle)
	
	var camera_x = grid_center_x
	var camera_y = distance * sin(deg_to_rad(abs(camera_angle)))
	var camera_z = grid_center_z + distance * cos(deg_to_rad(abs(camera_angle)))
	
	camera.position = Vector3(camera_x, camera_y, camera_z)
	
	add_child(camera)
	
	camera.look_at(Vector3(grid_center_x, 0, grid_center_z), Vector3.UP)
	
	camera.current = true

func _find_starting_tile() -> Vector2i:
	if starting_tile_positions.size() > 0:
		return starting_tile_positions[0]
	
	print("Warning: No starting tile found! Player not spawned.")
	return Vector2i(-1, -1)

func get_starting_tiles() -> Array[Vector2i]:
	return starting_tile_positions.duplicate()

func get_all_players() -> Array[Node3D]:
	return players.duplicate()

func get_player_count() -> int:
	return players.size()

func get_player_at_index(index: int) -> Node3D:
	if index >= 0 and index < players.size():
		return players[index]
	return null

func set_current_player(player: Node3D) -> void:
	current_player = player
	var player_name = player.name if player else "null"

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _is_click_on_ui(event.position):
			return
		
		if current_player:
			_handle_tile_click(event.position)

func _is_click_on_ui(mouse_position: Vector2) -> bool:
	var ui_rect = Rect2(20, 20, 300, 150)
	return ui_rect.has_point(mouse_position)

func _handle_tile_click(mouse_position: Vector2) -> void:
	var clicked_tile = _get_clicked_tile_by_collision(mouse_position)
	if clicked_tile:
		var grid_pos = _get_tile_grid_position(clicked_tile)
		if grid_pos != Vector2i(-1, -1):
			_attempt_player_movement(grid_pos)
		else:
			print("HexGrid: Could not determine grid position for tile")
		return
	
	var camera = get_viewport().get_camera_3d()
	
	var from = camera.project_ray_origin(mouse_position)
	var direction = camera.project_ray_normal(mouse_position)
	
	var t = -from.y / direction.y
	var world_pos = from + direction * t
	
	var grid_pos = _world_to_grid_position(world_pos)
	if _is_valid_grid_position(grid_pos):
		var closest_tile = _find_closest_tile_to_position(world_pos)
		if closest_tile:
			var closest_grid_pos = _get_tile_grid_position(closest_tile)
			if closest_grid_pos != Vector2i(-1, -1):
				_attempt_player_movement(closest_grid_pos)

func _get_clicked_tile_by_collision(mouse_position: Vector2) -> Node3D:
	var camera = get_viewport().get_camera_3d()
	if not camera:
		return null
	
	var space_state = get_world_3d().direct_space_state
	var from = camera.project_ray_origin(mouse_position)
	var to = from + camera.project_ray_normal(mouse_position) * 1000
	
	var query = PhysicsRayQueryParameters3D.create(from, to)
	var result = space_state.intersect_ray(query)
	
	if result:
		var clicked_object = result.collider
		if clicked_object.name.begins_with("hex_tile_") or clicked_object.name.begins_with("starting_tile_"):
			return clicked_object
	
	return null

func _find_closest_tile_to_position(world_pos: Vector3) -> Node3D:
	var closest_tile = null
	var closest_distance = INF
	
	for child in get_children():
		if child.name.begins_with("hex_tile_") or child.name.begins_with("starting_tile_"):
			var distance = world_pos.distance_to(child.global_position)
			if distance < closest_distance:
				closest_distance = distance
				closest_tile = child
	
	return closest_tile

func _get_tile_grid_position(tile: Node3D) -> Vector2i:
	if tile.name.begins_with("hex_tile_"):
		var parts = tile.name.split("_")
		if parts.size() >= 4:
			var x = int(parts[2])
			var y = int(parts[3])
			return Vector2i(x, y)
	elif tile.name.begins_with("starting_tile_"):
		return _world_to_grid_position(tile.global_position)
	
	return Vector2i(-1, -1)

func _attempt_player_movement(grid_pos: Vector2i) -> void:
	if current_player and current_player.has_method("move_to"):
		var success = current_player.move_to(grid_pos)
		if success:
			pass
		else:
			print("HexGrid: Player movement failed to: ", grid_pos)

func _world_to_grid_position(world_pos: Vector3) -> Vector2i:
	var x = round(world_pos.x / (TILE_SIZE * cos(deg_to_rad(30))))
	var y = round(world_pos.z / TILE_SIZE)
	return Vector2i(int(x), int(y))

func _is_valid_grid_position(grid_pos: Vector2i) -> bool:
	if grid_pos.x >= 0 and grid_pos.x < grid_width and grid_pos.y >= 0 and grid_pos.y < grid_height:
		return true
	
	for starting_pos in starting_tile_positions:
		if grid_pos == starting_pos:
			return true
	
	return false

func _grid_to_world_position(grid_pos: Vector2i) -> Vector3:
	var x = grid_pos.x
	var y = grid_pos.y
	
	var tile_coordinates := Vector2.ZERO
	tile_coordinates.x = x * TILE_SIZE * cos(deg_to_rad(30))
	tile_coordinates.y = 0.0 if x % 2 == 0 else TILE_SIZE / 2
	
	tile_coordinates.y += y * TILE_SIZE
	
	return Vector3(tile_coordinates.x, 0.1, tile_coordinates.y)

func generate_from_config(config: Array[Array]) -> void:
	grid_data = config
	_clear_existing_tiles()
	_generate_grid()

func generate_uniform_grid(tile_type: String) -> void:
	var config: Array[Array] = []
	for x in range(grid_width):
		var row: Array = []
		for y in range(grid_height):
			row.append(tile_type)
		config.append(row)
	generate_from_config(config)

func get_grid_dimensions() -> Vector2i:
	return Vector2i(grid_width, grid_height)

func get_tile_type_at(grid_pos: Vector2i) -> String:
	if grid_pos.x < 0 or grid_pos.x >= grid_data.size():
		return ""
	if grid_pos.y < 0 or grid_pos.y >= grid_data[grid_pos.x].size():
		return ""
	return grid_data[grid_pos.x][grid_pos.y]

func get_tile_config(tile_type: String) -> TileConfig:
	return TILE_CONFIGS.get(tile_type)

func get_tile_config_at(grid_pos: Vector2i) -> TileConfig:
	for start_pos in starting_tile_positions:
		if grid_pos == start_pos:
			return TILE_CONFIGS.get("starting")
	var tile_type := get_tile_type_at(grid_pos)
	if tile_type == "":
		return null
	return TILE_CONFIGS.get(tile_type)

func grid_to_world_position(grid_pos: Vector2i) -> Vector3:
	return _grid_to_world_position(grid_pos)

func spawn_player_on_starting_tile(player_instance: Node3D, starting_tile_pos: Vector2i = Vector2i(-1, -1)) -> bool:
	if starting_tile_pos == Vector2i(-1, -1):
		starting_tile_pos = _find_starting_tile()
	
	if starting_tile_pos != Vector2i(-1, -1):
		players.append(player_instance)
		add_child(player_instance)
		
		var world_pos = _grid_to_world_position(starting_tile_pos)
		player_instance.position = world_pos
		
		if player_instance.has_method("set_grid_position"):
			player_instance.set_grid_position(starting_tile_pos)
		
		return true
	else:
		print("HexGrid: Warning - No starting tile found! Player not spawned.")
		return false

func _normalize_to_grid(grid_pos: Vector2i) -> Vector2i:
	var x := grid_pos.x
	var y := grid_pos.y
	if x < 0:
		x = 0
	elif x >= grid_width:
		x = grid_width - 1
	if y < 0:
		y = 0
	elif y >= grid_height:
		y = grid_height - 1
	return Vector2i(x, y)

func _generate_test_grid() -> void:
	var test_config: Array[Array] = []
	
	for x in range(grid_width):
		var row: Array = []
		for y in range(grid_height):
			var rand_value = randf()
			var tile_type: String
			
			if rand_value < 0.5:
				tile_type = "grass"
			elif rand_value < 0.7:
				tile_type = "marsh"
			elif rand_value < 0.9:
				tile_type = "rock"
			else:
				tile_type = "water"
			
			row.append(tile_type)
		test_config.append(row)
	
	_add_starting_tiles_around_perimeter(test_config)
	
	generate_from_config(test_config)

func _add_starting_tiles_around_perimeter(_config: Array[Array]) -> void:
	var mid_height = grid_height / 2
	var quarter_width = grid_width / 4
	var three_quarter_width = grid_width * 3 / 4
	
	var starting_positions: Array[Vector2i] = [
		Vector2i(-1, mid_height),
		Vector2i(grid_width, mid_height),
		Vector2i(quarter_width, -1),
		Vector2i(three_quarter_width, -1),
		Vector2i(quarter_width - 1, grid_height),
		Vector2i(three_quarter_width + 1, grid_height)
	]
	
	starting_tile_positions = starting_positions

func _clear_existing_tiles() -> void:
	for child in get_children():
		if child.name.begins_with("hex_tile") or child.name.begins_with("Player_"):
			child.queue_free()
	
	players.clear()

func _generate_grid():
	for x in range(grid_data.size()):
		var tile_coordinates := Vector2.ZERO
		tile_coordinates.x = x * TILE_SIZE * cos(deg_to_rad(30))
		tile_coordinates.y = 0.0 if x % 2 == 0 else TILE_SIZE / 2
		
		for y in range(grid_data[x].size()):
			var tile_type = grid_data[x][y]
			var tile_config = TILE_CONFIGS.get(tile_type)
			var tile_scene = TILE_SCENES.get(tile_type)
			
			if tile_config and tile_scene:
				var tile = tile_scene.instantiate()
				tile.name = "hex_tile_" + str(x) + "_" + str(y)
				add_child(tile)
				tile.translate(Vector3(tile_coordinates.x, 0, tile_coordinates.y))
				
				_add_collision_to_tile(tile)
				
				tile.set_meta("tile_config", tile_config)
			
			tile_coordinates.y += TILE_SIZE
	
	_generate_starting_tiles()

func _add_collision_to_tile(tile: Node3D) -> void:
	if tile.get_node_or_null("StaticBody3D"):
		return
	
	var static_body = StaticBody3D.new()
	static_body.name = "StaticBody3D"
	tile.add_child(static_body)
	
	var collision_shape = CollisionShape3D.new()
	collision_shape.name = "CollisionShape3D"
	static_body.add_child(collision_shape)
	
	var cylinder_shape = CylinderShape3D.new()
	cylinder_shape.height = 0.2
	cylinder_shape.radius = TILE_SIZE / 2.0
	collision_shape.shape = cylinder_shape
	
func _generate_starting_tiles():
	for i in range(starting_tile_positions.size()):
		var pos = starting_tile_positions[i]
		var world_pos = _grid_to_world_position(pos)
		
		var starting_tile_scene = TILE_SCENES.get("starting")
		var starting_tile_config = TILE_CONFIGS.get("starting")
		
		if starting_tile_scene and starting_tile_config:
			var tile = starting_tile_scene.instantiate()
			tile.name = "starting_tile_" + str(i)
			add_child(tile)
			tile.translate(world_pos)
			
			_add_collision_to_tile(tile)
			
			tile.set_meta("tile_config", starting_tile_config)
			tile.set_meta("grid_position", pos)
