extends RefCounted
class_name TurnManager

var is_turn_active: bool = false
var max_turn_duration: float = 0.0
var turn_timer: float = 0.0

signal turn_started()
signal turn_ended()
signal turn_timeout()

func _init(max_duration: float = 0.0):
	max_turn_duration = max_duration
	print("TurnManager: Initialized with max duration: ", max_duration)

func start_turn() -> void:
	is_turn_active = true
	turn_timer = 0.0
	turn_started.emit()

func end_turn() -> void:
	is_turn_active = false
	turn_timer = 0.0
	turn_ended.emit()

func can_perform_action() -> bool:
	return is_turn_active

func get_turn_active() -> bool:
	return is_turn_active

func get_turn_duration() -> float:
	if not is_turn_active:
		return 0.0
	
	return turn_timer

func get_remaining_time() -> float:
	if max_turn_duration <= 0.0:
		return -1.0
	
	if not is_turn_active:
		return 0.0
	
	var elapsed = get_turn_duration()
	var remaining = max_turn_duration - elapsed
	return max(0.0, remaining)

func is_turn_timed_out() -> bool:
	if max_turn_duration <= 0.0:
		return false
	
	return get_remaining_time() <= 0.0

func set_max_turn_duration(duration: float) -> void:
	max_turn_duration = duration

func get_max_turn_duration() -> float:
	return max_turn_duration

func validate_turn_action(_action_type: String) -> bool:
	if not can_perform_action():
		return false
	
	if is_turn_timed_out():
		turn_timeout.emit()
		return false
	
	return true

func get_turn_info() -> Dictionary:
	return {
		"is_active": is_turn_active,
		"timer": turn_timer,
		"duration": get_turn_duration(),
		"remaining_time": get_remaining_time(),
		"max_duration": max_turn_duration,
		"is_timed_out": is_turn_timed_out()
	}


func _ready() -> void:
	if max_turn_duration > 0.0:
		pass

func _process(delta: float) -> void:
	if is_turn_active:
		turn_timer += delta
		
		if is_turn_timed_out():
			print("TurnManager: Turn timed out!")
			turn_timeout.emit()
			end_turn()
