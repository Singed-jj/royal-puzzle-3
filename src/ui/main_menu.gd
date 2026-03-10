extends Control

@onready var play_button: Button = $VBoxContainer/PlayButton
@onready var stars_label: Label = $VBoxContainer/StarsLabel
@onready var title_label: Label = $VBoxContainer/TitleLabel

func _ready() -> void:
	title_label.text = "곰사원의 회사 탈출"
	stars_label.text = "★ %d" % SaveManager.data.total_stars
	play_button.pressed.connect(_on_play_pressed)

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://src/ui/level_select.tscn")
