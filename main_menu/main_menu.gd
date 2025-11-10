extends Control

@export var game_scene: PackedScene

var ui_main_menu_manager: UIMainMenuManager = null

func _ready() -> void:
	_setup_ui()

func _on_start_button_pressed() -> void:
	if game_scene:
		get_tree().change_scene_to_packed(game_scene)
	else:
		print("MainMenu: Error - No game scene assigned!")

func _setup_ui() -> void:
	ui_main_menu_manager = UIMainMenuManager.new()
	add_child(ui_main_menu_manager)
	ui_main_menu_manager.start_game_requested.connect(_on_start_button_pressed)
