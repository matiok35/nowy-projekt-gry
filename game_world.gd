extends Node2D
# game_world.gd (Podpięty pod główny węzeł sceny GameWorld)

const MAP_SIZE = 25
const HEX_RADIUS = 50.0 

var hex_width: float = sqrt(3) * HEX_RADIUS
var hex_height: float = 2.0 * HEX_RADIUS

var map_data = {}        
var tile_nodes = {}      
var label_nodes = {}     

var owned_tiles: Dictionary = {}         
var city_centers: Array[Vector2] = []      
var territory_overlays: Dictionary = {}   
var last_expansion_turn: int = 1         

var map_container: Node2D
var hud_node: Control    

var astar: AStar2D = AStar2D.new()
var cell_to_id: Dictionary = {}
var cell_to_world: Dictionary = {}

var character: Node2D 
var path_line: Line2D

func _ready():
	hud_node = get_tree().current_scene.find_child("UI", true, false)
	if hud_node == null:
		hud_node = get_tree().current_scene.find_child("HUD", true, false)
		
	map_container = get_node_or_null("MapContainer")
	randomize()
	generate_map()
	build_astar_graph()
	
	character = get_node_or_null("Character")
	path_line = get_node_or_null("PathLine")
	
	if path_line:
		path_line.width = 4.0
		path_line.default_color = Color(1.0, 0.85, 0.0, 0.85)
		
	if character:
		var start_pos = Vector2(MAP_SIZE / 2, MAP_SIZE / 2)
		if cell_to_world.has(start_pos):
			character.global_position = cell_to_world[start_pos]
		if character.has_signal("city_creation_requested"):
			character.city_creation_requested.connect(_on_character_city_creation_requested)
			
	EconomyManager.economy_updated.connect(_on_economy_turn_changed)

func generate_map():
	var sizes = ["Małe", "Średnie", "Duże"]
	for x in range(MAP_SIZE):
		for y in range(MAP_SIZE):
			var pos = Vector2(x, y)
			var type = "Trawa"
			var rand = randf()
			if rand < 0.04: type = "Drewno"
			elif rand < 0.07: type = "Żelazo"
			elif rand < 0.09: type = "Węgiel"
				
			# Generowanie cech unikalnych dla pola
			var deposit_size = ""
			var fertility = 0.0
			
			if type == "Trawa":
				# Żyzność od 50% do 150%
				fertility = snapped(randf_range(0.5, 1.5), 0.1)
			else:
				deposit_size = sizes[randi() % sizes.size()]
				
			map_data[pos] = {
				"type": type, 
				"building": "Brak",
				"deposit_size": deposit_size,
				"fertility": fertility
			}
			create_procedural_hex(pos, type, deposit_size)

func create_procedural_hex(pos: Vector2, type: String, deposit_size: String):
	var area = Area2D.new()
	area.input_pickable = true
	area.monitoring = false
	area.monitorable = false
	
	var x_pos = pos.x * hex_width
	if int(pos.y) % 2 == 1:
		x_pos += hex_width / 2.0
	var y_pos = pos.y * (hex_height * 0.75)
	
	area.position = Vector2(x_pos, y_pos) + Vector2(200, 150)
	cell_to_world[pos] = area.position

	var polygon = Polygon2D.new()
	var points = PackedVector2Array()
	for i in range(6):
		var angle_deg = 60.0 * i - 30.0 
		var angle_rad = deg_to_rad(angle_deg)
		points.append(Vector2(cos(angle_rad), sin(angle_rad)) * HEX_RADIUS)
		
	polygon.polygon = points
	if type == "Drewno": polygon.color = Color(0.15, 0.6, 0.15)
	elif type == "Żelazo": polygon.color = Color(0.45, 0.45, 0.45)
	elif type == "Węgiel": polygon.color = Color(0.18, 0.18, 0.18)
	else: polygon.color = Color(0.1, 0.45, 0.1) 
		
	area.add_child(polygon)

	var line = Line2D.new()
	var line_points = points.duplicate()
	line_points.append(points[0])
	line.points = line_points
	line.width = 2.0
	line.default_color = Color(0.05, 0.25, 0.05)
	area.add_child(line)

	var collision = CollisionPolygon2D.new()
	collision.polygon = points
	area.add_child(collision)

	var label = Label.new()
	# Wyświetlanie nazwy i wielkości złoża na mapie
	if type != "Trawa":
		label.text = "%s\n(%s)" % [type, deposit_size]
	else:
		label.text = type
		
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size = Vector2(hex_width, hex_height)
	label.position = Vector2(-hex_width / 2.0, -hex_height / 2.0)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	area.add_child(label)
	label_nodes[pos] = label

	area.input_event.connect(func(_viewport, event, _shape_idx):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if hud_node: hud_node.hide_all_menus()
	)

	map_container.add_child(area)
	tile_nodes[pos] = area

func _on_character_city_creation_requested(char_global_pos: Vector2) -> void:
	var cell_pos = world_to_nearest_cell(char_global_pos)
	if map_data.has(cell_pos):
		if city_centers.has(cell_pos): return 
		if hud_node and hud_node.has_method("show_city_creation_menu"):
			hud_node.show_city_creation_menu(Vector2.ZERO, cell_pos)

func create_city_at(pos: Vector2) -> void:
	if city_centers.has(pos): return
	city_centers.append(pos)
	map_data[pos]["building"] = "Centrum Miasta"
	if label_nodes.has(pos):
		label_nodes[pos].text = "🏢 Centrum"
		
	var poly = tile_nodes[pos].get_child(0) as Polygon2D
	if poly: poly.color = Color(0.2, 0.5, 0.8)
		
	claim_tile(pos)
	for neighbor in get_hex_neighbors(pos):
		if map_data.has(neighbor):
			claim_tile(neighbor)

	if character:
		character.queue_free()
		character = null

func claim_tile(pos: Vector2) -> void:
	if owned_tiles.has(pos): return
	owned_tiles[pos] = true
	var tile_area = tile_nodes[pos]
	var base_poly = tile_area.get_child(0) as Polygon2D
	
	if base_poly:
		var overlay = Polygon2D.new()
		overlay.polygon = base_poly.polygon
		overlay.color = Color(1.0, 0.85, 0.0, 0.3)
		overlay.z_index = 1 
		tile_area.add_child(overlay)
		territory_overlays[pos] = overlay

func _on_economy_turn_changed(_balances: Dictionary, current_turn: int, _selected_build: String) -> void:
	if current_turn >= last_expansion_turn + 5:
		last_expansion_turn = current_turn
		expand_territory_by_single_tile()

func expand_territory_by_single_tile() -> void:
	if city_centers.is_empty(): return
	var candidates: Array[Vector2] = []
	var candidate_distances: Array[int] = []
	
	for owned in owned_tiles:
		for neighbor in get_hex_neighbors(owned):
			if map_data.has(neighbor) and not owned_tiles.has(neighbor):
				if not candidates.has(neighbor):
					var min_dist = get_hex_distance_to_nearest_city(neighbor)
					candidates.append(neighbor)
					candidate_distances.append(min_dist)
					
	if candidates.is_empty(): return
	var best_index = 0
	var min_distance = candidate_distances[0]
	
	for i in range(1, candidates.size()):
		if candidate_distances[i] < min_distance:
			min_distance = candidate_distances[i]
			best_index = i
			
	claim_tile(candidates[best_index])

func get_hex_distance_to_nearest_city(tile: Vector2) -> int:
	var min_d = 99999
	for city in city_centers:
		var d = get_hex_distance(tile, city)
		if d < min_d: min_d = d
	return min_d

func get_hex_distance(a: Vector2, b: Vector2) -> int:
	var az = a.y
	var ax = a.x - (int(a.y) / 2)
	var ay = -ax - az
	var bz = b.y
	var bx = b.x - (int(b.y) / 2)
	var by = -bx - bz
	return int((abs(ax - bx) + abs(ay - by) + abs(az - bz)) / 2.0)

func buy_tile(pos: Vector2) -> void:
	if owned_tiles.has(pos): return
	var borders_owned_territory = false
	for neighbor in get_hex_neighbors(pos):
		if owned_tiles.has(neighbor):
			borders_owned_territory = true
			break
	if not borders_owned_territory: return 
	if EconomyManager.can_afford_tile_purchase():
		EconomyManager.deduct_tile_purchase_costs()
		claim_tile(pos)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var global_mouse_pos = get_global_mouse_position()
		
		# --- PRAWY KLIK ---
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if character: character.call("set_selected", false)
			var space_state = get_world_2d().direct_space_state
			var query = PhysicsPointQueryParameters2D.new()
			query.position = global_mouse_pos
			query.collide_with_areas = true
			var results = space_state.intersect_point(query)
			
			if not results.is_empty():
				var hit_area = results[0]["collider"] as Area2D
				for pos in tile_nodes:
					if tile_nodes[pos] == hit_area:
						if character and character.get("selected"): return
						
						var tile = map_data[pos]
						var has_building = tile["building"] != "Brak"
						var is_owned = owned_tiles.has(pos)
						
						var borders_owned = false
						for n in get_hex_neighbors(pos):
							if owned_tiles.has(n):
								borders_owned = true
								break
								
						var screen_mouse_pos = get_viewport().get_mouse_position()
						if hud_node and hud_node.has_method("show_context_menu"):
							# Przekazujemy dodatkowe informacje o złożu i żyzności do HUD
							hud_node.show_context_menu(
								screen_mouse_pos, pos, tile["type"], tile["building"], 
								is_owned, borders_owned, tile["deposit_size"], tile["fertility"]
							)
						return
			return
			
		# --- LEWY KLIK ---
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
						if hud_node and hud_node.has_method("any_menu_visible") and hud_node.any_menu_visible():
							return
						if character and global_mouse_pos.distance_to(character.global_position) < 20.0:
							var current_state = character.get("selected")
							character.call("set_selected", not current_state)
							return
						if character and character.get("selected") and cell_to_id.has(pos):
							var world_path = get_world_path_to(pos)
							if not world_path.is_empty():
								character.call("follow_path", world_path)
						return

func build_on_tile(pos: Vector2, building_name: String) -> void:
	if character and character.get("selected"): return
	if not owned_tiles.has(pos): return 
	
	var tile = map_data[pos]
	if EconomyManager.can_afford_and_place(building_name, tile["type"]):
		EconomyManager.deduct_costs(building_name)
		
		if building_name in ["Farma", "Laboratorium", "Warsztat", "Biblioteka", "Świątynia"] and tile["type"] != "Trawa":
			tile["type"] = "Trawa"
			tile["deposit_size"] = ""
			tile["fertility"] = 1.0 # Domyślna żyzność po zniszczeniu
		
		tile["building"] = building_name
		
		var poly = tile_nodes[pos].get_child(0) as Polygon2D
		if poly:
			if building_name == "Farma": poly.color = Color(0.7, 0.6, 0.2)
			elif building_name == "Laboratorium": poly.color = Color(0.2, 0.5, 0.8)
			elif building_name == "Warsztat": poly.color = Color(0.5, 0.4, 0.2)
			elif building_name == "Biblioteka": poly.color = Color(0.6, 0.3, 0.6)
			elif building_name == "Świątynia": poly.color = Color(0.8, 0.7, 0.3)
			else: poly.color = Color(0.85, 0.65, 0.15)
			
		if label_nodes.has(pos):
			label_nodes[pos].text = building_name

# Tworzy kompletną listę budynków z ich modyfikatorami środowiskowymi dla EconomyManager
func get_active_buildings_list() -> Array:
	var list = []
	for pos in map_data:
		var tile = map_data[pos]
		if tile["building"] != "Brak":
			list.append({
				"name": tile["building"],
				"deposit_size": tile["deposit_size"],
				"fertility": tile["fertility"]
			})
	return list

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
	if not character: return []
	var start_pos: Vector2 = world_to_nearest_cell(character.global_position)
	if not cell_to_id.has(start_pos) or not cell_to_id.has(target_pos): return []
	var id_path: PackedInt64Array = astar.get_id_path(cell_to_id[start_pos], cell_to_id[target_pos])
	if id_path.is_empty(): return []
	var m_range = character.get("move_range") if character.get("move_range") else 4
	var max_steps: int = mini(id_path.size(), m_range + 1)
	var world_path: Array[Vector2] = []
	for i in range(max_steps):
		world_path.append(astar.get_point_position(id_path[i]))
	return world_path

func draw_path_line(world_path: Array[Vector2]) -> void:
	if not path_line: return
	path_line.clear_points()
	for point in world_path:
		path_line.add_point(point)

func _process(_delta: float) -> void:
	if not character or not path_line: return
	if hud_node and hud_node.has_method("any_menu_visible") and hud_node.any_menu_visible():
		path_line.clear_points()
		return
	if not character.get("selected"):
		path_line.clear_points()
		return
	var char_path = character.get("path")
	if char_path and not char_path.is_empty():
		draw_path_line(char_path)
		return
	var hovered_pos: Vector2 = world_to_nearest_cell(get_global_mouse_position())
	if cell_to_world.has(hovered_pos) and get_global_mouse_position().distance_to(cell_to_world[hovered_pos]) < HEX_RADIUS:
		draw_path_line(get_world_path_to(hovered_pos))
	else:
		path_line.clear_points()
