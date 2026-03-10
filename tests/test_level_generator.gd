extends Node

var generator := LevelGenerator.new()


func test_level_1_is_easy() -> void:
	var ld := generator.generate(1)
	assert(ld.moves >= 18, "Level 1 should have >= 18 moves")
	assert(ld.goals.size() == 1, "Level 1 should have 1 goal")
	assert(ld.obstacles.size() == 0, "Level 1 should have 0 obstacles")
	print("  PASS: test_level_1_is_easy")


func test_level_50_medium() -> void:
	var ld := generator.generate(50)
	assert(ld.moves <= 22, "Level 50 should have <= 22 moves")
	assert(ld.goals.size() >= 2, "Level 50 should have >= 2 goals")
	assert(ld.obstacles.size() > 0, "Level 50 should have obstacles")
	print("  PASS: test_level_50_medium")


func test_level_200_hard() -> void:
	var ld := generator.generate(200)
	assert(ld.moves <= 18, "Level 200 should have <= 18 moves")
	assert(ld.goals.size() >= 2, "Level 200 should have >= 2 goals")
	print("  PASS: test_level_200_hard")


func test_moves_decrease_with_level() -> void:
	var ld_early := generator.generate(1)
	var ld_late := generator.generate(200)
	assert(ld_early.moves > ld_late.moves, "Later levels should have fewer moves")
	print("  PASS: test_moves_decrease_with_level")


func test_all_200_levels_valid() -> void:
	for i in range(1, 201):
		var ld := generator.generate(i)
		assert(ld.moves > 0, "Level %d should have moves > 0" % i)
		assert(ld.goals.size() > 0, "Level %d should have at least 1 goal" % i)
	print("  PASS: test_all_200_levels_valid")
