class_name TempleMenu
extends RefCounted

var hud: Control
var temple_window: PanelContainer
var status_label: Label
var desc_label: Label
var activate_button: Button

func _init(_hud: Control):
	hud = _hud

func setup_temple_window():
	temple_window = PanelContainer.new()
	temple_window.visible = false
	temple_window.custom_minimum_size = Vector2(420, 0)

	var style_panel = StyleBoxFlat.new()
	style_panel.bg_color = hud.DF_BG
	style_panel.set_corner_radius_all(10)
	style_panel.set_border_width_all(2)
	style_panel.border_color = hud.DF_GOLD
	style_panel.content_margin_left = 22
	style_panel.content_margin_right = 22
	style_panel.content_margin_top = 18
	style_panel.content_margin_bottom = 18
	style_panel.shadow_color = Color(0, 0, 0, 0.55)
	style_panel.shadow_size = 6
	temple_window.add_theme_stylebox_override("panel", style_panel)

	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 14)
	temple_window.add_child(main_vbox)

	# HEADER
	var header_hbox = HBoxContainer.new()
	var title_label = Label.new()
	title_label.text = "⛩️ Świątynia — Błogosławieństwo"
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.add_theme_color_override("font_color", hud.DF_GOLD_TEXT)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var close_btn = Button.new()
	close_btn.text = "X"
	close_btn.custom_minimum_size = Vector2(30, 30)
	close_btn.pressed.connect(func(): temple_window.visible = false)
	hud._style_df_button(close_btn)
	header_hbox.add_child(title_label)
	header_hbox.add_child(close_btn)
	main_vbox.add_child(header_hbox)

	var sep = HSeparator.new()
	sep.add_theme_color_override("separator", hud.DF_GOLD)
	main_vbox.add_child(sep)

	# OPIS
	desc_label = Label.new()
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_label.custom_minimum_size = Vector2(370, 0)
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.add_theme_color_override("font_color", hud.DF_TEXT)
	main_vbox.add_child(desc_label)

	# STATUS
	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	status_label.custom_minimum_size = Vector2(370, 0)
	status_label.add_theme_font_size_override("font_size", 15)
	status_label.add_theme_color_override("font_color", hud.DF_GOLD_TEXT)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(status_label)

	# PRZYCISK AKTYWACJI
	activate_button = Button.new()
	activate_button.text = "🙏 Aktywuj Błogosławieństwo"
	activate_button.custom_minimum_size = Vector2(0, 46)
	var style_act = StyleBoxFlat.new()
	style_act.bg_color = Color(0.28, 0.22, 0.06, 0.95)
	style_act.set_border_width_all(2)
	style_act.border_color = hud.DF_GOLD
	style_act.set_corner_radius_all(6)
	style_act.set_content_margin_all(10)
	var style_act_hover = style_act.duplicate() as StyleBoxFlat
	style_act_hover.bg_color = Color(0.38, 0.3, 0.1, 0.95)
	style_act_hover.border_color = hud.DF_GOLD_BRIGHT
	var style_act_disabled = StyleBoxFlat.new()
	style_act_disabled.bg_color = Color(0.15, 0.13, 0.11, 0.5)
	style_act_disabled.set_border_width_all(2)
	style_act_disabled.border_color = Color(0.4, 0.32, 0.16, 0.5)
	style_act_disabled.set_corner_radius_all(6)
	style_act_disabled.set_content_margin_all(10)
	activate_button.add_theme_stylebox_override("normal", style_act)
	activate_button.add_theme_stylebox_override("hover", style_act_hover)
	activate_button.add_theme_stylebox_override("disabled", style_act_disabled)
	activate_button.add_theme_color_override("font_color", hud.DF_TEXT)
	activate_button.add_theme_color_override("font_disabled_color", Color(0.5, 0.45, 0.35, 0.6))
	activate_button.pressed.connect(_on_activate_pressed)
	main_vbox.add_child(activate_button)

	hud.add_child(temple_window)

func _on_activate_pressed() -> void:
	if EconomyManager.activate_temple_blessing():
		_refresh_status()

# Aktualny bonus (%) zależy od poziomu najlepiej rozwiniętej Świątyni gracza —
# im wyższy poziom, tym silniejsze błogosławieństwo (patrz
# EconomyManager.get_temple_blessing_bonus_percent).
func _get_current_bonus_percent() -> int:
	if hud.world_ref and hud.world_ref.has_method("get_active_buildings_list"):
		return EconomyManager.get_temple_blessing_bonus_percent(hud.world_ref.get_active_buildings_list())
	return 10

func _refresh_status() -> void:
	var bonus_percent = _get_current_bonus_percent()

	desc_label.text = "Aktywuj błogosławieństwo, aby zwiększyć produkcję wszystkich surowców o %d%% przez %d tur.\nOdnowienie (cooldown): %d tur od aktywacji.\nUlepszanie Świątyni zwiększa siłę błogosławieństwa (+10%% za poziom)." % [bonus_percent, EconomyManager.TEMPLE_BLESSING_DURATION, EconomyManager.TEMPLE_BLESSING_COOLDOWN]

	if EconomyManager.temple_blessing_turns_left > 0:
		status_label.text = "✅ Błogosławieństwo aktywne (+%d%%) jeszcze przez %d tur." % [bonus_percent, EconomyManager.temple_blessing_turns_left]
		status_label.add_theme_color_override("font_color", Color(0.55, 0.85, 0.55))
	elif EconomyManager.temple_blessing_cooldown_left > 0:
		status_label.text = "⏳ Odnowienie za %d tur." % EconomyManager.temple_blessing_cooldown_left
		status_label.add_theme_color_override("font_color", Color(0.85, 0.75, 0.4))
	else:
		status_label.text = "Błogosławieństwo gotowe do aktywacji (+%d%%)." % bonus_percent
		status_label.add_theme_color_override("font_color", hud.DF_GOLD_TEXT)

	activate_button.disabled = not EconomyManager.can_activate_temple_blessing()
	activate_button.modulate.a = 1.0 if not activate_button.disabled else 0.5

func show_temple_menu() -> void:
	temple_window.visible = true
	var viewport_size = hud.get_viewport_rect().size
	temple_window.reset_size()
	_refresh_status()
	temple_window.reset_size()
	temple_window.position = ((viewport_size - temple_window.size) / 2.0).round()
