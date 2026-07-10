class_name TutorialMenu
extends RefCounted

var hud: Control
var tutorial_window: PanelContainer
var _scroll: ScrollContainer

const MARGIN: float = 40.0
const MAX_WIDTH: float = 720.0
const MIN_SCROLL_HEIGHT: float = 140.0

func _init(_hud: Control):
	hud = _hud

func setup_tutorial_window():
	tutorial_window = PanelContainer.new()
	tutorial_window.visible = false
	tutorial_window.z_index = 20

	var style_panel = StyleBoxFlat.new()
	style_panel.bg_color = hud.DF_BG
	style_panel.set_corner_radius_all(10)
	style_panel.set_border_width_all(2)
	style_panel.border_color = hud.DF_GOLD
	style_panel.content_margin_left = 26
	style_panel.content_margin_right = 26
	style_panel.content_margin_top = 20
	style_panel.content_margin_bottom = 20
	style_panel.shadow_color = Color(0, 0, 0, 0.6)
	style_panel.shadow_size = 8
	tutorial_window.add_theme_stylebox_override("panel", style_panel)

	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 14)
	tutorial_window.add_child(main_vbox)

	# HEADER
	var title_label = Label.new()
	title_label.text = "👋 Witaj, Władco! Jak zacząć grę?"
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.add_theme_color_override("font_color", hud.DF_GOLD_TEXT)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(title_label)

	var sep = HSeparator.new()
	sep.add_theme_color_override("separator", hud.DF_GOLD)
	main_vbox.add_child(sep)

	# CONTENT (przewijalne, żeby okno nigdy nie rosło ponad rozmiar ekranu)
	_scroll = ScrollContainer.new()
	_scroll.custom_minimum_size = Vector2(0, 320)
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_vbox.add_child(_scroll)

	var content_label = RichTextLabel.new()
	content_label.bbcode_enabled = true
	content_label.fit_content = true
	content_label.scroll_active = false
	content_label.custom_minimum_size = Vector2(MAX_WIDTH - 60, 0)
	content_label.add_theme_font_size_override("normal_font_size", 15)
	content_label.text = _tutorial_text()
	_scroll.add_child(content_label)

	var sep2 = HSeparator.new()
	sep2.add_theme_color_override("separator", hud.DF_GOLD)
	main_vbox.add_child(sep2)

	# TIP O TAB
	var tip_lbl = Label.new()
	tip_lbl.text = "💡 Wskazówka: w każdej chwili naciśnij klawisz TAB, aby otworzyć okno pomocy ze szczegółowym opisem sterowania."
	tip_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	tip_lbl.add_theme_font_size_override("font_size", 14)
	tip_lbl.add_theme_color_override("font_color", hud.DF_GOLD_TEXT)
	tip_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(tip_lbl)

	# START BUTTON
	var start_btn = Button.new()
	start_btn.text = "⚔️ Rozpocznij grę!"
	start_btn.custom_minimum_size = Vector2(0, 46)
	var start_style = StyleBoxFlat.new()
	start_style.bg_color = hud.DF_BLOOD
	start_style.set_corner_radius_all(6)
	start_style.set_border_width_all(2)
	start_style.border_color = hud.DF_GOLD
	start_style.set_content_margin_all(10)
	var start_hover = start_style.duplicate() as StyleBoxFlat
	start_hover.bg_color = hud.DF_BLOOD_BRIGHT
	start_hover.border_color = hud.DF_GOLD_BRIGHT
	start_btn.add_theme_stylebox_override("normal", start_style)
	start_btn.add_theme_stylebox_override("hover", start_hover)
	start_btn.add_theme_color_override("font_color", hud.DF_TEXT)
	start_btn.add_theme_font_size_override("font_size", 17)
	start_btn.pressed.connect(func(): tutorial_window.visible = false)
	main_vbox.add_child(start_btn)

	hud.add_child(tutorial_window)

func _tutorial_text() -> String:
	return "[b][color=#8fdc8f]Cel gry[/color][/b]\n" \
		+ "Twoim zadaniem jest rozwinięcie własnego miasta na heksagonalnej mapie: zbieraj surowce, buduj budynki, rozwijaj technologię i kulturę, twórz armię i broń się (lub atakuj) obozowiska wrogich frakcji.\n\n" \
		+ "[b][color=#8fdc8f]Pierwsze kroki[/color][/b]\n" \
		+ "1. Twoja postać (generał) stoi na środku mapy. Kliknij ją dwukrotnie [b]LPM[/b], aby [b]założyć Miasto[/b] — to Twoja stolica i baza wypadowa.\n" \
		+ "2. Po założeniu miasta zyskujesz pola wokół niego. Kliknij [b]PPM[/b] na swoje pole, aby otworzyć [b]Menu Budowy[/b] i postawić pierwsze budynki (np. Chatę Drwala na złożu drewna, Farmę na polu z pszenicą).\n" \
		+ "3. Budynki produkują surowce (Drewno, Żelazo, Węgiel, Jedzenie, Złoto) po zakończeniu tury — kliknij [b]„Następna tura”[/b] w lewym dolnym rogu, aby naliczyć produkcję.\n" \
		+ "4. Powiększaj terytorium kupując sąsiednie pola za złoto (opcja [b]„Kup to pole”[/b] w menu pola) — miasto rozszerza się też automatycznie co kilka tur.\n\n" \
		+ "[b][color=#8fdc8f]Rozwój i kultura[/color][/b]\n" \
		+ "Buduj Laboratoria, Warsztaty, Biblioteki i Świątynie, aby generować Punkty Nauki i Kultury. Odblokowuj nowe technologie i tradycje w oknach [b]„Drzewo Rozwoju”[/b] i [b]„Drzewo Kultury”[/b] w prawym górnym rogu ekranu.\n\n" \
		+ "[b][color=#8fdc8f]Wojsko i obozowiska[/color][/b]\n" \
		+ "Zbuduj [b]Baraki[/b], aby rekrutować jednostki. Zarządzaj armią w oknie [b]„Moja Armia”[/b] i przypisuj jednostki do swojego generała. Na mapie napotkasz wrogie [b]obozowiska[/b] — sprawdzaj ich siłę zanim zaatakujesz.\n\n" \
		+ "[color=#a0a0a0]To tylko skrót — pełny opis sterowania (kamera, ruch generała, menu kontekstowe) znajdziesz w oknie pomocy pod klawiszem TAB.[/color]"

func show_tutorial_menu():
	tutorial_window.visible = true
	var viewport_size: Vector2 = hud.get_viewport_rect().size

	var max_w: float = min(MAX_WIDTH, viewport_size.x - MARGIN)
	var max_h: float = viewport_size.y - MARGIN

	tutorial_window.custom_minimum_size = Vector2(max_w, 0)
	tutorial_window.reset_size()

	# Czekamy klatkę, żeby Godot policzył naturalny (nieprzycięty) rozmiar okna
	await hud.get_tree().process_frame

	if tutorial_window.size.y > max_h:
		# Zmniejszamy obszar przewijanej treści dokładnie o tyle, o ile okno jest za wysokie
		var overflow: float = tutorial_window.size.y - max_h
		var new_scroll_h: float = max(MIN_SCROLL_HEIGHT, _scroll.custom_minimum_size.y - overflow)
		_scroll.custom_minimum_size.y = new_scroll_h
		tutorial_window.reset_size()
		await hud.get_tree().process_frame

	if not is_instance_valid(tutorial_window) or not tutorial_window.visible:
		return

	var final_size: Vector2 = tutorial_window.size
	var pos: Vector2 = ((viewport_size - final_size) / 2.0).round()
	pos.x = clamp(pos.x, 10.0, max(10.0, viewport_size.x - final_size.x - 10.0))
	pos.y = clamp(pos.y, 10.0, max(10.0, viewport_size.y - final_size.y - 10.0))
	tutorial_window.position = pos
