extends Node
class_name PotionsMenu

var hud
var my_potions_window: ColorRect
var buy_potions_window: ColorRect
var my_potions_list: VBoxContainer
var buy_potions_list: VBoxContainer

func _init(h):
	hud = h

func setup_potions_windows():
	# My Potions Window
	my_potions_window = ColorRect.new()
	my_potions_window.name = "MyPotionsWindow"
	my_potions_window.visible = false
	my_potions_window.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	my_potions_window.color = Color(0, 0, 0, 0)
	
	var center_my = CenterContainer.new()
	center_my.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	my_potions_window.add_child(center_my)
	
	var my_panel = PanelContainer.new()
	my_panel.custom_minimum_size = Vector2(650, 500)
	var my_style = StyleBoxFlat.new()
	my_style.bg_color = Color(0.12, 0.12, 0.15, 0.95)
	my_style.set_border_width_all(2)
	my_style.border_color = Color(0.8, 0.6, 0.2)
	my_style.set_corner_radius_all(8)
	my_style.content_margin_left = 20
	my_style.content_margin_right = 20
	my_style.content_margin_top = 20
	my_style.content_margin_bottom = 20
	my_panel.add_theme_stylebox_override("panel", my_style)
	center_my.add_child(my_panel)
	
	var my_vbox = VBoxContainer.new()
	my_vbox.add_theme_constant_override("separation", 15)
	my_panel.add_child(my_vbox)
	
	var my_header = Label.new()
	my_header.text = "🧪 Moje Potki"
	my_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	my_header.add_theme_font_size_override("font_size", 24)
	my_header.add_theme_color_override("font_color", Color(0.9, 0.7, 0.2))
	my_vbox.add_child(my_header)
	
	var my_scroll = ScrollContainer.new()
	my_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	my_vbox.add_child(my_scroll)
	
	my_potions_list = VBoxContainer.new()
	my_potions_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	my_potions_list.add_theme_constant_override("separation", 10)
	my_scroll.add_child(my_potions_list)
	
	var btn_close_my = Button.new()
	btn_close_my.text = "Zamknij"
	btn_close_my.custom_minimum_size = Vector2(100, 40)
	btn_close_my.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn_close_my.pressed.connect(func(): my_potions_window.visible = false)
	my_vbox.add_child(btn_close_my)
	
	hud.add_child(my_potions_window)
	
	# Buy Potions Window
	buy_potions_window = ColorRect.new()
	buy_potions_window.name = "BuyPotionsWindow"
	buy_potions_window.visible = false
	buy_potions_window.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	buy_potions_window.color = Color(0, 0, 0, 0)
	
	var center_buy = CenterContainer.new()
	center_buy.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	buy_potions_window.add_child(center_buy)
	
	var buy_panel = PanelContainer.new()
	buy_panel.custom_minimum_size = Vector2(650, 500)
	buy_panel.add_theme_stylebox_override("panel", my_style)
	center_buy.add_child(buy_panel)
	
	var buy_vbox = VBoxContainer.new()
	buy_vbox.add_theme_constant_override("separation", 15)
	buy_panel.add_child(buy_vbox)
	
	var buy_header = Label.new()
	buy_header.text = "💰 Kup Potki"
	buy_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	buy_header.add_theme_font_size_override("font_size", 24)
	buy_header.add_theme_color_override("font_color", Color(0.9, 0.7, 0.2))
	buy_vbox.add_child(buy_header)
	
	var buy_scroll = ScrollContainer.new()
	buy_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	buy_vbox.add_child(buy_scroll)
	
	buy_potions_list = VBoxContainer.new()
	buy_potions_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buy_potions_list.add_theme_constant_override("separation", 10)
	buy_scroll.add_child(buy_potions_list)
	
	var btn_close_buy = Button.new()
	btn_close_buy.text = "Zamknij"
	btn_close_buy.custom_minimum_size = Vector2(100, 40)
	btn_close_buy.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn_close_buy.pressed.connect(func(): buy_potions_window.visible = false)
	buy_vbox.add_child(btn_close_buy)
	
	hud.add_child(buy_potions_window)

func show_my_potions():
	my_potions_window.visible = true
	my_potions_window.move_to_front()
	_refresh_my_potions_list()

func show_buy_potions():
	buy_potions_window.visible = true
	buy_potions_window.move_to_front()
	_refresh_buy_potions_list()

func _refresh_my_potions_list():
	for child in my_potions_list.get_children():
		child.queue_free()
		
	var owned = EconomyManager.owned_potions
	var active = EconomyManager.active_potions
	
	if owned.is_empty():
		var lbl = Label.new()
		lbl.text = "Nie posiadasz żadnych potek."
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		my_potions_list.add_child(lbl)
		
	for p_id in active.keys():
		var p_data = EconomyManager.POTIONS_DATA[p_id]
		var hbox = HBoxContainer.new()
		var lbl = Label.new()
		lbl.text = p_data["name"] + " (Aktywna jeszcze " + str(active[p_id]) + " tur) - " + p_data["desc"]
		lbl.add_theme_color_override("font_color", Color(0.3, 0.8, 0.3))
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hbox.add_child(lbl)
		my_potions_list.add_child(hbox)
		
	for p_id in owned.keys():
		if owned[p_id] <= 0: continue
		var p_data = EconomyManager.POTIONS_DATA[p_id]
		var panel = PanelContainer.new()
		var p_style = StyleBoxFlat.new()
		p_style.bg_color = Color(0.15, 0.15, 0.2)
		p_style.set_border_width_all(1)
		p_style.border_color = Color(0.5, 0.5, 0.5)
		p_style.set_corner_radius_all(4)
		p_style.content_margin_left = 10
		p_style.content_margin_right = 10
		p_style.content_margin_top = 10
		p_style.content_margin_bottom = 10
		panel.add_theme_stylebox_override("panel", p_style)
		
		var hbox = HBoxContainer.new()
		panel.add_child(hbox)
		
		var info_vbox = VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(info_vbox)
		
		var name_lbl = Label.new()
		name_lbl.text = p_data["name"] + " (Posiadasz: " + str(owned[p_id]) + ")"
		info_vbox.add_child(name_lbl)
		
		var desc_lbl = Label.new()
		desc_lbl.text = p_data["desc"]
		desc_lbl.add_theme_font_size_override("font_size", 12)
		desc_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		info_vbox.add_child(desc_lbl)
		
		var btn_use = Button.new()
		btn_use.text = "Użyj"
		btn_use.custom_minimum_size = Vector2(120, 0)
		var has_active_of_type = false
		for a_id in active.keys():
			if EconomyManager.POTIONS_DATA[a_id]["effect"] == p_data["effect"]:
				has_active_of_type = true
				break
		
		btn_use.disabled = has_active_of_type
		if has_active_of_type:
			btn_use.tooltip_text = "Masz już aktywną potkę tego typu."
			
		btn_use.pressed.connect(func():
			if EconomyManager.use_potion(p_id):
				_refresh_my_potions_list()
				if hud.army_menu and hud.army_menu.army_window.visible:
					hud.army_menu.show_army_menu()
		)
		hbox.add_child(btn_use)
		
		my_potions_list.add_child(panel)

func _refresh_buy_potions_list():
	for child in buy_potions_list.get_children():
		child.queue_free()
		
	for p_id in EconomyManager.POTIONS_DATA.keys():
		var p_data = EconomyManager.POTIONS_DATA[p_id]
		var panel = PanelContainer.new()
		var p_style = StyleBoxFlat.new()
		p_style.bg_color = Color(0.15, 0.15, 0.2)
		p_style.set_border_width_all(1)
		p_style.border_color = Color(0.5, 0.5, 0.5)
		p_style.set_corner_radius_all(4)
		p_style.content_margin_left = 10
		p_style.content_margin_right = 10
		p_style.content_margin_top = 10
		p_style.content_margin_bottom = 10
		panel.add_theme_stylebox_override("panel", p_style)
		
		var hbox = HBoxContainer.new()
		panel.add_child(hbox)
		
		var info_vbox = VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(info_vbox)
		
		var name_lbl = Label.new()
		name_lbl.text = p_data["name"]
		info_vbox.add_child(name_lbl)
		
		var desc_lbl = Label.new()
		desc_lbl.text = p_data["desc"]
		desc_lbl.add_theme_font_size_override("font_size", 12)
		desc_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		info_vbox.add_child(desc_lbl)
		
		var cost_str = ""
		for res in p_data["cost"]:
			cost_str += res + ": " + str(p_data["cost"][res]) + " "
			
		var btn_buy = Button.new()
		btn_buy.text = "Kup\n(" + cost_str + ")"
		btn_buy.custom_minimum_size = Vector2(120, 0)
		
		var can_afford = true
		for res in p_data["cost"]:
			if EconomyManager.resources.get(res, 0) < p_data["cost"][res]:
				can_afford = false
				break
				
		btn_buy.disabled = not can_afford
		btn_buy.pressed.connect(func():
			if EconomyManager.buy_potion(p_id):
				_refresh_buy_potions_list()
		)
		hbox.add_child(btn_buy)
		
		buy_potions_list.add_child(panel)
