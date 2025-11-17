extends Control

class_name GearSelectionUI

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
@onready var extras_selector: Button

var player_selectors = {}
var extras_dialogs = {}
var extras_checkboxes = {}

var main_menu: Node3D = null

signal start_game_requested()

func _ready() -> void:
	_setup_ui()
	get_viewport().size_changed.connect(_on_viewport_size_changed)

func _create_extras_dialog(player_id: int) -> AcceptDialog:
	var dialog = AcceptDialog.new()
	dialog.title = "Select Extras - Player " + str(player_id)
	
	var viewport_size = get_viewport().get_visible_rect().size
	var dialog_size = Vector2i(int(viewport_size.x * 0.4), int(viewport_size.y * 0.4))
	dialog.size = dialog_size
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margin = 20
	vbox.offset_left = margin
	vbox.offset_right = -margin
	vbox.offset_top = margin
	vbox.offset_bottom = -margin
	vbox.add_theme_constant_override("separation", 10)
	dialog.add_child(vbox)
	
	var base_font_size = int(viewport_size.y * 0.02)
	var checkboxes = {}
	
	for extras_id in game_data.extras.keys():
		var extras_data = game_data.extras[extras_id]
		var checkbox = CheckBox.new()
		checkbox.text = extras_data["name"]
		checkbox.add_theme_font_size_override("font_size", base_font_size)
		vbox.add_child(checkbox)
		checkboxes[extras_id] = checkbox
	
	extras_checkboxes[player_id] = checkboxes
	dialog.confirmed.connect(_on_extras_dialog_confirmed.bind(player_id))
	
	return dialog

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
		for tent_id in game_data.tents.keys():
			var tent_data = game_data.tents[tent_id]
			tent_selector.add_item(tent_data["name"])
		tent_selector.custom_minimum_size = Vector2(button_width / 3.0, button_height)
		tent_selector.add_theme_font_size_override("font_size", base_font_size)
		var tent_popup_menu = tent_selector.get_popup()
		tent_popup_menu.add_theme_font_size_override("font_size", base_font_size)
		player_box.add_child(tent_selector)
		selectors["tent"] = tent_selector

		sleeping_bag_selector = OptionButton.new()
		for sleeping_bag_id in game_data.sleeping_bags.keys():
			var sleeping_bag_data = game_data.sleeping_bags[sleeping_bag_id]
			sleeping_bag_selector.add_item(sleeping_bag_data["name"])
		sleeping_bag_selector.custom_minimum_size = Vector2(button_width / 3.0, button_height)
		sleeping_bag_selector.add_theme_font_size_override("font_size", base_font_size)
		var sleeping_bag_popup_menu = sleeping_bag_selector.get_popup()
		sleeping_bag_popup_menu.add_theme_font_size_override("font_size", base_font_size)
		player_box.add_child(sleeping_bag_selector)
		selectors["sleeping_bag"] = sleeping_bag_selector

		extras_selector = Button.new()
		extras_selector.text = "Select Extras"
		extras_selector.custom_minimum_size = Vector2(button_width / 3.0, button_height)
		extras_selector.add_theme_font_size_override("font_size", base_font_size)
		extras_selector.connect("pressed", Callable(self, "_on_extras_button_pressed").bind(i+1))
		player_box.add_child(extras_selector)
		
		var extras_dialog = _create_extras_dialog(i+1)
		add_child(extras_dialog)
		extras_dialogs[i+1] = extras_dialog
		
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
	var saved_dialogs = extras_dialogs.duplicate()
	var saved_checkboxes = extras_checkboxes.duplicate()
	
	var children_to_remove = []
	for child in get_children():
		if not child in saved_dialogs.values():
			children_to_remove.append(child)
	
	for child in children_to_remove:
		child.queue_free()
	
	for player_id in saved_dialogs.keys():
		var dialog = saved_dialogs[player_id]
		if dialog and dialog.get_parent() != self:
			add_child(dialog)
	
	extras_dialogs = saved_dialogs
	extras_checkboxes = saved_checkboxes
	
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
			if gear_type == "extras":
				var selected_extras = []
				var checkboxes = extras_checkboxes.get(player_id, {})
				for extras_id in checkboxes.keys():
					if checkboxes[extras_id] and checkboxes[extras_id].button_pressed:
						selected_extras.append(game_data.extras[extras_id]["name"])
				gear[gear_type] = selected_extras
			else:
				gear[gear_type] = selector.get_item_text(selector.get_selected())

		game_data.player_gear[player_id] = gear

func _on_extras_button_pressed(player_id: int):
	var dialog = extras_dialogs.get(player_id)
	if dialog:
		var viewport_size = get_viewport().get_visible_rect().size
		var dialog_size = Vector2i(int(viewport_size.x * 0.4), int(viewport_size.y * 0.4))
		dialog.size = dialog_size
		dialog.popup_centered()

func _on_extras_dialog_confirmed(player_id: int):
	_update_extras_button_text(player_id)

func _update_extras_button_text(player_id: int):
	var button = player_selectors[player_id]["extras"]
	var checkboxes = extras_checkboxes.get(player_id, {})
	var selected = []
	
	for extras_id in checkboxes.keys():
		if checkboxes[extras_id] and checkboxes[extras_id].button_pressed:
			selected.append(game_data.extras[extras_id]["name"])
	
	button.text = "Extras: " + (", ".join(selected) if selected.size() > 0 else "None")
