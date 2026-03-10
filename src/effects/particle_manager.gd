extends Node2D

func _ready() -> void:
	GameEvents.gems_destroyed.connect(_on_gems_destroyed)
	GameEvents.booster_activated.connect(_on_booster_activated)

func _on_gems_destroyed(cells: Array) -> void:
	for cell in cells:
		_spawn_destroy_particles(cell)

func _on_booster_activated(col: int, row: int, type: int) -> void:
	var world_pos := _grid_to_world(col, row)
	match type:
		Types.BoosterType.H_ROCKET:
			_spawn_rocket_trail(world_pos, true)
		Types.BoosterType.V_ROCKET:
			_spawn_rocket_trail(world_pos, false)
		Types.BoosterType.TNT:
			_spawn_explosion(world_pos, 2)
		Types.BoosterType.LIGHT_BALL:
			_spawn_light_burst(world_pos)
		Types.BoosterType.MISSILE:
			_spawn_missile_trail(world_pos)

func _spawn_destroy_particles(cell: Vector2i) -> void:
	var pos := _grid_to_world(cell.x, cell.y)
	var particles := CPUParticles2D.new()
	particles.position = pos
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 8
	particles.lifetime = 0.4
	particles.explosiveness = 1.0
	particles.direction = Vector2(0, -1)
	particles.spread = 180.0
	particles.initial_velocity_min = 50.0
	particles.initial_velocity_max = 120.0
	particles.gravity = Vector2(0, 200)
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 4.0
	add_child(particles)
	get_tree().create_timer(1.0).timeout.connect(particles.queue_free)

func _spawn_rocket_trail(pos: Vector2, horizontal: bool) -> void:
	var particles := CPUParticles2D.new()
	particles.position = pos
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 16
	particles.lifetime = 0.3
	particles.explosiveness = 0.5
	particles.direction = Vector2(1, 0) if horizontal else Vector2(0, 1)
	particles.spread = 10.0
	particles.initial_velocity_min = 200.0
	particles.initial_velocity_max = 400.0
	particles.color = Color.ORANGE
	add_child(particles)
	get_tree().create_timer(1.0).timeout.connect(particles.queue_free)

func _spawn_explosion(pos: Vector2, radius: int) -> void:
	var particles := CPUParticles2D.new()
	particles.position = pos
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 24
	particles.lifetime = 0.5
	particles.explosiveness = 1.0
	particles.spread = 180.0
	particles.initial_velocity_min = 100.0
	particles.initial_velocity_max = 250.0
	particles.gravity = Vector2.ZERO
	particles.color = Color.YELLOW
	particles.scale_amount_min = 3.0
	particles.scale_amount_max = 6.0
	add_child(particles)
	get_tree().create_timer(1.5).timeout.connect(particles.queue_free)

func _spawn_light_burst(pos: Vector2) -> void:
	var particles := CPUParticles2D.new()
	particles.position = pos
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 32
	particles.lifetime = 0.6
	particles.explosiveness = 1.0
	particles.spread = 180.0
	particles.initial_velocity_min = 150.0
	particles.initial_velocity_max = 350.0
	particles.gravity = Vector2.ZERO
	particles.color = Color.WHITE
	add_child(particles)
	get_tree().create_timer(1.5).timeout.connect(particles.queue_free)

func _spawn_missile_trail(pos: Vector2) -> void:
	_spawn_rocket_trail(pos, true)

func _grid_to_world(col: int, row: int) -> Vector2:
	return Vector2(
		Types.BOARD_OFFSET_X + col * Types.CELL_SIZE + Types.CELL_SIZE / 2,
		Types.BOARD_OFFSET_Y + row * Types.CELL_SIZE + Types.CELL_SIZE / 2
	)
