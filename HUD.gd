extends Control
# HUD.gd (Podpięty pod węzeł CanvasLayer/UI)

@onready var resources_label = $Panel/ResourcesLabel
@onready var turn_button = $TurnButton
@onready var menu_budowania = $MenuBudowania

# Szukamy przycisków wewnątrz kontenera (z wersji rozbudowanej)
@onready var build_chata = $MenuBudowania/VBoxContainer/BuildChata
@onready var build_iron = $MenuBudowania/VBoxContainer/BuildKopalniaZelaza
@onready var build_coal = $MenuBudowania/VBoxContainer/BuildKopalniaWegla

# Świat gry przekaże nam tablicę postawionych budynków przy końcu tury
var world_ref: Node2D 
var active_tile_pos: Vector2 = Vector2.ZERO

func _ready():
	world_ref = get_tree().current_scene
	EconomyManager.economy_updated.connect(_on_economy_updated)
	
	# Podpięcie logiki
	turn_button.pressed.connect(_on_turn_pressed)
	build_chata.pressed.connect(func(): execute_build("Chata Drwala"))
	build_iron.pressed.connect(func(): execute_build("Kopalnia Żelaza"))
	build_coal.pressed.connect(func(): execute_build("Kopalnia Węgla"))
	
	# STYLIZOWANIE CAŁEGO INTERFEJSU (FANCY & COLORFUL)
	style_main_hud_elements()
	style_context_popup()
	style_individual_buttons()
	
	EconomyManager.notify_change()

func show_context_menu(mouse_pos: Vector2, tile_pos: Vector2, tile_type: String, has_building: bool) -> void:
	active_tile_pos = tile_pos
	if has_building:
		menu_budowania.visible = false
		return
		
	menu_budowania.visible = true
	
	# Zabezpieczenie: Jeśli menu wychodzi poza prawą/dolną krawędź okna, przesuwamy je
	var screen_size = get_viewport_rect().size
	var menu_size = menu_budowania.size
	
	var final_x = mouse_pos.x + 10
	var final_y = mouse_pos.y + 10
	
	if final_x + menu_size.x > screen_size.x:
		final_x = mouse_pos.x - menu_size.x - 10
	if final_y + menu_size.y > screen_size.y:
		final_y = mouse_pos.y - menu_size.y - 10
		
	menu_budowania.global_position = Vector2(final_x, final_y)
	
	# Sprawdzanie dostępności i automatyczne kolorowanie/wyszarzanie
	update_button_state(build_chata, "Chata Drwala", tile_type)
	update_button_state(build_iron, "Kopalnia Żelaza", tile_type)
	update_button_state(build_coal, "Kopalnia Węgla", tile_type)

func update_button_state(btn: Button, b_name: String, tile_type: String):
	var can_place = EconomyManager.can_afford_and_place(b_name, tile_type)
	btn.disabled = not can_place
	# Jeśli przycisk jest wyłączony, mocno go przyciemniamy (efekt wyszarzenia)
	btn.modulate.a = 1.0 if can_place else 0.35

func execute_build(building_name: String) -> void:
	world_ref.build_on_tile(active_tile_pos, building_name)
	menu_budowania.visible = false

func _on_economy_updated(balances: Dictionary, turn: int, selected_build: String):
	resources_label.text = "🌟 TURA: %d   |   🪙 ZŁOTO: %d   |   🪵 DREWNO: %d   |   ⛓️ ŻELAZO: %d   |   🌋 WĘGIEL: %d" % [
		turn, balances["Złoto"], balances["Drewno"], balances["Żelazo"], balances["Węgiel"]
	]
	# Utrzymano logikę z brancha o pokazywaniu wybranego budynku (jeśli mechanika wciąż tego używa)
	if selected_build != "":
		resources_label.text += " | Wybrano: " + selected_build

func _on_turn_pressed():
	menu_budowania.visible = false
	var buildings = world_ref.get_active_buildings_list()
	EconomyManager.next_turn(buildings)

# ==============================================================================
# --- WYPASIONE AUTOMATYCZNE OSTYLOWANIE GRAFICZNE (THEMING SYSTEM Z KODU) ---
# ==============================================================================

func style_main_hud_elements():
	# 1. Górny pasek zasobów (Nowoczesne szklane tło z neonowym paskiem na dole)
	var top_panel = $Panel
	var style_top = StyleBoxFlat.new()
	style_top.bg_color = Color(0.07, 0.08, 0.1, 0.85) # Głęboki cyber-granat
	style_top.border_width_bottom = 3
	style_top.border_color = Color(0.0, 0.75, 1.0) # Neonowy błękitny akcent
	style_top.content_margin_left = 15
	style_top.content_margin_top = 10
	top_panel.add_theme_stylebox_override("panel", style_top)
	
	# 2. Przycisk "Następna tura" (Soczysty, fioletowo-różowy styl gamingowy)
	var style_turn = StyleBoxFlat.new()
	style_turn.bg_color = Color(0.5, 0.1, 0.7) # Magnat/Fiolet
	style_turn.set_corner_radius_all(12)
	style_turn.border_width_bottom = 4
	style_turn.border_color = Color(0.35, 0.05, 0.5) # Cień pod przyciskiem
	
	var style_turn_hover = style_turn.duplicate() as StyleBoxFlat
	style_turn_hover.bg_color = Color(0.65, 0.15, 0.85) # Rozświetlenie po najechaniu
	
	turn_button.add_theme_stylebox_override("normal", style_turn)
	turn_button.add_theme_stylebox_override("hover", style_turn_hover)
	turn_button.add_theme_color_override("font_color", Color.WHITE)

func style_context_popup():
	# Eleganckie, półprzezroczyste, ciemne menu kołowe/kontekstowe
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.05, 0.05, 0.07, 0.92) 
	style_box.border_width_left = 2
	style_box.border_width_top = 2
	style_box.border_width_right = 2
	style_box.border_width_bottom = 2
	style_box.border_color = Color(0.2, 0.6, 1.0, 0.5) # Świecąca ramka
	style_box.set_corner_radius_all(14)
	style_box.content_margin_left = 10
	style_box.content_margin_top = 10
	style_box.content_margin_right = 10
	style_box.content_margin_bottom = 10
	menu_budowania.add_theme_stylebox_override("panel", style_box)
	
	# Dodajemy odstęp między przyciskami w liście menu
	$MenuBudowania/VBoxContainer.add_theme_constant_override("separation", 6)

func style_individual_buttons():
	# Tworzymy unikalne style dla każdego z 3 przycisków budowania
	style_single_button(build_chata, Color(0.15, 0.5, 0.15), Color(0.2, 0.7, 0.2), "🪵 Buduj Chatę Drwala")
	style_single_button(build_iron, Color(0.2, 0.35, 0.5), Color(0.3, 0.5, 0.75), "⛓️ Kopalnia Żelaza")
	style_single_button(build_coal, Color(0.7, 0.3, 0.0), Color(0.9, 0.45, 0.1), "🌋 Kopalnia Węgla")

func style_single_button(btn: Button, base_color: Color, hover_color: Color, new_text: String):
	btn.text = new_text
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.custom_minimum_size.y = 38 # Wyższe, wygodniejsze przyciski
	
	var normal = StyleBoxFlat.new()
	normal.bg_color = base_color
	normal.set_corner_radius_all(6)
	normal.content_margin_left = 12
	normal.content_margin_right = 12
	
	var hover = StyleBoxFlat.new()
	hover.bg_color = hover_color
	hover.set_corner_radius_all(6)
	hover.content_margin_left = 12
	hover.content_margin_right = 12
	
	var disabled = StyleBoxFlat.new()
	disabled.bg_color = Color(0.15, 0.15, 0.15) # Ciemnoszary dla zablokowanego
	disabled.set_corner_radius_all(6)
	disabled.content_margin_left = 12
	
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("disabled", disabled)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_disabled_color", Color(0.5, 0.5, 0.5))
