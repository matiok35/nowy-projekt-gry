extends Control
# HUD.gd (Podpięty pod węzeł CanvasLayer/UI)

@onready var resources_label = $Panel/ResourcesLabel
@onready var turn_button = $TurnButton
@onready var menu_budowania = $MenuBudowania

@onready var build_chata = $MenuBudowania/VBoxContainer/BuildChata
@onready var build_iron = $MenuBudowania/VBoxContainer/BuildKopalniaZelaza
@onready var build_coal = $MenuBudowania/VBoxContainer/BuildKopalniaWegla

var build_farma: Button
var info_label: Label
var menu_zalozenia_miasta: PopupPanel 
var zaloz_miasto_button: Button
var kup_pole_button: Button 

var cat_zasobowe: Button
var cat_tech: Button
var cat_naukowe: Button

var btn_tech_1: Button
var btn_tech_2: Button
var btn_naukowy_1: Button
var btn_naukowy_2: Button

# --- NOWE ELEMENTY STRUKTURALNE DRZEWKA Z ZALEŻNOŚCIAMI ---
var tech_tree_button: Button
var tech_tree_window: Panel
var tech_tree_map: Control # Panel rysowania linii i węzłów

# Stałe pozycjonowania siatki 2D
const X_SPACING: float = 280.0
const Y_SPACING: float = 90.0
const OFFSET_POS: Vector2 = Vector2(80, 50)

var world_ref: Node2D 
var active_tile_pos: Vector2 = Vector2.ZERO
var active_tile_type: String = ""
var last_mouse_pos: Vector2 = Vector2.ZERO
var confirm_dialog: ConfirmationDialog
var pending_building: String = ""

var points_panel: PanelContainer
var culture_label: Label
var culture_bar: ProgressBar
var tech_label: Label
var tech_bar: ProgressBar

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
	
	setup_points_panel()
	setup_custom_popups()
	if has_method("setup_tech_tree_ui"):
		setup_tech_tree_ui()
	style_main_hud_elements()
	style_context_popup()
	style_individual_buttons()
	
	EconomyManager.notify_change()

func setup_points_panel():
	points_panel = PanelContainer.new()
	points_panel.anchor_left = 1.0
	points_panel.anchor_right = 1.0
	points_panel.anchor_top = 0.0
	points_panel.anchor_bottom = 0.0
	points_panel.offset_left = -320
	points_panel.offset_right = -20
	points_panel.offset_top = 60

	var style_panel = StyleBoxFlat.new()
	style_panel.bg_color = Color(0.12, 0.16, 0.18, 0.85)
	style_panel.set_corner_radius_all(10)
	style_panel.set_border_width_all(2)
	style_panel.border_color = Color(0.2, 0.3, 0.4, 0.5)
	style_panel.content_margin_left = 12
	style_panel.content_margin_right = 12
	style_panel.content_margin_top = 12
	style_panel.content_margin_bottom = 12
	points_panel.add_theme_stylebox_override("panel", style_panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	points_panel.add_child(vbox)
	
	# CULTURE ROW
	var culture_vbox = VBoxContainer.new()
	culture_vbox.add_theme_constant_override("separation", 2)
	var culture_hbox = HBoxContainer.new()
	var c_icon = Label.new()
	c_icon.text = "🎭"
	culture_label = Label.new()
	culture_label.text = "Punkty Kultury: 0/100"
	culture_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	culture_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	culture_label.add_theme_font_size_override("font_size", 14)
	culture_hbox.add_child(c_icon)
	culture_hbox.add_child(culture_label)
	culture_vbox.add_child(culture_hbox)
	
	culture_bar = ProgressBar.new()
	culture_bar.custom_minimum_size = Vector2(0, 4)
	culture_bar.show_percentage = false
	var c_bg = StyleBoxFlat.new()
	c_bg.bg_color = Color(0.2, 0.15, 0.25)
	var c_fg = StyleBoxFlat.new()
	c_fg.bg_color = Color(0.65, 0.35, 0.75) # Fioletowy z obrazka
	culture_bar.add_theme_stylebox_override("background", c_bg)
	culture_bar.add_theme_stylebox_override("fill", c_fg)
	culture_vbox.add_child(culture_bar)
	
	vbox.add_child(culture_vbox)
	
	# TECH ROW
	var tech_vbox = VBoxContainer.new()
	tech_vbox.add_theme_constant_override("separation", 2)
	var tech_hbox = HBoxContainer.new()
	var t_icon = Label.new()
	t_icon.text = "🧪"
	tech_label = Label.new()
	tech_label.text = "Punkty Technologii: 0/100"
	tech_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tech_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tech_label.add_theme_font_size_override("font_size", 14)
	tech_hbox.add_child(t_icon)
	tech_hbox.add_child(tech_label)
	tech_vbox.add_child(tech_hbox)
	
	tech_bar = ProgressBar.new()
	tech_bar.custom_minimum_size = Vector2(0, 4)
	tech_bar.show_percentage = false
	var t_bg = StyleBoxFlat.new()
	t_bg.bg_color = Color(0.1, 0.25, 0.25)
	var t_fg = StyleBoxFlat.new()
	t_fg.bg_color = Color(0.25, 0.7, 0.65) # Morski z obrazka
	tech_bar.add_theme_stylebox_override("background", t_bg)
	tech_bar.add_theme_stylebox_override("fill", t_fg)
	tech_vbox.add_child(tech_bar)
	
	vbox.add_child(tech_vbox)
	
	add_child(points_panel)

func setup_custom_popups():
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.05, 0.05, 0.07, 0.95) 
	style_box.set_border_width_all(2) 
	style_box.border_color = Color(0.0, 0.75, 1.0, 0.8) 
	style_box.set_corner_radius_all(10)
	style_box.set_content_margin_all(8)

	var vbox = $MenuBudowania/VBoxContainer
	
	var info_panel = PanelContainer.new()
	var info_style = StyleBoxFlat.new()
	info_style.bg_color = Color(0.12, 0.15, 0.22, 0.95)
	info_style.set_corner_radius_all(8)
	info_style.set_content_margin_all(10)
	info_panel.add_theme_stylebox_override("panel", info_style)
	
	info_label = Label.new()
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.add_theme_color_override("font_color", Color(0.4, 0.9, 1.0))
	
	info_panel.add_child(info_label)
	vbox.add_child(info_panel)
	vbox.move_child(info_panel, 0)

	build_farma = Button.new()
	vbox.add_child(build_farma)
	build_farma.pressed.connect(func(): execute_build("Farma"))
	style_single_button(build_farma, Color(0.45, 0.4, 0.15), Color(0.65, 0.55, 0.2), "🌾 Buduj Farmę","Farma")

	cat_zasobowe = Button.new()
	cat_tech = Button.new()
	cat_naukowe = Button.new()
	
	vbox.add_child(cat_zasobowe)
	vbox.add_child(cat_tech)
	vbox.add_child(cat_naukowe)
	
	style_single_button(cat_zasobowe, Color(0.2, 0.4, 0.6), Color(0.3, 0.5, 0.8), "🛠️ Budynki Zasobowe")
	style_single_button(cat_tech, Color(0.4, 0.2, 0.6), Color(0.5, 0.3, 0.8), "⚙️ Budynki Technologiczne")
	style_single_button(cat_naukowe, Color(0.6, 0.2, 0.4), Color(0.8, 0.3, 0.5), "📜 Budynki Naukowe")

	cat_zasobowe.pressed.connect(func(): _show_building_category("zasobowe"))
	cat_tech.pressed.connect(func(): _show_building_category("tech"))
	cat_naukowe.pressed.connect(func(): _show_building_category("naukowe"))
	
	btn_tech_1 = Button.new()
	btn_tech_2 = Button.new()
	vbox.add_child(btn_tech_1)
	vbox.add_child(btn_tech_2)
	btn_tech_1.pressed.connect(func(): execute_build("Laboratorium"))
	btn_tech_2.pressed.connect(func(): execute_build("Warsztat"))
	style_single_button(btn_tech_1, Color(0.3, 0.4, 0.6), Color(0.4, 0.5, 0.8), "⚙️ Laboratorium", "Laboratorium")
	style_single_button(btn_tech_2, Color(0.4, 0.3, 0.2), Color(0.5, 0.4, 0.3), "⚙️ Warsztat",  "Warsztat")

	btn_naukowy_1 = Button.new()
	btn_naukowy_2 = Button.new()
	vbox.add_child(btn_naukowy_1)
	vbox.add_child(btn_naukowy_2)
	btn_naukowy_1.pressed.connect(func(): execute_build("Biblioteka"))
	btn_naukowy_2.pressed.connect(func(): execute_build("Świątynia"))
	style_single_button(btn_naukowy_1, Color(0.4, 0.2, 0.4), Color(0.5, 0.3, 0.5), "📜 Biblioteka","Biblioteka")
	style_single_button(btn_naukowy_2, Color(0.6, 0.5, 0.2), Color(0.7, 0.6, 0.3), "📜 Świątynia","Świątynia")

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

	kup_pole_button = Button.new()
	kup_pole_button.text = "🪙 Kup to pole (50 złota)"
	kup_pole_button.custom_minimum_size = Vector2(180, 35)
	
	var style_buy = StyleBoxFlat.new()
	style_buy.bg_color = Color(0.15, 0.35, 0.4)
	style_buy.set_corner_radius_all(6)
	style_buy.set_content_margin_all(12)
	kup_pole_button.add_theme_stylebox_override("normal", style_buy)
	
	vbox.add_child(kup_pole_button)
	vbox.move_child(kup_pole_button, 1)
	
	kup_pole_button.pressed.connect(func():
		if world_ref and world_ref.has_method("buy_tile"):
			world_ref.buy_tile(active_tile_pos)
		hide_all_menus()
	)

	# 5. Okno dialogowe potwierdzenia zniszczenia surowca
	confirm_dialog = ConfirmationDialog.new()
	confirm_dialog.title = "Uwaga: Zniszczenie Złoża!"
	confirm_dialog.dialog_text = "Czy na pewno chcesz postawić ten budynek na tym polu?\nPostawienie go tutaj bezpowrotnie zniszczy obecne złoże i zamieni pole w trawę."
	confirm_dialog.confirmed.connect(_on_confirm_build_on_resource)
	add_child(confirm_dialog)

# --- ZAAWANSOWANE DRZEWO TECHNOLOGICZNE W STYLU GRAFICZNYM Z LINIAMI ---
func setup_tech_tree_ui():
	tech_tree_button = Button.new()
	tech_tree_button.text = "Drzewo Rozwoju"
	tech_tree_button.custom_minimum_size = Vector2(0, 40)
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.18, 0.24, 0.35)
	btn_style.set_border_width_all(1)
	btn_style.border_color = Color(0.38, 0.55, 0.78)
	btn_style.set_corner_radius_all(4)
	tech_tree_button.add_theme_stylebox_override("normal", btn_style)
	var vbox = points_panel.get_child(0)
	vbox.add_child(tech_tree_button)
	
	# Główne okno stylizowane na pergaminowo-kamienne tło
	tech_tree_window = Panel.new()
	tech_tree_window.name = "TechTreeWindow"
	tech_tree_window.custom_minimum_size = Vector2(1000, 520)
	tech_tree_window.visible = false
	
	var style_tree = StyleBoxFlat.new()
	style_tree.bg_color = Color(0.14, 0.13, 0.11, 0.98) # Cieplejszy odcień (jak tło z drugiego obrazka)
	style_tree.set_border_width_all(3)
	style_tree.border_color = Color(0.45, 0.38, 0.28)
	style_tree.set_corner_radius_all(4)
	tech_tree_window.add_theme_stylebox_override("panel", style_tree)
	
	var title = Label.new()
	title.text = "DRZEWO ROZWOJU TECHNOLOGICZNEGO"
	title.position = Vector2(30, 20)
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.85, 0.76, 0.6))
	tech_tree_window.add_child(title)
	
	var close_btn = Button.new()
	close_btn.name = "CloseButton"
	close_btn.text = "✕ ZAMKNIJ"
	close_btn.position = Vector2(880, 15)
	close_btn.custom_minimum_size = Vector2(90, 30)
	tech_tree_window.add_child(close_btn)
	close_btn.pressed.connect(func(): tech_tree_window.visible = false)
	
	var scroll = ScrollContainer.new()
	scroll.position = Vector2(30, 70)
	scroll.custom_minimum_size = Vector2(940, 420)
	
	# Obiekt mapy rysującej linie i przechowującej węzły
	tech_tree_map = Control.new()
	tech_tree_map.name = "TechTreeMap"
	tech_tree_map.custom_minimum_size = Vector2(1100, 400)
	
	# Przypisujemy zachowanie rysowania bezpośrednio przez funkcję anonimową lub skrypt
	tech_tree_map.draw.connect(_draw_tech_connections)
	
	scroll.add_child(tech_tree_map)
	tech_tree_window.add_child(scroll)
	add_child(tech_tree_window)
	
	tech_tree_button.pressed.connect(func():
		hide_all_menus()
		tech_tree_window.visible = true
		var screen_center = get_viewport_rect().size / 2
		tech_tree_window.global_position = screen_center - (tech_tree_window.custom_minimum_size / 2)
		refresh_technology_tree_view()
	)

# Obliczanie pozycji węzła na podstawie jego współrzędnych w gridzie
func _get_tech_node_position(grid_coords: Vector2) -> Vector2:
	return Vector2(
		grid_coords.x * X_SPACING + OFFSET_POS.x,
		grid_coords.y * Y_SPACING + OFFSET_POS.y
	)

# Metoda rysująca linie połączeń w tle kafelków
func _draw_tech_connections():
	for tech_name in EconomyManager.technology_tree:
		var tech = EconomyManager.technology_tree[tech_name]
		var start_pos = _get_tech_node_position(tech["grid_coords"]) + Vector2(210, 32) # Środek prawego brzegu owalu
		
		for req_name in tech["req"]:
			if EconomyManager.technology_tree.has(req_name):
				var req_tech = EconomyManager.technology_tree[req_name]
				var end_pos = _get_tech_node_position(req_tech["grid_coords"]) + Vector2(0, 32) # Środek lewego brzegu celu
				
				# Określenie stanu linii podświetlenia
				var line_color = Color(0.25, 0.22, 0.18, 1.0) # Domyślny ciemny szary/brąz
				var line_width = 2.5
				
				if req_tech["unlocked"] and tech["unlocked"]:
					line_color = Color(0.32, 0.68, 0.85, 0.9) # Jasnoniebieska poświata (Zbadane)
					line_width = 3.5
				elif req_tech["unlocked"] and EconomyManager.current_research == tech_name:
					line_color = Color(0.72, 0.55, 0.25, 0.8) # Pomarańczowy impuls (W trakcie)
				
				# Rysowanie łamanej linii (ścieżka z zakrętem pod kątem prostym, estetyka Civ)
				var mid_x = start_pos.x + (end_pos.x - start_pos.x) / 2.0
				
				tech_tree_map.draw_line(start_pos, Vector2(mid_x, start_pos.y), line_color, line_width)
				tech_tree_map.draw_line(Vector2(mid_x, start_pos.y), Vector2(mid_x, end_pos.y), line_color, line_width)
				tech_tree_map.draw_line(Vector2(mid_x, end_pos.y), end_pos, line_color, line_width)

func refresh_technology_tree_view():
	if not tech_tree_map: return
	
	# Usuwamy stare przyciski węzłów, zostawiając logikę rysowania linii
	for child in tech_tree_map.get_children():
		child.queue_free()
		
	# Ponowne wywołanie draw linii
	tech_tree_map.queue_redraw()
	
	for tech_name in EconomyManager.technology_tree:
		var tech = EconomyManager.technology_tree[tech_name]
		var node_pos = _get_tech_node_position(tech["grid_coords"])
		
		# Karta pojedynczego węzła technologii (owalny kształt zbliżony do grafiki)
		var node_panel = PanelContainer.new()
		node_panel.position = node_pos
		node_panel.custom_minimum_size = Vector2(210, 64)
		
		var node_style = StyleBoxFlat.new()
		node_style.bg_color = Color(0.18, 0.16, 0.14)
		node_style.set_corner_radius_all(32) # Pełne zaokrąglenie rogów -> Owal
		node_style.set_border_width_all(2)
		node_style.border_color = Color(0.35, 0.3, 0.24)
		node_style.set_content_margin_all(6)
		node_panel.add_theme_stylebox_override("panel", node_style)
		
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 8)
		node_panel.add_child(hbox)
		
		# Kontener ikony (Okrągły avatar przed tekstem)
		var icon_panel = PanelContainer.new()
		icon_panel.custom_minimum_size = Vector2(46, 46)
		var icon_style = StyleBoxFlat.new()
		icon_style.bg_color = Color(0.24, 0.22, 0.18)
		icon_style.set_corner_radius_all(23) # Koło
		icon_style.set_border_width_all(1)
		icon_style.border_color = Color(0.5, 0.44, 0.35)
		icon_panel.add_theme_stylebox_override("panel", icon_style)
		
		var icon_label = Label.new()
		icon_label.text = tech["icon"]
		icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		icon_label.add_theme_font_size_override("font_size", 18)
		icon_panel.add_child(icon_label)
		hbox.add_child(icon_panel)
		
		# Sekcja tekstowa
		var vbox = VBoxContainer.new()
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		hbox.add_child(vbox)
		
		var lbl_title = Label.new()
		lbl_title.text = tech_name
		lbl_title.add_theme_font_size_override("font_size", 12)
		lbl_title.add_theme_color_override("font_color", Color(0.9, 0.85, 0.75))
		vbox.add_child(lbl_title)
		
		var lbl_desc = Label.new()
		lbl_desc.text = tech["desc"]
		lbl_desc.add_theme_font_size_override("font_size", 9)
		lbl_desc.add_theme_color_override("font_color", Color(0.6, 0.58, 0.53))
		vbox.add_child(lbl_desc)
		
		# Mini-pasek postępu badania wkomponowany pod spód owalu
		var bar = ProgressBar.new()
		var progress = EconomyManager.research_progress.get(tech_name, 0)
		bar.max_value = tech["cost"]
		bar.value = progress
		bar.show_percentage = false
		bar.custom_minimum_size.y = 4
		vbox.add_child(bar)
		
		# Interakcja kliknięcia na owal (wybór badania)
		var invisible_button = Button.new()
		invisible_button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		invisible_button.flat = true
		node_panel.add_child(invisible_button)
		
		# Logika weryfikacji i blokad węzłów
		var reqs_ok = true
		for r in tech["req"]:
			if not EconomyManager.technology_tree[r]["unlocked"]:
				reqs_ok = false
				
		if tech["unlocked"]:
			node_style.border_color = Color(0.3, 0.75, 0.45) # Zielona obwódka
			node_style.bg_color = Color(0.12, 0.22, 0.15)
			invisible_button.disabled = true
		elif EconomyManager.current_research == tech_name:
			node_style.border_color = Color(0.85, 0.64, 0.22) # Złota aktywna obwódka
			node_style.bg_color = Color(0.24, 0.2, 0.14)
			var current_science = EconomyManager.resources["Nauka"]
			var turns_left = ceil(float(tech["cost"] - progress) / max(1, current_science))
			lbl_title.text = "%s (%dt)" % [tech_name, turns_left]
			invisible_button.disabled = true
		elif not reqs_ok:
			node_panel.modulate.a = 0.35 # Rozmycie dla zablokowanych (Mgła wojny)
			invisible_button.disabled = true
		else:
			# Dostępny do kliknięcia
			invisible_button.pressed.connect(func():
				EconomyManager.current_research = tech_name
				refresh_technology_tree_view()
			)
			
		tech_tree_map.add_child(node_panel)

func show_context_menu(mouse_pos: Vector2, tile_pos: Vector2, tile_type: String, building_name: String, is_owned: bool, borders_owned: bool, deposit_size: String = "", fertility: float = 0.0) -> void:
	hide_all_menus()
	active_tile_pos = tile_pos
	active_tile_type = tile_type
	last_mouse_pos = mouse_pos
	
	menu_budowania.visible = true
	var has_building = building_name != "Brak"
	
	if has_building:
		info_label.text = "🏢 Budynek: %s\nPodłoże: %s" % [building_name, tile_type]
	elif tile_type == "Trawa":
		info_label.text = "🌱 Typ: Trawa\n✨ Żyzność pola: %d%%" % [int(fertility * 100)]
	else:
		info_label.text = "⛰️ Typ: Złoże %s\n📦 Wielkość: %s" % [tile_type, deposit_size]

	if is_owned or has_building:
		kup_pole_button.visible = false
	else:
		kup_pole_button.visible = true
		var can_afford = EconomyManager.resources["Złoto"] >= 50
		var can_buy = can_afford and borders_owned
		kup_pole_button.disabled = not can_buy
		kup_pole_button.modulate.a = 1.0 if can_buy else 0.35

	var show_buildings = is_owned and not has_building
	
	cat_zasobowe.visible = show_buildings
	cat_tech.visible = show_buildings
	cat_naukowe.visible = show_buildings
	
	build_chata.visible = false
	build_iron.visible = false
	build_coal.visible = false
	build_farma.visible = false
	btn_tech_1.visible = false
	btn_tech_2.visible = false
	btn_naukowy_1.visible = false
	btn_naukowy_2.visible = false
	
	if show_buildings:
		update_button_state(build_chata, "Chata Drwala", tile_type)
		update_button_state(build_iron, "Kopalnia Żelaza", tile_type)
		update_button_state(build_coal, "Kopalnia Węgla", tile_type)
		update_button_state(build_farma, "Farma", tile_type)
		update_button_state(btn_tech_1, "Laboratorium", tile_type)
		update_button_state(btn_tech_2, "Warsztat", tile_type)
		update_button_state(btn_naukowy_1, "Biblioteka", tile_type)
		update_button_state(btn_naukowy_2, "Świątynia", tile_type)
		
	_reposition_menu(menu_budowania, mouse_pos)

func _show_building_category(category: String):
	cat_zasobowe.visible = false
	cat_tech.visible = false
	cat_naukowe.visible = false
	
	var is_zasobowe = (category == "zasobowe")
	build_chata.visible = is_zasobowe
	build_iron.visible = is_zasobowe
	build_coal.visible = is_zasobowe
	build_farma.visible = is_zasobowe
	
	var is_tech = (category == "tech")
	btn_tech_1.visible = is_tech
	btn_tech_2.visible = is_tech
	
	var is_naukowe = (category == "naukowe")
	btn_naukowy_1.visible = is_naukowe
	btn_naukowy_2.visible = is_naukowe
	
	_reposition_menu(menu_budowania, last_mouse_pos)

func show_city_creation_menu(_screen_pos: Vector2, tile_pos: Vector2) -> void:
	hide_all_menus()
	active_tile_pos = tile_pos
	var current_mouse_pos = get_viewport().get_mouse_position()
	var popup_rect = Rect2(current_mouse_pos + Vector2(10, 10), Vector2(170, 45))
	menu_zalozenia_miasta.popup(popup_rect)

func hide_all_menus():
	menu_budowania.visible = false
	if menu_zalozenia_miasta: menu_zalozenia_miasta.visible = false
	if tech_tree_window: tech_tree_window.visible = false

func any_menu_visible() -> bool:
	return menu_budowania.visible or (menu_zalozenia_miasta and menu_zalozenia_miasta.visible) or (tech_tree_window and tech_tree_window.visible)

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
	if active_tile_type != "Trawa" and building_name in ["Farma", "Laboratorium", "Warsztat", "Biblioteka", "Świątynia"]:
		pending_building = building_name
		confirm_dialog.popup_centered()
		hide_all_menus()
	else:
		_do_execute_build(building_name)

func _on_confirm_build_on_resource() -> void:
	if pending_building != "":
		_do_execute_build(pending_building)
		pending_building = ""

func _do_execute_build(building_name: String) -> void:
	if world_ref and world_ref.has_method("build_on_tile"):
		world_ref.build_on_tile(active_tile_pos, building_name)
	hide_all_menus()

func _on_economy_updated(balances: Dictionary, turn: int, _selected_build: String):
	# Pokazujemy same surowce w odpowiedniej kolejności i odstępach (wzorowane na obrazku)
	resources_label.text = "🪵 Drewno: %d      ⛓️ Żelazo: %d      🌋 Węgiel: %d      🌾 Jedzenie: %d      🪙 Złoto: %d" % [
		balances["Drewno"], balances["Żelazo"], balances["Węgiel"], balances["Jedzenie"], balances["Złoto"]
	]
	turn_button.text = "Następna tura (%d)" % turn
	
	if culture_label and tech_label:
		var c_val = balances.get("Kultura", 0)
		var t_val = balances.get("Nauka", 0)
		var c_max = EconomyManager.max_culture_points
		var t_max = EconomyManager.max_tech_points
		
		culture_label.text = "Punkty Kultury:    %d/%d" % [c_val, int(c_max)]
		culture_bar.max_value = c_max
		culture_bar.value = c_val
		
		tech_label.text = "Punkty Technologii:    %d/%d" % [t_val, int(t_max)]
		tech_bar.max_value = t_max
		tech_bar.value = t_val
	
	if tech_tree_window and tech_tree_window.visible:
		refresh_technology_tree_view()

func _on_turn_pressed():
	hide_all_menus()
	if world_ref and world_ref.has_method("get_active_buildings_list"):
		var buildings = world_ref.get_active_buildings_list()
		EconomyManager.next_turn(buildings)

func style_main_hud_elements():
	var top_panel = $Panel
	
	# Przypinamy panel na środku u góry ekranu jako "zakładkę"
	top_panel.anchor_left = 0.5
	top_panel.anchor_right = 0.5
	top_panel.anchor_top = 0.0
	top_panel.anchor_bottom = 0.0
	top_panel.offset_left = -480
	top_panel.offset_right = 480
	top_panel.offset_top = 0
	top_panel.offset_bottom = 45
	
	var style_top = StyleBoxFlat.new()
	style_top.bg_color = Color(0.12, 0.13, 0.14, 0.98) # Ciemne tło
	style_top.border_width_bottom = 3
	style_top.border_width_left = 3
	style_top.border_width_right = 3
	style_top.border_width_top = 0
	style_top.border_color = Color(0.4, 0.38, 0.33) # Kamienno-złotawa ramka z obrazka
	style_top.corner_radius_bottom_left = 12
	style_top.corner_radius_bottom_right = 12
	
	# Delikatny cień
	style_top.shadow_color = Color(0, 0, 0, 0.6)
	style_top.shadow_size = 4
	style_top.shadow_offset = Vector2(0, 3)
	
	top_panel.add_theme_stylebox_override("panel", style_top)
	
	# Ustawienia czcionki na wzór obrazka (lekko złotawy odcień)
	resources_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resources_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	resources_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	resources_label.add_theme_font_size_override("font_size", 16)
	resources_label.add_theme_color_override("font_color", Color(0.9, 0.88, 0.8))
	
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
	style_single_button(build_chata, Color(0.15, 0.5, 0.15), Color(0.2, 0.7, 0.2), "🪵 Buduj Chatę Drwala", "Chata Drwala")
	style_single_button(build_iron, Color(0.2, 0.35, 0.5), Color(0.3, 0.5, 0.75), "⛓️ Kopalnia Żelaza", "Kopalnia Żelaza")
	style_single_button(build_coal, Color(0.7, 0.3, 0.0), Color(0.9, 0.45, 0.1), "🌋 Kopalnia Węgla", "Kopalnia Węgla")

func style_single_button(
	btn: Button,
	base_color: Color,
	hover_color: Color,
	new_text: String,
	building_name := ""
):
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
	
	if building_name != "":
		btn.tooltip_text = EconomyManager.get_building_tooltip(building_name)
