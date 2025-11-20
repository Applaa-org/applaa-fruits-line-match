extends Control

@onready var title_label = $Title
@onready var instructions_label = $Instructions
@onready var start_button = $StartButton

func _ready():
	start_button.connect("pressed", Callable(self, "_on_start_button_pressed"))
	title_label.text = "Fruits Line Match"
	instructions_label.text = """A vibrant 2D match-3 puzzle game!

How to Play:
- Click to select a tile
- Click an adjacent tile to swap
- Create lines of 3 or more fruits
- Earn points and power-ups
- Reach 5000 points to win!

Controls:
- Mouse: Click to select and swap
- WASD: Navigate and select
- Space: Confirm selection/swap

Good luck!"""

func _on_start_button_pressed():
	get_tree().change_scene_to_file("res://scenes/Main.tscn")