extends Control

@onready var grid: GridContainer = $ScrollContainer/GridContainer
@onready var back_button: Button = $BackButton
@onready var room_label: Label = $RoomLabel

var _current_room: int = 0
var _level_generator := LevelGenerator.new()

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	_current_room = (SaveManager.data.get("current_level", 1) - 1) / 10
	room_label.text = "Room %d" % (_current_room + 1)
	_populate_levels()

func _populate_levels() -> void:
	for child in grid.get_children():
		child.queue_free()

	var start_level := _current_room * 10 + 1
	var end_level := start_level + 9
	var current_level = SaveManager.data.get("current_level", 1)
	if typeof(current_level) == TYPE_FLOAT:
		current_level = int(current_level)

	for level_id in range(start_level, end_level + 1):
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(60, 60)
		var stars: int = SaveManager.get_level_stars(level_id)
		var unlocked: bool = level_id <= current_level

		if unlocked:
			btn.text = str(level_id)
			if stars > 0:
				btn.text += "\n" + "★".repeat(stars)
			btn.pressed.connect(_on_level_pressed.bind(level_id))
		else:
			btn.text = "🔒"
			btn.disabled = true

		grid.add_child(btn)

func _on_level_pressed(level_id: int) -> void:
	GameManager.current_level = level_id
	GameManager.is_level_active = false
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://src/ui/main_menu.tscn")
