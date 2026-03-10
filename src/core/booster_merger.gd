class_name BoosterMerger

var _table: Dictionary = {}


func _init() -> void:
	var B := Types.BoosterType
	var M := Types.MergeType

	_register(B.H_ROCKET, B.H_ROCKET, M.CROSS)
	_register(B.H_ROCKET, B.V_ROCKET, M.CROSS)
	_register(B.V_ROCKET, B.V_ROCKET, M.CROSS)

	_register(B.TNT, B.H_ROCKET, M.BIG_ROCKET)
	_register(B.TNT, B.V_ROCKET, M.BIG_ROCKET)

	_register(B.TNT, B.TNT, M.MEGA_EXPLOSION)

	_register(B.LIGHT_BALL, B.LIGHT_BALL, M.ALL_BOARD)
	_register(B.LIGHT_BALL, B.H_ROCKET, M.COLOR_ROCKET)
	_register(B.LIGHT_BALL, B.V_ROCKET, M.COLOR_ROCKET)
	_register(B.LIGHT_BALL, B.TNT, M.COLOR_TNT)
	_register(B.LIGHT_BALL, B.MISSILE, M.COLOR_MISSILE)

	_register(B.MISSILE, B.MISSILE, M.TRIPLE_MISSILE)
	_register(B.MISSILE, B.H_ROCKET, M.MISSILE_ROCKET)
	_register(B.MISSILE, B.V_ROCKET, M.MISSILE_ROCKET)
	_register(B.MISSILE, B.TNT, M.MISSILE_TNT)


## Returns the MergeType for two boosters, or -1 if they cannot merge.
func get_merge_type(type_a: int, type_b: int) -> int:
	var key := _make_key(type_a, type_b)
	if _table.has(key):
		return _table[key]
	return -1


func _make_key(a: int, b: int) -> int:
	return mini(a, b) * 100 + maxi(a, b)


func _register(a: int, b: int, result: int) -> void:
	_table[_make_key(a, b)] = result
