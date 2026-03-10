extends Node

const B := preload("res://src/core/booster_rules.gd")


func test_match_3_no_booster() -> void:
	assert(B.get_booster_for_match("horizontal_3", 3) == -1)
	assert(B.get_booster_for_match("vertical_3", 3) == -1)
	print("  PASS: test_match_3_no_booster")


func test_horizontal_4_creates_v_rocket() -> void:
	assert(B.get_booster_for_match("horizontal_4", 4) == Types.BoosterType.V_ROCKET)
	print("  PASS: test_horizontal_4_creates_v_rocket")


func test_vertical_4_creates_h_rocket() -> void:
	assert(B.get_booster_for_match("vertical_4", 4) == Types.BoosterType.H_ROCKET)
	print("  PASS: test_vertical_4_creates_h_rocket")


func test_5_match_creates_lightball() -> void:
	assert(B.get_booster_for_match("horizontal_5", 5) == Types.BoosterType.LIGHT_BALL)
	assert(B.get_booster_for_match("vertical_5", 5) == Types.BoosterType.LIGHT_BALL)
	print("  PASS: test_5_match_creates_lightball")


func test_l_shape_creates_tnt() -> void:
	assert(B.get_booster_for_match("l_shape", 5) == Types.BoosterType.TNT)
	print("  PASS: test_l_shape_creates_tnt")


func test_t_shape_creates_tnt() -> void:
	assert(B.get_booster_for_match("t_shape", 5) == Types.BoosterType.TNT)
	print("  PASS: test_t_shape_creates_tnt")


func test_cross_creates_tnt() -> void:
	assert(B.get_booster_for_match("cross", 5) == Types.BoosterType.TNT)
	print("  PASS: test_cross_creates_tnt")


func run_all() -> void:
	print("BoosterRules Tests:")
	test_match_3_no_booster()
	test_horizontal_4_creates_v_rocket()
	test_vertical_4_creates_h_rocket()
	test_5_match_creates_lightball()
	test_l_shape_creates_tnt()
	test_t_shape_creates_tnt()
	test_cross_creates_tnt()
	print("All BoosterRules tests passed!")
