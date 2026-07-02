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

	# --- DODANE: inicjalizacja pathfindingu i postaci ---
	build_astar_graph()
	character = get_node_or_null("Character")
	path_line = get_node_or_null("PathLine")
	if path_line:
		path_line.width = 4.0
		path_line.default_color = Color(1.0, 0.85, 0.0, 0.85)
		path_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		path_line.end_cap_mode = Line2D.LINE_CAP_ROUND
		path_line.joint_mode = Line2D.LINE_JOINT_ROUND
	if character:
		var start_pos = Vector2(MAP_SIZE / 2, MAP_SIZE / 2)
		if cell_to_world.has(start_pos):
			character.global_position = cell_to_world[start_pos]

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

	# --- DODANE: zapamiętaj pozycję świata ---
	cell_to_world[pos] = area.position

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
	area.input_event.connect(func(_viewport, event, _shape_idx):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if hud_node:
				var menu = hud_node.get_node_or_null("MenuBudowania")
				if menu: menu.visible = false
	)

	map_container.add_child(area)
	tile_nodes[pos] = area

# --- PANCERNA OBSŁUGA PRZYCISKÓW MYSZY ---
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var global_mouse_pos = get_global_mouse_position()
		# --- NOWE: Prawy klik zawsze odznacza postać i (opcjonalnie) otwiera menu tylko jeśli nie jest zaznaczona
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if character:
				character.set_selected(false)
			# Prawy klik otwiera menu kontekstowe TYLKO gdy postać nie jest zaznaczona
			var space_state = get_world_2d().direct_space_state
			var query = PhysicsPointQueryParameters2D.new()
			query.position = global_mouse_pos
			query.collide_with_areas = true
			var results = space_state.intersect_point(query)
			if not results.is_empty():
				var hit_area = results[0]["collider"] as Area2D
				for pos in tile_nodes:
					if tile_nodes[pos] == hit_area:
						var tile_type = map_data[pos]["type"]
						var has_building = map_data[pos]["building"] != "Brak"
						# --- BLOKADA BUDOWANIA gdy postać jest zaznaczona
						if character and character.selected:
							return
						var screen_mouse_pos = get_viewport().get_mouse_position()
						if hud_node and hud_node.has_method("show_context_menu"):
							hud_node.show_context_menu(screen_mouse_pos, pos, tile_type, has_building)
						return
			return
		# --- Dalsza obsługa lewego kliknięcia ---
		if event.button_index == MOUSE_BUTTON_LEFT:
			var space_state = get_world_2d().direct_space_state
			var query = PhysicsPointQueryParameters2D.new()
			query.position = global_mouse_pos
			query.collide_with_areas = true
			var results = space_state.intersect_point(query)
			if not results.is_empty():
				var hit_area = results[0]["collider"] as Area2D
				for pos in tile_nodes:
					if tile_nodes[pos] == hit_area:
						# Blokada ruchu gdy menu jest otwarte
						if hud_node:
							var menu = hud_node.get_node_or_null("MenuBudowania")
							if menu and menu.visible:
								return
						# Klik na postać (LEWY) => zaznaczenie/odznaczenie (TOGGLE)
						if character and global_mouse_pos.distance_to(character.global_position) < 20.0:
							# --- NOWE: przełącznik zaznaczenia lewym kliknięciem na postać
							character.set_selected(not character.selected)
							return
						# Ruch tylko gdy postać jest zaznaczona
						if character and character.selected and cell_to_id.has(pos):
							var world_path = get_world_path_to(pos)
							if not world_path.is_empty():
								character.follow_path(world_path)
						return

# --- FUNKCJA WYWOŁYWANA PRZEZ HUD PO KLIKNIĘCIU PRZYCISKU W POPUPIE ---
func build_on_tile(pos: Vector2, building_name: String) -> void:
	if character and character.selected:
		return
	var tile = map_data[pos]
	
	if EconomyManager.can_afford_and_place(building_name, tile["type"]):
		EconomyManager.deduct_costs(building_name)
		
		map_data[pos]["building"] = building_name
		
		var poly = tile_nodes[pos].get_child(0) as Polygon2D
		if poly:
			poly.color = Color(0.85, 0.65, 0.15)
		
		if label_nodes.has(pos):
			label_nodes[pos].text = building_name

# --- INTERFEJS TURY ---
func get_active_buildings_list() -> Array:
	var list = []
	for pos in map_data:
		if map_data[pos]["building"] != "Brak":
			list.append(map_data[pos]["building"])
	return list


# =============================================================
# --- DODANE: PATHFINDING I POSTAĆ ---
# =============================================================

var astar: AStar2D = AStar2D.new()
var cell_to_id: Dictionary = {}
var cell_to_world: Dictionary = {}

var character: Node2D
var path_line: Line2D

func get_cell_id(pos: Vector2) -> int:
	return int(pos.x) + 1000 + (int(pos.y) + 1000) * 2000

func get_hex_neighbors(pos: Vector2) -> Array[Vector2]:
	var x: int = int(pos.x)
	var y: int = int(pos.y)
	var neighbors: Array[Vector2]

	if y % 2 == 0:
		neighbors = [
			Vector2(x + 1, y), Vector2(x - 1, y),
			Vector2(x,     y - 1), Vector2(x - 1, y - 1),
			Vector2(x,     y + 1), Vector2(x - 1, y + 1),
		]
	else:
		neighbors = [
			Vector2(x + 1, y), Vector2(x - 1, y),
			Vector2(x + 1, y - 1), Vector2(x,     y - 1),
			Vector2(x + 1, y + 1), Vector2(x,     y + 1),
		]

	return neighbors

func build_astar_graph() -> void:
	astar.clear()
	cell_to_id.clear()

	for pos in map_data:
		var id: int = get_cell_id(pos)
		astar.add_point(id, cell_to_world[pos])
		cell_to_id[pos] = id

	for pos in map_data:
		for neighbor in get_hex_neighbors(pos):
			if cell_to_id.has(neighbor):
				var from_id: int = cell_to_id[pos]
				var to_id: int = cell_to_id[neighbor]
				if not astar.are_points_connected(from_id, to_id):
					astar.connect_points(from_id, to_id)

func world_to_nearest_cell(world_pos: Vector2) -> Vector2:
	var best_pos: Vector2 = Vector2.ZERO
	var best_dist: float = INF
	for pos in cell_to_world:
		var dist = world_pos.distance_to(cell_to_world[pos])
		if dist < best_dist:
			best_dist = dist
			best_pos = pos
	return best_pos

func get_world_path_to(target_pos: Vector2) -> Array[Vector2]:
	if not character:
		return []

	var start_pos: Vector2 = world_to_nearest_cell(character.global_position)

	if not cell_to_id.has(start_pos) or not cell_to_id.has(target_pos):
		return []

	var id_path: PackedInt64Array = astar.get_id_path(cell_to_id[start_pos], cell_to_id[target_pos])

	if id_path.is_empty():
		return []

	var max_steps: int = mini(id_path.size(), character.move_range + 1)
	var world_path: Array[Vector2] = []
	for i in range(max_steps):
		world_path.append(astar.get_point_position(id_path[i]))

	return world_path

func draw_path_line(world_path: Array[Vector2]) -> void:
	if not path_line:
		return
	path_line.clear_points()
	for point in world_path:
		path_line.add_point(point)


func _process(_delta: float) -> void:
	if not character or not path_line:
		return

	if hud_node:
		var menu = hud_node.get_node_or_null("MenuBudowania")
		if menu and menu.visible:
			path_line.clear_points()
			return

	# --- DODANE: nic nie rób jeśli postać nie jest zaznaczona ---
	if not character.selected:
		path_line.clear_points()
		return

	if not character.path.is_empty():
		draw_path_line(character.path)
		return

	var hovered_pos: Vector2 = world_to_nearest_cell(get_global_mouse_position())
	if cell_to_world.has(hovered_pos) and get_global_mouse_position().distance_to(cell_to_world[hovered_pos]) < HEX_RADIUS:
		draw_path_line(get_world_path_to(hovered_pos))
	else:
		path_line.clear_points()
