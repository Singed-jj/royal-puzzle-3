class_name LevelGenerator

const ROOM_NAMES: Array[String] = [
	"서버실", "감옥", "와인 저장고", "하수도",
	"우편물 창고", "식당", "휴게실", "환기 덕트",
	"문서 보관실", "인사팀", "회의실", "경리실",
	"감시실", "트로피 룸", "스파", "사장실",
	"엘리베이터", "옥상", "외벽", "정문",
]

const GEM_NAMES: Array[String] = ["red", "blue", "green", "yellow", "purple", "orange"]

const OBSTACLE_TYPES: Array[String] = ["stone", "fence", "grass", "chain"]


func generate(level_id: int) -> LevelData:
	var data := LevelData.new()
	data.level_id = level_id

	var room: int = (level_id - 1) / 10
	var stage: int = (level_id - 1) % 10

	# moves
	var base_moves: int = 25 - room
	data.moves = maxi(base_moves - stage / 3, 10)

	# goals
	var goal_count: int
	if stage < 3:
		goal_count = 1
	elif stage < 7:
		goal_count = 2
	else:
		goal_count = 3

	var goal_amount: int = 10 + room * 2 + stage * 3
	data.goals_data = []
	for i in range(goal_count):
		data.goals_data.append({
			"type": GEM_NAMES[i % GEM_NAMES.size()],
			"amount": goal_amount,
		})

	# obstacles
	if room < 1 and stage < 5:
		data.obstacles = []
	else:
		var obs_count: int = mini((room + stage) / 2, 15)
		data.obstacles = []
		for i in range(obs_count):
			var obs_type: String = "stone"
			if room >= 6:
				obs_type = OBSTACLE_TYPES[i % 4]
			elif room >= 4:
				obs_type = OBSTACLE_TYPES[i % 3]  # stone, fence, grass
			elif room >= 2:
				obs_type = OBSTACLE_TYPES[i % 2]  # stone, fence
			data.obstacles.append({
				"col": i % data.board_cols,
				"row": (i / data.board_cols) + 1,
				"type": obs_type,
				"hp": 1,
			})

	# available_gems
	if room >= 3:
		data.available_gems = [0, 1, 2, 3, 4, 5]
	else:
		data.available_gems = [0, 1, 2, 3, 4]

	return data


func get_room_name(level_id: int) -> String:
	var room: int = (level_id - 1) / 10
	room = clampi(room, 0, ROOM_NAMES.size() - 1)
	return ROOM_NAMES[room]
