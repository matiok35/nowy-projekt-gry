class_name HelpMenu
extends RefCounted

var hud: Control

var help_window: PanelContainer
var help_content_label: RichTextLabel
var help_tab_buttons: Dictionary = {}
var help_current_tab: String = "sterowanie"

func _init(_hud: Control):
	hud = _hud

func setup_help_window():
	help_window = PanelContainer.new()
	help_window.visible = false
	help_window.custom_minimum_size = Vector2(760, 520)

	var style_panel = StyleBoxFlat.new()
	style_panel.bg_color = hud.DF_BG
	style_panel.set_corner_radius_all(10)
	style_panel.set_border_width_all(2)
	style_panel.border_color = hud.DF_GOLD
	style_panel.content_margin_left = 20
	style_panel.content_margin_right = 20
	style_panel.content_margin_top = 16
	style_panel.content_margin_bottom = 16
	style_panel.shadow_color = Color(0, 0, 0, 0.55)
	style_panel.shadow_size = 6
	help_window.add_theme_stylebox_override("panel", style_panel)

	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 12)
	help_window.add_child(main_vbox)

	# HEADER
	var header_hbox = HBoxContainer.new()
	var title_label = Label.new()
	title_label.text = "📖 Pomoc — Sterowanie i Instrukcje"
	title_label.add_theme_font_size_override("font_size", 22)
	title_label.add_theme_color_override("font_color", hud.DF_GOLD_TEXT)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var close_btn = Button.new()
	close_btn.text = "X"
	close_btn.custom_minimum_size = Vector2(30, 30)
	close_btn.pressed.connect(func(): help_window.visible = false)
	hud._style_df_button(close_btn)
	header_hbox.add_child(title_label)
	header_hbox.add_child(close_btn)
	main_vbox.add_child(header_hbox)

	# TABS
	var tabs_hbox = HBoxContainer.new()
	tabs_hbox.add_theme_constant_override("separation", 6)
	var tab_defs = [
		["sterowanie", "🖱️ Sterowanie"],
		["budowanie", "🏗️ Budowanie"],
		["miasto", "👑 Miasto i Pola"],
		["wojsko", "⚔️ Wojsko"],
		["rozwoj", "🔬 Rozwój"],
	]
	for tab_def in tab_defs:
		var key = tab_def[0]
		var btn = Button.new()
		btn.text = tab_def[1]
		btn.toggle_mode = true
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(func(): _show_help_tab(key))
		hud._style_df_button(btn)
		var pressed_style = StyleBoxFlat.new()
		pressed_style.bg_color = Color(0.3, 0.23, 0.1, 0.95)
		pressed_style.set_corner_radius_all(6)
		pressed_style.set_border_width_all(1)
		pressed_style.border_color = hud.DF_GOLD_BRIGHT
		pressed_style.set_content_margin_all(8)
		btn.add_theme_stylebox_override("pressed", pressed_style)
		tabs_hbox.add_child(btn)
		help_tab_buttons[key] = btn
	main_vbox.add_child(tabs_hbox)

	# CONTENT
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_vbox.add_child(scroll)

	help_content_label = RichTextLabel.new()
	help_content_label.bbcode_enabled = true
	help_content_label.fit_content = true
	help_content_label.scroll_active = false
	help_content_label.custom_minimum_size = Vector2(700, 0)
	help_content_label.add_theme_font_size_override("normal_font_size", 15)
	scroll.add_child(help_content_label)

	hud.add_child(help_window)

func _help_tab_text(key: String) -> String:
	match key:
		"sterowanie":
			return "[b][color=#8fdc8f]Poruszanie się po mapie[/color][/b]\n" \
				+ "• [b]Przeciągnij lewym przyciskiem myszy (LPM)[/b] po mapie, aby przesunąć kamerę.\n" \
				+ "• [b]Kółko myszy[/b] — przybliżanie / oddalanie widoku mapy.\n\n" \
				+ "[b][color=#8fdc8f]Postać / jednostka gracza[/color][/b]\n" \
				+ "• Kliknij [b]LPM[/b] na swoją postać, aby ją [b]zaznaczyć[/b] (zaznaczenie można zdjąć ponownym kliknięciem).\n" \
				+ "• Gdy postać jest zaznaczona, kliknij [b]LPM[/b] na docelowe pole w zasięgu ruchu — postać przemieści się tam najkrótszą dostępną ścieżką.\n\n" \
				+ "[b][color=#8fdc8f]Pola mapy[/color][/b]\n" \
				+ "• Kliknij [b]prawym przyciskiem myszy (PPM)[/b] na dowolne pole, aby otworzyć [b]menu kontekstowe[/b] — to stąd wykonuje się większość akcji (budowa, kupno pola, zakładanie miasta, ulepszanie, rekrutacja).\n" \
				+ "• Kliknięcie poza otwartym menu lub na pustym obszarze zamyka aktualnie otwarte okno.\n\n" \
				+ "[b][color=#8fdc8f]Tura[/color][/b]\n" \
				+ "• Przycisk [b]„Następna tura”[/b] w lewym dolnym rogu ekranu kończy bieżącą turę i nalicza produkcję zasobów."
		"budowanie":
			return "[b][color=#8fdc8f]Jak wybudować budynek[/color][/b]\n" \
				+ "1. Kliknij [b]PPM[/b] na pole, które [b]należy do Ciebie[/b] (posiadane pola).\n" \
				+ "2. W otwartym „Menu Budowy” wybierz kategorię u góry: [b]Surowce[/b], [b]Kultura[/b], [b]Technologia[/b] lub [b]Wojskowe[/b].\n" \
				+ "3. Kliknij przycisk wybranego budynku — jeśli masz wystarczająco surowców, budynek zostanie postawiony na tym polu.\n\n" \
				+ "[b][color=#8fdc8f]Ulepszanie budynków[/color][/b]\n" \
				+ "• Kliknij [b]PPM[/b] na pole z istniejącym budynkiem i wybierz [b]„⬆️ Ulepsz budynek”[/b], aby zwiększyć jego poziom (jeśli stać Cię na koszt ulepszenia).\n\n" \
				+ "[color=#e0b060][b]Uwaga:[/b] postawienie budynku na polu ze złożem surowca (np. żelaza, węgla) bezpowrotnie zniszczy złoże i zamieni pole w zwykłą trawę — gra poprosi o potwierdzenie tej decyzji.[/color]"
		"miasto":
			return "[b][color=#8fdc8f]Zakładanie miasta[/color][/b]\n" \
				+ "• Kliknij [b]PPM[/b] na odpowiednie pole i wybierz [b]„👑 Załóż Miasto tutaj”[/b], aby założyć nowe miasto na tym polu.\n\n" \
				+ "[b][color=#8fdc8f]Kupowanie pól[/color][/b]\n" \
				+ "• Aby powiększyć terytorium, kliknij [b]PPM[/b] na pole [b]sąsiadujące[/b] z polem, które już posiadasz.\n" \
				+ "• Wybierz [b]„🪙 Kup to pole (50 złota)”[/b] — pole zostanie dołączone do Twojego terytorium, jeśli masz wystarczająco złota.\n\n" \
				+ "[color=#a0a0a0]Tylko pola graniczące z posiadanym terenem mogą zostać zakupione lub zabudowane.[/color]"
		"wojsko":
			return "[b][color=#8fdc8f]Rekrutacja jednostek[/color][/b]\n" \
				+ "• Zbuduj [b]Baraki[/b] (kategoria „Wojskowe” w menu budowy).\n" \
				+ "• Kliknij [b]PPM[/b] na pole z barakami i wybierz [b]„⚔️ Rekrutuj”[/b], aby otworzyć listę dostępnych jednostek do zwerbowania.\n" \
				+ "• Rekrutacja trwa określoną liczbę tur — postęp widać na ikonie jednostki w oknie „Moja Armia”.\n\n" \
				+ "[b][color=#8fdc8f]Zarządzanie armią[/color][/b]\n" \
				+ "• Otwórz [b]„🛡️ Moja Armia”[/b] z menu kontekstowego pola, aby zobaczyć wszystkie zwerbowane jednostki, ich statystyki oraz usunąć wybraną jednostkę lub całą armię.\n\n" \
				+ "[b][color=#8fdc8f]Ruch jednostki[/color][/b]\n" \
				+ "• Zaznacz swoją postać kliknięciem [b]LPM[/b], a następnie kliknij [b]LPM[/b] na pole docelowe w jej zasięgu ruchu."
		"rozwoj":
			return "[b][color=#8fdc8f]Drzewo Technologii[/color][/b]\n" \
				+ "• Kliknij przycisk [b]„Drzewo Technologii”[/b] w panelu w prawym górnym rogu ekranu.\n" \
				+ "• Kliknij dostępny (podświetlony) węzeł technologii, aby rozpocząć nad nim badanie — koszt w punktach Nauki (lub Kultury) jest pobierany od razu w całości, a samo badanie kończy się dopiero po stałej liczbie tur widocznej przy węźle, niezależnie od tego, ile punktów wygenerujesz w międzyczasie. Jeśli nie masz wystarczająco punktów, gra Cię o tym poinformuje.\n\n" \
				+ "[b][color=#8fdc8f]Drzewo Kultury[/color][/b]\n" \
				+ "• Kliknij przycisk [b]„Drzewo Kultury”[/b] w tym samym panelu, aby rozwijać ścieżkę kulturową w analogiczny sposób, korzystając z Punktów Kultury.\n\n" \
				+ "[color=#a0a0a0]Węzły wymagają spełnienia wcześniejszych wymagań (odblokowanych technologii/kultur) zanim staną się dostępne do zbadania.[/color]"
		_:
			return ""

func _show_help_tab(key: String):
	help_current_tab = key
	for tab_key in help_tab_buttons:
		help_tab_buttons[tab_key].button_pressed = (tab_key == key)
	if help_content_label:
		help_content_label.text = _help_tab_text(key)

func show_help_menu():
	help_window.visible = true
	var viewport_size = hud.get_viewport_rect().size
	help_window.position = (viewport_size - help_window.custom_minimum_size) / 2.0
	_show_help_tab(help_current_tab)
