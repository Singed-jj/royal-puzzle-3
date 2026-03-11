extends Sprite2D

var gem_type: int = -1
var grid_pos: Vector2i = Vector2i.ZERO
var _target_position: Vector2
var _is_moving: bool = false

const FALL_SPEED := 800.0
const SWAP_SPEED := 400.0

const GEM_COLORS := [
	Color.RED, Color.BLUE, Color.GREEN,
	Color.YELLOW, Color.PURPLE, Color.ORANGE
]

# 개별 젬 PNG 파일 경로 (128x128, 투명 배경)
const GEM_PATHS := [
	"res://assets/sprites/gems/gem_0.png",  # RED - heart
	"res://assets/sprites/gems/gem_1.png",  # BLUE - diamond
	"res://assets/sprites/gems/gem_2.png",  # GREEN - leaf
	"res://assets/sprites/gems/gem_3.png",  # YELLOW - star
	"res://assets/sprites/gems/gem_4.png",  # PURPLE - pentagon
	"res://assets/sprites/gems/gem_5.png",  # ORANGE - ball
]

static var _gem_textures: Array = []

static func _load_gem_textures() -> void:
	if _gem_textures.size() > 0:
		return
	for path in GEM_PATHS:
		var tex: Texture2D = load(path)
		_gem_textures.append(tex)

static var _placeholder_texture: ImageTexture

static func _get_placeholder() -> ImageTexture:
	if _placeholder_texture == null:
		var img := Image.create(40, 40, false, Image.FORMAT_RGBA8)
		img.fill(Color.WHITE)
		for x in range(40):
			for y in range(40):
				var dx := x - 19.5
				var dy := y - 19.5
				if dx * dx + dy * dy > 18.0 * 18.0:
					img.set_pixel(x, y, Color.TRANSPARENT)
		_placeholder_texture = ImageTexture.create_from_image(img)
	return _placeholder_texture

func setup(type: int, col: int, row: int) -> void:
	gem_type = type
	grid_pos = Vector2i(col, row)

	# 스프라이트시트에서 텍스처 로드 시도
	_load_gem_textures()
	if type >= 0 and type < _gem_textures.size() and _gem_textures[type] != null:
		texture = _gem_textures[type]
		modulate = Color.WHITE
	else:
		texture = _get_placeholder()
		modulate = GEM_COLORS[type] if type >= 0 and type < GEM_COLORS.size() else Color.WHITE

	# 스프라이트 크기를 셀 크기에 맞춤
	var tex_size: Vector2 = texture.get_size()
	if tex_size.x > 0 and tex_size.y > 0:
		var target_size := float(Types.CELL_SIZE - 4)
		var scale_factor: float = target_size / max(tex_size.x, tex_size.y)
		scale = Vector2(scale_factor, scale_factor)

	position = _grid_to_world(col, row)
	_target_position = position

func move_to(col: int, row: int, speed: float = FALL_SPEED) -> void:
	grid_pos = Vector2i(col, row)
	_target_position = _grid_to_world(col, row)
	_is_moving = true

func _process(delta: float) -> void:
	if _is_moving:
		position = position.move_toward(_target_position, FALL_SPEED * delta)
		if position.distance_to(_target_position) < 1.0:
			position = _target_position
			_is_moving = false

func destroy() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.15)
	tween.tween_callback(queue_free)

func _grid_to_world(col: int, row: int) -> Vector2:
	return Vector2(
		Types.BOARD_OFFSET_X + col * Types.CELL_SIZE + Types.CELL_SIZE / 2,
		Types.BOARD_OFFSET_Y + row * Types.CELL_SIZE + Types.CELL_SIZE / 2
	)
