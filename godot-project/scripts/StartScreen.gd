extends Node2D

@onready var start_button = $StartButton

func _ready():
	start_button.connect("pressed", Callable(self, "_on_start_pressed"))

func _on_start_pressed():
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _input(event):
	if event.is_action_pressed("ui_accept"):  # Spacebar
		_on_start_pressed()