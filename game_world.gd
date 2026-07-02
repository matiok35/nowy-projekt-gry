extends Node2D
# GameWorld.gd (Podpięty pod główny węzeł sceny GameWorld)

# --- KONFIGURACJA SIATKI HEKSAGONALNEJ 2D ---
const MAP_SIZE = 25
const HEX_RADIUS = 50.0 # Promień heksagonu (od środka do wierzchołka)

# Wyliczenie szerokości i wysokości heksagonu na podstawie promienia
var hex_width: float = sqrt(3) * HEX_RADIUS
var hex_height: float = 2.0 * HEX_RADIUS

# --- STAN ŚWIATA GRY ---
var map_data = {}        # Słownik danych: { Vector2(x,y): {"type": "Trawa", "building": "Brak"} }
var tile_nodes = {}      # Słownik referencji do kafelków: { Vector2(x,y): Area2D }
var label_nodes = {}     # Słownik referencji do etykiet tekstowych: { Vector2(x,y): Label }

# --- REFERENCJE DO WĘZŁÓW DZIECIĘCYCH ---
var map_container: Node2D
var hud_node: Control    # Dynamicznie wyszukiwana referencja do interfejsu

func _ready():
	# AUTOMATYCZNE LOKALIZOWANIE INTERFEJSU (Naprawa błędu z zrzutu ekranu image_61ed1f.png)
	# Szuka w aktywnym drzewie węzła o nazwie "UI", a jeśli go nie ma - szuka "HUD"
	hud_node = get_tree().current_scene.find_child("UI", true, false)
	if hud_node == null:
		hud_node = get_tree().current_scene.find_child("HUD", true, false)
	
	if hud_node == null:
		push_error("BŁĄD KRYTYCZNY: Nie znaleziono węzła interfejsu ('UI' lub 'HUD') w aktywnej scenie!")
		
	map_container = get_node_or_null("MapContainer")
	if map_container == null:
		push_error("BŁĄD: Nie znaleziono węzła o nazwie 'MapContainer'!")
		return
		
	randomize()
	generate_map()

# --- GENEROWANIE MAPY ---
func generate_map():
	for x in range(MAP_SIZE):
		for y in range(MAP_SIZE):
			var pos = Vector2(x, y)
			var type = "Trawa"
			
			var rand = randf()
			if rand < 0.04: type = "Drewno"
			elif rand < 0.07: type = "Żelazo"
			elif rand < 0.09: type = "Węgiel"
				
			map_data[pos] = {"type": type, "building": "Brak"}
			create_procedural_hex(pos, type)

# --- PROCEDURALNE TWORZENIE HEKSAGONU Z KODU ---
func create_procedural_hex(pos: Vector2, type: String):
	var area = Area2D.new()
	area.input_pickable = true
	area.monitoring = false
	area.monitorable = false
	
	# MATEMATYKA POZYCJI (Siatka heksagonalna pionowa - pointy-topped)
	var x_pos = pos.x * hex_width
	if int(pos.y) % 2 == 1:
		x_pos += hex_width / 2.0
	var y_pos = pos.y * (hex_height * 0.75)
	
	area.position = Vector2(x_pos, y_pos) + Vector2(200, 150)

	# 1. RYSUJEMY KSZTAŁT HEKSAGONU
	var polygon = Polygon2D.new()
	var points = PackedVector2Array()
	
	for i in range(6):
		var angle_deg = 60.0 * i - 30.0 # Obrót o -30 stopni czubkiem do góry
		var angle_rad = deg_to_rad(angle_deg)
		points.append(Vector2(cos(angle_rad), sin(angle_rad)) * HEX_RADIUS)
		
	polygon.polygon = points
	
	if type == "Drewno": polygon.color = Color(0.15, 0.6, 0.15)
	elif type == "Żelazo": polygon.color = Color(0.45, 0.45, 0.45)
	elif type == "Węgiel": polygon.color = Color(0.18, 0.18, 0.18)
	else: polygon.color = Color(0.1, 0.45, 0.1) # Trawa
		
	area.add_child(polygon)

	# 2. DODAJEMY LINIE BRZEGOWE (Ramka)
	var line = Line2D.new()
	var line_points = points.duplicate()
	line_points.append(points[0])
	line.points = line_points
	line.width = 2.0
	line.default_color = Color(0.05, 0.25, 0.05)
	area.add_child(line)

	# 3. KOLIZJA DLA AREA2D (Precyzyjne klikanie kształtu przez system fizyki)
	var collision = CollisionPolygon2D.new()
	collision.polygon = points
	area.add_child(collision)

	# 4. DODAJEMY IDEALNIE WYCENTROWANY TEKST
	var label = Label.new()
	label.text = type
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	label.size = Vector2(hex_width, hex_height)
	label.position = Vector2(-hex_width / 2.0, -hex_height / 2.0)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	area.add_child(label)
	label_nodes[pos] = label

	# 5. NASŁUCH NA LEWY PRZYCISK (Zamykanie menu)
	# Dodane przedrostki "_" usuwają żółte ostrzeżenia z konsoli (Warnings)
	area.input_event.connect(func(_viewport, event, _shape_idx):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if hud_node:
				var menu = hud_node.get_node_or_null("MenuBudowania")
				if menu: menu.visible = false
	)

	map_container.add_child(area)
	tile_nodes[pos] = area

# --- PANCERNA OBSŁUGA PRAWEGO PRZYCISKU MYSZY (PPM) ---
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		# Pobieramy pozycję myszy z uwzględnieniem ewentualnego ruchu kamery
		var global_mouse_pos = get_global_mouse_position()
		
		# Przepychanie zapytania punktowego przez system fizyki 2D
		var space_state = get_world_2d().direct_space_state
		var query = PhysicsPointQueryParameters2D.new()
		query.position = global_mouse_pos
		query.collide_with_areas = true
		
		var results = space_state.intersect_point(query)
		
		# Jeśli kursor znajduje się bezpośrednio nad heksagonem (Area2D):
		if not results.is_empty():
			var hit_area = results[0]["collider"] as Area2D
			
			# Szukamy, do której współrzędnej Vector2 w słowniku należy to Area2D
			for pos in tile_nodes:
				if tile_nodes[pos] == hit_area:
					var tile_type = map_data[pos]["type"]
					var has_building = map_data[pos]["building"] != "Brak"
					
					# Pobieramy czystą pozycję pikselową na monitorze (idealną dla UI)
					var screen_mouse_pos = get_viewport().get_mouse_position()
					
					# Wywołujemy menu kontekstowe w HUD
					if hud_node and hud_node.has_method("show_context_menu"):
						hud_node.show_context_menu(screen_mouse_pos, pos, tile_type, has_building)
					return

# --- FUNKCJA WYWOŁYWANA PRZEZ HUD PO KLIKNIĘCIU PRZYCISKU W POPUPIE ---
func build_on_tile(pos: Vector2, building_name: String) -> void:
	var tile = map_data[pos]
	
	if EconomyManager.can_afford_and_place(building_name, tile["type"]):
		EconomyManager.deduct_costs(building_name)
		
		map_data[pos]["building"] = building_name
		
		# Zmiana koloru Polygon2D (pierwsze dziecko Area2D) na złoty dla zaznaczenia budowli
		var poly = tile_nodes[pos].get_child(0) as Polygon2D
		if poly:
			poly.color = Color(0.85, 0.65, 0.15)
		
		# Dynamiczna zamiana tekstu na kafelku z surowca na nazwę postawionego budynku
		if label_nodes.has(pos):
			label_nodes[pos].text = building_name

# --- INTERFEJS TURY ---
func get_active_buildings_list() -> Array:
	var list = []
	for pos in map_data:
		if map_data[pos]["building"] != "Brak":
			list.append(map_data[pos]["building"])
	return list
