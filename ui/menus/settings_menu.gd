class_name SettingsMenu
extends RefCounted

var hud: Control
var settings_window: PanelContainer
var settings_seed_value_label: Label
var settings_copy_button: Button
var settings_volume_slider: HSlider

func _init(_hud: Control):
	hud = _hud

func setup_settings_window():
	settings_window = PanelContainer.new()
	settings_window.visible = false
	settings_window.custom_minimum_size = Vector2(440, 0)

	var style_panel = StyleBoxFlat.new()
	style_panel.bg_color = hud.DF_BG
	style_panel.set_corner_radius_all(10)
	style_panel.set_border_width_all(2)
	style_panel.border_color = hud.DF_GOLD
	style_panel.content_margin_left = 24
	style_panel.content_margin_right = 24
	style_panel.content_margin_top = 18
	style_panel.content_margin_bottom = 18
	style_panel.shadow_color = Color(0, 0, 0, 0.6)
	style_panel.shadow_size = 8
	settings_window.add_theme_stylebox_override("panel", style_panel)

	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 16)
	settings_window.add_child(main_vbox)

	# HEADER
	var header_hbox = HBoxContainer.new()
	var title_label = Label.new()
	title_label.text = "⚙️ Ustawienia"
	title_label.add_theme_font_size_override("font_size", 22)
	title_label.add_theme_color_override("font_color", hud.DF_GOLD_TEXT)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var close_btn = Button.new()
	close_btn.text = "X"
	close_btn.custom_minimum_size = Vector2(30, 30)
	close_btn.pressed.connect(func(): settings_window.visible = false)
	hud._style_df_button(close_btn)
	header_hbox.add_child(title_label)
	header_hbox.add_child(close_btn)
	main_vbox.add_child(header_hbox)

	var sep1 = HSeparator.new()
	sep1.add_theme_color_override("separator", hud.DF_GOLD)
	main_vbox.add_child(sep1)

	# SEED SECTION
	var seed_section = VBoxContainer.new()
	seed_section.add_theme_constant_override("separation", 8)
	var seed_title = Label.new()
	seed_title.text = "Seed świata"
	seed_title.add_theme_font_size_override("font_size", 16)
	seed_title.add_theme_color_override("font_color", hud.DF_GOLD_TEXT)
	seed_section.add_child(seed_title)

	var seed_row = HBoxContainer.new()
	seed_row.add_theme_constant_override("separation", 10)
	settings_seed_value_label = Label.new()
	settings_seed_value_label.add_theme_font_size_override("font_size", 14)
	settings_seed_value_label.add_theme_color_override("font_color", hud.DF_TEXT)
	settings_seed_value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings_seed_value_label.clip_text = true

	settings_copy_button = Button.new()
	settings_copy_button.text = "📋 Kopiuj seed"
	settings_copy_button.custom_minimum_size = Vector2(140, 36)
	hud._style_df_button(settings_copy_button)
	settings_copy_button.pressed.connect(_on_copy_seed_pressed)

	seed_row.add_child(settings_seed_value_label)
	seed_row.add_child(settings_copy_button)
	seed_section.add_child(seed_row)
	main_vbox.add_child(seed_section)

	var sep2 = HSeparator.new()
	sep2.add_theme_color_override("separator", hud.DF_GOLD)
	main_vbox.add_child(sep2)

	# DŹWIĘK SECTION
	var sound_section = VBoxContainer.new()
	sound_section.add_theme_constant_override("separation", 8)
	var sound_title = Label.new()
	sound_title.text = "Głośność"
	sound_title.add_theme_font_size_override("font_size", 16)
	sound_title.add_theme_color_override("font_color", hud.DF_GOLD_TEXT)
	sound_section.add_child(sound_title)

	settings_volume_slider = HSlider.new()
	settings_volume_slider.min_value = 0
	settings_volume_slider.max_value = 100
	settings_volume_slider.step = 1
	var master_idx = AudioServer.get_bus_index("Master")
	if master_idx >= 0:
		var current_db = AudioServer.get_bus_volume_db(master_idx)
		settings_volume_slider.value = clamp(db_to_linear(current_db) * 100.0, 0, 100)
	else:
		settings_volume_slider.value = 100
	settings_volume_slider.custom_minimum_size = Vector2(0, 24)
	settings_volume_slider.value_changed.connect(_on_volume_changed)
	sound_section.add_child(settings_volume_slider)
	main_vbox.add_child(sound_section)

	var sep3 = HSeparator.new()
	sep3.add_theme_color_override("separator", hud.DF_GOLD)
	main_vbox.add_child(sep3)

	# ACTION BUTTONS
	var resume_btn = Button.new()
	resume_btn.text = "▶️ Wróć do gry"
	resume_btn.custom_minimum_size = Vector2(0, 42)
	hud._style_df_button(resume_btn)
	resume_btn.pressed.connect(func(): settings_window.visible = false)
	main_vbox.add_child(resume_btn)

	var save_btn = Button.new()
	save_btn.text = "💾 Zapisz Grę"
	save_btn.custom_minimum_size = Vector2(0, 42)
	hud._style_df_button(save_btn)
	save_btn.pressed.connect(func():
		SaveManager.save_game(GameSettings.current_seed, hud.world_ref)
		save_btn.text = "✅ Zapisano!"
		hud.get_tree().create_timer(1.5).timeout.connect(func():
			if is_instance_valid(save_btn):
				save_btn.text = "💾 Zapisz Grę"
		)
	)
	main_vbox.add_child(save_btn)

	var reset_btn = Button.new()
	reset_btn.text = "🔄 Zresetuj Grę (Ten sam seed)"
	reset_btn.custom_minimum_size = Vector2(0, 42)
	hud._style_df_button(reset_btn)
	reset_btn.pressed.connect(func():
		SaveManager.delete_save(GameSettings.current_seed)
		EconomyManager.reset()
		hud.get_tree().change_scene_to_file("res://scenes/game_world.tscn")
	)
	main_vbox.add_child(reset_btn)

	var menu_btn = Button.new()
	menu_btn.text = "🏠 Wróć do menu głównego"
	menu_btn.custom_minimum_size = Vector2(0, 42)
	hud._style_df_button(menu_btn)
	menu_btn.pressed.connect(func():
		hud.get_tree().change_scene_to_file("res://ui/main_menu.tscn")
	)
	main_vbox.add_child(menu_btn)

	var quit_btn = Button.new()
	quit_btn.text = "❌ Wyjdź z gry"
	quit_btn.custom_minimum_size = Vector2(0, 42)
	var quit_style = StyleBoxFlat.new()
	quit_style.bg_color = hud.DF_BLOOD
	quit_style.set_corner_radius_all(6)
	quit_style.set_border_width_all(1)
	quit_style.border_color = hud.DF_GOLD
	quit_style.set_content_margin_all(8)
	var quit_hover = quit_style.duplicate() as StyleBoxFlat
	quit_hover.bg_color = hud.DF_BLOOD_BRIGHT
	quit_btn.add_theme_stylebox_override("normal", quit_style)
	quit_btn.add_theme_stylebox_override("hover", quit_hover)
	quit_btn.add_theme_color_override("font_color", hud.DF_TEXT)
	quit_btn.pressed.connect(func(): hud.get_tree().quit())
	main_vbox.add_child(quit_btn)

	hud.add_child(settings_window)

func _on_volume_changed(value: float) -> void:
	var master_idx = AudioServer.get_bus_index("Master")
	if master_idx >= 0:
		if value <= 0.0:
			AudioServer.set_bus_mute(master_idx, true)
		else:
			AudioServer.set_bus_mute(master_idx, false)
			AudioServer.set_bus_volume_db(master_idx, linear_to_db(value / 100.0))

func _on_copy_seed_pressed() -> void:
	var seed_str = str(GameSettings.current_seed) if GameSettings.use_custom_seed else "Losowy"
	DisplayServer.clipboard_set(seed_str)
	settings_copy_button.text = "✅ Skopiowano!"
	hud.get_tree().create_timer(1.2).timeout.connect(func():
		if is_instance_valid(settings_copy_button):
			settings_copy_button.text = "📋 Kopiuj seed"
	)

func show_settings_menu():
	if settings_seed_value_label:
		if GameSettings.use_custom_seed:
			settings_seed_value_label.text = "Seed: " + str(GameSettings.current_seed)
		else:
			settings_seed_value_label.text = "Seed: Losowy"
	settings_window.visible = true
	var viewport_size = hud.get_viewport_rect().size
	settings_window.reset_size()
	settings_window.position = ((viewport_size - settings_window.size) / 2.0).round()
