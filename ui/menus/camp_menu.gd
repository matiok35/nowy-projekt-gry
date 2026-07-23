class_name CampMenu
extends RefCounted

var hud: Control
var camp_details_window: PanelContainer
var camp_army_window: PanelContainer

var faction_lore: Dictionary = {}

func _init(_hud: Control):
	hud = _hud
	faction_lore = load_faction_lore()

func setup_camp_windows():
	camp_details_window = PanelContainer.new()
	camp_details_window.visible = false
	camp_details_window.custom_minimum_size = Vector2(700, 450)
	var style_panel = StyleBoxFlat.new()
	style_panel.bg_color = Color(0.13, 0.07, 0.07, 0.96)
	style_panel.set_corner_radius_all(10)
	style_panel.set_border_width_all(2)
	style_panel.border_color = hud.DF_GOLD
	style_panel.set_content_margin_all(20)
	style_panel.shadow_color = Color(0, 0, 0, 0.55)
	style_panel.shadow_size = 6
	camp_details_window.add_theme_stylebox_override("panel", style_panel)
	hud.add_child(camp_details_window)

	camp_army_window = PanelContainer.new()
	camp_army_window.visible = false
	camp_army_window.custom_minimum_size = Vector2(800, 500)
	var style_army = style_panel.duplicate()
	style_army.bg_color = Color(0.16, 0.08, 0.08, 0.96)
	camp_army_window.add_theme_stylebox_override("panel", style_army)
	hud.add_child(camp_army_window)

func show_camp_details_menu(pos: Vector2):
	camp_details_window.visible = true
	var viewport_size = hud.get_viewport_rect().size
	camp_details_window.position = (viewport_size - camp_details_window.custom_minimum_size) / 2.0
	
	for child in camp_details_window.get_children():
		child.queue_free()
		
	var camp_data = hud.world_ref.camps[pos] if hud.world_ref and hud.world_ref.get("camps") and hud.world_ref.camps.has(pos) else {}
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	camp_details_window.add_child(vbox)
	
	var header_hbox = HBoxContainer.new()
	var title_lbl = Label.new()
	title_lbl.text = "Obozowisko: " + camp_data.get("faction_name", "Nieznana") + " (Poziom " + str(camp_data.get("level", 1)) + ")"
	if camp_data.get("is_boss", false):
		title_lbl.text = "👑 OSTATECZNY BOSS 👑\n" + title_lbl.text
	title_lbl.add_theme_font_size_override("font_size", 24)
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var close_btn = Button.new()
	close_btn.text = "Zamknij"
	close_btn.custom_minimum_size = Vector2(80, 40)
	close_btn.pressed.connect(func(): camp_details_window.visible = false)
	header_hbox.add_child(title_lbl)
	header_hbox.add_child(close_btn)
	vbox.add_child(header_hbox)
	
	var lore_lbl = RichTextLabel.new()
	var f_id = camp_data.get("faction", "")
	lore_lbl.text = faction_lore.get(f_id, "Nieznana frakcja, ostrożnie!")
	lore_lbl.fit_content = true
	lore_lbl.add_theme_font_size_override("normal_font_size", 16)
	lore_lbl.add_theme_color_override("default_color", Color(0.8, 0.8, 0.8))
	vbox.add_child(lore_lbl)
	
	var res_hbox = HBoxContainer.new()
	res_hbox.add_theme_constant_override("separation", 20)
	var r = camp_data.get("resources", {})
	var r_lbl = Label.new()
	r_lbl.text = "Zgromadzone surowce:\n💰 Złoto: %d\n🪵 Drewno: %d\n⛏️ Żelazo: %d" % [r.get("gold", 0), r.get("wood", 0), r.get("iron", 0)]
	r_lbl.add_theme_color_override("font_color", Color(0.9, 0.85, 0.4))
	r_lbl.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	r_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	res_hbox.add_child(r_lbl)
	
	var t_lbl = Label.new()
	t_lbl.text = "Kontrolowane ziemie:\n"
	t_lbl.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	t_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var tiles_owned = []
	if hud.world_ref and hud.world_ref.get("camp_tile_owner") and not hud.world_ref.camp_tile_owner.is_empty():
		# Dokładna lista pól faktycznie należących do TEGO obozowiska
		# (uwzględnia też pola zdobyte później przez powolną ekspansję).
		for t in hud.world_ref.camp_tile_owner.keys():
			if hud.world_ref.camp_tile_owner[t] == pos:
				if hud.world_ref.map_data.has(t) and not tiles_owned.has(t):
					tiles_owned.append(hud.world_ref.map_data[t]["type"])
	elif hud.world_ref and hud.world_ref.get("camp_owned_tiles"):
		# Fallback dla starszych zapisów bez camp_tile_owner - przybliżenie
		# po dystansie od centrum obozowiska, tak jak wcześniej.
		for t in hud.world_ref.camp_owned_tiles:
			var center_dist = HexUtils.get_distance(t, pos)
			if center_dist <= camp_data.get("level", 1) + 1:
				if hud.world_ref.map_data.has(t) and not tiles_owned.has(t):
					tiles_owned.append(hud.world_ref.map_data[t]["type"])
	
	var type_counts = {}
	for type in tiles_owned:
		if type == "Trawa": continue
		if not type_counts.has(type): type_counts[type] = 0
		type_counts[type] += 1
		
	if type_counts.is_empty():
		t_lbl.text += "Brak specjalnych złóż"
	else:
		for type in type_counts:
			t_lbl.text += "  %d x %s\n" % [type_counts[type], type]
	
	res_hbox.add_child(t_lbl)
	vbox.add_child(res_hbox)
	
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)
	
	var army_btn = Button.new()
	army_btn.text = "⚔️ Pokaż armię"
	army_btn.custom_minimum_size = Vector2(200, 50)
	army_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var army_style = StyleBoxFlat.new()
	army_style.bg_color = Color(0.6, 0.2, 0.2)
	army_style.set_corner_radius_all(6)
	army_btn.add_theme_stylebox_override("normal", army_style)
	army_btn.pressed.connect(func():
		show_camp_army_menu(camp_data.get("army", []), func():
			if hud.world_ref and hud.world_ref.has_method("destroy_camp"):
				hud.world_ref.destroy_camp(pos)
			camp_details_window.visible = false
			if hud.has_method("execute_battle_rewards"):
				hud.execute_battle_rewards(camp_data)
		, func():
			camp_details_window.visible = false
			if hud.has_method("handle_battle_loss"):
				hud.handle_battle_loss()
		)
	)
	vbox.add_child(army_btn)

func show_camp_army_menu(enemy_army_raw: Array, win_callback: Callable, lose_callback: Callable):
	var enemy_army = []
	for u in enemy_army_raw:
		if typeof(u) == TYPE_DICTIONARY:
			enemy_army.append(u)
		else:
			var found = false
			if hud.get("unit_data_json") and hud.unit_data_json.has("factions"):
				for f in hud.unit_data_json["factions"]:
					if f.has("units"):
						for ud in f["units"]:
							if ud.get("id") == u:
								enemy_army.append(ud)
								found = true
								break
					if found: break
			if not found:
				enemy_army.append({"name": str(u), "hp": 0, "dmg": 0})

	camp_details_window.visible = false
	camp_army_window.visible = true
	var viewport_size = hud.get_viewport_rect().size
	camp_army_window.position = (viewport_size - camp_army_window.custom_minimum_size) / 2.0
	
	for child in camp_army_window.get_children():
		child.queue_free()
		
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	camp_army_window.add_child(vbox)
	
	var header_hbox = HBoxContainer.new()
	var title_lbl = Label.new()
	title_lbl.text = "Armia Obozowiska"
	title_lbl.add_theme_font_size_override("font_size", 24)
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	var close_btn = Button.new()
	close_btn.text = "Zamknij"
	close_btn.custom_minimum_size = Vector2(80, 40)
	close_btn.pressed.connect(func(): camp_army_window.visible = false)
	
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(80, 40)
	
	header_hbox.add_child(spacer)
	header_hbox.add_child(title_lbl)
	header_hbox.add_child(close_btn)
	vbox.add_child(header_hbox)
	
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)
	
	var list_vbox = VBoxContainer.new()
	list_vbox.add_theme_constant_override("separation", 10)
	list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list_vbox)
	
	if enemy_army.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.text = "Brak jednostek w armii."
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		list_vbox.add_child(empty_lbl)
	else:
		var unique_units = []
		var unit_counts = {}
		
		for unit in enemy_army:
			var u_id = unit.get("id", unit.get("name", "Unknown"))
			if not unit_counts.has(u_id):
				unit_counts[u_id] = 0
				unique_units.append(unit)
			unit_counts[u_id] += 1

		for unit in unique_units:
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
			var u_id = unit.get("id", unit.get("name", "Unknown"))
			var count = unit_counts[u_id]
			name_lbl.text = unit.get("name", "Nieznany")
			if count > 1:
				name_lbl.text += " x" + str(count)
			if unit.has("role") and unit["role"] != "":
				name_lbl.text += " (" + unit["role"] + ")"
			name_lbl.add_theme_font_size_override("font_size", 18)
			info_vbox.add_child(name_lbl)
			
			var stats_lbl = Label.new()
			stats_lbl.text = "HP: %d | DMG: %d | DEF: %d | RUCH: %d" % [unit.get("hp", 0), unit.get("dmg", 0), unit.get("def", 0), unit.get("move_range", 0)]
			stats_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
			info_vbox.add_child(stats_lbl)
			
			list_vbox.add_child(panel)

func load_faction_lore() -> Dictionary:
	var path = "res://data/faction_lore.json"
	if not FileAccess.file_exists(path):
		return {}
	var file = FileAccess.open(path, FileAccess.READ)
	if not file: return {}
	var txt = file.get_as_text()
	file.close()
	var parser = JSON.new()
	if parser.parse(txt) == OK:
		var parsed = parser.get_data()
		if typeof(parsed) == TYPE_DICTIONARY:
			return parsed
	return {}
