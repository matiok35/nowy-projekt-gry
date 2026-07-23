extends Node
class_name PotionsMenu

var hud
var my_potions_window: ColorRect
var buy_potions_window: ColorRect
var my_potions_list: VBoxContainer
var buy_potions_list: VBoxContainer

const POTION_IMAGES: Dictionary = {
	"potka_sily_1": preload("res://assets/potions/cropped_Potion_of_Strength.png"),
	"potka_sily_10": preload("res://assets/potions/cropped_Greater_Potion_of_Strength.png"),
	"potka_wit_1": preload("res://assets/potions/cropped_Potion_of_Vitality.png"),
	"potka_wit_10": preload("res://assets/potions/cropped_Greater_Potion_of_Vitality.png"),
	"potka_obrony_1": preload("res://assets/potions/cropped_Potion_of_Stoneskin.png"),
	"potka_obrony_10": preload("res://assets/potions/cropped_Greater_Potion_of_Stoneskin.png"),
	"potka_szybkosci_1": preload("res://assets/potions/cropped_Potion_of_Wind.png"),
	"potka_szybkosci_10": preload("res://assets/potions/cropped_Greater_Potion_of_Wind.png")
}

func _init(h):
	hud = h

func setup_potions_windows():
	# My Potions Window
	my_potions_window = ColorRect.new()
	my_potions_window.name = "MyPotionsWindow"
	my_potions_window.visible = false
	my_potions_window.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	my_potions_window.color = Color(0, 0, 0, 0)
	my_potions_window.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			my_potions_window.visible = false
	)
	
	var center_my = CenterContainer.new()
	center_my.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	my_potions_window.add_child(center_my)
	
	var my_panel = PanelContainer.new()
	my_panel.custom_minimum_size = Vector2(800, 500)
	var my_style = StyleBoxFlat.new()
	my_style.bg_color = hud.DF_BG
	my_style.set_border_width_all(2)
	my_style.border_color = hud.DF_GOLD
	my_style.set_corner_radius_all(10)
	my_style.content_margin_left = 20
	my_style.content_margin_right = 20
	my_style.content_margin_top = 20
	my_style.content_margin_bottom = 20
	my_panel.add_theme_stylebox_override("panel", my_style)
	center_my.add_child(my_panel)
	
	var my_vbox = VBoxContainer.new()
	my_vbox.add_theme_constant_override("separation", 15)
	my_panel.add_child(my_vbox)
	
	var header_hbox_my = HBoxContainer.new()
	
	var my_header = Label.new()
	my_header.text = "🧪 Moje Potki"
	my_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	my_header.add_theme_font_size_override("font_size", 24)
	my_header.add_theme_color_override("font_color", Color(0.9, 0.7, 0.2))
	my_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var btn_close_my = Button.new()
	btn_close_my.text = "X"
	btn_close_my.custom_minimum_size = Vector2(40, 40)
	btn_close_my.pressed.connect(func(): my_potions_window.visible = false)
	if hud.has_method("_style_df_button"):
		hud._style_df_button(btn_close_my)
	
	header_hbox_my.add_child(my_header)
	header_hbox_my.add_child(btn_close_my)
	my_vbox.add_child(header_hbox_my)
	
	var my_scroll = ScrollContainer.new()
	my_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	my_vbox.add_child(my_scroll)
	
	my_potions_list = VBoxContainer.new()
	my_potions_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	my_potions_list.add_theme_constant_override("separation", 10)
	my_scroll.add_child(my_potions_list)
	

	
	hud.add_child(my_potions_window)
	
	# Buy Potions Window
	buy_potions_window = ColorRect.new()
	buy_potions_window.name = "BuyPotionsWindow"
	buy_potions_window.visible = false
	buy_potions_window.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	buy_potions_window.color = Color(0, 0, 0, 0)
	buy_potions_window.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			buy_potions_window.visible = false
	)
	
	var center_buy = CenterContainer.new()
	center_buy.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	buy_potions_window.add_child(center_buy)
	
	var buy_panel = PanelContainer.new()
	buy_panel.custom_minimum_size = Vector2(800, 500)
	buy_panel.add_theme_stylebox_override("panel", my_style)
	center_buy.add_child(buy_panel)
	
	var buy_vbox = VBoxContainer.new()
	buy_vbox.add_theme_constant_override("separation", 15)
	buy_panel.add_child(buy_vbox)
	
	var header_hbox_buy = HBoxContainer.new()
	
	var buy_header = Label.new()
	buy_header.text = "💰 Kup Potki"
	buy_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	buy_header.add_theme_font_size_override("font_size", 24)
	buy_header.add_theme_color_override("font_color", Color(0.9, 0.7, 0.2))
	buy_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var btn_close_buy = Button.new()
	btn_close_buy.text = "X"
	btn_close_buy.custom_minimum_size = Vector2(40, 40)
	btn_close_buy.pressed.connect(func(): buy_potions_window.visible = false)
	if hud.has_method("_style_df_button"):
		hud._style_df_button(btn_close_buy)
	
	header_hbox_buy.add_child(buy_header)
	header_hbox_buy.add_child(btn_close_buy)
	buy_vbox.add_child(header_hbox_buy)
	
	var buy_scroll = ScrollContainer.new()
	buy_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	buy_vbox.add_child(buy_scroll)
	
	buy_potions_list = VBoxContainer.new()
	buy_potions_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buy_potions_list.add_theme_constant_override("separation", 10)
	buy_scroll.add_child(buy_potions_list)
	

	
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
		var panel = PanelContainer.new()
		var p_style = StyleBoxFlat.new()
		p_style.bg_color = Color(0.15, 0.25, 0.15)
		p_style.set_border_width_all(1)
		p_style.border_color = Color(0.3, 0.8, 0.3)
		p_style.set_corner_radius_all(4)
		p_style.content_margin_left = 10
		p_style.content_margin_right = 10
		p_style.content_margin_top = 10
		p_style.content_margin_bottom = 10
		panel.add_theme_stylebox_override("panel", p_style)
		
		var hbox = HBoxContainer.new()
		panel.add_child(hbox)
		
		var icon_container = CenterContainer.new()
		icon_container.custom_minimum_size = Vector2(80, 64)
		var icon = TextureRect.new()
		icon.texture = POTION_IMAGES.get(p_id)
		icon.custom_minimum_size = Vector2(64, 64)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_container.add_child(icon)
		hbox.add_child(icon_container)
		var lbl = Label.new()
		lbl.text = p_data["name"] + " (Aktywna jeszcze " + str(active[p_id]) + " tur) - " + p_data["desc"]
		lbl.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hbox.add_child(lbl)
		my_potions_list.add_child(panel)
		
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
		
		var icon_container = CenterContainer.new()
		icon_container.custom_minimum_size = Vector2(80, 64)
		var icon = TextureRect.new()
		icon.texture = POTION_IMAGES.get(p_id)
		icon.custom_minimum_size = Vector2(64, 64)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_container.add_child(icon)
		hbox.add_child(icon_container)
		
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
		_style_potion_button(btn_use)
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
				if AudioManager: AudioManager.play_potions()
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
		
		var icon_container = CenterContainer.new()
		icon_container.custom_minimum_size = Vector2(80, 64)
		var icon = TextureRect.new()
		icon.texture = POTION_IMAGES.get(p_id)
		icon.custom_minimum_size = Vector2(64, 64)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_container.add_child(icon)
		hbox.add_child(icon_container)
		
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
		_style_potion_button(btn_buy)
		
		var can_afford = true
		for res in p_data["cost"]:
			if EconomyManager.resources.get(res, 0) < p_data["cost"][res]:
				can_afford = false
				break
				
		btn_buy.disabled = not can_afford
		btn_buy.pressed.connect(func():
			if EconomyManager.buy_potion(p_id):
				if AudioManager: AudioManager.play_buy()
				_refresh_buy_potions_list()
		)
		hbox.add_child(btn_buy)
		
		buy_potions_list.add_child(panel)

func _style_potion_button(btn: Button):
	var style_btn = StyleBoxFlat.new()
	style_btn.bg_color = Color(0.28, 0.22, 0.06, 0.95)
	style_btn.set_border_width_all(2)
	style_btn.border_color = hud.DF_GOLD
	style_btn.set_corner_radius_all(6)
	style_btn.set_content_margin_all(10)
	
	var style_btn_hover = style_btn.duplicate() as StyleBoxFlat
	style_btn_hover.bg_color = Color(0.38, 0.3, 0.1, 0.95)
	style_btn_hover.border_color = hud.DF_GOLD_BRIGHT
	
	var style_btn_disabled = StyleBoxFlat.new()
	style_btn_disabled.bg_color = Color(0.15, 0.13, 0.11, 0.5)
	style_btn_disabled.set_border_width_all(2)
	style_btn_disabled.border_color = Color(0.4, 0.32, 0.16, 0.5)
	style_btn_disabled.set_corner_radius_all(6)
	style_btn_disabled.set_content_margin_all(10)
	
	btn.add_theme_stylebox_override("normal", style_btn)
	btn.add_theme_stylebox_override("hover", style_btn_hover)
	btn.add_theme_stylebox_override("pressed", style_btn_hover)
	btn.add_theme_stylebox_override("disabled", style_btn_disabled)
	btn.add_theme_color_override("font_color", hud.DF_GOLD_TEXT)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_disabled_color", Color(0.5, 0.5, 0.5))
