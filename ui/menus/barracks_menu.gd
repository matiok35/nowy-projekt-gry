class_name BarracksMenu
extends RefCounted

var hud: Control
var barracks_window: PanelContainer
var barracks_content_vbox: VBoxContainer

func _init(_hud: Control):
	hud = _hud

func setup_barracks_window():
	barracks_window = PanelContainer.new()
	barracks_window.visible = false
	barracks_window.custom_minimum_size = Vector2(800, 500)
	
	var style_panel = StyleBoxFlat.new()
	style_panel.bg_color = hud.DF_BG
	style_panel.set_corner_radius_all(10)
	style_panel.set_border_width_all(2)
	style_panel.border_color = hud.DF_GOLD
	style_panel.content_margin_left = 20
	style_panel.content_margin_right = 20
	style_panel.content_margin_top = 20
	style_panel.content_margin_bottom = 20
	style_panel.shadow_color = Color(0, 0, 0, 0.55)
	style_panel.shadow_size = 6
	barracks_window.add_theme_stylebox_override("panel", style_panel)
	
	barracks_content_vbox = VBoxContainer.new()
	barracks_content_vbox.add_theme_constant_override("separation", 15)
	barracks_window.add_child(barracks_content_vbox)
	
	hud.add_child(barracks_window)

func show_barracks_menu():
	barracks_window.visible = true
	var viewport_size = hud.get_viewport_rect().size
	barracks_window.position = (viewport_size - barracks_window.custom_minimum_size) / 2.0
	
	var humans_faction = null
	if hud.unit_data_json.has("factions"):
		for faction in hud.unit_data_json["factions"]:
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
			var base_hp = unit.get("hp", 0)
			var base_dmg = unit.get("dmg", 0)
			var base_def = unit.get("def", 0)
			var b_hp = EconomyManager.army_bonus_hp
			var b_dmg = EconomyManager.army_bonus_dmg
			var b_def = EconomyManager.army_bonus_def
			
			var hp_text = str(base_hp) if b_hp == 0 else "%d(+%d)" % [base_hp + b_hp, b_hp]
			var dmg_text = str(base_dmg) if b_dmg == 0 else "%d(+%d)" % [base_dmg + b_dmg, b_dmg]
			var def_text = str(base_def) if b_def == 0 else "%d(+%d)" % [base_def + b_def, b_def]
			
			stats_lbl.text = "HP: %s | DMG: %s | DEF: %s | RUCH: %d" % [hp_text, dmg_text, def_text, unit.get("move_range", 0)]
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
					var unit_name = unit.get("name", "")
					if unit_name == "Konnica" and EconomyManager.technology_tree.has("Konnica") and not EconomyManager.technology_tree["Konnica"]["unlocked"]:
						hud.tech_warning_dialog.dialog_text = "Aby zwerbować tę jednostkę, musisz najpierw odkryć technologię:\nKonnica"
						hud.tech_warning_dialog.popup_centered()
						return
					elif unit_name == "Magowie" and EconomyManager.technology_tree.has("Mag") and not EconomyManager.technology_tree["Mag"]["unlocked"]:
						hud.tech_warning_dialog.dialog_text = "Aby zwerbować tę jednostkę, musisz najpierw odkryć technologię:\nMag"
						hud.tech_warning_dialog.popup_centered()
						return

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

func upgrade_barracks_units() -> void:
	EconomyManager.army_bonus_hp += 5
	EconomyManager.army_bonus_dmg += 2
	EconomyManager.army_bonus_def += 1
	
	for unit in EconomyManager.player_army:
		if unit.has("hp"): unit["hp"] += 5
		if unit.has("dmg"): unit["dmg"] += 2
		if unit.has("def"): unit["def"] += 1
