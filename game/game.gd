extends Node2D

signal scored(score_amount: int)

@onready var board_layer: TileMapLayer = %BoardLayer
@onready var piece_layer: TileMapLayer = %PieceLayer
@onready var sfx_settle: AudioStreamPlayer = %SFX_Settle
@onready var sfx_clear: AudioStreamPlayer = %SFX_Clear
@onready var sfx_next_level: AudioStreamPlayer = %SFX_NextLevel
@onready var score_data: Label = %ScoreData
@onready var bgm_interactive: AudioStreamPlayer = %BGMInteractive
@onready var ui_overlay: ColorRect = %UIOverlay
@onready var ui_game_over: VBoxContainer = %UIGameOver
@onready var ui_pause: VBoxContainer = %UIPause
@onready var button_new_game: Button = %ButtonNewGame
@onready var end_score_data: Label = %EndScoreData
@onready var drop_timer: Timer = %DropTimer

# Board
@export var board_columns: int = 10
@export var board_rows: int = 20
var board: Array = []

enum PIECE_TYPE {
	CURRENT,
	NEXT
}

# Piece Grids		 [PIVOT         , GRID[0]       , GRID[1]		, GRID[2]		, GRID[3]		]
var piece_z: Array = [Vector2i(1, 1), Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1)]
var piece_l: Array = [Vector2i(1, 1), Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)]
var piece_o: Array = [Vector2i(-1, -1), Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]
var piece_t: Array = [Vector2i(1, 1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)]
var piece_j: Array = [Vector2i(1, 1), Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)]
var piece_s: Array = [Vector2i(1, 1), Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1)]
var piece_i: Array = [Vector2i(0, 1), Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 3)]
var pieces: Array  = [piece_z, piece_l, piece_o, piece_t, piece_j, piece_s, piece_i]
var pieces_bag: Array = pieces.duplicate()
var colors: Array = [0, 1, 2, 3, 4 , 5, 6]
var colors_bag: Array = colors.duplicate()

# Game Piece Variables
var current_piece: Array
var next_piece: Array
var rotation_index: int = 0
var drop_complete: bool = false

# Movement Variables
const starting_position: Vector2i = Vector2i(4, 0)
var current_position: Vector2i
var steps: int
const steps_req: int = 60
var speed: float

# Next Piece Variables
const next_piece_position := Vector2i(14, 1)

# TileMap Variables
const tile_id: int = 2
var current_piece_atlas: Vector2i
var next_piece_atlas: Vector2i

# Scoring
var score_amount: int = 100
var lines_cleared: int = 0

# Sound & Music
var danger: bool = false
var danger_playing: bool = false

func _ready() -> void:
	ui_overlay.hide()
	ui_game_over.hide()
	ui_pause.hide()
	scored.connect(update_score)
	score_data.text = "0"
	speed = 1.0
	steps = 0
	create_board_grid()

	# Randomize start
	colors_bag.shuffle()
	pieces_bag.shuffle()
	create_piece()

func _process(delta: float) -> void:
	# Apply downward movement every frame
	steps += speed
	if steps > steps_req:
		move_piece(Vector2i.DOWN)
		steps = 0

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("move_left"):
		move_piece(Vector2i.LEFT)
	if Input.is_action_just_pressed("move_right"):
		move_piece(Vector2i.RIGHT)
	if Input.is_action_just_pressed("move_up"):
		rotate_piece_ccw(PIECE_TYPE.CURRENT)
	if Input.is_action_pressed("move_down"):
		steps += 10
	if Input.is_action_just_pressed("move_down"):
		drop_complete = true
		drop_timer.start()
	if Input.is_action_just_released("move_down"):
		drop_timer.stop()

# Creates and initializes the board grid
func create_board_grid() -> void:
	board.resize(board_rows)
	board.fill([0,0,0,0,0,0,0,0,0,0])

func create_piece() -> void:
	pick_piece()
	current_position = starting_position

	draw_piece(current_piece, current_position, current_piece_atlas)
	draw_piece(next_piece, next_piece_position, next_piece_atlas)

func pick_piece() -> void:
	# Check for current piece
	if not pieces_bag.is_empty():
		current_piece_atlas = pick_color()
		current_piece = pieces_bag.pop_front()

	# Check for next piece
	if pieces_bag.is_empty():
		pieces_bag = pieces.duplicate()
		pieces_bag.shuffle()

	# Handle next piece
	clear_piece(PIECE_TYPE.NEXT)
	next_piece_atlas = Vector2i(colors_bag[0], 0)
	next_piece = pieces_bag[0]
	random_rotate()

func draw_piece(piece: Array, pos: Vector2i, atlas: Vector2i) -> void:
	for i: int in piece.size():
		if i != 0:
			piece_layer.set_cell(pos + piece[i], tile_id, atlas)

func clear_row(y_value) -> void:
	for i in range(0, 10):
		piece_layer.erase_cell(Vector2i(i, y_value))

func clear_piece(piece_type: PIECE_TYPE) -> void:
	var selected_piece: Array
	var selected_position: Vector2i

	match piece_type:
		PIECE_TYPE.CURRENT:
			selected_piece = current_piece
			selected_position = current_position
		PIECE_TYPE.NEXT:
			selected_piece = next_piece
			selected_position = next_piece_position

	for i: int in selected_piece.size():
		if i != 0:
			piece_layer.erase_cell(selected_position + selected_piece[i])

func move_piece(direction: Vector2i) -> void:
	if can_move(direction):
		clear_piece(PIECE_TYPE.CURRENT)
		current_position += direction
		draw_piece(current_piece, current_position, current_piece_atlas)
	else:
		if direction == Vector2i.DOWN:
			drop_complete = true
			sfx_settle.play()
			check_game_over()
			create_piece()

func drop_piece() -> void:
	while drop_complete != true:
		if can_move(Vector2i.DOWN):
			clear_piece(PIECE_TYPE.CURRENT)
			current_position += Vector2i.DOWN
			draw_piece(current_piece, current_position, current_piece_atlas)
		else:
			drop_complete = true
			drop_timer.stop()

func pick_color() -> Vector2i:
	var picked_color: int

	# Check for current piece
	if not colors_bag.is_empty():
		picked_color = colors_bag.pop_front()

	# Check for next piece
	if colors_bag.is_empty():
		colors_bag = colors.duplicate()
		colors_bag.shuffle()

	return Vector2i(picked_color, 0)

func random_rotate() -> void:
	var random = randi_range(0, 3)
	for i in range(0, random):
		rotate_piece_ccw(PIECE_TYPE.NEXT)

func rotate_piece_ccw(piece_type: PIECE_TYPE) -> void:
	clear_piece(piece_type)
	var selected_piece: Array
	var selected_position: Vector2i
	var selected_atlas: Vector2i

	match piece_type:
		PIECE_TYPE.CURRENT:
			selected_piece = current_piece
			selected_position = current_position
			selected_atlas = current_piece_atlas
		PIECE_TYPE.NEXT:
			selected_piece = next_piece
			selected_position = next_piece_position
			selected_atlas = next_piece_atlas

	var piece_pivot: Vector2i

	for i: int in selected_piece.size():
		if i != 0:
			if piece_pivot != Vector2i(-1, -1):
				var temp_piece: Array = selected_piece.duplicate()
				selected_piece[i].x = -(temp_piece[i].y - piece_pivot.y) + piece_pivot.y
				selected_piece[i].y = (temp_piece[i].x - piece_pivot.x) + piece_pivot.y
		else:
			piece_pivot = selected_piece[i]

	draw_piece(selected_piece, selected_position, selected_atlas)

func can_move(direction: Vector2i) -> bool:
	var moving: bool = true
	# General Check
	for i in current_piece.size():
		if i != 0:
			if not is_free(current_piece[i] + current_position + direction, 1):
				moving = false
				check_clear()

	# Lowest Check
	if direction == Vector2i.DOWN:
		var most_downward: Array = most_downward()
		for i in current_piece.size():
			if i != 0 and current_piece[i].y == most_downward[current_piece[i].x + 1]:
				if not is_free(current_piece[i] + current_position + direction, 0):
					moving = false
					check_clear()
	else:
		for i in current_piece.size():
			if i != 0:
				if not is_free(current_piece[i] + current_position + direction, 0):
					pass
					#moving = false

	return moving

func most_downward() -> Array:
	var lowest_y_values: Array = [-1, 0, 0, 0, 0]

	for i in range(current_piece.size()):
		if i != 0:
			if current_piece[i].y > lowest_y_values[current_piece[i].x + 1]:
				lowest_y_values[current_piece[i].x + 1] = current_piece[i].y

	return lowest_y_values

func is_free(pos: Vector2i, layer: int) -> bool:
	if layer == 1:
		return board_layer.get_cell_source_id(pos) == -1
	else:
		return piece_layer.get_cell_source_id(pos) == -1

func can_rotate() -> bool:
	var rotating: bool = true
	#Use is_free to see if piece change is free
	return rotating

func check_clear() -> void:
	var y_values: Array
	var x_count = 0

	for i in current_piece.size():
		if i != 0:
			if not y_values.has((current_position + current_piece[i]).y):
				y_values.append((current_position + current_piece[i]).y)

	for y in y_values.size():
		x_count = 0
		for x in range(0, 10):
			if piece_layer.get_cell_source_id(Vector2i(x, y_values[y])) != -1:
				x_count += 1
				if x_count == 10:
					clear_row(y_values[y])
					drop_rows(y_values[y])
					sfx_clear.play()
					scored.emit(score_amount)
					lines_cleared += 1
					if lines_cleared % 10 == 0:
						speed += 1.0
						sfx_next_level.play()

func drop_rows(y_value: int) -> void:
	for row in range(y_value, -1, -1):
		for col in range(0, 10):
			var existing_piece
			var existing_color
			existing_piece = piece_layer.get_cell_source_id(Vector2i(col, row))
			existing_color = piece_layer.get_cell_atlas_coords(Vector2i(col, row))
			if existing_piece != -1:
				piece_layer.erase_cell(Vector2i(col, row))
				piece_layer.set_cell(Vector2i(col, row + 1), existing_piece, existing_color)

func update_score(score_increment: int) -> void:
	score_data.text = str(score_data.text.to_int() + score_increment)

func check_game_over() -> void:
	for x in range(0, 10):
		if piece_layer.get_cell_source_id(Vector2i(x, 6)) != -1:
			danger = true
			if danger == true and danger_playing == false:
				danger_playing = true
				bgm_interactive["parameters/switch_to_clip"] = "Tetrifection Alt"

		if piece_layer.get_cell_source_id(Vector2i(x, 2)) != -1:
			end_score_data.text = score_data.text
			ui_overlay.show()
			ui_pause.hide()
			ui_game_over.show()
			button_new_game.grab_focus()
			get_tree().paused = true

func _on_button_new_game_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_button_quit_pressed() -> void:
	get_tree().quit()

func _on_drop_timer_timeout() -> void:
	drop_complete = false
	drop_piece()
