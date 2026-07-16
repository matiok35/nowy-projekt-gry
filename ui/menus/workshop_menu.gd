class_name WorkshopMenu
extends RefCounted

var hud: Control
var workshop_window: PanelContainer
var status_label: Label
var heal_button: Button
var _current_tile_pos: Vector2 = Vector2.ZERO

func _init(_hud: Control):
	hud = _hud

func setup_workshop_window():
	workshop_window = PanelContainer.new()
	workshop_window.visible = false
	workshop_window.custom_minimum_size = Vector2(420, 0)

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
	workshop_window.add_theme_stylebox_override("panel", style_panel)

	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 14)
	workshop_window.add_child(main_vbox)

	# HEADER
	var header_hbox = HBoxContainer.new()
	var title_label = Label.new()
	title_label.text = "🔧 Warsztat — Uzdrawianie"
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.add_theme_color_override("font_color", hud.DF_GOLD_TEXT)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var close_btn = Button.new()
	close_btn.text = "X"
	close_btn.custom_minimum_size = Vector2(30, 30)
	close_btn.pressed.connect(func(): workshop_window.visible = false)
	hud._style_df_button(close_btn)
	header_hbox.add_child(title_label)
	header_hbox.add_child(close_btn)
	main_vbox.add_child(header_hbox)

	var sep = HSeparator.new()
	sep.add_theme_color_override("separator", hud.DF_GOLD)
	main_vbox.add_child(sep)

	# OPIS
	var desc_label = Label.new()
	desc_label.text = "Warsztat może uleczyć Twoją armię, jeśli generał wraz z oddziałem stoi dokładnie na tym polu."
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.add_theme_color_override("font_color", hud.DF_TEXT)
	main_vbox.add_child(desc_label)

	# STATUS
	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	status_label.add_theme_font_size_override("font_size", 15)
	status_label.add_theme_color_override("font_color", hud.DF_GOLD_TEXT)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(status_label)

	# PRZYCISK LECZENIA
	heal_button = Button.new()
	heal_button.text = "✚ Lecz jednostki"
	heal_button.custom_minimum_size = Vector2(0, 46)
	var style_heal = StyleBoxFlat.new()
	style_heal.bg_color = Color(0.1, 0.28, 0.14, 0.95)
	style_heal.set_border_width_all(2)
	style_heal.border_color = hud.DF_GOLD
	style_heal.set_corner_radius_all(6)
	style_heal.set_content_margin_all(10)
	var style_heal_hover = style_heal.duplicate() as StyleBoxFlat
	style_heal_hover.bg_color = Color(0.14, 0.38, 0.2, 0.95)
	style_heal_hover.border_color = hud.DF_GOLD_BRIGHT
	var style_heal_disabled = StyleBoxFlat.new()
	style_heal_disabled.bg_color = Color(0.15, 0.13, 0.11, 0.5)
	style_heal_disabled.set_border_width_all(2)
	style_heal_disabled.border_color = Color(0.4, 0.32, 0.16, 0.5)
	style_heal_disabled.set_corner_radius_all(6)
	style_heal_disabled.set_content_margin_all(10)
	heal_button.add_theme_stylebox_override("normal", style_heal)
	heal_button.add_theme_stylebox_override("hover", style_heal_hover)
	heal_button.add_theme_stylebox_override("disabled", style_heal_disabled)
	heal_button.add_theme_color_override("font_color", hud.DF_TEXT)
	heal_button.add_theme_color_override("font_disabled_color", Color(0.5, 0.45, 0.35, 0.6))
	heal_button.pressed.connect(_on_heal_pressed)
	main_vbox.add_child(heal_button)

	hud.add_child(workshop_window)

func _general_with_army_on_tile() -> bool:
	if not hud.world_ref or not hud.world_ref.get("character"):
		return false
	var gen = hud.world_ref.character
	if not gen or not gen.has_method("has_army") or not gen.has_army():
		return false
	var gen_tile = hud.world_ref.world_to_nearest_cell(gen.global_position)
	return gen_tile == _current_tile_pos

func _on_heal_pressed() -> void:
	if not _general_with_army_on_tile():
		return
	EconomyManager.heal_army_units()
	_refresh_status()

func _refresh_status() -> void:
	var can_heal = _general_with_army_on_tile()
	if can_heal:
		status_label.text = "✅ Generał z armią stoi na tym polu — możesz leczyć jednostki."
		status_label.add_theme_color_override("font_color", Color(0.55, 0.85, 0.55))
	else:
		status_label.text = "⚠️ Aby leczyć, generał z przypisaną armią musi stać dokładnie na tym polu."
		status_label.add_theme_color_override("font_color", Color(0.85, 0.55, 0.4))

	heal_button.disabled = not can_heal
	heal_button.modulate.a = 1.0 if can_heal else 0.5

func show_workshop_menu(tile_pos: Vector2) -> void:
	_current_tile_pos = tile_pos
	workshop_window.visible = true
	var viewport_size = hud.get_viewport_rect().size
	workshop_window.reset_size()
	_refresh_status()
	workshop_window.position = ((viewport_size - workshop_window.size) / 2.0).round()
