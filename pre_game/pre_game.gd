extends Control

@export var game_scene: PackedScene

var pre_grame_ui: PreGameUI = null

func _ready() -> void:
	_setup_ui()

func _on_start_button_pressed() -> void:
	if game_scene:
		get_tree().change_scene_to_packed(game_scene)
	else:
		print("PreGame: Error - No game scene assigned!")

func _setup_ui() -> void:
	pre_grame_ui = PreGameUI.new()
	add_child(pre_grame_ui)
	pre_grame_ui.start_game_requested.connect(_on_start_button_pressed)
