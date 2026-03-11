extends Node2D

@onready var _board: Node2D = $Board
@onready var _input: Node2D = $InputHandler
@onready var _hud: CanvasLayer = $HUD

var _level_generator := LevelGenerator.new()

func _ready() -> void:
	_input.swap_requested.connect(_on_swap_requested)

	# 기본 레벨로 시작 (GameManager에 레벨이 설정되지 않았으면 레벨 1)
	if not GameManager.is_level_active:
		var level_data := _level_generator.generate(GameManager.current_level)
		GameManager.start_level(GameManager.current_level, level_data)
		_hud.setup_level(level_data.moves, level_data.goals)

func _on_swap_requested(from: Vector2i, to: Vector2i) -> void:
	if GameManager.is_level_active:
		_board.try_swap(from, to)
