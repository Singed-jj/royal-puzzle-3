extends CanvasLayer

@onready var moves_label: Label = $TopBar/MovesPanel/MovesMargin/MovesVBox/MovesLabel
@onready var moves_header: Label = $TopBar/MovesPanel/MovesMargin/MovesVBox/MovesHeader
@onready var target_container: VBoxContainer = $TopBar/TargetPanel/TargetMargin/TargetVBox/TargetContainer
@onready var target_header: Label = $TopBar/TargetPanel/TargetMargin/TargetVBox/TargetLabel
@onready var avatar: TextureRect = $TopBar/AvatarPanel/Avatar

const GEM_PATHS := [
	"res://assets/sprites/gems/gem_0.png",
	"res://assets/sprites/gems/gem_1.png",
	"res://assets/sprites/gems/gem_2.png",
	"res://assets/sprites/gems/gem_3.png",
	"res://assets/sprites/gems/gem_4.png",
	"res://assets/sprites/gems/gem_5.png",
]

var _goal_labels: Dictionary = {}  # goal_type(String) → Label node
var _goal_type_to_index: Dictionary = {}

func _ready() -> void:
	GameEvents.moves_changed.connect(_on_moves_changed)
	GameEvents.goal_progress.connect(_on_goal_progress)
	_setup_type_mapping()
	_style_labels()

func _setup_type_mapping() -> void:
	for i in range(Types.GEM_NAMES.size()):
		_goal_type_to_index[Types.GEM_NAMES[i]] = i

func _style_labels() -> void:
	# Moves 숫자: 크고 굵게, 흰색
	var moves_settings := LabelSettings.new()
	moves_settings.font_size = 28
	moves_settings.font_color = Color.WHITE
	moves_settings.outline_size = 3
	moves_settings.outline_color = Color(0, 0, 0, 0.6)
	moves_label.label_settings = moves_settings

	# Moves 헤더: 작고 밝은 회색
	var header_settings := LabelSettings.new()
	header_settings.font_size = 11
	header_settings.font_color = Color(0.8, 0.85, 0.9, 1.0)
	moves_header.label_settings = header_settings

	# Target 헤더도 동일
	target_header.label_settings = header_settings

func setup_level(moves: int, goals: Array) -> void:
	moves_label.text = str(moves)
	_goal_labels.clear()
	for child in target_container.get_children():
		child.queue_free()
	for goal in goals:
		_add_goal_row(goal.type, goal.amount)

func _add_goal_row(goal_type: String, target_amount: int) -> void:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 6)

	# 젬 아이콘
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(24, 24)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var idx: int = _goal_type_to_index.get(goal_type, -1)
	if idx >= 0 and idx < GEM_PATHS.size():
		icon.texture = load(GEM_PATHS[idx])
	row.add_child(icon)

	# 카운트 라벨 ("0 / 12")
	var label := Label.new()
	var label_settings := LabelSettings.new()
	label_settings.font_size = 16
	label_settings.font_color = Color.WHITE
	label_settings.outline_size = 2
	label_settings.outline_color = Color(0, 0, 0, 0.5)
	label.label_settings = label_settings
	label.text = "0/%d" % target_amount
	row.add_child(label)

	target_container.add_child(row)
	_goal_labels[goal_type] = label

func _on_moves_changed(remaining: int) -> void:
	moves_label.text = str(remaining)
	if remaining <= 5:
		moves_label.label_settings.font_color = Color(1.0, 0.3, 0.3)

func _on_goal_progress(goal_type: String, current: int, target: int) -> void:
	if _goal_labels.has(goal_type):
		var label: Label = _goal_labels[goal_type]
		label.text = "%d/%d" % [current, target]
		if current >= target:
			label.label_settings.font_color = Color(0.3, 1.0, 0.3)
