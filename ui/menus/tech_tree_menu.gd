class_name TechTreeMenu
extends RefCounted

var hud: Control
var tech_tree_button: Button
var tech_tree_window: Panel
var tech_tree_map: Control
var insufficient_points_dialog: AcceptDialog

const X_SPACING: float = 280.0
const Y_SPACING: float = 95.0
const OFFSET_POS: Vector2 = Vector2(80, -20)

func _init(_hud: Control):
	hud = _hud

func setup_tech_tree_ui():
	tech_tree_window = hud.get_node("TechTreeWindow")
	tech_tree_map = hud.get_node("TechTreeWindow/ScrollContainer/TechTreeMap")

	tech_tree_button = Button.new()
	tech_tree_button.text = "Drzewo Technologii"
	tech_tree_button.custom_minimum_size = Vector2(0, 40)
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.1, 0.16, 0.22, 0.95)
	btn_style.set_border_width_all(1)
	btn_style.border_color = hud.DF_GOLD
	btn_style.set_corner_radius_all(4)
	tech_tree_button.add_theme_stylebox_override("normal", btn_style)
	var btn_style_hover = btn_style.duplicate() as StyleBoxFlat
	btn_style_hover.bg_color = Color(0.15, 0.22, 0.3, 0.95)
	btn_style_hover.border_color = hud.DF_GOLD_BRIGHT
	tech_tree_button.add_theme_stylebox_override("hover", btn_style_hover)
	tech_tree_button.add_theme_color_override("font_color", hud.DF_TEXT)
	var vbox = hud.points_panel.get_child(0)
	vbox.add_child(tech_tree_button)
	
	if tech_tree_window:
		tech_tree_window.visible = false
		tech_tree_window.z_index = 10
		var style_tree = StyleBoxFlat.new()
		style_tree.bg_color = hud.DF_BG
		style_tree.set_border_width_all(3)
		style_tree.border_color = hud.DF_GOLD
		style_tree.set_corner_radius_all(4)
		tech_tree_window.add_theme_stylebox_override("panel", style_tree)
		var close_btn = tech_tree_window.get_node_or_null("CloseButton")
		if close_btn: 
			close_btn.pressed.connect(func(): tech_tree_window.visible = false)
			close_btn.text = "X"
			close_btn.custom_minimum_size = Vector2(35, 35)
			close_btn.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
			close_btn.offset_left = -45
			close_btn.offset_top = 10
			close_btn.offset_right = -10
			close_btn.offset_bottom = 45
			if hud.has_method("_style_df_button"):
				hud._style_df_button(close_btn)
			
			# Przesunięcie na koniec drzewa, by ScrollContainer nie blokował kliknięć
			close_btn.get_parent().move_child(close_btn, -1)
		var scroll = tech_tree_window.get_node_or_null("ScrollContainer")
		if scroll:
			scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
			scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	if tech_tree_map: tech_tree_map.draw.connect(_draw_tech_connections)

	# Dialog pokazywany, gdy kliknięcie węzła technologii nie mogło
	# rozpocząć badania (np. za mało punktów Nauki) — wcześniej takie
	# kliknięcie nie dawało żadnej reakcji, co wyglądało jak zepsuty przycisk.
	insufficient_points_dialog = AcceptDialog.new()
	insufficient_points_dialog.title = "Za mało punktów"
	insufficient_points_dialog.dialog_text = "Nie masz wystarczającej liczby punktów Nauki, aby rozpocząć to badanie."
	insufficient_points_dialog.ok_button_text = "Zrozumiałem"
	hud.add_child(insufficient_points_dialog)

	tech_tree_button.pressed.connect(func():
		hud.hide_all_menus()
		if tech_tree_window:
			tech_tree_window.visible = true
			tech_tree_window.custom_minimum_size = Vector2(900, 600)
			tech_tree_window.size = Vector2(900, 600)
			var screen_center = hud.get_viewport_rect().size / 2
			tech_tree_window.global_position = screen_center - (tech_tree_window.size / 2)
			refresh_technology_tree_view()
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
		var current_cost = EconomyManager.get_tech_cost(tech_name)
		lbl_desc.text = "%s\n💎 Koszt: %d pkt" % [tech["desc"], current_cost]
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
			var progress = EconomyManager.get_tech_cost(tech_name) - EconomyManager.resources["Nauka"]
			progress = clamp(progress, 0, EconomyManager.get_tech_cost(tech_name))
			lbl_title.text = "%s (%d tur)" % [tech_name, EconomyManager.research_turns_left]
			invisible_button.disabled = true
		elif not reqs_ok:
			node_panel.modulate.a = 0.35 
			invisible_button.disabled = true
		else:
			invisible_button.pressed.connect(func():
				if EconomyManager.current_research != "":
					insufficient_points_dialog.title = "Trwają badania"
					insufficient_points_dialog.dialog_text = "Nie możesz rozpocząć nowego badania, dopóki obecne się nie zakończy."
					insufficient_points_dialog.popup_centered()
				elif EconomyManager.start_research(tech_name):
					refresh_technology_tree_view()
				else:
					insufficient_points_dialog.title = "Za mało punktów"
					insufficient_points_dialog.dialog_text = "Nie masz wystarczającej liczby punktów Nauki, aby rozpocząć to badanie."
					insufficient_points_dialog.popup_centered()
			)
		tech_tree_map.add_child(node_panel)
	tech_tree_map.custom_minimum_size = max_size
