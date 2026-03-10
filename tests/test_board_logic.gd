extends GutTest

var board: BoardLogic

func before_each():
	board = BoardLogic.new()
	board.initialize(Types.BOARD_COLS, Types.BOARD_ROWS)

func test_initialize_fills_board():
	assert_eq(board.cols, Types.BOARD_COLS)
	assert_eq(board.rows, Types.BOARD_ROWS)
	for col in range(board.cols):
		for row in range(board.rows):
			assert_true(board.get_gem(col, row) >= 0, "셀(%d,%d)에 보석이 있어야 함" % [col, row])

func test_initialize_no_initial_matches():
	var matches = board.find_matches()
	assert_eq(matches.size(), 0, "초기 보드에 매치가 없어야 함")

func test_swap_gems():
	var gem_a = board.get_gem(0, 0)
	var gem_b = board.get_gem(1, 0)
	board.swap(Vector2i(0, 0), Vector2i(1, 0))
	assert_eq(board.get_gem(0, 0), gem_b)
	assert_eq(board.get_gem(1, 0), gem_a)

func test_swap_invalid_non_adjacent():
	var result = board.try_swap(Vector2i(0, 0), Vector2i(2, 0))
	assert_false(result, "인접하지 않은 스왑은 실패해야 함")

func test_remove_and_fill():
	board.set_gem(0, 7, Types.GemType.RED)
	board.set_gem(1, 7, Types.GemType.RED)
	board.set_gem(2, 7, Types.GemType.RED)
	var to_remove = [Vector2i(0, 7), Vector2i(1, 7), Vector2i(2, 7)]
	board.remove_gems(to_remove)
	assert_eq(board.get_gem(0, 7), -1)
	board.apply_gravity()
	board.fill_empty()
	for col in range(3):
		for row in range(board.rows):
			assert_true(board.get_gem(col, row) >= 0)

func test_cascade_loop():
	board.set_gem(0, 9, Types.GemType.RED)
	board.set_gem(1, 9, Types.GemType.RED)
	board.set_gem(2, 9, Types.GemType.RED)
	var result = board.process_matches()
	assert_true(result.matched, "매치가 처리되어야 함")
