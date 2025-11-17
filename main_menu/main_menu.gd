extends Control

@export var skill_card_allocation_scene: PackedScene

var main_menu_ui: MainMenuUI = null

func _ready() -> void:
	_setup_ui()

func _on_start_button_pressed() -> void:
	if skill_card_allocation_scene:
		get_tree().change_scene_to_packed(skill_card_allocation_scene)
	else:
		print("MainMenu: Error - No skill card allocation scene assigned!")

func _setup_ui() -> void:
	main_menu_ui = MainMenuUI.new()
	add_child(main_menu_ui)
	main_menu_ui.start_game_requested.connect(_on_start_button_pressed)
