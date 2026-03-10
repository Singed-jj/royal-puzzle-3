extends Node

const COLS := 8
const ROWS := 10


func _create_manager() -> ObstacleManager:
	var mgr := ObstacleManager.new()
	mgr.initialize(COLS, ROWS)
	return mgr


func test_stone_blocks_swap() -> void:
	var mgr := _create_manager()
	mgr.set_obstacle(3, 4, Types.ObstacleType.STONE, "main")
	assert(mgr.can_swap(3, 4) == false, "Stone should block swapping")
	assert(mgr.can_swap(3, 5) == true, "Adjacent cell should allow swapping")
	print("  PASS: test_stone_blocks_swap")


func test_stone_damaged_by_adjacent_match() -> void:
	var mgr := _create_manager()
	mgr.set_obstacle(3, 4, Types.ObstacleType.STONE, "main")
	assert(mgr.has_main(3, 4) == true, "Stone should exist before damage")

	# Match adjacent to stone
	var matched: Array = [Vector2i(2, 4), Vector2i(4, 4), Vector2i(3, 3)]
	var damaged := mgr.process_adjacent_match(matched)
	assert(damaged.has(Vector2i(3, 4)), "Stone at (3,4) should be damaged by adjacent match")
	assert(mgr.has_main(3, 4) == false, "Stone with HP 1 should be destroyed after 1 hit")
	print("  PASS: test_stone_damaged_by_adjacent_match")


func test_fence_protects_gem() -> void:
	var mgr := _create_manager()
	mgr.set_obstacle(5, 5, Types.ObstacleType.FENCE, "overlay")
	# Fence allows swap but blocks matching
	assert(mgr.can_swap(5, 5) == true, "Fence should allow swapping")
	assert(mgr.can_match(5, 5) == false, "Fence should block matching")
	print("  PASS: test_fence_protects_gem")


func test_fence_broken_by_adjacent() -> void:
	var mgr := _create_manager()
	mgr.set_obstacle(5, 5, Types.ObstacleType.FENCE, "overlay")
	assert(mgr.has_overlay(5, 5) == true, "Fence should exist before damage")

	var matched: Array = [Vector2i(5, 4)]
	var damaged := mgr.process_adjacent_match(matched)
	assert(damaged.has(Vector2i(5, 5)), "Fence at (5,5) should be damaged by adjacent match")
	assert(mgr.has_overlay(5, 5) == false, "Fence with HP 1 should be destroyed")
	print("  PASS: test_fence_broken_by_adjacent")


func test_grass_cleared_on_match() -> void:
	var mgr := _create_manager()
	mgr.set_obstacle(2, 3, Types.ObstacleType.GRASS, "underlay")
	# Grass allows swap and matching
	assert(mgr.can_swap(2, 3) == true, "Grass should allow swapping")
	assert(mgr.can_match(2, 3) == true, "Grass should allow matching")
	assert(mgr.has_underlay(2, 3) == true, "Grass should exist before clear")

	# Grass is cleared when the item above it is matched
	mgr.clear_underlay(2, 3)
	assert(mgr.has_underlay(2, 3) == false, "Grass should be cleared")
	print("  PASS: test_grass_cleared_on_match")


func test_chain_prevents_movement() -> void:
	var mgr := _create_manager()
	mgr.set_obstacle(4, 6, Types.ObstacleType.CHAIN, "overlay")
	# Chain blocks swap but allows matching
	assert(mgr.can_swap(4, 6) == false, "Chain should block swapping")
	assert(mgr.can_match(4, 6) == true, "Chain should allow matching")

	# Chain damaged by adjacent match
	var matched: Array = [Vector2i(4, 5)]
	var damaged := mgr.process_adjacent_match(matched)
	assert(damaged.has(Vector2i(4, 6)), "Chain at (4,6) should be damaged by adjacent match")
	assert(mgr.has_overlay(4, 6) == false, "Chain with HP 1 should be destroyed")
	print("  PASS: test_chain_prevents_movement")


func test_multi_hp_obstacle() -> void:
	var mgr := _create_manager()
	mgr.set_obstacle(3, 3, Types.ObstacleType.STONE, "main", 3)
	assert(mgr.has_main(3, 3) == true, "Stone HP3 should exist")

	# First hit: HP 3 -> 2
	var matched1: Array = [Vector2i(2, 3)]
	mgr.process_adjacent_match(matched1)
	assert(mgr.has_main(3, 3) == true, "Stone should survive after 1 hit (HP=2)")

	# Second hit: HP 2 -> 1
	var matched2: Array = [Vector2i(4, 3)]
	mgr.process_adjacent_match(matched2)
	assert(mgr.has_main(3, 3) == true, "Stone should survive after 2 hits (HP=1)")

	# Third hit: HP 1 -> 0, destroyed
	var matched3: Array = [Vector2i(3, 2)]
	mgr.process_adjacent_match(matched3)
	assert(mgr.has_main(3, 3) == false, "Stone should be destroyed after 3 hits (HP=0)")
	print("  PASS: test_multi_hp_obstacle")


func run_all() -> void:
	print("ObstacleManager Tests:")
	test_stone_blocks_swap()
	test_stone_damaged_by_adjacent_match()
	test_fence_protects_gem()
	test_fence_broken_by_adjacent()
	test_grass_cleared_on_match()
	test_chain_prevents_movement()
	test_multi_hp_obstacle()
	print("All ObstacleManager tests passed!")
