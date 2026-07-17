class_name AdminMenu
extends RefCounted

var hud: Control
var admin_window: PanelContainer

func _init(_hud: Control):
	hud = _hud

func setup_admin_window():
	admin_window = PanelContainer.new()
	admin_window.visible = false
	admin_window.custom_minimum_size = Vector2(400, 0)
	admin_window.z_index = 50 # Pół-przezroczysty, na wierzchu

	var style_panel = StyleBoxFlat.new()
	style_panel.bg_color = hud.DF_BG
	style_panel.set_corner_radius_all(10)
	style_panel.set_border_width_all(2)
	style_panel.border_color = Color(0.8, 0.2, 0.2, 1.0) # Czerwona ramka wyróżniająca
	style_panel.content_margin_left = 24
	style_panel.content_margin_right = 24
	style_panel.content_margin_top = 18
	style_panel.content_margin_bottom = 18
	style_panel.shadow_color = Color(0, 0, 0, 0.6)
	style_panel.shadow_size = 8
	admin_window.add_theme_stylebox_override("panel", style_panel)

	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 16)
	admin_window.add_child(main_vbox)

	# HEADER
	var header_hbox = HBoxContainer.new()
	var title_label = Label.new()
	title_label.text = "🛠️ Panel Administratora"
	title_label.add_theme_font_size_override("font_size", 22)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4, 1.0))
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	var close_btn = Button.new()
	close_btn.text = "X"
	close_btn.custom_minimum_size = Vector2(30, 30)
	close_btn.pressed.connect(func(): admin_window.visible = false)
	hud._style_df_button(close_btn)
	
	header_hbox.add_child(title_label)
	header_hbox.add_child(close_btn)
	main_vbox.add_child(header_hbox)

	var sep1 = HSeparator.new()
	sep1.add_theme_color_override("separator", Color(0.8, 0.2, 0.2, 1.0))
	main_vbox.add_child(sep1)

	# RESOURCES GRID
	var res_label = Label.new()
	res_label.text = "Surowce (+1000) i Punkty (+100)"
	res_label.add_theme_color_override("font_color", hud.DF_GOLD_TEXT)
	main_vbox.add_child(res_label)

	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	main_vbox.add_child(grid)

	_add_cheat_button(grid, "Złoto +1000", func(): _add_res("Złoto", 1000))
	_add_cheat_button(grid, "Drewno +1000", func(): _add_res("Drewno", 1000))
	_add_cheat_button(grid, "Żelazo +1000", func(): _add_res("Żelazo", 1000))
	_add_cheat_button(grid, "Węgiel +1000", func(): _add_res("Węgiel", 1000))
	_add_cheat_button(grid, "Jedzenie +1000", func(): _add_res("Jedzenie", 1000))
	_add_cheat_button(grid, "Populacja +10", func(): _add_res("Populacja", 10))
	
	_add_cheat_button(grid, "Nauka +100", func(): _add_res("Nauka", 100))
	_add_cheat_button(grid, "Kultura +100", func(): _add_res("Kultura", 100))

	var sep2 = HSeparator.new()
	sep2.add_theme_color_override("separator", Color(0.8, 0.2, 0.2, 1.0))
	main_vbox.add_child(sep2)

	# UTILS
	var unlock_tech_btn = Button.new()
	unlock_tech_btn.text = "Odkryj wszystkie technologie"
	hud._style_df_button(unlock_tech_btn)
	unlock_tech_btn.pressed.connect(_unlock_all_techs)
	main_vbox.add_child(unlock_tech_btn)

	var unlock_cult_btn = Button.new()
	unlock_cult_btn.text = "Odkryj wszystkie nurty kultury"
	hud._style_df_button(unlock_cult_btn)
	unlock_cult_btn.pressed.connect(_unlock_all_cultures)
	main_vbox.add_child(unlock_cult_btn)

	var sep3 = HSeparator.new()
	sep3.add_theme_color_override("separator", Color(0.8, 0.2, 0.2, 1.0))
	main_vbox.add_child(sep3)

	# Przełącznik pozwalający wyłączyć krótkie opóźnienie (cooldown)
	# przycisku „Następna tura” — przydatne przy testowaniu, gdy trzeba
	# szybko przeklikać wiele tur pod rząd.
	var skip_delay_check = CheckButton.new()
	skip_delay_check.text = "Wyłącz opóźnienie przycisku „Następna tura”"
	skip_delay_check.button_pressed = GameSettings.skip_turn_button_delay
	skip_delay_check.add_theme_color_override("font_color", hud.DF_TEXT)
	skip_delay_check.toggled.connect(func(pressed: bool):
		GameSettings.skip_turn_button_delay = pressed
	)
	main_vbox.add_child(skip_delay_check)

	hud.add_child(admin_window)

func _add_cheat_button(parent: Node, text: String, callback: Callable):
	var btn = Button.new()
	btn.text = text
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hud._style_df_button(btn)
	btn.pressed.connect(callback)
	parent.add_child(btn)

func _add_res(res_name: String, amount: int):
	EconomyManager.resources[res_name] += amount
	if res_name == "Populacja":
		EconomyManager.resources["Maks_Populacja"] = max(EconomyManager.resources["Maks_Populacja"], EconomyManager.resources["Populacja"])
	EconomyManager.notify_change()

func _unlock_all_techs():
	for tech in EconomyManager.technology_tree:
		EconomyManager.technology_tree[tech]["unlocked"] = true
	EconomyManager.notify_change()

func _unlock_all_cultures():
	for cult in EconomyManager.culture_tree:
		EconomyManager.culture_tree[cult]["unlocked"] = true
	EconomyManager.notify_change()

func show_admin_menu():
	admin_window.visible = true
	var viewport_size = hud.get_viewport_rect().size
	admin_window.reset_size()
	admin_window.position = ((viewport_size - admin_window.size) / 2.0).round()
