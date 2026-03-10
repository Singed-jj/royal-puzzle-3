extends Node

const SAVE_PATH := "user://save_data.json"

var data: Dictionary = {
	"current_level": 1,
	"stars": {},
	"coins": 0,
	"lives": 5,
	"boosters": {},
	"room_progress": {},
	"total_stars": 0,
}


func _ready() -> void:
	load_game()


func save_game() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: Cannot open save file for writing")
		return
	file.store_string(JSON.stringify(data))
	file.close()


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("SaveManager: Cannot open save file for reading")
		return
	var content := file.get_as_text()
	file.close()
	var json := JSON.new()
	var err := json.parse(content)
	if err == OK:
		var parsed: Variant = json.data
		if parsed is Dictionary:
			data = parsed
	else:
		push_error("SaveManager: Failed to parse save file")


func complete_level(level_id: int, stars: int) -> void:
	var key := str(level_id)
	var old_stars: int = data["stars"].get(key, 0)
	if stars > old_stars:
		data["stars"][key] = stars
		_recalculate_total_stars()
	if level_id >= data["current_level"]:
		data["current_level"] = level_id + 1
	var room: int = (level_id - 1) / 10
	var room_key := str(room)
	var stage: int = (level_id - 1) % 10
	if not data["room_progress"].has(room_key) or stage >= data["room_progress"][room_key]:
		data["room_progress"][room_key] = stage + 1
	save_game()


func get_level_stars(level_id: int) -> int:
	var key := str(level_id)
	return data["stars"].get(key, 0)


func get_total_stars() -> int:
	return data["total_stars"]


func add_coins(amount: int) -> void:
	data["coins"] += amount
	save_game()


func use_life() -> bool:
	if data["lives"] <= 0:
		return false
	data["lives"] -= 1
	save_game()
	return true


func _recalculate_total_stars() -> void:
	var total: int = 0
	for key in data["stars"]:
		total += data["stars"][key]
	data["total_stars"] = total
