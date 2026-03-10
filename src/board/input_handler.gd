extends Node2D

signal swap_requested(from: Vector2i, to: Vector2i)

var _touch_start: Vector2 = Vector2.ZERO
var _is_touching: bool = false
var _start_cell: Vector2i = Vector2i(-1, -1)
const SWIPE_THRESHOLD := 20.0

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch_event: InputEventScreenTouch = event
		if touch_event.pressed:
			_touch_start = touch_event.position
			_is_touching = true
			_start_cell = _world_to_grid(touch_event.position)
		else:
			_is_touching = false
	elif event is InputEventScreenDrag and _is_touching:
		var drag_event: InputEventScreenDrag = event
		var delta: Vector2 = drag_event.position - _touch_start
		if delta.length() > SWIPE_THRESHOLD:
			var direction: Vector2i = _snap_direction(delta)
			var target: Vector2i = _start_cell + direction
			if _start_cell.x >= 0:
				swap_requested.emit(_start_cell, target)
			_is_touching = false
	elif event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event
		if mouse_event.pressed:
			_touch_start = mouse_event.position
			_is_touching = true
			_start_cell = _world_to_grid(mouse_event.position)
		else:
			_is_touching = false
	elif event is InputEventMouseMotion and _is_touching:
		var motion_event: InputEventMouseMotion = event
		var delta: Vector2 = motion_event.position - _touch_start
		if delta.length() > SWIPE_THRESHOLD:
			var direction: Vector2i = _snap_direction(delta)
			var target: Vector2i = _start_cell + direction
			if _start_cell.x >= 0:
				swap_requested.emit(_start_cell, target)
			_is_touching = false

func _snap_direction(delta: Vector2) -> Vector2i:
	if abs(delta.x) > abs(delta.y):
		return Vector2i(1, 0) if delta.x > 0 else Vector2i(-1, 0)
	else:
		return Vector2i(0, 1) if delta.y > 0 else Vector2i(0, -1)

func _world_to_grid(world_pos: Vector2) -> Vector2i:
	var col: int = int((world_pos.x - Types.BOARD_OFFSET_X) / Types.CELL_SIZE)
	var row: int = int((world_pos.y - Types.BOARD_OFFSET_Y) / Types.CELL_SIZE)
	if col < 0 or col >= Types.BOARD_COLS or row < 0 or row >= Types.BOARD_ROWS:
		return Vector2i(-1, -1)
	return Vector2i(col, row)
