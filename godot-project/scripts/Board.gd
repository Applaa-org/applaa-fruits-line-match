extends Node2D

# Board constants
const BOARD_WIDTH = 8
const BOARD_HEIGHT = 8
const TILE_SIZE = 64
const TILE_TYPES = ["apple", "banana", "orange", "grape", "mango", "cherry"]
const COLORS = [Color("#ff6b6b"), Color("#ffd93d"), Color("#ff8c42"), Color("#6bcf7f"), Color("#4ecdc4"), Color("#45b7d1")]

# Board state
var board = []
var selected_tile = null
var is_animating = false

# Signals
signal tile_swapped
signal match_found(matches)
signal board_updated

# Particle system
@onready var particle_system = $CPUParticles2D

func _ready():
	initialize_board()
	particle_system.emitting = false

func initialize_board():
	board = []
	for y in range(BOARD_HEIGHT):
		board.append([])
		for x in range(BOARD_WIDTH):
			board[y].append(randi() % TILE_TYPES.size())
	
	# Ensure no initial matches
	while find_matches().size() > 0:
		shuffle_board()

func shuffle_board():
	for y in range(BOARD_HEIGHT):
		for x in range(BOARD_WIDTH):
			board[y][x] = randi() % TILE_TYPES.size()

func get_tile_at(pos: Vector2i) -> int:
	if pos.x >= 0 and pos.x < BOARD_WIDTH and pos.y >= 0 and pos.y < BOARD_HEIGHT:
		return board[pos.y][pos.x]
	return -1

func set_tile_at(pos: Vector2i, type: int):
	if pos.x >= 0 and pos.x < BOARD_WIDTH and pos.y >= 0 and pos.y < BOARD_HEIGHT:
		board[pos.y][pos.x] = type

func swap_tiles(pos1: Vector2i, pos2: Vector2i):
	var temp = get_tile_at(pos1)
	set_tile_at(pos1, get_tile_at(pos2))
	set_tile_at(pos2, temp)
	emit_signal("tile_swapped")

func is_adjacent(pos1: Vector2i, pos2: Vector2i) -> bool:
	var dx = abs(pos1.x - pos2.x)
	var dy = abs(pos1.y - pos2.y)
	return (dx == 1 and dy == 0) or (dx == 0 and dy == 1)

func find_matches() -> Array:
	var matches = []
	
	# Horizontal matches
	for y in range(BOARD_HEIGHT):
		var count = 1
		for x in range(1, BOARD_WIDTH):
			if get_tile_at(Vector2i(x, y)) == get_tile_at(Vector2i(x-1, y)):
				count += 1
			else:
				if count >= 3:
					for i in range(x - count, x):
						matches.append(Vector2i(i, y))
				count = 1
		if count >= 3:
			for i in range(BOARD_WIDTH - count, BOARD_WIDTH):
				matches.append(Vector2i(i, y))
	
	# Vertical matches
	for x in range(BOARD_WIDTH):
		var count = 1
		for y in range(1, BOARD_HEIGHT):
			if get_tile_at(Vector2i(x, y)) == get_tile_at(Vector2i(x, y-1)):
				count += 1
			else:
				if count >= 3:
					for i in range(y - count, y):
						matches.append(Vector2i(x, i))
				count = 1
		if count >= 3:
			for i in range(BOARD_HEIGHT - count, BOARD_HEIGHT):
				matches.append(Vector2i(x, i))
	
	return matches

func remove_matches(matches: Array):
	for match_pos in matches:
		create_particles(match_pos)
		set_tile_at(match_pos, -1)
	emit_signal("match_found", matches)

func create_particles(pos: Vector2i):
	particle_system.global_position = Vector2(pos.x * TILE_SIZE + TILE_SIZE/2, pos.y * TILE_SIZE + TILE_SIZE/2)
	particle_system.color = COLORS[get_tile_at(pos)]
	particle_system.emitting = true

func drop_tiles():
	for x in range(BOARD_WIDTH):
		var write_pos = BOARD_HEIGHT - 1
		for y in range(BOARD_HEIGHT - 1, -1, -1):
			if get_tile_at(Vector2i(x, y)) != -1:
				set_tile_at(Vector2i(x, write_pos), get_tile_at(Vector2i(x, y)))
				if write_pos != y:
					set_tile_at(Vector2i(x, y), -1)
				write_pos -= 1

func fill_empty_spaces():
	for x in range(BOARD_WIDTH):
		for y in range(BOARD_HEIGHT):
			if get_tile_at(Vector2i(x, y)) == -1:
				set_tile_at(Vector2i(x, y), randi() % TILE_TYPES.size())

func process_matches() -> bool:
	var matches = find_matches()
	if matches.size() > 0:
		remove_matches(matches)
		drop_tiles()
		fill_empty_spaces()
		emit_signal("board_updated")
		return true
	return false

func _draw():
	for y in range(BOARD_HEIGHT):
		for x in range(BOARD_WIDTH):
			var tile_type = get_tile_at(Vector2i(x, y))
			if tile_type != -1:
				var rect = Rect2(x * TILE_SIZE, y * TILE_SIZE, TILE_SIZE, TILE_SIZE)
				draw_rect(rect, COLORS[tile_type])
				# Draw fruit emoji or simple shape
				var center = Vector2(x * TILE_SIZE + TILE_SIZE/2, y * TILE_SIZE + TILE_SIZE/2)
				match TILE_TYPES[tile_type]:
					"apple":
						draw_circle(center, TILE_SIZE/3, Color.RED)
					"banana":
						draw_circle(center, TILE_SIZE/3, Color.YELLOW)
					"orange":
						draw_circle(center, TILE_SIZE/3, Color.ORANGE)
					"grape":
						draw_circle(center, TILE_SIZE/3, Color.PURPLE)
					"mango":
						draw_circle(center, TILE_SIZE/3, Color("#FFD700"))
					"cherry":
						draw_circle(center, TILE_SIZE/3, Color("#DC143C"))
	
	# Highlight selected tile
	if selected_tile:
		var rect = Rect2(selected_tile.x * TILE_SIZE - 2, selected_tile.y * TILE_SIZE - 2, TILE_SIZE + 4, TILE_SIZE + 4)
		draw_rect(rect, Color.YELLOW, false, 3)

func _process(delta):
	queue_redraw()