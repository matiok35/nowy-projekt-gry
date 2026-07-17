class_name LibraryResearchMenu
extends RefCounted

var hud: Control
var library_window: PanelContainer
var list_vbox: VBoxContainer

func _init(_hud: Control):
	hud = _hud

func setup_library_window():
	library_window = PanelContainer.new()
	library_window.visible = false
	library_window.custom_minimum_size = Vector2(620, 480)

	var style_panel = StyleBoxFlat.new()
	style_panel.bg_color = hud.DF_BG
	style_panel.set_corner_radius_all(10)
	style_panel.set_border_width_all(2)
	style_panel.border_color = hud.DF_GOLD
	style_panel.content_margin_left = 20
	style_panel.content_margin_right = 20
	style_panel.content_margin_top = 18
	style_panel.content_margin_bottom = 18
	style_panel.shadow_color = Color(0, 0, 0, 0.55)
	style_panel.shadow_size = 6
	library_window.add_theme_stylebox_override("panel", style_panel)

	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 12)
	library_window.add_child(main_vbox)

	# HEADER
	var header_hbox = HBoxContainer.new()
	var title_label = Label.new()
	title_label.text = "📚 Biblioteka — Badanie Umiejętności"
	title_label.add_theme_font_size_override("font_size", 22)
	title_label.add_theme_color_override("font_color", hud.DF_GOLD_TEXT)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var close_btn = Button.new()
	close_btn.text = "X"
	close_btn.custom_minimum_size = Vector2(30, 30)
	close_btn.pressed.connect(func(): library_window.visible = false)
	hud._style_df_button(close_btn)
	header_hbox.add_child(title_label)
	header_hbox.add_child(close_btn)
	main_vbox.add_child(header_hbox)

	var desc_label = Label.new()
	desc_label.text = "Odblokuj umiejętności jednostek za Złoto i punkty technologii. Raz zbadana umiejętność pozostaje odblokowana na stałe."
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_label.add_theme_font_size_override("font_size", 13)
	desc_label.add_theme_color_override("font_color", hud.DF_TEXT)
	main_vbox.add_child(desc_label)

	var sep = HSeparator.new()
	sep.add_theme_color_override("separator", hud.DF_GOLD)
	main_vbox.add_child(sep)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_vbox.add_child(scroll)

	list_vbox = VBoxContainer.new()
	list_vbox.add_theme_constant_override("separation", 10)
	list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list_vbox)

	hud.add_child(library_window)

func _populate_list() -> void:
	for child in list_vbox.get_children():
		child.queue_free()

	for skill_id in EconomyManager.skill_tree.keys():
		var skill = EconomyManager.skill_tree[skill_id]

		var panel = PanelContainer.new()
		var p_style = StyleBoxFlat.new()
		p_style.bg_color = Color(0.16, 0.14, 0.12, 0.95) if not skill["unlocked"] else Color(0.12, 0.2, 0.14, 0.95)
		p_style.set_border_width_all(1)
		p_style.border_color = hud.DF_GOLD if not skill["unlocked"] else Color(0.4, 0.75, 0.45)
		p_style.set_corner_radius_all(6)
		p_style.set_content_margin_all(10)
		panel.add_theme_stylebox_override("panel", p_style)

		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 12)
		panel.add_child(hbox)

		var info_vbox = VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(info_vbox)

		var name_lbl = Label.new()
		name_lbl.text = "%s  (%s)" % [skill["name"], skill["unit"]]
		name_lbl.add_theme_font_size_override("font_size", 16)
		name_lbl.add_theme_color_override("font_color", hud.DF_GOLD_TEXT)
		info_vbox.add_child(name_lbl)

		var desc_lbl = Label.new()
		desc_lbl.text = skill["desc"]
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		desc_lbl.add_theme_font_size_override("font_size", 12)
		desc_lbl.add_theme_color_override("font_color", Color(0.75, 0.7, 0.65))
		info_vbox.add_child(desc_lbl)

		var cost_lbl = Label.new()
		if skill["unlocked"]:
			cost_lbl.text = "✅ Odkryta"
			cost_lbl.add_theme_color_override("font_color", Color(0.55, 0.85, 0.55))
		else:
			cost_lbl.text = "Koszt: 🪙 %d Złota, 🔬 %d punktów technologii" % [skill["cost_gold"], skill["cost_tech"]]
			cost_lbl.add_theme_color_override("font_color", Color(0.85, 0.75, 0.4))
		cost_lbl.add_theme_font_size_override("font_size", 12)
		info_vbox.add_child(cost_lbl)

		var research_btn = Button.new()
		research_btn.custom_minimum_size = Vector2(120, 44)
		research_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		if skill["unlocked"]:
			research_btn.text = "Odkryta"
			research_btn.disabled = true
		else:
			research_btn.text = "Badaj"
			var can_afford = EconomyManager.can_research_skill(skill_id)
			research_btn.disabled = not can_afford
			var r_style = StyleBoxFlat.new()
			r_style.bg_color = Color(0.2, 0.6, 0.2) if can_afford else Color(0.2, 0.2, 0.2)
			r_style.set_corner_radius_all(4)
			research_btn.add_theme_stylebox_override("normal", r_style)
			research_btn.pressed.connect(func(sid=skill_id):
				if EconomyManager.research_skill(sid):
					_populate_list()
			)
		hbox.add_child(research_btn)

		list_vbox.add_child(panel)

func show_library_menu() -> void:
	library_window.visible = true
	var viewport_size = hud.get_viewport_rect().size
	library_window.position = ((viewport_size - library_window.custom_minimum_size) / 2.0).round()
	_populate_list()
