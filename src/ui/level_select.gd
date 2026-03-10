extends Control

@onready var grid: GridContainer = $ScrollContainer/GridContainer
@onready var back_button: Button = $BackButton
@onready var room_label: Label = $RoomLabel

var _current_room: int = 0
var _level_generator := LevelGenerator.new()

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	_current_room = (SaveManager.data.current_level - 1) / 10 if SaveManager.data.has("current_level") else 0
	room_label.text = "Room %d" % (_current_room + 1)
	_populate_levels()

func _populate_levels() -> void:
	for child in grid.get_children():
		child.queue_free()

	var start_level := _current_room * 10 + 1
	var end_level := start_level + 9

	for level_id in range(start_level, end_level + 1):
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(60, 60)
		var stars: int = SaveManager.get_level_stars(level_id)
		var unlocked: bool = level_id <= SaveManager.data.current_level

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
	var level_data := _level_generator.generate(level_id)
	GameManager.start_level(level_id, level_data)
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://src/ui/main_menu.tscn")
