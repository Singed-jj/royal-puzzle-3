extends Sprite2D

var cell_type: int = Types.CellType.NORMAL
var grid_pos: Vector2i = Vector2i.ZERO

func setup(type: int, col: int, row: int) -> void:
	cell_type = type
	grid_pos = Vector2i(col, row)
	position = Vector2(
		Types.BOARD_OFFSET_X + col * Types.CELL_SIZE + Types.CELL_SIZE / 2,
		Types.BOARD_OFFSET_Y + row * Types.CELL_SIZE + Types.CELL_SIZE / 2
	)
	if type == Types.CellType.BLANK:
		visible = false
