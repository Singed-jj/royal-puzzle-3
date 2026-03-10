extends Node

const ROOM_NAMES := [
	"서버실", "감옥", "와인 저장고", "하수도",
	"우편물 창고", "식당", "휴게실", "환기 덕트",
	"문서 보관실", "인사팀", "회의실", "경리실",
	"감시실", "트로피 룸", "스파", "사장실",
	"엘리베이터", "옥상", "외벽", "정문",
]

const ROOM_TASKS := {
	0: ["서버 랙 정리", "케이블 연결", "냉각 장치 수리", "모니터 설치", "방화벽 점검", "UPS 교체"],
	1: ["잠금장치 해제", "창살 제거", "벽 균열 수리", "환기구 열기", "조명 설치", "탈출로 확보"],
	2: ["선반 정리", "와인 분류", "온도 조절기 수리", "조명 교체", "습도 관리", "재고 기록"],
	3: ["배수구 청소", "파이프 수리", "펌프 가동", "악취 제거", "조명 확보", "안전 난간 설치"],
	4: ["우편물 분류", "택배 정리", "선반 조립", "라벨 부착기 수리", "카트 수리", "운송장 정리"],
	5: ["테이블 배치", "주방 청소", "식기 정리", "조명 교체", "메뉴판 수리", "환풍기 점검"],
	6: ["소파 배치", "자판기 수리", "TV 설치", "탁자 정리", "잡지 정리", "에어컨 점검"],
	7: ["덕트 청소", "필터 교체", "팬 수리", "그릴 설치", "온도 센서 교체", "밀봉 점검"],
	8: ["서류 정리", "캐비넷 수리", "라벨링", "분쇄기 수리", "조명 교체", "잠금장치 설치"],
	9: ["데스크 정리", "파일 캐비넷 수리", "컴퓨터 설치", "출입증 시스템 수리", "게시판 설치", "의자 교체"],
	10: ["프로젝터 설치", "화이트보드 수리", "테이블 배치", "마이크 설치", "조명 조절", "커튼 설치", "에어컨 수리"],
	11: ["금고 수리", "계산기 교체", "서류 캐비넷 정리", "조명 교체", "CCTV 설치", "창문 수리", "자물쇠 교체"],
	12: ["모니터 벽 수리", "컨트롤 패널 점검", "녹화기 교체", "케이블 정리", "비상 버튼 수리", "창문 보강", "잠금 시스템 점검"],
	13: ["전시대 설치", "조명 교체", "유리 케이스 수리", "명판 부착", "바닥 연마", "경보 장치 설치", "청소 도구 배치"],
	14: ["욕조 수리", "사우나 점검", "타일 교체", "배수구 청소", "조명 설치", "온도 조절기 수리", "수건 선반 설치"],
	15: ["데스크 배치", "의자 교체", "금고 수리", "서가 정리", "조명 교체", "카펫 교체", "창문 수리"],
	16: ["버튼 패널 수리", "케이블 교체", "조명 설치", "안전 센서 점검", "비상 전화 설치", "거울 교체", "환풍기 청소"],
	17: ["안테나 수리", "난간 설치", "조명 배치", "바닥 방수 처리", "배수구 청소", "벤치 설치", "풍향계 수리"],
	18: ["벽면 수리", "배수관 점검", "창문 교체", "페인트 작업", "비계 설치", "안전망 설치", "조명 교체"],
	19: ["대문 수리", "보안 시스템 설치", "인터폰 교체", "조명 배치", "울타리 수리", "간판 설치", "CCTV 설치"],
}

var _rooms: Array = []  # Array[RoomData]
var _current_room: int = 0
var _completed_tasks: Dictionary = {}  # task_id -> true


func _ready() -> void:
	_generate_20_rooms()


func get_current_room() -> RoomData:
	if _current_room >= 0 and _current_room < _rooms.size():
		return _rooms[_current_room]
	return null


func set_current_room(index: int) -> void:
	if index >= 0 and index < _rooms.size():
		_current_room = index


func complete_task(task_id: String) -> void:
	if _completed_tasks.has(task_id):
		return

	_completed_tasks[task_id] = true
	GameEvents.task_completed.emit(task_id)

	# 현재 방의 모든 태스크 완료 체크
	var room: RoomData = get_current_room()
	if room == null:
		return

	var all_done := true
	for task in room.tasks:
		if not _completed_tasks.has(task["id"]):
			all_done = false
			break

	if all_done:
		GameEvents.area_completed.emit(room.room_id)
		# 다음 방으로 이동
		if _current_room < _rooms.size() - 1:
			_current_room += 1


func get_area_progress() -> Dictionary:
	var room: RoomData = get_current_room()
	if room == null:
		return {"done": 0, "total": 0}

	var done := 0
	for task in room.tasks:
		if _completed_tasks.has(task["id"]):
			done += 1

	return {"done": done, "total": room.tasks.size()}


func is_task_completed(task_id: String) -> bool:
	return _completed_tasks.has(task_id)


func get_room_count() -> int:
	return _rooms.size()


func _generate_20_rooms() -> void:
	_rooms.clear()

	for i in range(20):
		var room := RoomData.new()
		room.room_id = i
		room.name = ROOM_NAMES[i]
		room.description = "%s - 곰사원의 탈출 경로 %d번째 공간" % [ROOM_NAMES[i], i + 1]
		room.background_texture = "res://assets/rooms/room_%02d.png" % i
		room.escape_description = "%s을(를) 통과하라!" % ROOM_NAMES[i]

		var task_count: int = 6 if i < 10 else 7
		var task_names: Array = ROOM_TASKS[i]
		var tasks: Array = []

		for j in range(task_count):
			var star_cost: int = 1 + (j / 3)
			var task_name: String = task_names[j] if j < task_names.size() else "작업 %d" % j
			tasks.append({
				"id": "room_%d_task_%d" % [i, j],
				"name": task_name,
				"star_cost": star_cost,
			})

		room.tasks = tasks
		_rooms.append(room)
