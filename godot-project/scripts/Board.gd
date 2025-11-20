extends Node2D

signal tile_matched(points)
signal move_made
signal game_won
signal game_lost

const BOARD_WIDTH = 8
const BOARD_HEIGHT = 8
const TILE_SIZE = 50
const TILE_TYPES = ["apple", "banana", "orange", "grape", "mango", "cherry"]
const COLORS = [Color("#ff6b6b"), Color("#ffd93d"), Color("#ff8c42"), Color("#6bcf7f"), Color("#4ecdc4"), Color("#45b7d1")]

var board = []
var selected_tile = null
var particles = []

func _ready():
	initialize_board()
	$Particles.emitting = false

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var pos = get_local_mouse_position()
		var grid_x = floor((pos.x + BOARD_WIDTH * TILE_SIZE / 2) / TILE_SIZE)
		var grid_y = floor((pos.y + BOARD_HEIGHT * TILE_SIZE / 2) / TILE_SIZE)
		
		if grid_x >= 0 and grid_x < BOARD_WIDTH and grid_y >= 0 and grid_y < BOARD_HEIGHT:
			handle_tile_click(grid_x, grid_y)

func initialize_board():
	board = []
	for y in range(BOARD_HEIGHT):
		board.append([])
		for x in range(BOARD_WIDTH):
			var tile_type = randi() % TILE_TYPES.size()
			board[y].append(tile_type)
			create_tile_sprite(x, y, tile_type)
	
	# Ensure no initial matches
	while find_matches().size() > 0:
		shuffle_board()

func create_tile_sprite(x, y, tile_type):
	var sprite = Sprite2D.new()
	sprite.texture = load("res://assets/sprites/" + TILE_TYPES[tile_type] + ".png")
	sprite.position = Vector2(x * TILE_SIZE - BOARD_WIDTH * TILE_SIZE / 2 + TILE_SIZE / 2, 
							 y * TILE_SIZE - BOARD_HEIGHT * TILE_SIZE / 2 + TILE_SIZE / 2)
	add_child(sprite)

func handle_tile_click(grid_x, grid_y):
	if selected_tile == null:
		selected_tile = Vector2(grid_x, grid_y)
		highlight_tile(grid_x, grid_y, true)
	else:
		if abs(selected_tile.x - grid_x) + abs(selected_tile.y - grid_y) == 1:
			swap_tiles(selected_tile, Vector2(grid_x, grid_y))
			emit_signal("move_made")
			if not check_for_matches():
				swap_tiles(selected_tile, Vector2(grid_x, grid_y))  # Swap back if no match
		highlight_tile(selected_tile.x, selected_tile.y, false)
		selected_tile = null

func swap_tiles(pos1, pos2):
	var temp = board[pos1.y][pos1.x]
	board[pos1.y][pos1.x] = board[pos2.y][pos2.x]
	board[pos2.y][pos2.x] = temp
	update_tile_positions()

func check_for_matches():
	var matches = find_matches()
	if matches.size() > 0:
		remove_matches(matches)
		drop_tiles()
		fill_empty_spaces()
		emit_signal("tile_matched", matches.size() * 100)
		return true
	return false

func find_matches():
	var matches = []
	# Horizontal matches
	for y in range(BOARD_HEIGHT):
		var count = 1
		for x in range(1, BOARD_WIDTH):
			if board[y][x] == board[y][x-1]:
				count += 1
			else:
				if count >= 3:
					for i in range(x-count, x):
						matches.append(Vector2(i, y))
				count = 1
		if count >= 3:
			for i in range(BOARD_WIDTH-count, BOARD_WIDTH):
				matches.append(Vector2(i, y))
	
	# Vertical matches
	for x in range(BOARD_WIDTH):
		var count = 1
		for y in range(1, BOARD_HEIGHT):
			if board[y][x] == board[y-1][x]:
				count += 1
			else:
				if count >= 3:
					for i in range(y-count, y):
						matches.append(Vector2(x, i))
				count = 1
		if count >= 3:
			for i in range(BOARD_HEIGHT-count, BOARD_HEIGHT):
				matches.append(Vector2(x, i))
	
	return matches

func remove_matches(matches):
	for match in matches:
		board[match.y][match.x] = -1
		create_particle_effect(match.x, match.y)
	update_tile_positions()

func create_particle_effect(x, y):
	var particle = CPUParticles2D.new()
	particle.emitting = true
	particle.amount = 10
	particle.lifetime = 0.5
	particle.position = Vector2(x * TILE_SIZE - BOARD_WIDTH * TILE_SIZE / 2 + TILE_SIZE / 2, 
							   y * TILE_SIZE - BOARD_HEIGHT * TILE_SIZE / 2 + TILE_SIZE / 2)
	particle.color = COLORS[board[y][x]]
	add_child(particle)
	particles.append(particle)

func drop_tiles():
	for x in range(BOARD_WIDTH):
		var write_pos = BOARD_HEIGHT - 1
		for y in range(BOARD_HEIGHT - 1, -1, -1):
			if board[y][x] != -1:
				board[write_pos][x] = board[y][x]
				if write_pos != y:
					board[y][x] = -1
				write_pos -= 1

func fill_empty_spaces():
	for x in range(BOARD_WIDTH):
		for y in range(BOARD_HEIGHT):
			if board[y][x] == -1:
				board[y][x] = randi() % TILE_TYPES.size()

func update_tile_positions():
	for child in get_children():
		if child is Sprite2D:
			child.queue_free()
	
	for y in range(BOARD_HEIGHT):
		for x in range(BOARD_WIDTH):
			if board[y][x] != -1:
				create_tile_sprite(x, y, board[y][x])

func highlight_tile(x, y, highlight):
	var sprite = get_child(get_child_count() - 1)  # Assuming last child is the sprite
	if highlight:
		sprite.modulate = Color(2, 2, 2)  # Brighten
	else:
		sprite.modulate = Color(1, 1, 1)  # Normal

func shuffle_board():
	for y in range(BOARD_HEIGHT):
		for x in range(BOARD_WIDTH):
			board[y][x] = randi() % TILE_TYPES.size()
	update_tile_positions()