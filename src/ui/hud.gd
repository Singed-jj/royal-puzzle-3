extends CanvasLayer

@onready var moves_label: Label = $MovesPanel/MovesLabel
@onready var target_container: VBoxContainer = $TargetPanel/TargetContainer
@onready var avatar: TextureRect = $AvatarPanel/Avatar
@onready var booster_bar: HBoxContainer = $BoosterBar

var _goal_labels: Dictionary = {}

func _ready() -> void:
	GameEvents.moves_changed.connect(_on_moves_changed)
	GameEvents.goal_progress.connect(_on_goal_progress)

func setup_level(moves: int, goals: Array) -> void:
	moves_label.text = str(moves)
	_goal_labels.clear()
	for child in target_container.get_children():
		child.queue_free()
	for goal in goals:
		var label := Label.new()
		label.text = "%s: 0/%d" % [goal.type, goal.amount]
		target_container.add_child(label)
		_goal_labels[goal.type] = label

func _on_moves_changed(remaining: int) -> void:
	moves_label.text = str(remaining)
	if remaining <= 5:
		moves_label.add_theme_color_override("font_color", Color.RED)

func _on_goal_progress(goal_type: String, current: int, target: int) -> void:
	if _goal_labels.has(goal_type):
		_goal_labels[goal_type].text = "%s: %d/%d" % [goal_type, current, target]
		if current >= target:
			_goal_labels[goal_type].add_theme_color_override("font_color", Color.GREEN)
