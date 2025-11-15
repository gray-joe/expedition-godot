extends Control

class_name InGameUI

const PANEL_WIDTH_RATIO = 0.2
const PANEL_HEIGHT_RATIO = 0.25
const MARGIN_RATIO = 0.02
const SEPARATION_RATIO = 0.01
const BASE_FONT_RATIO = 0.02
const PROGRESS_WIDTH_RATIO = 0.7
const PROGRESS_HEIGHT_RATIO = 0.02
const BUTTON_WIDTH_RATIO = 0.6
const BUTTON_HEIGHT_RATIO = 0.04

@onready var current_player_label: Label
@onready var end_turn_button: Button
@onready var turn_info_panel: Panel
@onready var turn_label: Label
@onready var phase_label: Label
@onready var movement_instruction_label: Label
@onready var turn_timer_label: Label
@onready var turn_progress_bar: ProgressBar
@onready var movement_remaining_label: Label

var game_manager: Node3D = null
var current_turn_manager: TurnManager = null
var turn_timer_active: bool = false
var ui_timer: float = 0.0
var timeout_triggered: bool = false

signal end_turn_requested()

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
	
	turn_info_panel = Panel.new()
	turn_info_panel.custom_minimum_size = Vector2(panel_width, panel_height)
	vbox.add_child(turn_info_panel)
	
	var turn_vbox = VBoxContainer.new()
	turn_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	turn_vbox.add_theme_constant_override("separation", separation)
	turn_info_panel.add_child(turn_vbox)
	
	var base_font_size = int(screen_size.y * BASE_FONT_RATIO)
	var title_font_size = int(base_font_size * 1.2)
	var instruction_font_size = int(base_font_size * 0.8)
	var timer_font_size = int(base_font_size * 1.0)
	
	current_player_label = Label.new()
	current_player_label.text = "Current Player: Loading..."
	current_player_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	current_player_label.add_theme_font_size_override("font_size", title_font_size)
	turn_vbox.add_child(current_player_label)
	
	turn_label = Label.new()
	turn_label.name = "TurnLabel"
	turn_label.text = "Turn: 1"
	turn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	turn_label.add_theme_font_size_override("font_size", base_font_size)
	turn_vbox.add_child(turn_label)
	
	phase_label = Label.new()
	phase_label.name = "PhaseLabel"
	phase_label.text = "Phase: Morning Move"
	phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	phase_label.add_theme_font_size_override("font_size", base_font_size)
	turn_vbox.add_child(phase_label)
	
	movement_instruction_label = Label.new()
	movement_instruction_label.text = "Click a tile to move"
	movement_instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	movement_instruction_label.add_theme_font_size_override("font_size", instruction_font_size)
	turn_vbox.add_child(movement_instruction_label)
	
	turn_timer_label = Label.new()
	turn_timer_label.text = "Time: --"
	turn_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	turn_timer_label.add_theme_font_size_override("font_size", timer_font_size)
	turn_vbox.add_child(turn_timer_label)
	
	movement_remaining_label = Label.new()
	movement_remaining_label.text = "Movement: --"
	movement_remaining_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	movement_remaining_label.add_theme_font_size_override("font_size", timer_font_size)
	turn_vbox.add_child(movement_remaining_label)
	
	turn_progress_bar = ProgressBar.new()
	var progress_width = int(panel_width * PROGRESS_WIDTH_RATIO)
	var progress_height = int(screen_size.y * PROGRESS_HEIGHT_RATIO)
	turn_progress_bar.show_percentage = false
	turn_progress_bar.custom_minimum_size = Vector2(progress_width, progress_height)
	turn_progress_bar.value = 100
	turn_progress_bar.max_value = 100
	turn_vbox.add_child(turn_progress_bar)
	
	end_turn_button = Button.new()
	end_turn_button.text = "End Turn"
	var button_width = int(panel_width * BUTTON_WIDTH_RATIO)
	var button_height = int(screen_size.y * BUTTON_HEIGHT_RATIO)
	end_turn_button.custom_minimum_size = Vector2(button_width, button_height)
	end_turn_button.add_theme_font_size_override("font_size", base_font_size)
	vbox.add_child(end_turn_button)
	
func _connect_signals() -> void:
	if end_turn_button:
		end_turn_button.pressed.connect(_on_end_turn_button_pressed)
	else:
		print("InGameUI: Error - End turn button not found!")

func _on_end_turn_button_pressed() -> void:
	end_turn_requested.emit()

func _on_viewport_size_changed() -> void:
	for child in get_children():
		child.queue_free()
	_setup_responsive_ui()
	_connect_signals()

func update_current_player(player_name: String, turn_number: int, phase: int = 0) -> void:
	if current_player_label:
		current_player_label.text = "Current Player: " + player_name
	
	if turn_label:
		turn_label.text = "Turn: " + str(turn_number)

	if phase_label:
		match phase:
			0:
				phase_label.text = "Phase: Morning Move"
				movement_instruction_label.text = "Click a tile to move!"
			1:
				phase_label.text = "Phase: Afternoon Move"
				movement_instruction_label.text = "Click a tile to move!"
			2:
				phase_label.text = "Phase: Night Action"
				movement_instruction_label.text = "Take an action card"
			_:
				phase_label.text = "Phase: Unknown"

func set_end_turn_enabled(enabled: bool) -> void:
	if end_turn_button:
		end_turn_button.disabled = not enabled

func set_turn_manager(turn_manager: TurnManager) -> void:
	current_turn_manager = turn_manager
	turn_timer_active = (turn_manager != null and turn_manager.get_max_turn_duration() > 0.0)
	
	ui_timer = 0.0
	timeout_triggered = false
	
	if turn_timer_label:
		turn_timer_label.visible = turn_timer_active
	if turn_progress_bar:
		turn_progress_bar.visible = turn_timer_active

func reset_turn_timer() -> void: 
	ui_timer = 0.0
	timeout_triggered = false

func update_movement_remaining(movement_speed: float, movement_cost_spent: int) -> void:
	if movement_remaining_label:
		var remaining = movement_speed - movement_cost_spent
		remaining = max(0.0, remaining)
		movement_remaining_label.text = "Movement: " + str(int(remaining)) + " / " + str(int(movement_speed))

func _process(delta: float) -> void:
	if turn_timer_active and current_turn_manager:
		if current_turn_manager.get_turn_active():
			ui_timer += delta
			
			var max_duration = current_turn_manager.get_max_turn_duration()
			if max_duration > 0.0 and ui_timer >= max_duration and not timeout_triggered:
				timeout_triggered = true
				current_turn_manager.turn_timeout.emit()
				current_turn_manager.end_turn()
				ui_timer = 0.0
				# ToDo: Add alert to the user that their turn ended due to timout
				end_turn_requested.emit()
		
		_update_turn_timer()

func _update_turn_timer() -> void:
	if not current_turn_manager or not turn_timer_active:
		return
	
	var max_duration = current_turn_manager.get_max_turn_duration()
	
	if max_duration > 0.0:
		var remaining_time = max_duration - ui_timer
		remaining_time = max(0.0, remaining_time)
		
		if turn_timer_label:
			turn_timer_label.text = "Time: " + str(int(remaining_time)) + "s"
		
		if turn_progress_bar:
			var progress = (remaining_time / max_duration) * 100.0
			turn_progress_bar.value = progress
			
			if progress > 50.0:
				turn_progress_bar.modulate = Color.DARK_GREEN
			elif progress > 25.0:
				turn_progress_bar.modulate = Color.YELLOW
			else:
				turn_progress_bar.modulate = Color.RED
	else:
		if turn_timer_label:
			turn_timer_label.text = "Time: ∞"
		if turn_progress_bar:
			turn_progress_bar.value = 100
			turn_progress_bar.modulate = Color.DARK_GREEN
