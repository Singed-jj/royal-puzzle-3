class_name AreaProgress

var room_id: int
var tasks_done: Array = []
var total_tasks: int


func _init(p_room_id: int = 0, p_total_tasks: int = 0) -> void:
	room_id = p_room_id
	total_tasks = p_total_tasks


func is_complete() -> bool:
	return tasks_done.size() >= total_tasks


func progress_ratio() -> float:
	if total_tasks == 0:
		return 0.0
	return float(tasks_done.size()) / float(total_tasks)
