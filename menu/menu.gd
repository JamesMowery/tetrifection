extends Control

@onready var new_game: Button = %NewGame
@onready var settings: Button = %Settings
@onready var exit_game: Button = %ExitGame

@export var game_scene: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	new_game.grab_focus()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_new_game_pressed() -> void:
	get_tree().change_scene_to_packed(game_scene)

func _on_settings_pressed() -> void:
	pass # Replace with function body.

func _on_exit_game_pressed() -> void:
	#get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	# Should send the signal for the above and listen instead of this:
	get_tree().quit()
