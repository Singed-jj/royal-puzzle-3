extends Sprite2D

var gem_type: int = -1
var grid_pos: Vector2i = Vector2i.ZERO
var _target_position: Vector2
var _is_moving: bool = false

const FALL_SPEED := 800.0
const SWAP_SPEED := 400.0

const GEM_COLORS := [
	Color.RED, Color.BLUE, Color.GREEN,
	Color.YELLOW, Color.PURPLE, Color.ORANGE
]

func setup(type: int, col: int, row: int) -> void:
	gem_type = type
	grid_pos = Vector2i(col, row)
	position = _grid_to_world(col, row)
	_target_position = position
	modulate = GEM_COLORS[type] if type >= 0 and type < GEM_COLORS.size() else Color.WHITE

func move_to(col: int, row: int, speed: float = FALL_SPEED) -> void:
	grid_pos = Vector2i(col, row)
	_target_position = _grid_to_world(col, row)
	_is_moving = true

func _process(delta: float) -> void:
	if _is_moving:
		position = position.move_toward(_target_position, FALL_SPEED * delta)
		if position.distance_to(_target_position) < 1.0:
			position = _target_position
			_is_moving = false

func destroy() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.15)
	tween.tween_callback(queue_free)

func _grid_to_world(col: int, row: int) -> Vector2:
	return Vector2(
		Types.BOARD_OFFSET_X + col * Types.CELL_SIZE + Types.CELL_SIZE / 2,
		Types.BOARD_OFFSET_Y + row * Types.CELL_SIZE + Types.CELL_SIZE / 2
	)
