extends Control

@export var pre_game_scene: PackedScene

var main_menu_ui: MainMenuUI = null

func _ready() -> void:
	_setup_ui()

func _on_start_button_pressed() -> void:
	if pre_game_scene:
		get_tree().change_scene_to_packed(pre_game_scene)
	else:
		print("MainMenu: Error - No pre-game scene assigned!")

func _setup_ui() -> void:
	main_menu_ui = MainMenuUI.new()
	add_child(main_menu_ui)
	main_menu_ui.start_game_requested.connect(_on_start_button_pressed)
