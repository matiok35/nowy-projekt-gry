extends Control
# hud.gd (Podpięty pod węzeł CanvasLayer/UI)

@onready var resources_label = $Panel/ResourcesLabel
@onready var turn_button = $TurnButton
@onready var menu_budowania = $MenuBudowania

@onready var build_chata = $MenuBudowania/VBoxContainer/BuildChata
@onready var build_iron = $MenuBudowania/VBoxContainer/BuildKopalniaZelaza
@onready var build_coal = $MenuBudowania/VBoxContainer/BuildKopalniaWegla

var build_farma: Button
var build_pastwisko: Button
var build_dom: Button 
var info_label: Label
var menu_zalozenia_miasta: PopupPanel
var zaloz_miasto_button: Button
var kup_pole_button: Button
var upgrade_button: Button
var tile_info_menu: PanelContainer

var cat_zasobowe: Button
var cat_tech: Button
var cat_naukowe: Button
var cat_wojskowe: Button

var btn_tech_1: Button
var btn_tech_2: Button
var btn_naukowy_1: Button
var btn_naukowy_2: Button
var build_baraki: Button
var build_akademia: Button

var tech_tree_button: Button
var culture_tree_button: Button

@onready var tech_tree_window = $TechTreeWindow
@onready var tech_tree_map = $TechTreeWindow/ScrollContainer/TechTreeMap

@onready var culture_tree_window = $CultureTreeWindow
@onready var culture_tree_map = $CultureTreeWindow/ScrollContainer/CultureTreeMap

const X_SPACING: float = 280.0
const Y_SPACING: float = 90.0
const OFFSET_POS: Vector2 = Vector2(80, 50)

var world_ref: Node2D
var active_tile_pos: Vector2 = Vector2.ZERO
var active_tile_type: String = ""
var last_mouse_pos: Vector2 = Vector2.ZERO
var confirm_dialog: ConfirmationDialog
var pending_building: String = ""

var barracks_window: PanelContainer
var barracks_content_vbox: VBoxContainer
var unit_data_json: Dictionary = {}
var recruit_button: Button

var army_window: PanelContainer
var army_content_vbox: VBoxContainer
var army_button: Button

var resources_container: HBoxContainer
var resource_labels: Dictionary = {}

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
	
	turn_button.pressed.connect(_on_turn_pressed)
	build_chata.pressed.connect(func(): execute_build("Chata Drwala"))
	build_iron.pressed.connect(func(): execute_build("Kopalnia Żelaza"))
	build_coal.pressed.connect(func(): execute_build("Kopalnia Węgla"))
	
	setup_points_panel()
	setup_resources_header()
	setup_custom_popups()
	setup_tech_tree_ui()
	setup_culture_tree_ui()
	load_unit_data()
	setup_barracks_window()
	setup_army_window()
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
	
	var culture_vbox = VBoxContainer.new()
	culture_vbox.add_theme_constant_override("separation", 5)
	
	var culture_hbox = HBoxContainer.new()
	culture_hbox.add_theme_constant_override("separation", 10)
	
	var c_icon = TextureRect.new()
	c_icon.texture = preload("res://assets/resources/cultural.png")
	c_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	c_icon.custom_minimum_size = Vector2(36, 36)
	c_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	c_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	var c_info_vbox = VBoxContainer.new()
	c_info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c_info_vbox.add_theme_constant_override("separation", 2)
	c_info_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	culture_label = Label.new()
	culture_label.text = "Punkty Kultury: 0/100"
	culture_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	culture_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	culture_label.add_theme_font_size_override("font_size", 14)
	
	culture_bar = ProgressBar.new()
	culture_bar.custom_minimum_size = Vector2(0, 8)
	culture_bar.show_percentage = false
	var c_bg = StyleBoxFlat.new()
	c_bg.bg_color = Color(0.2, 0.15, 0.25)
	var c_fg = StyleBoxFlat.new()
	c_fg.bg_color = Color(0.65, 0.35, 0.75)  
	culture_bar.add_theme_stylebox_override("background", c_bg)
	culture_bar.add_theme_stylebox_override("fill", c_fg)
	
	c_info_vbox.add_child(culture_label)
	c_info_vbox.add_child(culture_bar)
	
	culture_hbox.add_child(c_icon)
	culture_hbox.add_child(c_info_vbox)
	culture_vbox.add_child(culture_hbox)
	
	culture_tree_button = Button.new()
	culture_tree_button.text = "Drzewo Kultury"
	culture_tree_button.custom_minimum_size = Vector2(0, 40)
	var culture_style = StyleBoxFlat.new()
	culture_style.bg_color = Color(0.45, 0.15, 0.65)
	culture_style.border_color = Color(0.8, 0.55, 1.0)
	culture_style.set_border_width_all(1)
	culture_style.set_corner_radius_all(4)
	culture_tree_button.add_theme_stylebox_override("normal", culture_style)
	var culture_hover = culture_style.duplicate()
	culture_hover.bg_color = Color(0.60, 0.25, 0.80)
	culture_tree_button.add_theme_stylebox_override("hover", culture_hover)
	culture_vbox.add_child(culture_tree_button)

	vbox.add_child(culture_vbox)
	
	var tech_vbox = VBoxContainer.new()
	tech_vbox.add_theme_constant_override("separation", 5)
	
	var tech_hbox = HBoxContainer.new()
	tech_hbox.add_theme_constant_override("separation", 10)
	
	var t_icon = TextureRect.new()
	t_icon.texture = preload("res://assets/resources/technology.png")
	t_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t_icon.custom_minimum_size = Vector2(36, 36)
	t_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	var t_info_vbox = VBoxContainer.new()
	t_info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t_info_vbox.add_theme_constant_override("separation", 2)
	t_info_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	tech_label = Label.new()
	tech_label.text = "Punkty Technologii: 0/100"
	tech_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tech_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tech_label.add_theme_font_size_override("font_size", 14)
	
	tech_bar = ProgressBar.new()
	tech_bar.custom_minimum_size = Vector2(0, 8)
	tech_bar.show_percentage = false
	var t_bg = StyleBoxFlat.new()
	t_bg.bg_color = Color(0.1, 0.25, 0.25)
	var t_fg = StyleBoxFlat.new()
	t_fg.bg_color = Color(0.25, 0.7, 0.65) 
	tech_bar.add_theme_stylebox_override("background", t_bg)
	tech_bar.add_theme_stylebox_override("fill", t_fg)
	
	t_info_vbox.add_child(tech_label)
	t_info_vbox.add_child(tech_bar)
	
	tech_hbox.add_child(t_icon)
	tech_hbox.add_child(t_info_vbox)
	tech_vbox.add_child(tech_hbox)
	vbox.add_child(tech_vbox)
	
	add_child(points_panel)

func setup_resources_header():
	resources_label.visible = false
	
	resources_container = HBoxContainer.new()
	resources_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resources_container.alignment = BoxContainer.ALIGNMENT_CENTER
	resources_container.add_theme_constant_override("separation", 25)
	$Panel.add_child(resources_container)
	
	var default_icon = null
	
	var resources_list = ["Drewno", "Żelazo", "Węgiel", "Jedzenie", "Złoto", "Populacja"]
	for res_name in resources_list:
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 5)
		
		var icon = TextureRect.new()
		if res_name == "Złoto":
			icon.texture = preload("res://assets/resources/gold.png")
		elif res_name == "Jedzenie":
			icon.texture = preload("res://assets/resources/food.png")
		elif res_name == "Drewno":
			icon.texture = preload("res://assets/resources/wood.png")
		elif res_name == "Żelazo":
			icon.texture = preload("res://assets/resources/iron.png")
		elif res_name == "Węgiel":
			icon.texture = preload("res://assets/resources/coal.png")
		elif res_name == "Populacja":
			icon.texture = preload("res://assets/resources/population.png")
		else:
			icon.texture = default_icon
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.custom_minimum_size = Vector2(24, 24)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		
		var lbl = Label.new()
		lbl.add_theme_font_size_override("font_size", 16)
		lbl.add_theme_color_override("font_color", Color(0.9, 0.88, 0.8))
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.text = res_name + ": 0"
		
		hbox.add_child(icon)
		hbox.add_child(lbl)
		
		resources_container.add_child(hbox)
		resource_labels[res_name] = lbl

var build_grid: GridContainer

func setup_custom_popups():
	var vbox = $MenuBudowania/VBoxContainer
	menu_budowania.custom_minimum_size = Vector2(360, 0) # Wymuszenie stałej szerokości
	
	# Anchor bottom right ONCE
	menu_budowania.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	menu_budowania.offset_right = -20
	menu_budowania.offset_bottom = -20
	menu_budowania.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	menu_budowania.grow_vertical = Control.GROW_DIRECTION_BEGIN
	
	# 1. HEADER
	var header_hbox = HBoxContainer.new()
	header_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	var title_label = Label.new()
	title_label.text = "Menu Budowy"
	title_label.add_theme_font_size_override("font_size", 18)
	title_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.75))
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	var close_btn = Button.new()
	close_btn.text = "X"
	close_btn.custom_minimum_size = Vector2(30, 30)
	close_btn.pressed.connect(func(): hide_all_menus())
	
	header_hbox.add_child(Control.new()) # Spacer
	header_hbox.get_child(0).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(title_label)
	header_hbox.add_child(close_btn)
	vbox.add_child(header_hbox)
	vbox.move_child(header_hbox, 0)
	
	# 2. TABS
	var tabs_hbox = HBoxContainer.new()
	cat_zasobowe = Button.new()
	cat_naukowe = Button.new()
	cat_tech = Button.new()
	cat_wojskowe = Button.new()
	cat_zasobowe.text = "Surowce"
	cat_naukowe.text = "Kultura"
	cat_tech.text = "Technologia"
	cat_wojskowe.text = "Wojskowe"
	cat_zasobowe.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cat_naukowe.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cat_tech.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cat_wojskowe.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs_hbox.add_child(cat_zasobowe)
	tabs_hbox.add_child(cat_naukowe)
	tabs_hbox.add_child(cat_tech)
	tabs_hbox.add_child(cat_wojskowe)
	vbox.add_child(tabs_hbox)
	vbox.move_child(tabs_hbox, 1)
	
	cat_zasobowe.pressed.connect(func(): _show_building_category("zasobowe"))
	cat_naukowe.pressed.connect(func(): _show_building_category("naukowe"))
	cat_tech.pressed.connect(func(): _show_building_category("tech"))
	cat_wojskowe.pressed.connect(func(): _show_building_category("wojskowe"))
	
	# 3. KUP POLE BUTTON AND TILE INFO MENU SEPARATION
	tile_info_menu = PanelContainer.new()
	tile_info_menu.visible = false
	var tile_info_style = StyleBoxFlat.new()
	tile_info_style.bg_color = Color(0.05, 0.05, 0.07, 0.95)  
	tile_info_style.set_border_width_all(2) 
	tile_info_style.border_color = Color(0.2, 0.6, 1.0, 0.8) 
	tile_info_style.set_corner_radius_all(10)
	tile_info_style.set_content_margin_all(8)
	tile_info_menu.add_theme_stylebox_override("panel", tile_info_style)
	
	var tile_info_vbox = VBoxContainer.new()
	tile_info_vbox.add_theme_constant_override("separation", 6)
	tile_info_menu.add_child(tile_info_vbox)
	
	info_label = Label.new()
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.add_theme_color_override("font_color", Color(0.4, 0.9, 1.0))
	
	upgrade_button = Button.new()
	upgrade_button.text = "⬆️ Ulepsz budynek"
	upgrade_button.pressed.connect(func(): 
		if world_ref and world_ref.has_method("upgrade_building"):
			world_ref.upgrade_building(active_tile_pos)
		hide_all_menus()
	)
	var style_upg = StyleBoxFlat.new()
	style_upg.bg_color = Color(0.3, 0.6, 0.2)
	style_upg.set_corner_radius_all(6)
	style_upg.set_content_margin_all(12)
	upgrade_button.add_theme_stylebox_override("normal", style_upg)

	recruit_button = Button.new()
	recruit_button.text = "⚔️ Rekrutuj"
	recruit_button.pressed.connect(func():
		hide_all_menus()
		show_barracks_menu()
	)
	var style_recruit = StyleBoxFlat.new()
	style_recruit.bg_color = Color(0.6, 0.2, 0.2)
	style_recruit.set_corner_radius_all(6)
	style_recruit.set_content_margin_all(12)
	recruit_button.add_theme_stylebox_override("normal", style_recruit)

	army_button = Button.new()
	army_button.text = "🛡️ Moja Armia"
	army_button.pressed.connect(func():
		hide_all_menus()
		show_army_menu()
	)
	var style_army = StyleBoxFlat.new()
	style_army.bg_color = Color(0.2, 0.4, 0.6)
	style_army.set_corner_radius_all(6)
	style_army.set_content_margin_all(12)
	army_button.add_theme_stylebox_override("normal", style_army)

	tile_info_vbox.add_child(info_label)
	tile_info_vbox.add_child(upgrade_button)
	tile_info_vbox.add_child(army_button)
	tile_info_vbox.add_child(recruit_button)
	
	kup_pole_button = Button.new()
	kup_pole_button.text = "🪙 Kup to pole (50 złota)"
	kup_pole_button.custom_minimum_size = Vector2(180, 35)
	var style_buy = StyleBoxFlat.new()
	style_buy.bg_color = Color(0.15, 0.35, 0.4)
	style_buy.set_corner_radius_all(6)
	style_buy.set_content_margin_all(12)
	kup_pole_button.add_theme_stylebox_override("normal", style_buy)
	tile_info_vbox.add_child(kup_pole_button)
	
	kup_pole_button.pressed.connect(func():
		if world_ref and world_ref.has_method("buy_tile"):
			world_ref.buy_tile(active_tile_pos)
		hide_all_menus()
	)
	
	add_child(tile_info_menu)
	
	# 4. GRID CONTAINER FOR BUTTONS
	build_grid = GridContainer.new()
	build_grid.columns = 3
	build_grid.custom_minimum_size = Vector2(320, 0) # Miejsce na 3 kolumny po 100px + odstępy
	build_grid.add_theme_constant_override("h_separation", 10)
	build_grid.add_theme_constant_override("v_separation", 10)
	build_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(build_grid)
	vbox.move_child(build_grid, 2)
	
	# 5. BUTTONS (Reparent and create new ones)
	build_chata.reparent(build_grid)
	build_iron.reparent(build_grid)
	build_coal.reparent(build_grid)
	build_farma = Button.new()
	build_grid.add_child(build_farma)
	build_farma.pressed.connect(func(): execute_build("Farma"))
	style_single_button(build_farma, "🌾 Buduj Farmę", "Farma")
	
	build_pastwisko = Button.new()
	build_grid.add_child(build_pastwisko)
	build_pastwisko.pressed.connect(func(): execute_build("Pastwisko"))
	style_single_button(build_pastwisko, "Pastwisko", "Pastwisko")

	build_dom = Button.new()
	build_grid.add_child(build_dom)
	build_dom.pressed.connect(func(): execute_build("Dom mieszkalny"))
	
	btn_tech_1 = Button.new()
	btn_tech_2 = Button.new()
	build_grid.add_child(btn_tech_1)
	build_grid.add_child(btn_tech_2)
	btn_tech_1.pressed.connect(func(): execute_build("Laboratorium"))
	btn_tech_2.pressed.connect(func(): execute_build("Warsztat"))
	
	btn_naukowy_1 = Button.new()
	btn_naukowy_2 = Button.new()
	build_grid.add_child(btn_naukowy_1)
	build_grid.add_child(btn_naukowy_2)
	btn_naukowy_1.pressed.connect(func(): execute_build("Biblioteka"))
	btn_naukowy_2.pressed.connect(func(): execute_build("Świątynia"))

	build_baraki = Button.new()
	build_akademia = Button.new()
	build_grid.add_child(build_baraki)
	build_grid.add_child(build_akademia)
	build_baraki.pressed.connect(func(): execute_build("Baraki"))
	build_akademia.pressed.connect(func(): execute_build("Akademia generałów"))
	
	# 7. ZALOZ MIASTO MENU
	menu_zalozenia_miasta = PopupPanel.new()
	menu_zalozenia_miasta.visible = false
	var mz_style = StyleBoxFlat.new()
	mz_style.bg_color = Color(0.05, 0.05, 0.07, 0.95)  
	mz_style.set_border_width_all(2) 
	mz_style.border_color = Color(0.0, 0.75, 1.0, 0.8) 
	mz_style.set_corner_radius_all(10)
	mz_style.set_content_margin_all(8)
	menu_zalozenia_miasta.add_theme_stylebox_override("panel", mz_style)
	
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
	
	confirm_dialog = ConfirmationDialog.new()
	confirm_dialog.title = "Uwaga: Zniszczenie Złoża!"
	confirm_dialog.dialog_text = "Czy na pewno chcesz postawić ten budynek na tym polu?\nPostawienie go tutaj bezpowrotnie zniszczy obecne złoże i zamieni pole w trawę."
	confirm_dialog.confirmed.connect(_on_confirm_build_on_resource)
	add_child(confirm_dialog)

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
	
	if tech_tree_window:
		tech_tree_window.visible = false
		tech_tree_window.z_index = 10
		var style_tree = StyleBoxFlat.new()
		style_tree.bg_color = Color(0.14, 0.13, 0.11, 0.98) 
		style_tree.set_border_width_all(3)
		style_tree.border_color = Color(0.45, 0.38, 0.28)
		style_tree.set_corner_radius_all(4)
		tech_tree_window.add_theme_stylebox_override("panel", style_tree)
		var close_btn = tech_tree_window.get_node_or_null("CloseButton")
		if close_btn: close_btn.pressed.connect(func(): tech_tree_window.visible = false)
		var scroll = tech_tree_window.get_node_or_null("ScrollContainer")
		if scroll:
			scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
			scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	if tech_tree_map: tech_tree_map.draw.connect(_draw_tech_connections)
	
	tech_tree_button.pressed.connect(func():
		hide_all_menus()
		if tech_tree_window:
			tech_tree_window.visible = true
			tech_tree_window.custom_minimum_size = Vector2(900, 600)
			tech_tree_window.size = Vector2(900, 600)
			var screen_center = get_viewport_rect().size / 2
			tech_tree_window.global_position = screen_center - (tech_tree_window.size / 2)
			refresh_technology_tree_view()
	)

func setup_culture_tree_ui():
	if culture_tree_window:
		culture_tree_window.visible = false
		culture_tree_window.z_index = 10
		var style_tree = StyleBoxFlat.new()
		style_tree.bg_color = Color(0.14, 0.13, 0.11, 0.98)
		style_tree.set_border_width_all(3)
		style_tree.border_color = Color(0.55, 0.25, 0.80)
		style_tree.set_corner_radius_all(4)
		culture_tree_window.add_theme_stylebox_override("panel", style_tree)
		var close_btn = culture_tree_window.get_node_or_null("CloseButton")
		if close_btn:
			close_btn.pressed.connect(func(): culture_tree_window.visible = false)
		var scroll = culture_tree_window.get_node_or_null("ScrollContainer")
		if scroll:
			scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
			scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO

	if culture_tree_map:
		culture_tree_map.draw.connect(_draw_culture_connections)

	culture_tree_button.pressed.connect(func():
		hide_all_menus()
		if culture_tree_window:
			culture_tree_window.visible = true
			culture_tree_window.custom_minimum_size = Vector2(900,600)
			culture_tree_window.size = Vector2(900,600)
			var center = get_viewport_rect().size / 2
			culture_tree_window.global_position = center - culture_tree_window.size / 2
			refresh_culture_tree_view()
	)

func _get_tech_node_position(grid_coords: Vector2) -> Vector2:
	return Vector2(
		grid_coords.x * X_SPACING + OFFSET_POS.x,
		grid_coords.y * Y_SPACING + OFFSET_POS.y
	)

func _draw_tech_connections():
	for tech_name in EconomyManager.technology_tree:
		var tech = EconomyManager.technology_tree[tech_name]
		var start_pos = _get_tech_node_position(tech["grid_coords"]) + Vector2(210, 32) 
		for req_name in tech["req"]:
			if EconomyManager.technology_tree.has(req_name):
				var req_tech = EconomyManager.technology_tree[req_name]
				var end_pos = _get_tech_node_position(req_tech["grid_coords"]) + Vector2(0, 32) 
				var line_color = Color(0.25, 0.22, 0.18, 1.0) 
				var line_width = 2.5
				if req_tech["unlocked"] and tech["unlocked"]:
					line_color = Color(0.32, 0.68, 0.85, 0.9) 
					line_width = 3.5
				elif req_tech["unlocked"] and EconomyManager.current_research == tech_name:
					line_color = Color(0.72, 0.55, 0.25, 0.8)  
				var mid_x = start_pos.x + (end_pos.x - start_pos.x) / 2.0
				tech_tree_map.draw_line(start_pos, Vector2(mid_x, start_pos.y), line_color, line_width)
				tech_tree_map.draw_line(Vector2(mid_x, start_pos.y), Vector2(mid_x, end_pos.y), line_color, line_width)
				tech_tree_map.draw_line(Vector2(mid_x, end_pos.y), end_pos, line_color, line_width)

func _draw_culture_connections():
	for tech_name in EconomyManager.culture_tree:
		var tech = EconomyManager.culture_tree[tech_name]
		var start_pos = _get_tech_node_position(tech["grid_coords"]) + Vector2(210, 32)
		for req_name in tech["req"]:
			if EconomyManager.culture_tree.has(req_name):
				var req_tech = EconomyManager.culture_tree[req_name]
				var end_pos = _get_tech_node_position(req_tech["grid_coords"]) + Vector2(0, 32)
				var line_color = Color(0.25, 0.22, 0.18, 1.0)
				var line_width = 2.5
				if req_tech["unlocked"] and tech["unlocked"]:
					line_color = Color(0.75, 0.35, 1.0, 0.9)
					line_width = 3.5
				elif req_tech["unlocked"] and EconomyManager.current_culture_research == tech_name:
					line_color = Color(0.85, 0.45, 1.0, 0.8)
				var mid_x = start_pos.x + (end_pos.x - start_pos.x) / 2.0
				culture_tree_map.draw_line(start_pos, Vector2(mid_x, start_pos.y), line_color, line_width)
				culture_tree_map.draw_line(Vector2(mid_x, start_pos.y), Vector2(mid_x, end_pos.y), line_color, line_width)
				culture_tree_map.draw_line(Vector2(mid_x, end_pos.y), end_pos, line_color, line_width)

func refresh_technology_tree_view():
	if not tech_tree_map: return
	for child in tech_tree_map.get_children(): child.queue_free()
	tech_tree_map.queue_redraw()
	var max_size := Vector2.ZERO
	for tech_name in EconomyManager.technology_tree:
		var tech = EconomyManager.technology_tree[tech_name]
		var node_pos = _get_tech_node_position(tech["grid_coords"])
		var node_end = node_pos + Vector2(300, 150)
		max_size.x = max(max_size.x, node_end.x)
		max_size.y = max(max_size.y, node_end.y)
		var node_panel = PanelContainer.new()
		node_panel.position = node_pos
		node_panel.custom_minimum_size = Vector2(210, 64)
		var node_style = StyleBoxFlat.new()
		node_style.bg_color = Color(0.18, 0.16, 0.14)
		node_style.set_corner_radius_all(32)  
		node_style.set_border_width_all(2)
		node_style.border_color = Color(0.35, 0.3, 0.24)
		node_style.set_content_margin_all(6)
		node_panel.add_theme_stylebox_override("panel", node_style)
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 8)
		node_panel.add_child(hbox)
		var icon_panel = PanelContainer.new()
		icon_panel.custom_minimum_size = Vector2(46, 46)
		var icon_style = StyleBoxFlat.new()
		icon_style.bg_color = Color(0.24, 0.22, 0.18)
		icon_style.set_corner_radius_all(23) 
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
		lbl_desc.text = "%s\n💎 Koszt: %d pkt" % [tech["desc"], tech["research_cost"]]
		lbl_desc.add_theme_font_size_override("font_size", 9)
		lbl_desc.add_theme_color_override("font_color", Color(0.75, 0.65, 0.85))
		vbox.add_child(lbl_desc)

		var invisible_button = Button.new()
		invisible_button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		invisible_button.flat = true
		node_panel.add_child(invisible_button)
		
		var reqs_ok = true
		for r in tech["req"]:
			if not EconomyManager.technology_tree[r]["unlocked"]: reqs_ok = false
				
		if tech["unlocked"]:
			node_style.border_color = Color(0.3, 0.75, 0.45) 
			node_style.bg_color = Color(0.12, 0.22, 0.15)
			invisible_button.disabled = true
		elif EconomyManager.current_research == tech_name:
			node_style.border_color = Color(0.85, 0.64, 0.22) 
			node_style.bg_color = Color(0.24, 0.2, 0.14)
			var current_science = EconomyManager.resources["Nauka"]
			var progress = tech["research_cost"] - EconomyManager.resources["Nauka"]
			progress = clamp(progress, 0, tech["research_cost"])
			lbl_title.text = "%s (%d tur)" % [tech_name, EconomyManager.research_turns_left]
			invisible_button.disabled = true
		elif not reqs_ok:
			node_panel.modulate.a = 0.35 
			invisible_button.disabled = true
		else:
			invisible_button.pressed.connect(func():
				EconomyManager.start_research(tech_name)
				refresh_technology_tree_view()
			)
		tech_tree_map.add_child(node_panel)
	tech_tree_map.custom_minimum_size = max_size

func refresh_culture_tree_view():
	if not culture_tree_map: return
	for child in culture_tree_map.get_children(): child.queue_free()
	culture_tree_map.queue_redraw()
	var max_size := Vector2.ZERO
	for tech_name in EconomyManager.culture_tree:
		var tech = EconomyManager.culture_tree[tech_name]
		var node_pos = _get_tech_node_position(tech["grid_coords"])
		var node_end = node_pos + Vector2(300, 150)
		max_size.x = max(max_size.x, node_end.x)
		max_size.y = max(max_size.y, node_end.y)
		var node_panel = PanelContainer.new()
		node_panel.position = node_pos
		node_panel.custom_minimum_size = Vector2(210, 64)
		var node_style = StyleBoxFlat.new()
		node_style.bg_color = Color(0.18, 0.16, 0.14)
		node_style.set_corner_radius_all(32)  
		node_style.set_border_width_all(2)
		node_style.border_color = Color(0.45, 0.25, 0.70)
		node_style.set_content_margin_all(6)
		node_panel.add_theme_stylebox_override("panel", node_style)
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 8)
		node_panel.add_child(hbox)
		var icon_panel = PanelContainer.new()
		icon_panel.custom_minimum_size = Vector2(46, 46)
		var icon_style = StyleBoxFlat.new()
		icon_style.bg_color = Color(0.24, 0.22, 0.18)
		icon_style.set_corner_radius_all(23) 
		icon_style.set_border_width_all(1)
		icon_style.border_color = Color(0.6, 0.3, 0.9)
		icon_panel.add_theme_stylebox_override("panel", icon_style)
		var icon_label = Label.new()
		icon_label.text = tech["icon"]
		icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		icon_label.add_theme_font_size_override("font_size", 18)
		icon_panel.add_child(icon_label)
		hbox.add_child(icon_panel)
		var vbox = VBoxContainer.new()
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		hbox.add_child(vbox)
		var lbl_title = Label.new()
		lbl_title.text = tech_name
		lbl_title.add_theme_font_size_override("font_size", 12)
		lbl_title.add_theme_color_override("font_color", Color(1.0, 0.85, 1.0))
		vbox.add_child(lbl_title)
		var lbl_desc = Label.new()
		lbl_desc.text = "%s\n💎 Koszt: %d pkt" % [tech["desc"], tech["research_cost"]]
		lbl_desc.add_theme_font_size_override("font_size", 9)
		lbl_desc.add_theme_color_override("font_color", Color(0.75, 0.65, 0.85))
		vbox.add_child(lbl_desc)

		var invisible_button = Button.new()
		invisible_button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		invisible_button.flat = true
		node_panel.add_child(invisible_button)
		
		var reqs_ok = true
		for r in tech["req"]:
			if not EconomyManager.culture_tree[r]["unlocked"]: reqs_ok = false
				
		if tech["unlocked"]:
			node_style.border_color = Color(0.5, 1.0, 0.6) 
			node_style.bg_color = Color(0.15, 0.22, 0.16)
			invisible_button.disabled = true
		elif EconomyManager.current_culture_research == tech_name:
			node_style.border_color = Color(0.85, 0.3, 1.0) 
			node_style.bg_color = Color(0.28, 0.18, 0.35)
			var current = EconomyManager.resources["Kultura"]
			var progress = tech["research_cost"] - EconomyManager.resources["Kultura"]
			progress = clamp(progress, 0, tech["research_cost"])
			lbl_title.text = "%s (%d tur)" % [tech_name, EconomyManager.culture_turns_left]
			invisible_button.disabled = true
		elif not reqs_ok:
			node_panel.modulate.a = 0.35 
			invisible_button.disabled = true
		else:
			invisible_button.pressed.connect(func():
				EconomyManager.start_culture_research(tech_name)
				refresh_culture_tree_view()
			)
		culture_tree_map.add_child(node_panel)
	culture_tree_map.custom_minimum_size = max_size

func show_context_menu(mouse_pos: Vector2, tile_pos: Vector2, tile_type: String, building_name: String, building_level: int, is_owned: bool, borders_owned: bool, deposit_size: String = "", fertility: float = 0.0) -> void:
	hide_all_menus()
	active_tile_pos = tile_pos
	active_tile_type = tile_type
	last_mouse_pos = mouse_pos
	
	var has_building = building_name != "Brak"
	var show_buildings = is_owned and not has_building
	
	menu_budowania.visible = show_buildings
	
	tile_info_menu.visible = true
	
	if has_building:
		info_label.text = "🏢 Budynek: %s (Lvl %d)\nPodłoże: %s" % [building_name, building_level, tile_type]
	elif tile_type == "Trawa":
		info_label.text = "🌱 Typ: %s\n✨ Żyzność pola: %d%%" % [tile_type, int(fertility * 100)]
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

	var show_upgrade = is_owned and has_building and building_name != "Centrum Miasta" and building_level < 3
	
	upgrade_button.visible = show_upgrade
	recruit_button.visible = (has_building and building_name == "Baraki" and is_owned)
	army_button.visible = (has_building and building_name == "Baraki" and is_owned)
	if show_upgrade:
		var can_upgrade = EconomyManager.can_afford_upgrade(building_name, building_level)
		upgrade_button.disabled = not can_upgrade
		upgrade_button.modulate.a = 1.0 if can_upgrade else 0.35
		var up_cost = EconomyManager.get_upgrade_cost(building_name, building_level)
	
	cat_zasobowe.visible = show_buildings
	cat_tech.visible = show_buildings
	cat_naukowe.visible = show_buildings
	cat_wojskowe.visible = show_buildings
	
	build_chata.visible = false
	build_iron.visible = false
	build_coal.visible = false
	build_farma.visible = false
	build_pastwisko.visible = false
	build_dom.visible = false
	btn_tech_1.visible = false
	btn_tech_2.visible = false
	btn_naukowy_1.visible = false
	btn_naukowy_2.visible = false
	build_baraki.visible = false
	build_akademia.visible = false
	
	if show_buildings:
		update_button_state(build_chata, "Chata Drwala", tile_type)
		update_button_state(build_iron, "Kopalnia Żelaza", tile_type)
		update_button_state(build_coal, "Kopalnia Węgla", tile_type)
		update_button_state(build_farma, "Farma", tile_type)
		update_button_state(build_pastwisko, "Pastwisko", tile_type)
		update_button_state(build_dom, "Dom mieszkalny", tile_type)
		update_button_state(btn_tech_1, "Laboratorium", tile_type)
		update_button_state(btn_tech_2, "Warsztat", tile_type)
		update_button_state(btn_naukowy_1, "Biblioteka", tile_type)
		update_button_state(btn_naukowy_2, "Świątynia", tile_type)
		update_button_state(build_baraki, "Baraki", tile_type)
		update_button_state(build_akademia, "Akademia generałów", tile_type)
		
		_show_building_category("zasobowe")
		
	_reposition_menu(tile_info_menu, mouse_pos)

func _show_building_category(category: String):
	var is_zasobowe = (category == "zasobowe")
	build_chata.visible = is_zasobowe
	build_iron.visible = is_zasobowe
	build_coal.visible = is_zasobowe
	build_farma.visible = is_zasobowe
	build_pastwisko.visible = is_zasobowe
	build_dom.visible = is_zasobowe
	
	var is_tech = (category == "tech")
	btn_tech_1.visible = is_tech
	btn_tech_2.visible = is_tech
	
	var is_naukowe = (category == "naukowe")
	btn_naukowy_1.visible = is_naukowe
	btn_naukowy_2.visible = is_naukowe

	var is_wojskowe = (category == "wojskowe")
	build_baraki.visible = is_wojskowe
	build_akademia.visible = is_wojskowe
	
	var selected_color = Color(0.75, 0.65, 0.5)
	var unselected_color = Color(0.65, 0.55, 0.4)
	
	var s_z = cat_zasobowe.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
	s_z.bg_color = selected_color if is_zasobowe else unselected_color
	cat_zasobowe.add_theme_stylebox_override("normal", s_z)
	
	var s_n = cat_naukowe.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
	s_n.bg_color = selected_color if is_naukowe else unselected_color
	cat_naukowe.add_theme_stylebox_override("normal", s_n)
	
	var s_t = cat_tech.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
	s_t.bg_color = selected_color if is_tech else unselected_color
	cat_tech.add_theme_stylebox_override("normal", s_t)

	var s_w = cat_wojskowe.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
	s_w.bg_color = selected_color if is_wojskowe else unselected_color
	cat_wojskowe.add_theme_stylebox_override("normal", s_w)

func show_city_creation_menu(_screen_pos: Vector2, tile_pos: Vector2) -> void:
	hide_all_menus()
	active_tile_pos = tile_pos
	var current_mouse_pos = get_viewport().get_mouse_position()
	var popup_rect = Rect2(current_mouse_pos + Vector2(10, 10), Vector2(170, 45))
	menu_zalozenia_miasta.popup(popup_rect)

func hide_all_menus():
	menu_budowania.visible = false
	if tile_info_menu: tile_info_menu.visible = false
	if menu_zalozenia_miasta: menu_zalozenia_miasta.visible = false
	if tech_tree_window: tech_tree_window.visible = false
	if culture_tree_window: culture_tree_window.visible = false
	if barracks_window: barracks_window.visible = false
	if army_window: army_window.visible = false

func any_menu_visible() -> bool:
	return menu_budowania.visible or (tile_info_menu and tile_info_menu.visible) or (menu_zalozenia_miasta and menu_zalozenia_miasta.visible) or (tech_tree_window and tech_tree_window.visible) or (culture_tree_window and culture_tree_window.visible) or (barracks_window and barracks_window.visible) or (army_window and army_window.visible)

func _reposition_menu(menu: Control, base_pos: Vector2):
	var vbox = menu.get_node("VBoxContainer") as VBoxContainer
	if vbox:
		vbox.queue_sort()
		menu.size = vbox.get_combined_minimum_size() + Vector2(24, 24)
	else: menu.reset_size()
		
	var screen_size = get_viewport_rect().size
	var menu_size = menu.size
	var final_x = base_pos.x + 10
	var final_y = base_pos.y + 10
	
	if final_x + menu_size.x > screen_size.x: final_x = base_pos.x - menu_size.x - 10
	if final_y + menu_size.y > screen_size.y: final_y = base_pos.y - menu_size.y - 10
		
	menu.global_position = Vector2(final_x, final_y)
	
	if menu == tile_info_menu and menu_budowania.visible:
		var build_menu_size = menu_budowania.get_combined_minimum_size()
		# Upewniamy się, że rozmiar menu jest użyty poprawnie, nawet jeśli layout jeszcze nie został w pełni zaktualizowany
		if build_menu_size.x < menu_budowania.size.x:
			build_menu_size.x = menu_budowania.size.x
		if build_menu_size.y < menu_budowania.size.y:
			build_menu_size.y = menu_budowania.size.y
			
		var build_menu_pos = Vector2(screen_size.x - 20 - build_menu_size.x, screen_size.y - 20 - build_menu_size.y)
		var build_menu_rect = Rect2(build_menu_pos, build_menu_size)
		var menu_rect = Rect2(menu.global_position, menu_size)
		
		if menu_rect.intersects(build_menu_rect):
			final_x = base_pos.x - menu_size.x - 10
			if final_x < 0:
				final_x = 10
			menu.global_position = Vector2(final_x, final_y)

func update_button_state(btn: Button, b_name: String, tile_type: String):
	var can_place = EconomyManager.can_afford_and_place(b_name, tile_type)
	btn.disabled = not can_place
	btn.modulate.a = 1.0 if can_place else 0.35

func execute_build(building_name: String) -> void:
	if active_tile_type != "Trawa" and building_name in ["Dom mieszkalny", "Laboratorium", "Warsztat", "Biblioteka", "Świątynia", "Baraki", "Akademia generałów"]:
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
	if resources_container:
		resource_labels["Drewno"].text = "Drewno: %d" % balances["Drewno"]
		resource_labels["Żelazo"].text = "Żelazo: %d" % balances["Żelazo"]
		resource_labels["Węgiel"].text = "Węgiel: %d" % balances["Węgiel"]
		resource_labels["Jedzenie"].text = "Jedzenie: %d" % balances["Jedzenie"]
		resource_labels["Złoto"].text = "Złoto: %d" % balances["Złoto"]
		resource_labels["Populacja"].text = "Pop: %d/%d" % [balances.get("Populacja", 1), balances.get("Maks_Populacja", 5)]
	else:
		resources_label.text = "🪵 Drewno: %d      ⛓️ Żelazo: %d      🌋 Węgiel: %d      🌾 Jedzenie: %d      🪙 Złoto: %d      👥 Pop: %d/%d" % [
			balances["Drewno"], balances["Żelazo"], balances["Węgiel"], balances["Jedzenie"], balances["Złoto"], balances.get("Populacja", 1), balances.get("Maks_Populacja", 5)
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
	
	if tech_tree_window and tech_tree_window.visible: refresh_technology_tree_view()

func _on_turn_pressed():
	hide_all_menus()
	if world_ref and world_ref.has_method("get_active_buildings_list"):
		var buildings = world_ref.get_active_buildings_list()
		EconomyManager.next_turn(buildings)

func style_main_hud_elements():
	var top_panel = $Panel
	top_panel.anchor_left = 0.0
	top_panel.anchor_right = 1.0
	top_panel.anchor_top = 0.0
	top_panel.anchor_bottom = 0.0
	top_panel.offset_left = 10
	top_panel.offset_right = -10
	top_panel.offset_top = 5
	top_panel.offset_bottom = 50
	
	var style_top = StyleBoxFlat.new()
	style_top.bg_color = Color(0.12, 0.13, 0.14, 0.98) 
	style_top.border_width_bottom = 3
	style_top.border_width_left = 3
	style_top.border_width_right = 3
	style_top.border_width_top = 3
	style_top.border_color = Color(0.4, 0.38, 0.33) 
	style_top.set_corner_radius_all(10)
	style_top.shadow_color = Color(0, 0, 0, 0.6)
	style_top.shadow_size = 4
	style_top.shadow_offset = Vector2(0, 3)
	top_panel.add_theme_stylebox_override("panel", style_top)
	
	resources_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resources_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	resources_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	resources_label.add_theme_font_size_override("font_size", 14)
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
	style_box.bg_color = Color(0.85, 0.78, 0.65, 1.0) # Parchment background
	style_box.set_border_width_all(4) 
	style_box.border_color = Color(0.3, 0.25, 0.2, 1.0) # Dark brown border
	style_box.set_corner_radius_all(8)
	style_box.set_content_margin_all(10)
	menu_budowania.add_theme_stylebox_override("panel", style_box)
	$MenuBudowania/VBoxContainer.add_theme_constant_override("separation", 8)
	
	var tab_style = StyleBoxFlat.new()
	tab_style.bg_color = Color(0.65, 0.55, 0.4)
	tab_style.set_corner_radius_all(6)
	tab_style.set_content_margin_all(8)
	tab_style.border_color = Color(0.3, 0.25, 0.2)
	tab_style.set_border_width_all(2)
	
	cat_zasobowe.add_theme_stylebox_override("normal", tab_style.duplicate())
	cat_naukowe.add_theme_stylebox_override("normal", tab_style.duplicate())
	cat_tech.add_theme_stylebox_override("normal", tab_style.duplicate())
	cat_wojskowe.add_theme_stylebox_override("normal", tab_style.duplicate())
	
	cat_zasobowe.add_theme_color_override("font_color", Color(0.2, 0.15, 0.1))
	cat_naukowe.add_theme_color_override("font_color", Color(0.2, 0.15, 0.1))
	cat_tech.add_theme_color_override("font_color", Color(0.2, 0.15, 0.1))
	cat_wojskowe.add_theme_color_override("font_color", Color(0.2, 0.15, 0.1))

func style_individual_buttons():
	style_single_button(build_chata, "Tartak", "Chata Drwala")
	style_single_button(build_iron, "Kopalnia Żelaza", "Kopalnia Żelaza")
	style_single_button(build_coal, "Kopalnia Węgla", "Kopalnia Węgla")
	style_single_button(build_farma, "Farma", "Farma")
	style_single_button(build_dom, "Dom mieszkalny", "Dom mieszkalny")
	style_single_button(btn_tech_1, "Laboratorium", "Laboratorium")
	style_single_button(btn_tech_2, "Warsztat", "Warsztat")
	style_single_button(btn_naukowy_1, "Biblioteka", "Biblioteka")
	style_single_button(btn_naukowy_2, "Świątynia", "Świątynia")
	style_single_button(build_baraki, "Baraki", "Baraki")
	style_single_button(build_akademia, "Akademia gen.", "Akademia generałów")

func style_single_button(btn: Button, display_name: String, building_name := ""):
	btn.text = ""
	btn.custom_minimum_size = Vector2(100, 100)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(vbox)
	
	var default_icon = null
	var icon = TextureRect.new()
	icon.texture = default_icon
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.custom_minimum_size = Vector2(40, 40)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var lbl = Label.new()
	lbl.text = display_name
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	vbox.add_child(icon)
	vbox.add_child(lbl)
	
	var base_color = Color(0.75, 0.65, 0.5)
	var hover_color = Color(0.85, 0.75, 0.6)
	
	var normal = StyleBoxFlat.new()
	normal.bg_color = base_color
	normal.set_corner_radius_all(6)
	normal.set_border_width_all(2)
	normal.border_color = Color(0.4, 0.35, 0.3)
	normal.set_content_margin_all(8)
	
	var hover = normal.duplicate() as StyleBoxFlat
	hover.bg_color = hover_color
	hover.border_color = Color(0.6, 0.55, 0.4)
	
	var disabled = StyleBoxFlat.new()
	disabled.bg_color = Color(0.6, 0.5, 0.4, 0.5) 
	disabled.set_corner_radius_all(6)
	disabled.content_margin_left = 12
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("disabled", disabled)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_disabled_color", Color(0.5, 0.5, 0.5))
	if building_name != "": btn.tooltip_text = EconomyManager.get_building_tooltip(building_name)
	disabled.set_border_width_all(2)
	disabled.border_color = Color(0.3, 0.25, 0.2, 0.5)
	disabled.set_content_margin_all(8)
	
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("disabled", disabled)
	btn.add_theme_color_override("font_color", Color(0.2, 0.15, 0.1))
	btn.add_theme_color_override("font_disabled_color", Color(0.3, 0.25, 0.2, 0.6))
	
	if building_name != "":
		btn.tooltip_text = EconomyManager.get_building_tooltip(building_name)

func load_unit_data():
	var file = FileAccess.open("res://assets/json/unit_types.json", FileAccess.READ)
	if file:
		var content = file.get_as_text()
		var json = JSON.new()
		var error = json.parse(content)
		if error == OK:
			unit_data_json = json.data
		file.close()

func setup_barracks_window():
	barracks_window = PanelContainer.new()
	barracks_window.visible = false
	barracks_window.custom_minimum_size = Vector2(800, 500)
	
	var style_panel = StyleBoxFlat.new()
	style_panel.bg_color = Color(0.12, 0.16, 0.18, 0.95)
	style_panel.set_corner_radius_all(10)
	style_panel.set_border_width_all(2)
	style_panel.border_color = Color(0.8, 0.2, 0.2, 0.8)
	style_panel.content_margin_left = 20
	style_panel.content_margin_right = 20
	style_panel.content_margin_top = 20
	style_panel.content_margin_bottom = 20
	barracks_window.add_theme_stylebox_override("panel", style_panel)
	
	barracks_content_vbox = VBoxContainer.new()
	barracks_content_vbox.add_theme_constant_override("separation", 15)
	barracks_window.add_child(barracks_content_vbox)
	
	add_child(barracks_window)

func show_barracks_menu():
	barracks_window.visible = true
	var viewport_size = get_viewport_rect().size
	barracks_window.position = (viewport_size - barracks_window.custom_minimum_size) / 2.0
	
	var humans_faction = null
	if unit_data_json.has("factions"):
		for faction in unit_data_json["factions"]:
			if faction.get("id") == "humans":
				humans_faction = faction
				break
				
	if humans_faction != null:
		_populate_barracks_units(humans_faction)

func _populate_barracks_units(faction: Dictionary):
	for child in barracks_content_vbox.get_children():
		child.queue_free()
		
	var header_hbox = HBoxContainer.new()
	header_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(80, 40)
	
	var title_label = Label.new()
	title_label.text = "Jednostki: " + faction["name"]
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	var close_btn = Button.new()
	close_btn.text = "Zamknij"
	close_btn.custom_minimum_size = Vector2(80, 40)
	close_btn.pressed.connect(func(): barracks_window.visible = false)
	
	header_hbox.add_child(spacer)
	header_hbox.add_child(title_label)
	header_hbox.add_child(close_btn)
	barracks_content_vbox.add_child(header_hbox)
	
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	barracks_content_vbox.add_child(scroll)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)
	
	if faction.has("units"):
		for unit in faction["units"]:
			var panel = PanelContainer.new()
			var p_style = StyleBoxFlat.new()
			p_style.bg_color = Color(0.2, 0.2, 0.25)
			p_style.set_content_margin_all(10)
			panel.add_theme_stylebox_override("panel", p_style)
			
			var hbox = HBoxContainer.new()
			hbox.add_theme_constant_override("separation", 15)
			panel.add_child(hbox)
			
			var img_rect = TextureRect.new()
			var tex = load(unit["portrait"]) if unit.has("portrait") else null
			if tex: img_rect.texture = tex
			img_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			img_rect.custom_minimum_size = Vector2(64, 64)
			img_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			hbox.add_child(img_rect)
			
			var info_vbox = VBoxContainer.new()
			info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			info_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
			hbox.add_child(info_vbox)
			
			var name_lbl = Label.new()
			name_lbl.text = unit["name"] + " (" + unit.get("role", "") + ")"
			name_lbl.add_theme_font_size_override("font_size", 18)
			info_vbox.add_child(name_lbl)
			
			var stats_lbl = Label.new()
			stats_lbl.text = "HP: %d | DMG: %d | DEF: %d | RUCH: %d" % [unit.get("hp", 0), unit.get("dmg", 0), unit.get("def", 0), unit.get("move_range", 0)]
			stats_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
			info_vbox.add_child(stats_lbl)
			
			var btn_recruit = Button.new()
			var cost = EconomyManager.calculate_unit_cost(unit)
			btn_recruit.text = "Zwerbuj"
			btn_recruit.tooltip_text = "Koszt:\n%d Złota\n%d Żelaza\n%d Jedzenia\n%d Populacji" % [cost.get("Złoto", 0), cost.get("Żelazo", 0), cost.get("Jedzenie", 0), cost.get("Populacja", 0)]
			btn_recruit.custom_minimum_size = Vector2(150, 40)
			btn_recruit.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			if EconomyManager.can_recruit_unit(unit):
				btn_recruit.pressed.connect(func():
					EconomyManager.recruit_unit(unit)
					_populate_barracks_units(faction)
				)
				var style_ok = StyleBoxFlat.new()
				style_ok.bg_color = Color(0.2, 0.6, 0.2)
				style_ok.set_corner_radius_all(4)
				btn_recruit.add_theme_stylebox_override("normal", style_ok)
			else:
				btn_recruit.disabled = true
			
			hbox.add_child(btn_recruit)
			
			vbox.add_child(panel)

func setup_army_window():
	army_window = PanelContainer.new()
	army_window.visible = false
	army_window.custom_minimum_size = Vector2(800, 500)
	
	var style_panel = StyleBoxFlat.new()
	style_panel.bg_color = Color(0.12, 0.16, 0.22, 0.95)
	style_panel.set_corner_radius_all(10)
	style_panel.set_border_width_all(2)
	style_panel.border_color = Color(0.2, 0.6, 1.0, 0.8)
	style_panel.content_margin_left = 20
	style_panel.content_margin_right = 20
	style_panel.content_margin_top = 20
	style_panel.content_margin_bottom = 20
	army_window.add_theme_stylebox_override("panel", style_panel)
	
	army_content_vbox = VBoxContainer.new()
	army_content_vbox.add_theme_constant_override("separation", 15)
	army_window.add_child(army_content_vbox)
	
	add_child(army_window)

func show_army_menu():
	army_window.visible = true
	var viewport_size = get_viewport_rect().size
	army_window.position = (viewport_size - army_window.custom_minimum_size) / 2.0
	_populate_army()

func _populate_army():
	for child in army_content_vbox.get_children():
		child.queue_free()
		
	var header_hbox = HBoxContainer.new()
	header_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	var title_label = Label.new()
	title_label.text = "Moja Armia"
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	var close_btn = Button.new()
	close_btn.text = "Zamknij"
	close_btn.custom_minimum_size = Vector2(80, 40)
	close_btn.pressed.connect(func(): army_window.visible = false)
	
	var clear_all_btn = Button.new()
	clear_all_btn.text = "Zwolnij armię"
	clear_all_btn.custom_minimum_size = Vector2(120, 40)
	clear_all_btn.pressed.connect(func():
		var dialog = ConfirmationDialog.new()
		dialog.title = "Potwierdzenie"
		dialog.dialog_text = "Czy na pewno chcesz zwolnić całą armię?"
		dialog.confirmed.connect(func():
			EconomyManager.clear_army()
			_populate_army()
			dialog.queue_free()
		)
		dialog.canceled.connect(func(): dialog.queue_free())
		add_child(dialog)
		dialog.popup_centered()
	)
	if EconomyManager.player_army.is_empty():
		clear_all_btn.disabled = true
	
	header_hbox.add_child(clear_all_btn)
	header_hbox.add_child(title_label)
	header_hbox.add_child(close_btn)
	army_content_vbox.add_child(header_hbox)
	
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	army_content_vbox.add_child(scroll)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)
	
	var army_list = EconomyManager.player_army
	if army_list.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.text = "Nie posiadasz jeszcze żadnych zwerbowanych jednostek."
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.add_theme_font_size_override("font_size", 18)
		empty_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		vbox.add_child(empty_lbl)
	else:
		var grouped_army = {}
		for unit in army_list:
			var u_name = unit.get("name", "Nieznana")
			var turns_in = unit.get("turns_in_recruitment", 0)
			var turns_to = unit.get("turns_to_recruit", 0)
			var is_recruiting = turns_in < turns_to
			
			var group_key = u_name
			if is_recruiting:
				group_key = "%s_%d" % [u_name, turns_in]
				
			if not grouped_army.has(group_key):
				grouped_army[group_key] = {"unit": unit, "count": 1, "is_recruiting": is_recruiting, "turns_in": turns_in, "turns_to": turns_to}
			else:
				grouped_army[group_key]["count"] += 1
				
		for group in grouped_army.values():
			var unit = group["unit"]
			var count = group["count"]
			var is_recruiting = group["is_recruiting"]
			var turns_in = group["turns_in"]
			var turns_to = group["turns_to"]
			
			var panel = PanelContainer.new()
			var p_style = StyleBoxFlat.new()
			p_style.bg_color = Color(0.15, 0.25, 0.3)
			if is_recruiting:
				p_style.bg_color = Color(0.1, 0.15, 0.2)
			p_style.set_content_margin_all(10)
			panel.add_theme_stylebox_override("panel", p_style)
			
			var hbox = HBoxContainer.new()
			hbox.add_theme_constant_override("separation", 15)
			panel.add_child(hbox)
			
			var img_rect = TextureRect.new()
			var tex = load(unit["portrait"]) if unit.has("portrait") else null
			if tex: img_rect.texture = tex
			img_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			img_rect.custom_minimum_size = Vector2(64, 64)
			img_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			
			var img_container = Control.new()
			img_container.custom_minimum_size = Vector2(64, 64)
			
			img_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
			img_container.add_child(img_rect)
			
			if is_recruiting:
				img_rect.modulate = Color(0.4, 0.4, 0.4, 1.0)
				var ring_ctrl = Control.new()
				ring_ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
				ring_ctrl.draw.connect(func():
					var center = ring_ctrl.size / 2.0
					var radius = min(ring_ctrl.size.x, ring_ctrl.size.y) / 2.0 + 2.0
					var angle = (float(turns_in) / float(turns_to)) * TAU
					ring_ctrl.draw_arc(center, radius, -PI/2, -PI/2 + angle, 32, Color(0.2, 0.8, 0.2), 4.0, true)
					ring_ctrl.draw_arc(center, radius, -PI/2 + angle, -PI/2 + TAU, 32, Color(0.3, 0.3, 0.3), 4.0, true)
				)
				img_container.add_child(ring_ctrl)
			
			hbox.add_child(img_container)
			
			var info_vbox = VBoxContainer.new()
			info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			info_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
			hbox.add_child(info_vbox)
			
			var name_lbl = Label.new()
			var name_text = unit["name"] + " (" + unit.get("role", "") + ") x" + str(count)
			if is_recruiting:
				name_text += " [Rekrutacja: %d/%d tur]" % [turns_in, turns_to]
			name_lbl.text = name_text
			name_lbl.add_theme_font_size_override("font_size", 18)
			if is_recruiting:
				name_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
			info_vbox.add_child(name_lbl)
			
			var stats_lbl = Label.new()
			stats_lbl.text = "HP: %d | DMG: %d | DEF: %d | RUCH: %d" % [unit.get("hp", 0), unit.get("dmg", 0), unit.get("def", 0), unit.get("move_range", 0)]
			stats_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8) if not is_recruiting else Color(0.5, 0.5, 0.5))
			info_vbox.add_child(stats_lbl)
			
			var delete_unit_btn = Button.new()
			delete_unit_btn.text = "Usuń"
			delete_unit_btn.custom_minimum_size = Vector2(80, 40)
			delete_unit_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			delete_unit_btn.pressed.connect(func():
				EconomyManager.remove_unit(unit)
				_populate_army()
			)
			hbox.add_child(delete_unit_btn)
			
			vbox.add_child(panel)
