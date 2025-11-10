extends Control

class_name UIMainMenuManager

const PANEL_WIDTH_RATIO = 1
const PANEL_HEIGHT_RATIO = 1
const MARGIN_RATIO = 0.2
const SEPARATION_RATIO = 0.01
const BASE_FONT_RATIO = 0.025
const BUTTON_WIDTH_RATIO = 0.6
const BUTTON_HEIGHT_RATIO = 0.04

@onready var start_game_button: Button

var main_menu: Node3D = null

signal start_game_requested()

func _ready() -> void:
	_setup_ui()
	get_viewport().size_changed.connect(_on_viewport_size_changed)

func _setup_ui() -> void:
	await get_tree().process_frame
	_setup_responsive_ui()
	_connect_signals()

func _setup_responsive_ui() -> void:
	var screen_size = get_viewport().get_visible_rect().size
	var panel_width = int(screen_size.x * PANEL_WIDTH_RATIO)
	var panel_height = int(screen_size.y * PANEL_HEIGHT_RATIO)
	var margin = int(screen_size.x * MARGIN_RATIO)
	var separation = int(screen_size.y * SEPARATION_RATIO)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	vbox.offset_left = margin
	vbox.offset_top = margin
	vbox.add_theme_constant_override("separation", separation)
	add_child(vbox)
	
	var base_font_size = int(screen_size.y * BASE_FONT_RATIO)
	var title_font_size = int(base_font_size * 1.2)
	var button_font_size = int(base_font_size * 0.8)
	
	start_game_button = Button.new()
	start_game_button.text = "Start Game"
	var button_width = int(panel_width * BUTTON_WIDTH_RATIO)
	var button_height = int(screen_size.y * BUTTON_HEIGHT_RATIO)
	start_game_button.custom_minimum_size = Vector2(button_width, button_height)
	start_game_button.add_theme_font_size_override("font_size", base_font_size)
	vbox.add_child(start_game_button)

func _connect_signals() -> void:
	if start_game_button:
		start_game_button.pressed.connect(_on_start_game_button_pressed)
	else:
		print("UIMainMenuManager: Error - Start game turn button not found!")

func _on_start_game_button_pressed() -> void:
	start_game_requested.emit()

func _on_viewport_size_changed() -> void:
	for child in get_children():
		child.queue_free()
	_setup_responsive_ui()
	_connect_signals()

func set_start_game_enabled(enabled: bool) -> void:
	if start_game_button:
		start_game_button.disabled = not enabled

