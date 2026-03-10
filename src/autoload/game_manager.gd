extends Node

var current_level: int = 1
var remaining_moves: int = 20
var goals: Dictionary = {}  # {"gem_type": {"current": 0, "target": 12}}
var is_level_active: bool = false

func start_level(level_id: int, level_data: LevelData) -> void:
	current_level = level_id
	remaining_moves = level_data.moves
	goals.clear()
	for goal in level_data.goals:
		goals[goal.type] = {"current": 0, "target": goal.amount}
	is_level_active = true

func use_move() -> void:
	remaining_moves -= 1
	GameEvents.moves_changed.emit(remaining_moves)
	if remaining_moves <= 0 and not _all_goals_met():
		is_level_active = false
		GameEvents.level_failed.emit()

func add_goal_progress(goal_type: String, amount: int = 1) -> void:
	if goals.has(goal_type):
		goals[goal_type].current += amount
		var g = goals[goal_type]
		GameEvents.goal_progress.emit(goal_type, g.current, g.target)
		if _all_goals_met():
			_complete_level()

func _all_goals_met() -> bool:
	for key in goals:
		if goals[key].current < goals[key].target:
			return false
	return true

func _complete_level() -> void:
	is_level_active = false
	var stars := _calculate_stars()
	GameEvents.level_completed.emit(stars)
	GameEvents.star_earned.emit(stars)

func _calculate_stars() -> int:
	if remaining_moves >= 10:
		return 3
	elif remaining_moves >= 5:
		return 2
	else:
		return 1
