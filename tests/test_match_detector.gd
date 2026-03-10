extends GutTest


var detector: MatchDetector


func before_each() -> void:
	detector = MatchDetector.new()


# ── 헬퍼 ────────────────────────────────────────────────────────

func _create_empty_board() -> Array:
	var board: Array = []
	for col in range(Types.BOARD_COLS):
		var column: Array = []
		column.resize(Types.BOARD_ROWS)
		column.fill(-1)
		board.append(column)
	return board


func _find_match_by_type(matches: Array, match_type: String) -> MatchDetector.MatchResult:
	for m in matches:
		if m.type == match_type:
			return m
	return null


func _has_cell(match_result: MatchDetector.MatchResult, col: int, row: int) -> bool:
	return match_result.cells.has(Vector2i(col, row))


# ── 테스트: 가로 3매치 ──────────────────────────────────────────

func test_horizontal_match_3() -> void:
	var board := _create_empty_board()
	# row 0에 col 0,1,2를 RED(0)로
	board[0][0] = Types.GemType.RED
	board[1][0] = Types.GemType.RED
	board[2][0] = Types.GemType.RED

	var matches := detector.find_matches(board)

	assert_eq(matches.size(), 1, "가로 3매치가 1개 감지되어야 함")
	var m: MatchDetector.MatchResult = matches[0]
	assert_eq(m.type, "horizontal", "매치 타입이 horizontal이어야 함")
	assert_eq(m.gem_type, Types.GemType.RED, "gem_type이 RED여야 함")
	assert_eq(m.cells.size(), 3, "셀이 3개여야 함")
	assert_true(_has_cell(m, 0, 0))
	assert_true(_has_cell(m, 1, 0))
	assert_true(_has_cell(m, 2, 0))


# ── 테스트: 세로 3매치 ──────────────────────────────────────────

func test_vertical_match_3() -> void:
	var board := _create_empty_board()
	# col 3에 row 2,3,4를 BLUE(1)로
	board[3][2] = Types.GemType.BLUE
	board[3][3] = Types.GemType.BLUE
	board[3][4] = Types.GemType.BLUE

	var matches := detector.find_matches(board)

	assert_eq(matches.size(), 1, "세로 3매치가 1개 감지되어야 함")
	var m: MatchDetector.MatchResult = matches[0]
	assert_eq(m.type, "vertical", "매치 타입이 vertical이어야 함")
	assert_eq(m.gem_type, Types.GemType.BLUE)
	assert_eq(m.cells.size(), 3)


# ── 테스트: 가로 4매치 ──────────────────────────────────────────

func test_match_4_horizontal() -> void:
	var board := _create_empty_board()
	board[1][5] = Types.GemType.GREEN
	board[2][5] = Types.GemType.GREEN
	board[3][5] = Types.GemType.GREEN
	board[4][5] = Types.GemType.GREEN

	var matches := detector.find_matches(board)

	assert_eq(matches.size(), 1)
	var m: MatchDetector.MatchResult = matches[0]
	assert_eq(m.type, "horizontal_4", "4매치는 horizontal_4 타입")
	assert_eq(m.cells.size(), 4)


# ── 테스트: 가로 5매치 (라이트볼 생성) ──────────────────────────

func test_match_5_creates_lightball() -> void:
	var board := _create_empty_board()
	for col in range(5):
		board[col][3] = Types.GemType.YELLOW

	var matches := detector.find_matches(board)

	assert_eq(matches.size(), 1)
	var m: MatchDetector.MatchResult = matches[0]
	assert_eq(m.type, "horizontal_5", "5매치는 horizontal_5 타입")
	assert_eq(m.cells.size(), 5)
	assert_eq(m.gem_type, Types.GemType.YELLOW)


# ── 테스트: L자 매치 ────────────────────────────────────────────

func test_l_shape_match() -> void:
	var board := _create_empty_board()
	# L자: 가로 col 0,1,2 row 0 + 세로 col 0 row 0,1,2
	# 교차점 (0,0)은 h_run의 시작이자 v_run의 시작 → 양쪽 다 끝점 → l_shape
	board[0][0] = Types.GemType.PURPLE
	board[1][0] = Types.GemType.PURPLE
	board[2][0] = Types.GemType.PURPLE
	board[0][1] = Types.GemType.PURPLE
	board[0][2] = Types.GemType.PURPLE

	var matches := detector.find_matches(board)

	var l_match := _find_match_by_type(matches, "l_shape")
	assert_not_null(l_match, "L자 매치가 감지되어야 함")
	assert_eq(l_match.cells.size(), 5, "L자 매치는 5개 셀")
	assert_eq(l_match.gem_type, Types.GemType.PURPLE)


# ── 테스트: T자 매치 ────────────────────────────────────────────

func test_t_shape_match() -> void:
	var board := _create_empty_board()
	# T자: 가로 col 0,1,2 row 1 + 세로 col 1 row 0,1,2
	# 교차점 (1,1)은 h_run의 내부, v_run의 내부 → cross가 아닌 t_shape?
	# 실제로 이 패턴은 cross. T자를 만들려면 교차점이 한쪽만 interior여야 함.
	# T자: 가로 col 0,1,2 row 0 + 세로 col 1 row 0,1,2
	# 교차점 (1,0): h_run 내부(0,1,2 중 1), v_run 시작(0,1,2 중 0) → h만 interior → t_shape
	board[0][0] = Types.GemType.ORANGE
	board[1][0] = Types.GemType.ORANGE
	board[2][0] = Types.GemType.ORANGE
	board[1][1] = Types.GemType.ORANGE
	board[1][2] = Types.GemType.ORANGE

	var matches := detector.find_matches(board)

	var t_match := _find_match_by_type(matches, "t_shape")
	assert_not_null(t_match, "T자 매치가 감지되어야 함")
	assert_eq(t_match.cells.size(), 5, "T자 매치는 5개 셀")


# ── 테스트: 매치 없음 ───────────────────────────────────────────

func test_no_match() -> void:
	var board := _create_empty_board()
	# 2개만 연속 → 매치 아님
	board[0][0] = Types.GemType.RED
	board[1][0] = Types.GemType.RED
	board[2][0] = Types.GemType.BLUE
	board[3][0] = Types.GemType.GREEN

	var matches := detector.find_matches(board)

	assert_eq(matches.size(), 0, "매치가 없어야 함")


# ── 테스트: 빈 보드 ─────────────────────────────────────────────

func test_empty_board_no_match() -> void:
	var board := _create_empty_board()

	var matches := detector.find_matches(board)

	assert_eq(matches.size(), 0, "빈 보드에서 매치가 없어야 함")


# ── 테스트: +자 (cross) 매치 ────────────────────────────────────

func test_cross_shape() -> void:
	var board := _create_empty_board()
	# +자: 가로 col 1,2,3 row 2 + 세로 col 2 row 1,2,3
	# 교차점 (2,2): h_run 내부(1,2,3 중 2), v_run 내부(1,2,3 중 2) → 양쪽 interior → cross
	board[1][2] = Types.GemType.RED
	board[2][2] = Types.GemType.RED
	board[3][2] = Types.GemType.RED
	board[2][1] = Types.GemType.RED
	board[2][3] = Types.GemType.RED

	var matches := detector.find_matches(board)

	var cross_match := _find_match_by_type(matches, "cross")
	assert_not_null(cross_match, "+자 매치가 감지되어야 함")
	assert_eq(cross_match.cells.size(), 5, "+자 매치는 5개 셀")
	assert_eq(cross_match.gem_type, Types.GemType.RED)


# ── 테스트: 세로 4매치 ──────────────────────────────────────────

func test_vertical_match_4() -> void:
	var board := _create_empty_board()
	for row in range(4):
		board[5][row] = Types.GemType.BLUE

	var matches := detector.find_matches(board)

	assert_eq(matches.size(), 1)
	assert_eq(matches[0].type, "vertical_4")
	assert_eq(matches[0].cells.size(), 4)


# ── 테스트: 여러 매치 동시 감지 ─────────────────────────────────

func test_multiple_matches() -> void:
	var board := _create_empty_board()
	# 가로 3매치 (RED) at row 0
	board[0][0] = Types.GemType.RED
	board[1][0] = Types.GemType.RED
	board[2][0] = Types.GemType.RED
	# 세로 3매치 (BLUE) at col 5
	board[5][3] = Types.GemType.BLUE
	board[5][4] = Types.GemType.BLUE
	board[5][5] = Types.GemType.BLUE

	var matches := detector.find_matches(board)

	assert_eq(matches.size(), 2, "두 개의 독립된 매치가 감지되어야 함")
