class_name BoosterExecutor


## Returns the cells affected by activating a booster at (col, row).
static func get_targets(
	booster_type: int, col: int, row: int,
	board_cols: int, board_rows: int
) -> Array[Vector2i]:
	var targets: Array[Vector2i] = []

	match booster_type:
		Types.BoosterType.H_ROCKET:
			for c in range(board_cols):
				targets.append(Vector2i(c, row))

		Types.BoosterType.V_ROCKET:
			for r in range(board_rows):
				targets.append(Vector2i(col, r))

		Types.BoosterType.TNT:
			for dx in range(-2, 3):
				for dy in range(-2, 3):
					var tx := col + dx
					var ty := row + dy
					if tx >= 0 and tx < board_cols and ty >= 0 and ty < board_rows:
						targets.append(Vector2i(tx, ty))

		Types.BoosterType.MISSILE:
			pass  # Missile targets are resolved separately

	return targets


## Returns positions of all gems matching swap_gem_type on the board.
## board is a 2D array: board[col][row] holds gem type (int) or -1 for empty.
static func get_lightball_targets(board: Array, swap_gem_type: int) -> Array[Vector2i]:
	var targets: Array[Vector2i] = []
	for col in range(board.size()):
		var column: Array = board[col]
		for row in range(column.size()):
			if column[row] == swap_gem_type:
				targets.append(Vector2i(col, row))
	return targets
