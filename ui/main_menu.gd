extends Control

@onready var seed_input: LineEdit = $VBoxContainer/SeedInput
@onready var random_button: Button = $VBoxContainer/RandomButton
@onready var seed_button: Button = $VBoxContainer/SeedButton

func _ready() -> void:
	random_button.pressed.connect(_on_random_button_pressed)
	seed_button.pressed.connect(_on_seed_button_pressed)

func _on_random_button_pressed() -> void:
	randomize()
	GameSettings.current_seed = randi()
	GameSettings.use_custom_seed = true
	get_tree().change_scene_to_file("res://game_world/game_world.tscn")

func _on_seed_button_pressed() -> void:
	var seed_text = seed_input.text.strip_edges()
	if seed_text != "":
		if seed_text.is_valid_int():
			GameSettings.current_seed = seed_text.to_int()
		else:
			GameSettings.current_seed = seed_text.hash()
	else:
		randomize()
		GameSettings.current_seed = randi()
	GameSettings.use_custom_seed = true
	get_tree().change_scene_to_file("res://game_world/game_world.tscn")
