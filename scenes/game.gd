extends Node2D

@onready var _board: Node2D = $Board
@onready var _input: Node2D = $InputHandler

func _ready() -> void:
	_input.swap_requested.connect(_on_swap_requested)

func _on_swap_requested(from: Vector2i, to: Vector2i) -> void:
	_board.try_swap(from, to)
