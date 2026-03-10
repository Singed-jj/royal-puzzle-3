class_name BoardLogic

var cols: int
var rows: int
var _grid: Array = []  # Array[Array[int]] - gem types (-1 = empty)
var _cell_types: Array = []  # Array[Array[CellType]]
var _match_detector: MatchDetector
var _gravity_handler: GravityHandler

class ProcessResult:
	var matched: bool = false
	var matches: Array = []
	var destroyed_cells: Array = []
	var cascade_count: int = 0

func initialize(p_cols: int, p_rows: int, cell_types: Array = []) -> void:
	cols = p_cols
	rows = p_rows
	_match_detector = MatchDetector.new()
	_gravity_handler = GravityHandler.new()
	_cell_types = cell_types if cell_types.size() > 0 else _default_cell_types()
	_grid = _generate_no_match_board()

func get_gem(col: int, row: int) -> int:
	if col < 0 or col >= cols or row < 0 or row >= rows:
		return -1
	return _grid[col][row]

func set_gem(col: int, row: int, gem_type: int) -> void:
	if col >= 0 and col < cols and row >= 0 and row < rows:
		_grid[col][row] = gem_type

func try_swap(from: Vector2i, to: Vector2i) -> bool:
	if abs(from.x - to.x) + abs(from.y - to.y) != 1:
		return false
	if get_gem(from.x, from.y) < 0 or get_gem(to.x, to.y) < 0:
		return false
	return true

func swap(from: Vector2i, to: Vector2i) -> void:
	var temp := _grid[from.x][from.y]
	_grid[from.x][from.y] = _grid[to.x][to.y]
	_grid[to.x][to.y] = temp

func find_matches() -> Array:
	return _match_detector.find_matches(_grid)

func remove_gems(cells: Array) -> void:
	for cell in cells:
		_grid[cell.x][cell.y] = -1

func apply_gravity() -> Array:
	var moves := _gravity_handler.calculate_falls(_grid, _cell_types)
	for m in moves:
		_grid[m.to.x][m.to.y] = m.gem_type
		_grid[m.from.x][m.from.y] = -1
	return moves

func fill_empty() -> Array:
	var filled := []
	for col in range(cols):
		for row in range(rows):
			if _grid[col][row] == -1 and _cell_types[col][row] != Types.CellType.BLANK:
				_grid[col][row] = _random_gem_avoiding_match(col, row)
				filled.append(Vector2i(col, row))
	return filled

func process_matches() -> ProcessResult:
	var result := ProcessResult.new()
	var matches := find_matches()
	if matches.size() == 0:
		return result
	result.matched = true
	result.matches = matches
	for m in matches:
		for cell in m.cells:
			if not result.destroyed_cells.has(cell):
				result.destroyed_cells.append(cell)
	remove_gems(result.destroyed_cells)
	return result

func process_cascade() -> int:
	var cascade_count := 0
	while true:
		var result := process_matches()
		if not result.matched:
			break
		cascade_count += 1
		apply_gravity()
		fill_empty()
	return cascade_count

func _generate_no_match_board() -> Array:
	var grid := []
	for col in range(cols):
		var column := []
		for row in range(rows):
			column.append(_random_gem_avoiding_match_in(grid, column, col, row))
		grid.append(column)
	return grid

func _random_gem_avoiding_match_in(grid: Array, current_col: Array, col: int, row: int) -> int:
	var max_attempts := 20
	for _i in range(max_attempts):
		var gem := randi() % Types.GEM_TYPES_COUNT
		# 가로 체크
		if col >= 2:
			if grid[col - 1][row] == gem and grid[col - 2][row] == gem:
				continue
		# 세로 체크
		if row >= 2:
			if current_col[row - 1] == gem and current_col[row - 2] == gem:
				continue
		return gem
	return randi() % Types.GEM_TYPES_COUNT

func _random_gem_avoiding_match(col: int, row: int) -> int:
	var max_attempts := 20
	for _i in range(max_attempts):
		var gem := randi() % Types.GEM_TYPES_COUNT
		if col >= 2 and _grid[col - 1][row] == gem and _grid[col - 2][row] == gem:
			continue
		if row >= 2 and _grid[col][row - 1] == gem and _grid[col][row - 2] == gem:
			continue
		return gem
	return randi() % Types.GEM_TYPES_COUNT

func _default_cell_types() -> Array:
	var types := []
	for col in range(cols):
		var column := []
		for row in range(rows):
			column.append(Types.CellType.NORMAL)
		types.append(column)
	return types
