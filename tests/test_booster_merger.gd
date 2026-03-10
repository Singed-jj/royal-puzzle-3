extends Node

var _merger: BoosterMerger


func _init() -> void:
	_merger = BoosterMerger.new()


func test_rocket_rocket_cross() -> void:
	var B := Types.BoosterType
	assert(_merger.get_merge_type(B.H_ROCKET, B.H_ROCKET) == Types.MergeType.CROSS)
	assert(_merger.get_merge_type(B.H_ROCKET, B.V_ROCKET) == Types.MergeType.CROSS)
	assert(_merger.get_merge_type(B.V_ROCKET, B.V_ROCKET) == Types.MergeType.CROSS)
	print("  PASS: test_rocket_rocket_cross")


func test_tnt_tnt_mega() -> void:
	assert(_merger.get_merge_type(Types.BoosterType.TNT, Types.BoosterType.TNT) == Types.MergeType.MEGA_EXPLOSION)
	print("  PASS: test_tnt_tnt_mega")


func test_lightball_lightball_all() -> void:
	assert(_merger.get_merge_type(Types.BoosterType.LIGHT_BALL, Types.BoosterType.LIGHT_BALL) == Types.MergeType.ALL_BOARD)
	print("  PASS: test_lightball_lightball_all")


func test_lightball_rocket_color_rocket() -> void:
	var B := Types.BoosterType
	assert(_merger.get_merge_type(B.LIGHT_BALL, B.H_ROCKET) == Types.MergeType.COLOR_ROCKET)
	assert(_merger.get_merge_type(B.LIGHT_BALL, B.V_ROCKET) == Types.MergeType.COLOR_ROCKET)
	print("  PASS: test_lightball_rocket_color_rocket")


func test_lightball_tnt_color_tnt() -> void:
	assert(_merger.get_merge_type(Types.BoosterType.LIGHT_BALL, Types.BoosterType.TNT) == Types.MergeType.COLOR_TNT)
	print("  PASS: test_lightball_tnt_color_tnt")


func test_tnt_rocket_big_rocket() -> void:
	var B := Types.BoosterType
	assert(_merger.get_merge_type(B.TNT, B.H_ROCKET) == Types.MergeType.BIG_ROCKET)
	assert(_merger.get_merge_type(B.TNT, B.V_ROCKET) == Types.MergeType.BIG_ROCKET)
	print("  PASS: test_tnt_rocket_big_rocket")


func test_normal_gem_no_merge() -> void:
	# Normal gems (negative or out-of-range values) should not merge
	assert(_merger.get_merge_type(-1, Types.BoosterType.H_ROCKET) == -1)
	assert(_merger.get_merge_type(-1, -1) == -1)
	print("  PASS: test_normal_gem_no_merge")


func test_commutative() -> void:
	var B := Types.BoosterType
	# Verify A+B == B+A for all registered pairs
	var pairs := [
		[B.H_ROCKET, B.V_ROCKET],
		[B.TNT, B.H_ROCKET],
		[B.TNT, B.V_ROCKET],
		[B.LIGHT_BALL, B.H_ROCKET],
		[B.LIGHT_BALL, B.V_ROCKET],
		[B.LIGHT_BALL, B.TNT],
		[B.LIGHT_BALL, B.MISSILE],
		[B.MISSILE, B.H_ROCKET],
		[B.MISSILE, B.V_ROCKET],
		[B.MISSILE, B.TNT],
	]
	for pair in pairs:
		assert(_merger.get_merge_type(pair[0], pair[1]) == _merger.get_merge_type(pair[1], pair[0]))
	print("  PASS: test_commutative")


func run_all() -> void:
	print("BoosterMerger Tests:")
	test_rocket_rocket_cross()
	test_tnt_tnt_mega()
	test_lightball_lightball_all()
	test_lightball_rocket_color_rocket()
	test_lightball_tnt_color_tnt()
	test_tnt_rocket_big_rocket()
	test_normal_gem_no_merge()
	test_commutative()
	print("All BoosterMerger tests passed!")
