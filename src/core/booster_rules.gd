class_name BoosterRules


## Returns the BoosterType for a given match, or -1 if no booster is earned.
static func get_booster_for_match(match_type: String, _cell_count: int) -> int:
	match match_type:
		"horizontal_4":
			return Types.BoosterType.V_ROCKET
		"vertical_4":
			return Types.BoosterType.H_ROCKET
		"horizontal_5", "vertical_5":
			return Types.BoosterType.LIGHT_BALL
		"l_shape", "t_shape", "cross":
			return Types.BoosterType.TNT
		_:
			return -1
