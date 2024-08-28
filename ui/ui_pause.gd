extends VBoxContainer

@onready var ui_overlay: ColorRect = %UIOverlay
@onready var ui_game_over: VBoxContainer = %UIGameOver
@onready var ui_pause: VBoxContainer = %UIPause

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("menu"):
		if get_tree().paused == false:
			ui_overlay.show()
			ui_game_over.hide()
			ui_pause.show()
			get_tree().paused = true
		else:
			get_tree().paused = false
			ui_pause.hide()
			ui_overlay.hide()

func _on_button_unpause_pressed() -> void:
	get_tree().paused = false
	ui_pause.hide()
	ui_overlay.hide()
