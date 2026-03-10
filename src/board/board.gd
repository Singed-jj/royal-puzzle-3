extends Node2D

var _logic: BoardLogic
var _gem_nodes: Dictionary = {}  # Vector2i → Gem node
var _is_processing: bool = false

@onready var _gem_container := $GemContainer

func _ready() -> void:
	_logic = BoardLogic.new()
	_logic.initialize(Types.BOARD_COLS, Types.BOARD_ROWS)
	_create_gem_nodes()

func _create_gem_nodes() -> void:
	for col in range(_logic.cols):
		for row in range(_logic.rows):
			var gem_type := _logic.get_gem(col, row)
			if gem_type >= 0:
				_spawn_gem(col, row, gem_type)

func _spawn_gem(col: int, row: int, gem_type: int) -> void:
	var gem := preload("res://src/board/gem.tscn").instantiate()
	gem.setup(gem_type, col, row)
	_gem_container.add_child(gem)
	_gem_nodes[Vector2i(col, row)] = gem

func try_swap(from: Vector2i, to: Vector2i) -> void:
	if _is_processing:
		return
	if not _logic.try_swap(from, to):
		return

	_is_processing = true
	_logic.swap(from, to)

	var gem_a: Sprite2D = _gem_nodes.get(from)
	var gem_b: Sprite2D = _gem_nodes.get(to)
	if gem_a:
		gem_a.move_to(to.x, to.y, gem_a.SWAP_SPEED)
	if gem_b:
		gem_b.move_to(from.x, from.y, gem_b.SWAP_SPEED)
	_gem_nodes[from] = gem_b
	_gem_nodes[to] = gem_a

	await get_tree().create_timer(0.2).timeout
	var result := _logic.process_matches()

	if not result.matched:
		_logic.swap(from, to)
		if gem_a:
			gem_a.move_to(from.x, from.y, gem_a.SWAP_SPEED)
		if gem_b:
			gem_b.move_to(to.x, to.y, gem_b.SWAP_SPEED)
		_gem_nodes[from] = gem_a
		_gem_nodes[to] = gem_b
		await get_tree().create_timer(0.2).timeout
		_is_processing = false
		return

	_destroy_matched(result.destroyed_cells)
	GameEvents.gems_matched.emit(result.destroyed_cells, result.matches[0].type if result.matches.size() > 0 else "")
	GameManager.use_move()

	await get_tree().create_timer(0.2).timeout
	_run_cascade()

func _destroy_matched(cells: Array) -> void:
	for cell in cells:
		var gem = _gem_nodes.get(cell)
		if gem:
			gem.destroy()
			_gem_nodes.erase(cell)
	GameEvents.gems_destroyed.emit(cells)

func _run_cascade() -> void:
	while true:
		var falls := _logic.apply_gravity()
		_animate_falls(falls)
		await get_tree().create_timer(0.15).timeout

		var filled := _logic.fill_empty()
		_spawn_new_gems(filled)
		await get_tree().create_timer(0.15).timeout

		var result := _logic.process_matches()
		if not result.matched:
			break
		_destroy_matched(result.destroyed_cells)
		GameEvents.cascade_started.emit()
		await get_tree().create_timer(0.2).timeout

	GameEvents.board_settled.emit()
	_is_processing = false

func _animate_falls(falls: Array) -> void:
	for fall in falls:
		var gem = _gem_nodes.get(fall.from)
		if gem:
			_gem_nodes.erase(fall.from)
			gem.move_to(fall.to.x, fall.to.y)
			_gem_nodes[fall.to] = gem

func _spawn_new_gems(positions: Array) -> void:
	for pos in positions:
		var gem_type := _logic.get_gem(pos.x, pos.y)
		_spawn_gem(pos.x, pos.y, gem_type)
