class_name LevelData
extends Resource

class Goal:
	var type: String
	var amount: int

	func _init(t: String = "", a: int = 0) -> void:
		type = t
		amount = a

@export var level_id: int
@export var moves: int = 20
@export var board_cols: int = 8
@export var board_rows: int = 10
@export var goals_data: Array = []  # [{"type": "red", "amount": 12}]
@export var cell_layout: Array = []
@export var obstacles: Array = []   # [{"col":2,"row":3,"type":"stone","hp":1}]
@export var available_gems: Array = [0, 1, 2, 3, 4]

var goals: Array:
	get:
		var result: Array = []
		for gd in goals_data:
			var g := Goal.new(gd.get("type", ""), gd.get("amount", 0))
			result.append(g)
		return result
