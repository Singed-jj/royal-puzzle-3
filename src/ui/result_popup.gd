extends CanvasLayer

@onready var overlay: ColorRect = $Overlay
@onready var panel: PanelContainer = $Panel
@onready var title_label: Label = $Panel/VBox/TitleLabel
@onready var stars_container: HBoxContainer = $Panel/VBox/StarsContainer
@onready var message_label: Label = $Panel/VBox/MessageLabel
@onready var continue_button: Button = $Panel/VBox/ContinueButton
@onready var retry_button: Button = $Panel/VBox/RetryButton

func _ready() -> void:
	_set_visible(false)
	GameEvents.level_completed.connect(_on_level_completed)
	GameEvents.level_failed.connect(_on_level_failed)
	continue_button.pressed.connect(_on_continue_pressed)
	retry_button.pressed.connect(_on_retry_pressed)

func _set_visible(show: bool) -> void:
	overlay.visible = show
	panel.visible = show

func _on_level_completed(stars: int) -> void:
	_set_visible(true)
	title_label.text = "레벨 클리어!"
	message_label.text = "축하합니다!"
	_show_stars(stars)
	continue_button.visible = true
	retry_button.visible = false
	SaveManager.complete_level(GameManager.current_level, stars)

func _on_level_failed() -> void:
	_set_visible(true)
	title_label.text = "실패..."
	message_label.text = "다시 도전하세요!"
	_show_stars(0)
	continue_button.visible = false
	retry_button.visible = true

func _show_stars(count: int) -> void:
	for child in stars_container.get_children():
		child.queue_free()
	for i in range(3):
		var star := Label.new()
		star.text = "★" if i < count else "☆"
		star.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stars_container.add_child(star)

func _on_continue_pressed() -> void:
	_set_visible(false)
	get_tree().change_scene_to_file("res://src/ui/level_select.tscn")

func _on_retry_pressed() -> void:
	_set_visible(false)
	get_tree().reload_current_scene()
