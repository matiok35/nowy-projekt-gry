extends Control
# HUD.gd (Podpięty pod węzeł CanvasLayer/UI)

@onready var resources_label = $Panel/ResourcesLabel
@onready var turn_button = $TurnButton
@onready var menu_budowania = $MenuBudowania

# Przyciski budynków wewnątrz VBoxContainer
@onready var build_chata = $MenuBudowania/VBoxContainer/BuildChata
@onready var build_iron = $MenuBudowania/VBoxContainer/BuildKopalniaZelaza
@onready var build_coal = $MenuBudowania/VBoxContainer/BuildKopalniaWegla

# --- SYSTEM DYNAMICZNYCH ELEMENTÓW ---
var build_farma: Button # Nowy przycisk farmy tworzony proceduralnie
var info_label: Label   # Etykieta wyświetlająca parametry pola nad przyciskami
var menu_zalozenia_miasta: PopupPanel 
var zaloz_miasto_button: Button
var kup_pole_button: Button 

var world_ref: Node2D 
var active_tile_pos: Vector2 = Vector2.ZERO

func _ready():
	world_ref = get_tree().current_scene
	if world_ref == null or not world_ref.has_method("build_on_tile"):
		world_ref = get_tree().root.find_child("GameWorld", true, false)
		
	EconomyManager.economy_updated.connect(_on_economy_updated)
	
	# Podpięcie logiki przycisków głównych
	turn_button.pressed.connect(_on_turn_pressed)
	build_chata.pressed.connect(func(): execute_build("Chata Drwala"))
	build_iron.pressed.connect(func(): execute_build("Kopalnia Żelaza"))
	build_coal.pressed.connect(func(): execute_build("Kopalnia Węgla"))
	
	setup_custom_popups()
	style_main_hud_elements()
	style_context_popup()
	style_individual_buttons()
	
	EconomyManager.notify_change()

func setup_custom_popups():
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.05, 0.05, 0.07, 0.95) 
	style_box.set_border_width_all(2) 
	style_box.border_color = Color(0.0, 0.75, 1.0, 0.8) 
	style_box.set_corner_radius_all(10)
	style_box.set_content_margin_all(8)

	# 1. Nagłówek informacyjny w menu budowania (Żyzność / Wielkość złoża)
	var vbox = $MenuBudowania/VBoxContainer
	info_label = Label.new()
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.add_theme_color_override("font_color", Color(0.0, 0.9, 1.0))
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(info_label)
	vbox.move_child(info_label, 0) # Zawsze na samej górze menu

	# 2. Przycisk budowy farmy
	build_farma = Button.new()
	vbox.add_child(build_farma)
	build_farma.pressed.connect(func(): execute_build("Farma"))
	style_single_button(build_farma, Color(0.45, 0.4, 0.15), Color(0.65, 0.55, 0.2), "🌾 Buduj Farmę")

	# 3. Menu zakładania miasta
	menu_zalozenia_miasta = PopupPanel.new()
	menu_zalozenia_miasta.visible = false
	menu_zalozenia_miasta.add_theme_stylebox_override("panel", style_box)
	
	var margin_container = MarginContainer.new()
	margin_container.add_theme_constant_override("margin_left", 4)
	margin_container.add_theme_constant_override("margin_right", 4)
	margin_container.add_theme_constant_override("margin_top", 4)
	margin_container.add_theme_constant_override("margin_bottom", 4)
	
	zaloz_miasto_button = Button.new()
	zaloz_miasto_button.text = "👑 Załóż Miasto tutaj"
	zaloz_miasto_button.custom_minimum_size = Vector2(160, 35)
	
	margin_container.add_child(zaloz_miasto_button)
	menu_zalozenia_miasta.add_child(margin_container)
	add_child(menu_zalozenia_miasta)
	
	zaloz_miasto_button.pressed.connect(func():
		if world_ref and world_ref.has_method("create_city_at"):
			world_ref.create_city_at(active_tile_pos)
		hide_all_menus()
	)

	# 4. Dynamiczny przycisk zakupu pola
	kup_pole_button = Button.new()
	kup_pole_button.text = "🪙 Kup to pole (50 złota)"
	kup_pole_button.custom_minimum_size = Vector2(180, 35)
	
	var style_buy = StyleBoxFlat.new()
	style_buy.bg_color = Color(0.15, 0.35, 0.4)
	style_buy.set_corner_radius_all(6)
	style_buy.set_content_margin_all(12)
	kup_pole_button.add_theme_stylebox_override("normal", style_buy)
	
	vbox.add_child(kup_pole_button)
	vbox.move_child(kup_pole_button, 1) # Pod napisem informacyjnym
	
	kup_pole_button.pressed.connect(func():
		if world_ref and world_ref.has_method("buy_tile"):
			world_ref.buy_tile(active_tile_pos)
		hide_all_menus()
	)

# --- SPERSONALIZOWANE MENU KONTEKSTOWE ---
func show_context_menu(mouse_pos: Vector2, tile_pos: Vector2, tile_type: String, has_building: bool, is_owned: bool, borders_owned: bool, deposit_size: String = "", fertility: float = 0.0) -> void:
	hide_all_menus()
	active_tile_pos = tile_pos
	
	menu_budowania.visible = true
	_reposition_menu(menu_budowania, mouse_pos)
	
	# Aktualizacja tekstu informacyjnego nad przyciskami
	if tile_type == "Trawa":
		info_label.text = "🌱 Typ: Trawa\n✨ Żyzność pola: %d%%" % [int(fertility * 100)]
	else:
		info_label.text = "⛰️ Typ: Złoże %s\n📦 Wielkość: %s" % [tile_type, deposit_size]

	# Zarządzanie przyciskiem kupna pola
	if is_owned or has_building:
		kup_pole_button.visible = false
	else:
		kup_pole_button.visible = true
		var can_afford = EconomyManager.resources["Złoto"] >= 50
		var can_buy = can_afford and borders_owned
		kup_pole_button.disabled = not can_buy
		kup_pole_button.modulate.a = 1.0 if can_buy else 0.35

	# Zarządzanie przyciskami budynków
	var show_buildings = is_owned and not has_building
	build_chata.visible = show_buildings
	build_iron.visible = show_buildings
	build_coal.visible = show_buildings
	build_farma.visible = show_buildings
	
	if show_buildings:
		update_button_state(build_chata, "Chata Drwala", tile_type)
		update_button_state(build_iron, "Kopalnia Żelaza", tile_type)
		update_button_state(build_coal, "Kopalnia Węgla", tile_type)
		update_button_state(build_farma, "Farma", tile_type)

func show_city_creation_menu(_screen_pos: Vector2, tile_pos: Vector2) -> void:
	hide_all_menus()
	active_tile_pos = tile_pos
	var current_mouse_pos = get_viewport().get_mouse_position()
	var popup_rect = Rect2(current_mouse_pos + Vector2(10, 10), Vector2(170, 45))
	menu_zalozenia_miasta.popup(popup_rect)

func hide_all_menus():
	menu_budowania.visible = false
	if menu_zalozenia_miasta: menu_zalozenia_miasta.visible = false

func any_menu_visible() -> bool:
	return menu_budowania.visible or (menu_zalozenia_miasta and menu_zalozenia_miasta.visible)

func _reposition_menu(menu: Control, base_pos: Vector2):
	menu.reset_size()
	var screen_size = get_viewport_rect().size
	var menu_size = menu.size
	var final_x = base_pos.x + 10
	var final_y = base_pos.y + 10
	
	if final_x + menu_size.x > screen_size.x:
		final_x = base_pos.x - menu_size.x - 10
	if final_y + menu_size.y > screen_size.y:
		final_y = base_pos.y - menu_size.y - 10
		
	menu.global_position = Vector2(final_x, final_y)

func update_button_state(btn: Button, b_name: String, tile_type: String):
	var can_place = EconomyManager.can_afford_and_place(b_name, tile_type)
	btn.disabled = not can_place
	btn.modulate.a = 1.0 if can_place else 0.35

func execute_build(building_name: String) -> void:
	if world_ref and world_ref.has_method("build_on_tile"):
		world_ref.build_on_tile(active_tile_pos, building_name)
	hide_all_menus()

func _on_economy_updated(balances: Dictionary, turn: int, _selected_build: String):
	# Zaktualizowano interfejs o wyświetlanie zasobów Jedzenia
	resources_label.text = "🌟 TURA: %d   |   🪙 ZŁOTO: %d   |   🌾 JEDZENIE: %d   |   🪵 DREWNO: %d   |   ⛓️ ŻELAZO: %d   |   🌋 WĘGIEL: %d" % [
		turn, balances["Złoto"], balances["Jedzenie"], balances["Drewno"], balances["Żelazo"], balances["Węgiel"]
	]

func _on_turn_pressed():
	hide_all_menus()
	if world_ref and world_ref.has_method("get_active_buildings_list"):
		var buildings = world_ref.get_active_buildings_list()
		EconomyManager.next_turn(buildings)

func style_main_hud_elements():
	var top_panel = $Panel
	var style_top = StyleBoxFlat.new()
	style_top.bg_color = Color(0.07, 0.08, 0.1, 0.85) 
	style_top.border_width_bottom = 3
	style_top.border_color = Color(0.0, 0.75, 1.0) 
	style_top.content_margin_left = 15
	style_top.content_margin_top = 10
	top_panel.add_theme_stylebox_override("panel", style_top)
	
	var style_turn = StyleBoxFlat.new()
	style_turn.bg_color = Color(0.5, 0.1, 0.7) 
	style_turn.set_corner_radius_all(12)
	style_turn.border_width_bottom = 4
	style_turn.border_color = Color(0.35, 0.05, 0.5) 
	
	var style_turn_hover = style_turn.duplicate() as StyleBoxFlat
	style_turn_hover.bg_color = Color(0.65, 0.15, 0.85) 
	
	turn_button.add_theme_stylebox_override("normal", style_turn)
	turn_button.add_theme_stylebox_override("hover", style_turn_hover)
	turn_button.add_theme_color_override("font_color", Color.WHITE)

func style_context_popup():
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.05, 0.05, 0.07, 0.92) 
	style_box.set_border_width_all(2) 
	style_box.border_color = Color(0.2, 0.6, 1.0, 0.5) 
	style_box.set_corner_radius_all(14)
	style_box.set_content_margin_all(10)
	menu_budowania.add_theme_stylebox_override("panel", style_box)
	
	$MenuBudowania/VBoxContainer.add_theme_constant_override("separation", 6)

func style_individual_buttons():
	style_single_button(build_chata, Color(0.15, 0.5, 0.15), Color(0.2, 0.7, 0.2), "🪵 Buduj Chatę Drwala")
	style_single_button(build_iron, Color(0.2, 0.35, 0.5), Color(0.3, 0.5, 0.75), "⛓️ Kopalnia Żelaza")
	style_single_button(build_coal, Color(0.7, 0.3, 0.0), Color(0.9, 0.45, 0.1), "🌋 Kopalnia Węgla")

func style_single_button(btn: Button, base_color: Color, hover_color: Color, new_text: String):
	btn.text = new_text
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.custom_minimum_size.y = 38 
	
	var normal = StyleBoxFlat.new()
	normal.bg_color = base_color
	normal.set_corner_radius_all(6)
	normal.set_content_margin_all(12)
	
	var hover = StyleBoxFlat.new()
	hover.bg_color = hover_color
	hover.set_corner_radius_all(6)
	hover.set_content_margin_all(12)
	
	var disabled = StyleBoxFlat.new()
	disabled.bg_color = Color(0.15, 0.15, 0.15) 
	disabled.set_corner_radius_all(6)
	disabled.content_margin_left = 12
	
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("disabled", disabled)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_disabled_color", Color(0.5, 0.5, 0.5))
