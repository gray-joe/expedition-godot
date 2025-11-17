extends Control

@export var game_scene: PackedScene

var gear_selection_ui: GearSelectionUI = null

func _ready() -> void:
	_setup_ui()

func _on_start_button_pressed() -> void:
	if game_scene:
		get_tree().change_scene_to_packed(game_scene)
	else:
		print("GearSelection: Error - No game scene assigned!")

func _setup_ui() -> void:
	gear_selection_ui = GearSelectionUI.new()
	add_child(gear_selection_ui)
	gear_selection_ui.start_game_requested.connect(_on_start_button_pressed)
