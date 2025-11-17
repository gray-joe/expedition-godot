extends Control

@export var gear_selection_scene: PackedScene

var skill_card_allocation_ui: SkillCardAllocationUI = null

func _ready() -> void:
	_setup_ui()

func _on_continue_button_pressed() -> void:
	if gear_selection_scene:
		get_tree().change_scene_to_packed(gear_selection_scene)
	else:
		print("SkillCardAllocation: Error - No gear selection scene assigned!")

func _setup_ui() -> void:
	skill_card_allocation_ui = SkillCardAllocationUI.new()
	add_child(skill_card_allocation_ui)
	skill_card_allocation_ui.continue_requested.connect(_on_continue_button_pressed)

