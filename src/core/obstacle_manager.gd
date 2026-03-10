class_name ObstacleManager


class CellObstacle:
	var type: int = Types.ObstacleType.NONE
	var hp: int = 0
	var layer: String = ""


var _cols: int = 0
var _rows: int = 0

# Each layer is a 2D dictionary: _main[col][row] -> CellObstacle or null
var _main: Dictionary = {}
var _overlay: Dictionary = {}
var _underlay: Dictionary = {}


func initialize(cols: int, rows: int) -> void:
	_cols = cols
	_rows = rows
	_main.clear()
	_overlay.clear()
	_underlay.clear()

	for c in range(cols):
		_main[c] = {}
		_overlay[c] = {}
		_underlay[c] = {}
		for r in range(rows):
			_main[c][r] = null
			_overlay[c][r] = null
			_underlay[c][r] = null


func set_obstacle(col: int, row: int, type: int, layer: String, hp: int = 1) -> void:
	var obstacle := CellObstacle.new()
	obstacle.type = type
	obstacle.hp = hp
	obstacle.layer = layer

	match layer:
		"main":
			_main[col][row] = obstacle
		"overlay":
			_overlay[col][row] = obstacle
		"underlay":
			_underlay[col][row] = obstacle


## Stone and Chain block swapping.
func can_swap(col: int, row: int) -> bool:
	if has_main(col, row):
		var obs: CellObstacle = _main[col][row]
		if obs.type == Types.ObstacleType.STONE:
			return false
	if has_overlay(col, row):
		var obs: CellObstacle = _overlay[col][row]
		if obs.type == Types.ObstacleType.CHAIN:
			return false
	return true


## Stone blocks matching. Fence blocks matching. Chain allows matching.
func can_match(col: int, row: int) -> bool:
	if has_main(col, row):
		var obs: CellObstacle = _main[col][row]
		if obs.type == Types.ObstacleType.STONE:
			return false
	if has_overlay(col, row):
		var obs: CellObstacle = _overlay[col][row]
		if obs.type == Types.ObstacleType.FENCE:
			return false
	return true


func has_main(col: int, row: int) -> bool:
	return _main.has(col) and _main[col].has(row) and _main[col][row] != null


func has_overlay(col: int, row: int) -> bool:
	return _overlay.has(col) and _overlay[col].has(row) and _overlay[col][row] != null


func has_underlay(col: int, row: int) -> bool:
	return _underlay.has(col) and _underlay[col].has(row) and _underlay[col][row] != null


func damage_main(col: int, row: int) -> void:
	if not has_main(col, row):
		return
	var obs: CellObstacle = _main[col][row]
	obs.hp -= 1
	if obs.hp <= 0:
		_main[col][row] = null


func damage_overlay(col: int, row: int) -> void:
	if not has_overlay(col, row):
		return
	var obs: CellObstacle = _overlay[col][row]
	obs.hp -= 1
	if obs.hp <= 0:
		_overlay[col][row] = null


func clear_underlay(col: int, row: int) -> void:
	if has_underlay(col, row):
		_underlay[col][row] = null


## Process adjacent matches: for each matched cell, damage neighboring obstacles
## that are destroyed by adjacency (Stone in main, Fence/Chain in overlay).
## Returns an array of Vector2i positions where obstacles were damaged.
func process_adjacent_match(matched_cells: Array) -> Array:
	var damaged: Array = []
	var directions := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

	for cell in matched_cells:
		var mc: Vector2i = cell
		for dir in directions:
			var nc := mc + dir
			if nc.x < 0 or nc.x >= _cols or nc.y < 0 or nc.y >= _rows:
				continue

			# Damage adjacent Stone (main layer)
			if has_main(nc.x, nc.y):
				var obs: CellObstacle = _main[nc.x][nc.y]
				if obs.type == Types.ObstacleType.STONE:
					damage_main(nc.x, nc.y)
					if not damaged.has(nc):
						damaged.append(nc)

			# Damage adjacent Fence (overlay layer)
			if has_overlay(nc.x, nc.y):
				var obs: CellObstacle = _overlay[nc.x][nc.y]
				if obs.type == Types.ObstacleType.FENCE:
					damage_overlay(nc.x, nc.y)
					if not damaged.has(nc):
						damaged.append(nc)

			# Damage adjacent Chain (overlay layer)
			if has_overlay(nc.x, nc.y):
				var obs: CellObstacle = _overlay[nc.x][nc.y]
				if obs.type == Types.ObstacleType.CHAIN:
					damage_overlay(nc.x, nc.y)
					if not damaged.has(nc):
						damaged.append(nc)

	return damaged
