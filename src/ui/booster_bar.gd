extends HBoxContainer

const BOOSTERS := [
	{"type": "hammer", "name": "해머", "cost": 100, "desc": "보석 1개 제거"},
	{"type": "arrow", "name": "화살", "cost": 150, "desc": "가로줄 제거"},
	{"type": "cannon", "name": "대포", "cost": 150, "desc": "세로줄 제거"},
	{"type": "rainbow", "name": "무지개", "cost": 200, "desc": "같은 색 전체 제거"},
]

func _ready() -> void:
	_create_buttons()

func _create_buttons() -> void:
	for booster in BOOSTERS:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(80, 50)
		btn.text = "%s\n%d💰" % [booster.name, booster.cost]
		btn.tooltip_text = booster.desc
		btn.pressed.connect(_on_booster_pressed.bind(booster))
		add_child(btn)

func _on_booster_pressed(booster: Dictionary) -> void:
	if SaveManager.data.coins >= booster.cost:
		SaveManager.data.coins -= booster.cost
		SaveManager.save_game()
		GameEvents.ui_booster_used.emit(booster.type)
