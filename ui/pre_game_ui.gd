extends Control

class_name PreGameUI

const PANEL_WIDTH_RATIO = 1
const PANEL_HEIGHT_RATIO = 1
const MARGIN_RATIO = 0.2
const SEPARATION_RATIO = 0.01
const BASE_FONT_RATIO = 0.025
const BUTTON_WIDTH_RATIO = 0.6
const BUTTON_HEIGHT_RATIO = 0.04

@onready var start_game_button: Button
@onready var player_label: Label
@onready var tent_selector: OptionButton
@onready var sleeping_bag_selector: OptionButton
@onready var extras_selector: OptionButton

var player_selectors = {}

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
	#var panel_height = int(screen_size.y * PANEL_HEIGHT_RATIO)
	var margin = int(screen_size.x * MARGIN_RATIO)
	var separation = int(screen_size.y * SEPARATION_RATIO)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	vbox.offset_left = margin
	vbox.offset_top = margin
	vbox.add_theme_constant_override("separation", separation)
	add_child(vbox)
	
	var base_font_size = int(screen_size.y * BASE_FONT_RATIO)
	#var title_font_size = int(base_font_size * 1.2)
	#var button_font_size = int(base_font_size * 0.8)
	
	start_game_button = Button.new()
	start_game_button.text = "Begin Expedition!"
	var button_width = int(panel_width * BUTTON_WIDTH_RATIO)
	var button_height = int(screen_size.y * BUTTON_HEIGHT_RATIO)
	start_game_button.custom_minimum_size = Vector2(button_width, button_height)
	start_game_button.add_theme_font_size_override("font_size", base_font_size)
	vbox.add_child(start_game_button)

	for i in range(game_data.player_count):
		var player_box = HBoxContainer.new()
		vbox.add_child(player_box)

		player_label = Label.new()
		player_label.text = "Player %s" % [i+1]
		player_box.add_child(player_label)

		var selectors = {}

		tent_selector = OptionButton.new()
		tent_selector.add_item("Heavy / all seasons")
		tent_selector.add_item("Light / 2 seasons")
		tent_selector.custom_minimum_size = Vector2(button_width / 3.0, button_height)
		tent_selector.add_theme_font_size_override("font_size", base_font_size)
		var tent_popup_menu = tent_selector.get_popup()
		tent_popup_menu.add_theme_font_size_override("font_size", base_font_size)
		player_box.add_child(tent_selector)
		selectors["tent"] = tent_selector

		sleeping_bag_selector = OptionButton.new()
		sleeping_bag_selector.add_item("Heavy / all seasons")
		sleeping_bag_selector.add_item("Light / 2 seasons")
		sleeping_bag_selector.custom_minimum_size = Vector2(button_width / 3.0, button_height)
		sleeping_bag_selector.add_theme_font_size_override("font_size", base_font_size)
		var sleeping_bag_popup_menu = sleeping_bag_selector.get_popup()
		sleeping_bag_popup_menu.add_theme_font_size_override("font_size", base_font_size)
		player_box.add_child(sleeping_bag_selector)
		selectors["sleeping_bag"] = sleeping_bag_selector

		extras_selector = OptionButton.new()
		extras_selector.add_item("Extra water")
		extras_selector.add_item("Extra food")
		extras_selector.add_item("Extra socks")
		extras_selector.custom_minimum_size = Vector2(button_width / 3.0, button_height)
		extras_selector.add_theme_font_size_override("font_size", base_font_size)
		var extras_popup_menu = extras_selector.get_popup()
		extras_popup_menu.add_theme_font_size_override("font_size", base_font_size)
		player_box.add_child(extras_selector)
		selectors["extras"] = extras_selector
		
		player_selectors[i+1] = selectors


func _connect_signals() -> void:
	if start_game_button:
		start_game_button.pressed.connect(_on_start_game_button_pressed)
	else:
		print("PreGameUI: Error - Start expedition button not found!")

func _on_start_game_button_pressed() -> void:
	get_gear_selection()
	start_game_requested.emit()

func _on_viewport_size_changed() -> void:
	for child in get_children():
		child.queue_free()
	_setup_responsive_ui()
	_connect_signals()

func set_start_game_enabled(enabled: bool) -> void:
	if start_game_button:
		start_game_button.disabled = not enabled

func get_gear_selection():
	for player_id in player_selectors.keys():
		var gear = {}
		for gear_type in player_selectors[player_id].keys():
			var selector = player_selectors[player_id][gear_type]
			gear[gear_type] = selector.get_item_text(selector.get_selected())
			game_data.player_gear[player_id] = gear
