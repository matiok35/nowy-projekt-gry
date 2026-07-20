extends Node

var current_seed: int = 0
var use_custom_seed: bool = false

var skip_turn_button_delay: bool = false

var debug_mode: bool = false

func _ready():
	var emoji_font = load("res://assets/fonts/NotoColorEmoji.ttf")
	if emoji_font:
		var default_font = ThemeDB.fallback_font
		if default_font:
			var fallbacks = default_font.fallbacks
			if not emoji_font in fallbacks:
				fallbacks.append(emoji_font)
			default_font.fallbacks = fallbacks
