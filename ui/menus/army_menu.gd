class_name ArmyMenu
extends RefCounted

var hud: Control
var army_window: PanelContainer
var army_content_vbox: VBoxContainer

func _init(_hud: Control):
	hud = _hud

func setup_army_window():
	army_window = PanelContainer.new()
	army_window.visible = false
	army_window.custom_minimum_size = Vector2(800, 500)
	
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
	army_window.add_theme_stylebox_override("panel", style_panel)
	
	army_content_vbox = VBoxContainer.new()
	army_content_vbox.add_theme_constant_override("separation", 15)
	army_window.add_child(army_content_vbox)
	
	hud.add_child(army_window)

func show_army_menu():
	army_window.visible = true
	var viewport_size = hud.get_viewport_rect().size
	army_window.position = (viewport_size - army_window.custom_minimum_size) / 2.0
	_populate_army()
	_recenter_window_deferred(army_window)

func _recenter_window_deferred(win: Control) -> void:
	await hud.get_tree().process_frame
	if not is_instance_valid(win) or not win.visible: return
	var viewport_size = hud.get_viewport_rect().size
	win.position = ((viewport_size - win.size) / 2.0).round()

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
			if hud.world_ref and hud.world_ref.get("character") and hud.world_ref.character:
				hud.world_ref.character.army.clear()
				hud.world_ref.character._update_army_label()
			_populate_army()
			dialog.queue_free()
		)
		dialog.canceled.connect(func(): dialog.queue_free())
		hud.add_child(dialog)
		dialog.popup_centered()
	)
	
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
	
	if EconomyManager.player_army.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.text = "Brak jednostek w armii."
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(empty_lbl)
		return
		
	# --- GRUPOWANIE JEDNOSTEK (STACKOWANIE) -------------------------------
	# Jednostki są grupowane wg typu (id/nazwa) ORAZ stanu rekrutacji, żeby
	# np. "Łucznik x2" pokazywał się jako jeden wiersz, a jednostki wciąż
	# w trakcie werbunku (z inną liczbą pozostałych tur) były widoczne osobno.
	var groups: Array = []
	var group_index_by_key: Dictionary = {}

	for i in range(EconomyManager.player_army.size()):
		var unit = EconomyManager.player_army[i]
		var turns_to_recruit = unit.get("turns_to_recruit", 0)
		var turns_in_recruitment = unit.get("turns_in_recruitment", 0)
		var is_ready = turns_in_recruitment >= turns_to_recruit
		var turns_left = max(0, turns_to_recruit - turns_in_recruitment)
		var unit_type_key = str(unit.get("id", unit.get("name", "Unknown")))
		var state_key = "ready" if is_ready else ("training_%d" % turns_left)
		var key = unit_type_key + "_" + state_key

		if group_index_by_key.has(key):
			groups[group_index_by_key[key]]["indices"].append(i)
		else:
			group_index_by_key[key] = groups.size()
			groups.append({
				"unit": unit,
				"indices": [i],
				"is_ready": is_ready,
				"turns_left": turns_left
			})

	for group in groups:
		var unit = group["unit"]
		var count = group["indices"].size()
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
		if count > 1:
			name_lbl.text += " x%d" % count
		name_lbl.add_theme_font_size_override("font_size", 18)
		info_vbox.add_child(name_lbl)
		
		var stats_lbl = Label.new()
		var p_hp = EconomyManager.potion_bonus_hp
		var p_dmg = EconomyManager.potion_bonus_dmg
		var p_def = EconomyManager.potion_bonus_def
		var p_speed = EconomyManager.potion_bonus_speed
		
		var total_hp = unit.get("hp", 0) + p_hp
		var total_dmg = unit.get("dmg", 0) + p_dmg
		var total_def = unit.get("def", 0) + p_def
		var total_speed = unit.get("move_range", 0) + p_speed
		
		var hp_str = str(total_hp) if p_hp == 0 else "%d(+%d)" % [total_hp, p_hp]
		var dmg_str = str(total_dmg) if p_dmg == 0 else "%d(+%d)" % [total_dmg, p_dmg]
		var def_str = str(total_def) if p_def == 0 else "%d(+%d)" % [total_def, p_def]
		var speed_str = str(total_speed) if p_speed == 0 else "%d(+%d)" % [total_speed, p_speed]
		
		stats_lbl.text = "HP: %s | DMG: %s | DEF: %s | RUCH: %s" % [hp_str, dmg_str, def_str, speed_str]
		stats_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		info_vbox.add_child(stats_lbl)

		var status_lbl = Label.new()
		if group["is_ready"]:
			status_lbl.text = "✅ Gotowa — przypisana do generała"
			status_lbl.add_theme_color_override("font_color", Color(0.55, 0.85, 0.55))
		else:
			status_lbl.text = "⏳ W trakcie rekrutacji (jeszcze %d tur)" % group["turns_left"]
			status_lbl.add_theme_color_override("font_color", Color(0.85, 0.75, 0.4))
		info_vbox.add_child(status_lbl)
		
		var dismiss_btn = Button.new()
		dismiss_btn.text = "Zwolnij" if count == 1 else "Zwolnij 1"
		dismiss_btn.custom_minimum_size = Vector2(110, 40)
		dismiss_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var btn_style = StyleBoxFlat.new()
		btn_style.bg_color = Color(0.6, 0.2, 0.2)
		btn_style.set_corner_radius_all(4)
		dismiss_btn.add_theme_stylebox_override("normal", btn_style)
		dismiss_btn.pressed.connect(func(u=unit):
			var dialog = ConfirmationDialog.new()
			dialog.title = "Potwierdzenie"
			dialog.dialog_text = "Czy zwolnić jednostkę " + unit["name"] + "?"
			dialog.confirmed.connect(func():
				_unassign_units_from_general([u])
				EconomyManager.remove_unit(u)
				_populate_army()
				dialog.queue_free()
			)
			dialog.canceled.connect(func(): dialog.queue_free())
			hud.add_child(dialog)
			dialog.popup_centered()
		)
		
		hbox.add_child(dismiss_btn)
		vbox.add_child(panel)

func _unassign_units_from_general(units_to_remove: Array):
	var gen = null
	if hud.world_ref and hud.world_ref.get("character"):
		gen = hud.world_ref.character
	for u in units_to_remove:
		if gen: gen.unassign_unit(u)
	_populate_army()
