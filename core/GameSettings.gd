extends Node

var current_seed: int = 0
var use_custom_seed: bool = false

func _ready():
	var emoji_font = load("res://assets/fonts/NotoColorEmoji.ttf")
	if emoji_font:
		ThemeDB.fallback_font = emoji_font
