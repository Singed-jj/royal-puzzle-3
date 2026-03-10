extends GutTest

var handler: GravityHandler


func before_each() -> void:
	handler = GravityHandler.new()


# 헬퍼: cols x rows 보드를 생성하고 fill_value로 채운다
func _make_board(cols: int, rows: int, fill_value: int = 0) -> Array:
	var board: Array = []
	for col in cols:
		var column: Array = []
		column.resize(rows)
		column.fill(fill_value)
		board.append(column)
	return board


# 헬퍼: cols x rows cell_types 보드 생성 (기본 NORMAL)
func _make_cell_types(cols: int, rows: int) -> Array:
	var types: Array = []
	for col in cols:
		var column: Array = []
		column.resize(rows)
		column.fill(Types.CellType.NORMAL)
		types.append(column)
	return types


## 한 칸 빈곳 -> 위 보석이 수직 낙하
func test_vertical_fall() -> void:
	# 3x3 보드, col=1의 row=2가 빈칸, row=1에 보석
	var board := _make_board(3, 3, 0)
	board[1][0] = -1  # empty
	board[1][1] = 2   # gem type 2
	board[1][2] = -1  # empty (아래)

	var falls := handler.calculate_falls(board)

	# row=1의 보석이 row=2로 이동해야 함
	assert_gt(falls.size(), 0, "낙하 이동이 있어야 합니다")

	var found_fall := false
	for fall in falls:
		if fall.from == Vector2i(1, 1) and fall.to == Vector2i(1, 2):
			found_fall = true
			assert_eq(fall.gem_type, 2, "gem_type이 보존되어야 합니다")
			break

	assert_true(found_fall, "col=1에서 row=1 -> row=2 낙하가 있어야 합니다")


## 아래 막힘 + 대각선 빈칸 -> 대각선 이동
func test_diagonal_fall() -> void:
	# 3x3 보드
	# col=1, row=2는 보석으로 채워짐 (아래 막힘)
	# col=1, row=1에 보석 존재
	# col=0, row=2가 빈칸 -> col=1, row=1 보석이 대각선으로 col=0, row=2로 이동
	var board := _make_board(3, 3, -1)
	board[1][1] = 3   # 보석
	board[1][2] = 1   # 아래 막힘

	var falls := handler.calculate_falls(board)

	var found_diagonal := false
	for fall in falls:
		if fall.from == Vector2i(1, 1) and fall.to == Vector2i(0, 2):
			found_diagonal = true
			assert_eq(fall.gem_type, 3, "gem_type이 보존되어야 합니다")
			break

	assert_true(found_diagonal, "대각선 낙하가 있어야 합니다")


## 연속 3칸 빈칸 -> 3개 순차 낙하
func test_multiple_falls() -> void:
	# 1열, 6행 보드
	# row 0,1,2에 보석 (type 0,1,2), row 3,4,5 빈칸
	var board: Array = []
	var column: Array = [0, 1, 2, -1, -1, -1]
	board.append(column)

	var falls := handler.calculate_falls(board)

	assert_eq(falls.size(), 3, "3개의 낙하 이동이 있어야 합니다")

	# 각 보석이 3칸씩 아래로 이동했는지 확인
	for fall in falls:
		assert_eq(fall.to.y - fall.from.y, 3, "각 보석은 3칸 낙하해야 합니다")


## 가득 찬 보드 -> 이동 없음
func test_no_fall_when_full() -> void:
	var board := _make_board(4, 4, 1)  # 모두 gem_type=1로 채움

	var falls := handler.calculate_falls(board)

	assert_eq(falls.size(), 0, "가득 찬 보드에서는 낙하가 없어야 합니다")


## BLANK 셀을 건너뛰는지 확인
func test_blank_cells_skipped() -> void:
	# 1열, 4행 보드
	# row 0: 보석, row 1: BLANK, row 2: empty, row 3: 보석
	var board: Array = [[5, -1, -1, 3]]
	var cell_types: Array = [[
		Types.CellType.NORMAL,
		Types.CellType.BLANK,
		Types.CellType.NORMAL,
		Types.CellType.NORMAL
	]]

	var falls := handler.calculate_falls(board, cell_types)

	# row 0의 보석이 row 2로 이동해야 함 (BLANK인 row 1은 건너뜀)
	var found := false
	for fall in falls:
		if fall.from == Vector2i(0, 0) and fall.to == Vector2i(0, 2):
			found = true
			assert_eq(fall.gem_type, 5)
			break

	assert_true(found, "BLANK 셀을 건너뛰고 row=2로 낙하해야 합니다")


## 빈 보드 -> 이동 없음 (모두 empty)
func test_empty_board_no_falls() -> void:
	var board := _make_board(3, 3, -1)

	var falls := handler.calculate_falls(board)

	assert_eq(falls.size(), 0, "빈 보드에서는 낙하가 없어야 합니다")
