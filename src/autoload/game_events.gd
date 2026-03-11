extends Node

const FONT_PATH := "res://assets/fonts/NotoSansKR-Bold.ttf"

func _ready() -> void:
	var font := load(FONT_PATH) as Font
	if font:
		ThemeDB.fallback_font = font

# Board events
signal gems_matched(cells: Array, match_type: String)
signal gems_destroyed(cells: Array)
signal cascade_started()
signal cascade_ended()
signal board_settled()

# Booster events
signal booster_created(col: int, row: int, type: int)
signal booster_activated(col: int, row: int, type: int)
signal boosters_merged(col: int, row: int, merge_type: int)

# Game state events
signal moves_changed(remaining: int)
signal goal_progress(goal_type: String, current: int, target: int)
signal level_completed(stars: int)
signal level_failed()

# UI events
signal ui_booster_used(booster_type: String)
signal hint_requested()

# Meta events
signal star_earned(count: int)
signal task_completed(task_id: String)
signal area_completed(area_id: int)
signal room_decorated(room_id: int, item_id: String)
