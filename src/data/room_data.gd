class_name RoomData
extends Resource

@export var room_id: int
@export var name: String
@export var description: String
@export var tasks: Array = []  # [{"id":"room_0_task_0","name":"책상 설치","star_cost":2}]
@export var background_texture: String
@export var escape_description: String
