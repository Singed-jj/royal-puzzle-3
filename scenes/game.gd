extends Node2D

@onready var _board: Node2D = $Board
@onready var _input: Node2D = $InputHandler
@onready var _hud: CanvasLayer = $HUD

var _level_generator := LevelGenerator.new()

func _ready() -> void:
	_input.swap_requested.connect(_on_swap_requested)

	# level_select에서 왔으면 current_level이 이미 설정됨
	# 직접 진입(새로고침)이면 SaveManager에서 복원
	if not GameManager.is_level_active:
		var saved_level = SaveManager.data.get("current_level", 1)
		if typeof(saved_level) == TYPE_FLOAT:
			saved_level = int(saved_level)
		GameManager.current_level = maxi(saved_level, 1)

	# 항상 레벨 데이터 생성 및 HUD 세팅
	var level_data := _level_generator.generate(GameManager.current_level)
	GameManager.start_level(GameManager.current_level, level_data)
	_hud.setup_level(level_data.moves, level_data.goals)

func _on_swap_requested(from: Vector2i, to: Vector2i) -> void:
	if GameManager.is_level_active:
		_board.try_swap(from, to)
