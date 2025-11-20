extends Node2D

# Game constants
const SCORE_TARGET = 5000
const MOVES_LIMIT = 30
const POINTS_PER_MATCH = 100

# Game state
var score = 0
var moves_left = MOVES_LIMIT
var game_started = false

# UI elements
@onready var score_label = $UI/ScoreLabel
@onready var moves_label = $UI/MovesLabel
@onready var victory_screen = $UI/VictoryScreen
@onready var defeat_screen = $UI/DefeatScreen
@onready var board = $Board

func _ready():
	update_ui()
	board.connect("tile_swapped", Callable(self, "_on_tile_swapped"))
	board.connect("match_found", Callable(self, "_on_match_found"))
	board.connect("board_updated", Callable(self, "_on_board_updated"))
	victory_screen.hide()
	defeat_screen.hide()

func _input(event):
	if not game_started:
		return
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos = get_viewport().get_mouse_position()
		var grid_pos = Vector2i(floor(mouse_pos.x / 64), floor(mouse_pos.y / 64))
		handle_tile_click(grid_pos)
	
	# Keyboard controls
	if event is InputEventKey and event.pressed:
		if board.selected_tile == null:
			var new_pos = board.selected_tile if board.selected_tile else Vector2i(0, 0)
			match event.keycode:
				KEY_W, KEY_UP:
					new_pos.y = max(0, new_pos.y - 1)
				KEY_S, KEY_DOWN:
					new_pos.y = min(7, new_pos.y + 1)
				KEY_A, KEY_LEFT:
					new_pos.x = max(0, new_pos.x - 1)
				KEY_D, KEY_RIGHT:
					new_pos.x = min(7, new_pos.x + 1)
				KEY_SPACE:
					board.selected_tile = new_pos
					return
			board.selected_tile = new_pos
		else:
			var new_pos = board.selected_tile
			match event.keycode:
				KEY_W, KEY_UP:
					new_pos.y = max(0, new_pos.y - 1)
				KEY_S, KEY_DOWN:
					new_pos.y = min(7, new_pos.y + 1)
				KEY_A, KEY_LEFT:
					new_pos.x = max(0, new_pos.x - 1)
				KEY_D, KEY_RIGHT:
					new_pos.x = min(7, new_pos.x + 1)
				KEY_SPACE:
					handle_tile_click(new_pos)
					return
			if board.is_adjacent(board.selected_tile, new_pos):
				handle_tile_click(new_pos)

func handle_tile_click(grid_pos: Vector2i):
	if board.selected_tile == null:
		board.selected_tile = grid_pos
	else:
		if board.is_adjacent(board.selected_tile, grid_pos):
			board.swap_tiles(board.selected_tile, grid_pos)
			moves_left -= 1
			update_ui()
			
			if not board.process_matches():
				# No match, swap back after delay
				await get_tree().create_timer(0.2).timeout
				board.swap_tiles(grid_pos, board.selected_tile)
			else:
				# Check for cascading matches
				while board.process_matches():
					await get_tree().create_timer(0.3).timeout
			
			check_game_end()
		board.selected_tile = null

func _on_tile_swapped():
	pass  # Handle any post-swap logic

func _on_match_found(matches):
	score += matches.size() * POINTS_PER_MATCH
	update_ui()

func _on_board_updated():
	pass  # Handle board updates

func update_ui():
	score_label.text = "Score: " + str(score)
	moves_label.text = "Moves: " + str(moves_left)

func check_game_end():
	if score >= SCORE_TARGET:
		show_victory()
	elif moves_left <= 0:
		show_defeat()

func show_victory():
	victory_screen.show()

func show_defeat():
	defeat_screen.show()

func _on_restart_button_pressed():
	get_tree().reload_current_scene()

func _on_start_button_pressed():
	game_started = true
	# Hide start screen and show game