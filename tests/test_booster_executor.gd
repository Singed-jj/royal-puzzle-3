extends Node

const COLS := 8
const ROWS := 10


func test_h_rocket_destroys_row() -> void:
	var targets := BoosterExecutor.get_targets(
		Types.BoosterType.H_ROCKET, 3, 5, COLS, ROWS
	)
	assert(targets.size() == COLS, "H_ROCKET should return %d cells, got %d" % [COLS, targets.size()])
	for t in targets:
		assert(t.y == 5, "H_ROCKET targets should all be in row 5")
	# Verify all columns are covered
	for c in range(COLS):
		assert(targets.has(Vector2i(c, 5)), "H_ROCKET should include col %d" % c)
	print("  PASS: test_h_rocket_destroys_row")


func test_v_rocket_destroys_col() -> void:
	var targets := BoosterExecutor.get_targets(
		Types.BoosterType.V_ROCKET, 2, 4, COLS, ROWS
	)
	assert(targets.size() == ROWS, "V_ROCKET should return %d cells, got %d" % [ROWS, targets.size()])
	for t in targets:
		assert(t.x == 2, "V_ROCKET targets should all be in col 2")
	# Verify all rows are covered
	for r in range(ROWS):
		assert(targets.has(Vector2i(2, r)), "V_ROCKET should include row %d" % r)
	print("  PASS: test_v_rocket_destroys_col")


func test_tnt_radius_2() -> void:
	# TNT at center (4, 5) — full 5x5 fits within 8x10 board
	var targets := BoosterExecutor.get_targets(
		Types.BoosterType.TNT, 4, 5, COLS, ROWS
	)
	assert(targets.size() == 25, "TNT at center should return 25 cells, got %d" % targets.size())
	# All targets must be within radius 2
	for t in targets:
		assert(abs(t.x - 4) <= 2, "TNT target col out of radius")
		assert(abs(t.y - 5) <= 2, "TNT target row out of radius")

	# TNT at corner (0, 0) — should be clipped to 3x3
	var corner_targets := BoosterExecutor.get_targets(
		Types.BoosterType.TNT, 0, 0, COLS, ROWS
	)
	assert(corner_targets.size() == 9, "TNT at corner should return 9 cells, got %d" % corner_targets.size())
	for t in corner_targets:
		assert(t.x >= 0 and t.x < COLS, "TNT corner target x out of board")
		assert(t.y >= 0 and t.y < ROWS, "TNT corner target y out of board")
	print("  PASS: test_tnt_radius_2")


func test_lightball_finds_most_common() -> void:
	# Build a board where RED appears at specific positions
	var board: Array = []
	for c in range(COLS):
		var column: Array = []
		for r in range(ROWS):
			column.append(Types.GemType.BLUE)
		board.append(column)

	# Place RED gems at known positions
	board[0][0] = Types.GemType.RED
	board[2][3] = Types.GemType.RED
	board[5][7] = Types.GemType.RED
	board[7][9] = Types.GemType.RED

	var targets := BoosterExecutor.get_lightball_targets(board, Types.GemType.RED)
	assert(targets.size() == 4, "LIGHT_BALL should find 4 RED gems, got %d" % targets.size())
	assert(targets.has(Vector2i(0, 0)), "Should find RED at (0,0)")
	assert(targets.has(Vector2i(2, 3)), "Should find RED at (2,3)")
	assert(targets.has(Vector2i(5, 7)), "Should find RED at (5,7)")
	assert(targets.has(Vector2i(7, 9)), "Should find RED at (7,9)")
	print("  PASS: test_lightball_finds_most_common")


func run_all() -> void:
	print("BoosterExecutor Tests:")
	test_h_rocket_destroys_row()
	test_v_rocket_destroys_col()
	test_tnt_radius_2()
	test_lightball_finds_most_common()
	print("All BoosterExecutor tests passed!")
