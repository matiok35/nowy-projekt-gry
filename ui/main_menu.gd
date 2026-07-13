extends Control

@onready var background: ColorRect = $ColorRect
@onready var vbox: VBoxContainer = $VBoxContainer
@onready var title_label: Label = $VBoxContainer/Label
@onready var seed_input: LineEdit = $VBoxContainer/SeedInput
@onready var random_button: Button = $VBoxContainer/RandomButton
@onready var seed_button: Button = $VBoxContainer/SeedButton

# --- PALETA "DARK FANTASY" (spójna z hud.gd) -------------------------------
const DF_BG: Color = Color(0.055, 0.05, 0.06, 1.0)
const DF_BG_LIGHT: Color = Color(0.12, 0.1, 0.09, 0.97)
const DF_GOLD: Color = Color(0.62, 0.49, 0.24, 1.0)
const DF_GOLD_BRIGHT: Color = Color(0.85, 0.7, 0.36, 1.0)
const DF_GOLD_TEXT: Color = Color(0.86, 0.72, 0.4, 1.0)
const DF_TEXT: Color = Color(0.85, 0.8, 0.7, 1.0)

func _ready() -> void:
	random_button.pressed.connect(_on_random_button_pressed)
	seed_button.pressed.connect(_on_seed_button_pressed)
	_apply_dark_fantasy_style()

func _apply_dark_fantasy_style() -> void:
	# Tlo - gleboka, prawie czarna czern zamiast plaskiego szarego fioletu
	background.color = DF_BG

	vbox.add_theme_constant_override("separation", 18)

	# Tytul - postarzale zloto z lekka "poswiata"
	title_label.add_theme_font_size_override("font_size", 30)
	title_label.add_theme_color_override("font_color", DF_GOLD_TEXT)
	title_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	title_label.add_theme_constant_override("shadow_offset_x", 0)
	title_label.add_theme_constant_override("shadow_offset_y", 2)

	# Pole wpisywania seeda
	var input_style = StyleBoxFlat.new()
	input_style.bg_color = DF_BG_LIGHT
	input_style.set_border_width_all(2)
	input_style.border_color = DF_GOLD
	input_style.set_corner_radius_all(6)
	input_style.set_content_margin_all(8)

	var input_focus = input_style.duplicate() as StyleBoxFlat
	input_focus.border_color = DF_GOLD_BRIGHT

	seed_input.add_theme_stylebox_override("normal", input_style)
	seed_input.add_theme_stylebox_override("focus", input_focus)
	seed_input.add_theme_color_override("font_color", DF_TEXT)
	seed_input.add_theme_color_override("font_placeholder_color", Color(DF_TEXT.r, DF_TEXT.g, DF_TEXT.b, 0.4))
	seed_input.add_theme_color_override("caret_color", DF_GOLD_BRIGHT)

	# Przyciski
	_style_button(random_button, false)
	_style_button(seed_button, true)

func _style_button(btn: Button, accent: bool) -> void:
	btn.custom_minimum_size = Vector2(0, 44)

	var normal = StyleBoxFlat.new()
	normal.bg_color = Color(0.3, 0.06, 0.07, 0.95) if accent else Color(0.15, 0.13, 0.11, 0.95)
	normal.set_border_width_all(2)
	normal.border_color = DF_GOLD
	normal.set_corner_radius_all(6)
	normal.set_content_margin_all(10)
	normal.shadow_color = Color(0, 0, 0, 0.5)
	normal.shadow_size = 3

	var hover = normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.42, 0.09, 0.1, 0.95) if accent else Color(0.22, 0.19, 0.15, 0.95)
	hover.border_color = DF_GOLD_BRIGHT

	var pressed = hover.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.22, 0.04, 0.05, 0.95) if accent else Color(0.1, 0.09, 0.07, 0.95)

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_color_override("font_color", DF_TEXT)
	btn.add_theme_color_override("font_hover_color", DF_GOLD_TEXT)
	btn.add_theme_font_size_override("font_size", 16)

func _on_random_button_pressed() -> void:
	randomize()
	GameSettings.current_seed = randi()
	GameSettings.use_custom_seed = true
	EconomyManager.reset()
	get_tree().change_scene_to_file("res://scenes/game_world.tscn")

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
	EconomyManager.reset()
	get_tree().change_scene_to_file("res://scenes/game_world.tscn")
