class_name NightmareMode
extends Node

signal time_expired()
signal rescue_progress(current: int, target: int)
signal rescue_complete()

const SCENARIOS := {
	"fire": {"time": 60.0, "target": 50, "description": "곰사원이 서버실 화재에 갇혔다!"},
	"flood": {"time": 55.0, "target": 55, "description": "하수도가 범람한다! 곰사원을 구출하라!"},
	"dragon": {"time": 50.0, "target": 60, "description": "악덕사장의 드래곤이 나타났다!"},
	"trap": {"time": 45.0, "target": 65, "description": "감시실 트랩이 작동했다!"},
}

var _active: bool = false
var _time_remaining: float = 0.0
var _current_progress: int = 0
var _target: int = 0
var _scenario: String = ""


func start(scenario: String, time: float = 60.0, target: int = 65) -> void:
	if SCENARIOS.has(scenario):
		var data: Dictionary = SCENARIOS[scenario]
		_time_remaining = data["time"]
		_target = data["target"]
	else:
		_time_remaining = time
		_target = target

	_scenario = scenario
	_current_progress = 0
	_active = true
	set_process(true)


func _process(delta: float) -> void:
	if not _active:
		return

	_time_remaining -= delta
	if _time_remaining <= 0.0:
		_active = false
		set_process(false)
		time_expired.emit()


func add_progress(amount: int = 1) -> void:
	if not _active:
		return

	_current_progress += amount
	rescue_progress.emit(_current_progress, _target)

	if _current_progress >= _target:
		_active = false
		set_process(false)
		rescue_complete.emit()


func is_active() -> bool:
	return _active


func get_time_remaining() -> float:
	return _time_remaining


func get_scenario_description() -> String:
	if SCENARIOS.has(_scenario):
		return SCENARIOS[_scenario]["description"]
	return ""


static func should_trigger(level_id: int) -> bool:
	return level_id % 10 == 5


static func get_scenario_for_level(level_id: int) -> Dictionary:
	var scenario_keys := ["fire", "flood", "dragon", "trap"]
	var index: int = (level_id / 10) % scenario_keys.size()
	var key: String = scenario_keys[index]
	return {"scenario": key, "time": SCENARIOS[key]["time"], "target": SCENARIOS[key]["target"], "description": SCENARIOS[key]["description"]}


func _ready() -> void:
	set_process(false)
