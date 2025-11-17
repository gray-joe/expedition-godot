extends Control

class_name SkillCardAllocationUI

const PANEL_WIDTH_RATIO = 1
const PANEL_HEIGHT_RATIO = 1
const MARGIN_RATIO = 0.2
const SEPARATION_RATIO = 0.01
const BASE_FONT_RATIO = 0.025
const BUTTON_WIDTH_RATIO = 0.6
const BUTTON_HEIGHT_RATIO = 0.04

@onready var continue_button: Button
@onready var randomize_button: Button

var player_selectors = {}
var info_buttons = {}

var main_menu: Node3D = null
var description_dialog: AcceptDialog = null
var description_label: RichTextLabel = null

signal continue_requested()

func _ready() -> void:
	description_dialog = AcceptDialog.new()
	description_dialog.title = "Skill Card Description"
	
	# Create RichTextLabel for better text formatting
	description_label = RichTextLabel.new()
	description_label.bbcode_enabled = true
	description_label.fit_content = true
	description_label.scroll_active = false
	description_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margin = 20
	description_label.offset_left = margin
	description_label.offset_right = -margin
	description_label.offset_top = margin
	description_label.offset_bottom = -margin
	
	description_dialog.add_child(description_label)
	add_child(description_dialog)
	
	_setup_ui()
	get_viewport().size_changed.connect(_on_viewport_size_changed)

func _setup_ui() -> void:
	await get_tree().process_frame
	_setup_responsive_ui()
	_connect_signals()

func _setup_responsive_ui() -> void:
	var screen_size = get_viewport().get_visible_rect().size
	var panel_width = int(screen_size.x * PANEL_WIDTH_RATIO)
	var margin = int(screen_size.x * MARGIN_RATIO)
	var separation = int(screen_size.y * SEPARATION_RATIO)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	vbox.offset_left = margin
	vbox.offset_top = margin
	vbox.add_theme_constant_override("separation", separation)
	add_child(vbox)
	
	var base_font_size = int(screen_size.y * BASE_FONT_RATIO)
	
	var button_container = HBoxContainer.new()
	button_container.add_theme_constant_override("separation", separation)
	vbox.add_child(button_container)
	
	var button_width = int(panel_width * BUTTON_WIDTH_RATIO)
	var button_height = int(screen_size.y * BUTTON_HEIGHT_RATIO)
	
	continue_button = Button.new()
	continue_button.text = "Continue"
	continue_button.custom_minimum_size = Vector2(button_width / 1.25, button_height)
	continue_button.add_theme_font_size_override("font_size", base_font_size)
	button_container.add_child(continue_button)

	randomize_button = Button.new()
	randomize_button.text = "Randomize"
	randomize_button.custom_minimum_size = Vector2(button_width / 4.0, button_height)
	randomize_button.add_theme_font_size_override("font_size", base_font_size)
	button_container.add_child(randomize_button)
	
	for i in range(game_data.player_count):
		var player_box = HBoxContainer.new()
		vbox.add_child(player_box)

		var player_label = Label.new()
		player_label.text = "Player %s" % [i+1]
		player_box.add_child(player_label)

		var skill_card_selector = OptionButton.new()
		skill_card_selector.add_item("None")
		for skill_card_id in game_data.skill_cards.keys():
			var skill_card_data = game_data.skill_cards[skill_card_id]
			skill_card_selector.add_item(skill_card_data["name"])
		skill_card_selector.custom_minimum_size = Vector2(button_width / 2.0, button_height)
		skill_card_selector.add_theme_font_size_override("font_size", base_font_size)
		var skill_card_popup_menu = skill_card_selector.get_popup()
		skill_card_popup_menu.add_theme_font_size_override("font_size", base_font_size)
		player_box.add_child(skill_card_selector)
		
		var info_button = Button.new()
		info_button.text = "ℹ"
		info_button.custom_minimum_size = Vector2(button_height, button_height)
		info_button.add_theme_font_size_override("font_size", int(base_font_size * 1.2))
		info_button.pressed.connect(_on_info_button_pressed.bind(i+1))
		player_box.add_child(info_button)
		
		player_selectors[i+1] = skill_card_selector
		info_buttons[i+1] = info_button


func _connect_signals() -> void:
	if continue_button:
		continue_button.pressed.connect(_on_continue_button_pressed)
	else:
		print("SkillCardAllocationUI: Error - Continue button not found!")
	
	if randomize_button:
		randomize_button.pressed.connect(_on_randomize_button_pressed)
	else:
		print("SkillCardAllocationUI: Error - Randomize button not found!")

func _on_continue_button_pressed() -> void:
	get_skill_card_selection()
	continue_requested.emit()

func _on_randomize_button_pressed() -> void:
	randomize_skill_cards()

func _on_info_button_pressed(player_id: int) -> void:
	show_skill_card_description(player_id)

func _on_viewport_size_changed() -> void:
	var saved_dialog = description_dialog
	var saved_label = description_label
	
	var children_to_remove = []
	for child in get_children():
		if child != saved_dialog:
			children_to_remove.append(child)
	
	for child in children_to_remove:
		child.queue_free()
	
	if saved_dialog and saved_dialog.get_parent() != self:
		add_child(saved_dialog)
		# Re-add label if it was removed
		if saved_label and saved_label.get_parent() != saved_dialog:
			saved_dialog.add_child(saved_label)
	
	description_dialog = saved_dialog
	description_label = saved_label
	_setup_responsive_ui()
	_connect_signals()

func set_continue_enabled(enabled: bool) -> void:
	if continue_button:
		continue_button.disabled = not enabled

func randomize_skill_cards() -> void:
	var available_cards = game_data.skill_cards.keys().duplicate()
	available_cards.shuffle()
	
	var card_index = 0
	for player_id in player_selectors.keys():
		var selector = player_selectors[player_id]
		
		if card_index < available_cards.size():
			var skill_card_id = available_cards[card_index]
			var skill_card_name = game_data.skill_cards[skill_card_id]["name"]
			
			var target_index = 0
			for i in range(1, selector.get_item_count()):
				if selector.get_item_text(i) == skill_card_name:
					target_index = i
					break
			
			selector.selected = target_index
			card_index += 1
		else:
			var random_card_id = available_cards[randi() % available_cards.size()]
			var skill_card_name = game_data.skill_cards[random_card_id]["name"]
			
			var target_index = 0
			for i in range(1, selector.get_item_count()):
				if selector.get_item_text(i) == skill_card_name:
					target_index = i
					break
			
			selector.selected = target_index

func show_skill_card_description(player_id: int) -> void:
	if not description_dialog:
		print("SkillCardAllocationUI: Error - Description dialog not created!")
		return
	
	var selector = player_selectors.get(player_id)
	if not selector:
		print("SkillCardAllocationUI: Error - Selector not found for player ", player_id)
		return
	
	var selected_text = selector.get_item_text(selector.get_selected())
	
	# Set dialog size as percentage of viewport
	var viewport_size = get_viewport().get_visible_rect().size
	var dialog_size = Vector2i(int(viewport_size.x * 0.4), int(viewport_size.y * 0.3))
	description_dialog.size = dialog_size
	
	# Calculate font size based on viewport
	var base_font_size = int(viewport_size.y * 0.02)
	
	if selected_text == "None":
		description_label.text = "[center][font_size=" + str(base_font_size) + "]No skill card selected.[/font_size][/center]"
	else:
		for skill_card_id in game_data.skill_cards.keys():
			if game_data.skill_cards[skill_card_id]["name"] == selected_text:
				var skill_card_data = game_data.skill_cards[skill_card_id]
				var title_size = int(base_font_size * 1.4)
				var desc_size = int(base_font_size * 1.1)
				description_label.text = "[center][font_size=" + str(title_size) + "][b]" + skill_card_data["name"] + "[/b][/font_size][/center]\n\n[font_size=" + str(desc_size) + "]" + skill_card_data["description"] + "[/font_size]"
				break
	
	description_dialog.popup_centered()
	print("SkillCardAllocationUI: Showing description dialog for: ", selected_text)

func get_skill_card_selection():
	for player_id in player_selectors.keys():
		var selector = player_selectors[player_id]
		var selected_text = selector.get_item_text(selector.get_selected())
		
		if selected_text == "None":
			game_data.player_skill_cards[player_id] = null
		else:
			for skill_card_id in game_data.skill_cards.keys():
				if game_data.skill_cards[skill_card_id]["name"] == selected_text:
					game_data.player_skill_cards[player_id] = skill_card_id
					break
