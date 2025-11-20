extends Node2D

@onready var board = $Board
@onready var ui = $UI
@onready var score_label = $UI/ScoreLabel
@onready var moves_label = $UI/MovesLabel
@onready var victory_screen = $UI/VictoryScreen
@onready var defeat_screen = $UI/DefeatScreen

var score = 0
var moves_left = 30
var score_target = 5000

func _ready():
	board.connect("tile_matched", Callable(self, "_on_tile_matched"))
	board.connect("move_made", Callable(self, "_on_move_made"))
	board.connect("game_won", Callable(self, "_on_game_won"))
	board.connect("game_lost", Callable(self, "_on_game_lost"))
	update_ui()

func _on_tile_matched(points):
	score += points
	update_ui()
	if score >= score_target:
		_on_game_won()

func _on_move_made():
	moves_left -= 1
	update_ui()
	if moves_left <= 0:
		_on_game_lost()

func _on_game_won():
	victory_screen.visible = true
	board.set_process(false)

func _on_game_lost():
	defeat_screen.visible = true
	board.set_process(false)

func update_ui():
	score_label.text = "Score: " + str(score)
	moves_label.text = "Moves: " + str(moves_left)

func _on_restart_pressed():
	get_tree().reload_current_scene()