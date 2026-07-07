extends Node2D
# game_world.gd (Podpięty pod główny węzeł sceny GameWorld)

const MAP_SIZE = 25
const HEX_RADIUS = 80.0

var hex_width: float = sqrt(3) * HEX_RADIUS
var hex_height: float = 2.0 * HEX_RADIUS

var map_data = {}
var tile_nodes = {}
var tile_sprites = {}
var label_nodes = {}
var owned_tiles: Dictionary = {}
var city_centers: Array[Vector2] = []
var territory_overlays: Dictionary = {}
var last_expansion_turn: int = 1

var map_container: Node2D
var hud_node: Control
var character: Character
var path_line: Line2D

var astar: AStar2D = AStar2D.new()
var cell_to_id: Dictionary = {}
var cell_to_world: Dictionary = {}

const BUILDINGS_RESET_TILE_TO_GRASS = ["Dom mieszkalny", "Laboratorium", "Warsztat", "Biblioteka", "Świątynia", "Baraki", "Akademia generałów"]

func _ready() -> void:
	hud_node = get_tree().current_scene.find_child("UI", true, false)
	if hud_node == null: hud_node = get_tree().current_scene.find_child("HUD", true, false)
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
		if map_data.has(start_pos): map_data[start_pos]["type"] = "Trawa"
		if cell_to_world.has(start_pos):
			character.global_position = cell_to_world[start_pos]
		character.city_creation_requested.connect(_on_character_city_creation_requested)
	EconomyManager.economy_updated.connect(_on_economy_turn_changed)

func generate_map() -> void:
	var sizes = ["Małe", "Średnie", "Duże"]
	for x in range(MAP_SIZE):
		for y in range(MAP_SIZE):
			var pos = Vector2(x, y)
			var type = "Trawa"
			var rand = randf()
			if rand < 0.04: type = "Drewno"
			elif rand < 0.07: type = "Żelazo"
			elif rand < 0.09: type = "Węgiel"
			elif rand < 0.14: type = "Pszenica"
			elif rand < 0.19: type = "Bydło"

			var deposit_size = ""
			var fertility = 0.0

			if type == "Trawa":
				fertility = snapped(randf_range(0.5, 1.5), 0.1)
			else:
				deposit_size = sizes[randi() % sizes.size()]

			map_data[pos] = {
				"type": type,
				"building": "Brak",
				"level": 1,
				"deposit_size": deposit_size,
				"fertility": fertility
			}
			create_procedural_hex(pos, type, deposit_size)

func create_procedural_hex(pos: Vector2, type: String, deposit_size: String) -> void:
	var area = Area2D.new()
	area.input_pickable = true
	area.monitoring = false
	area.monitorable = false

	var x_pos = pos.x * hex_width
	if int(pos.y) % 2 == 1: x_pos += hex_width / 2.0
	var y_pos = pos.y * (hex_height * 0.75)

	area.position = Vector2(x_pos, y_pos) + Vector2(200, 150)
	cell_to_world[pos] = area.position

	var points = _build_hex_points()
	var polygon = Polygon2D.new()
	polygon.polygon = points
	if type == "Trawa" or type == "Drewno" or type == "Pszenica" or type == "Żelazo" or type == "Bydło" or type == "Węgiel":
		# Ustawiamy poligon jako maskę (nie będzie rysowany jego kolor, tylko przytnie on swoje dzieci)
		polygon.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
		polygon.color = Color(1, 1, 1, 1) # Musi mieć pełną widoczność (alpha = 1), żeby działał jako maska
		
		var sprite_bg = Sprite2D.new()
		var zoom_factor = 1.0
		var stretch_y = 1.0
		if type == "Trawa":
			sprite_bg.texture = load("res://assets/tiles/hex_grass.png")
			zoom_factor = 1.25
		elif type == "Drewno":
			sprite_bg.texture = load("res://assets/tiles/hex_forest.png")
			zoom_factor = 1.10
		elif type == "Pszenica":
			sprite_bg.texture = load("res://assets/tiles/hex_wheat.png")
			zoom_factor = 1.15
			stretch_y = 1.20
		elif type == "Żelazo":
			sprite_bg.texture = load("res://assets/tiles/hex_iron.png")
			zoom_factor = 1.15
			stretch_y = 1.15
		elif type == "Bydło":
			sprite_bg.texture = load("res://assets/tiles/hex_cows.png")
			zoom_factor = 1.15
			stretch_y = 1.50
		elif type == "Węgiel":
			sprite_bg.texture = load("res://assets/tiles/hex_coal.png")
			zoom_factor = 1.15
			
		var tex_size = sprite_bg.texture.get_size()
		# Skalujemy Sprite proporcjonalnie i dopasowujemy powiększenie do konkretnej tekstury
		var s = max(hex_width / tex_size.x, hex_height / tex_size.y) * zoom_factor
		sprite_bg.scale = Vector2(s, s * stretch_y)
		polygon.add_child(sprite_bg)
	else:
		polygon.color = _get_tile_color(type)
	area.add_child(polygon)

	var sprite = Sprite2D.new()
	sprite.texture = null
	sprite.scale = Vector2(0.6, 0.6)
	area.add_child(sprite)
	tile_sprites[pos] = sprite

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
	if type == "Trawa" or type == "Drewno" or type == "Pszenica" or type == "Żelazo" or type == "Bydło" or type == "Węgiel":
		label.text = ""
	else:
		label.text = "%s\n(%s)" % [type, deposit_size] if deposit_size != "" else type
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size = Vector2(hex_width, hex_height)
	label.position = Vector2(-hex_width / 2.0, -hex_height / 2.0)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	area.add_child(label)
	label_nodes[pos] = label

	if map_container: map_container.add_child(area)
	else: add_child(area)
	tile_nodes[pos] = area

func _build_hex_points() -> PackedVector2Array:
	var points = PackedVector2Array()
	for i in range(6):
		var angle_rad = deg_to_rad(60.0 * i - 30.0)
		points.append(Vector2(cos(angle_rad), sin(angle_rad)) * HEX_RADIUS)
	return points

func _get_tile_color(type: String) -> Color:
	match type:
		"Drewno": return Color(0.15, 0.6, 0.15)
		"Żelazo": return Color(0.45, 0.45, 0.45)
		"Węgiel": return Color(0.18, 0.18, 0.18)
		"Pszenica": return Color(0.85, 0.75, 0.2)
		"Bydło": return Color(0.45, 0.55, 0.2)
		_: return Color(0.1, 0.45, 0.1)

func _on_character_city_creation_requested(char_global_pos: Vector2) -> void:
	# Dodany warunek: Jeśli tablica city_centers nie jest pusta, przerwij działanie.
	# Zapewnia to, że można stworzyć tylko jedno miasto w grze.
	if not city_centers.is_empty():
		return

	var cell_pos = world_to_nearest_cell(char_global_pos)
	if map_data.has(cell_pos):
		if city_centers.has(cell_pos): return
		if hud_node and hud_node.has_method("show_city_creation_menu"):
			hud_node.show_city_creation_menu(Vector2.ZERO, cell_pos)

func create_city_at(pos: Vector2) -> void:
	if city_centers.has(pos): return
	city_centers.append(pos)
	map_data[pos]["building"] = "Centrum Miasta"
	map_data[pos]["level"] = 1
	if label_nodes.has(pos): label_nodes[pos].text = "🏢 Centrum"

	var poly = tile_nodes[pos].get_child(0) as Polygon2D
	if poly: poly.color = Color(0.2, 0.5, 0.8)

	claim_tile(pos)
	for neighbor in HexUtils.get_neighbors(pos):
		if map_data.has(neighbor): claim_tile(neighbor)

	# Zmiana: Postać nie znika (usuwamy queue_free()), odznaczamy ją jedynie dla porządku wizualnego
	if character:
		character.set_selected(false)

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

func buy_tile(pos: Vector2) -> void:
	if owned_tiles.has(pos): return
	var borders_owned_territory = false
	for neighbor in HexUtils.get_neighbors(pos):
		if owned_tiles.has(neighbor):
			borders_owned_territory = true
			break
	if not borders_owned_territory: return
	if EconomyManager.can_afford_tile_purchase():
		EconomyManager.deduct_tile_purchase_costs()
		claim_tile(pos)

func _on_economy_turn_changed(_balances: Dictionary, current_turn: int, _selected_build: String) -> void:
	if current_turn >= last_expansion_turn + 5:
		last_expansion_turn = current_turn
		expand_territory_by_single_tile()

func expand_territory_by_single_tile() -> void:
	if city_centers.is_empty(): return
	var candidates: Array[Vector2] = []
	var candidate_distances: Array[int] = []

	for owned in owned_tiles:
		for neighbor in HexUtils.get_neighbors(owned):
			if map_data.has(neighbor) and not owned_tiles.has(neighbor):
				if not candidates.has(neighbor):
					candidates.append(neighbor)
					candidate_distances.append(_get_hex_distance_to_nearest_city(neighbor))

	if candidates.is_empty(): return
	var best_index = 0
	var min_distance = candidate_distances[0]

	for i in range(1, candidates.size()):
		if candidate_distances[i] < min_distance:
			min_distance = candidate_distances[i]
			best_index = i

	claim_tile(candidates[best_index])

func _get_hex_distance_to_nearest_city(tile: Vector2) -> int:
	var min_d = 99999
	for city in city_centers:
		var d = HexUtils.get_distance(tile, city)
		if d < min_d: min_d = d
	return min_d

func build_on_tile(pos: Vector2, building_name: String) -> void:
	if character and character.selected: return
	if not owned_tiles.has(pos): return

	var tile = map_data[pos]
	if not EconomyManager.can_afford_and_place(building_name, tile["type"]): return

	EconomyManager.deduct_costs(building_name)

	if building_name in BUILDINGS_RESET_TILE_TO_GRASS and tile["type"] != "Trawa":
		tile["type"] = "Trawa"
		tile["deposit_size"] = ""
		tile["fertility"] = 1.0

	tile["building"] = building_name
	tile["level"] = 1

	var poly = tile_nodes[pos].get_child(0) as Polygon2D
	if poly: poly.color = _get_building_color(building_name)

	if tile_sprites.has(pos):
		# TODO: Zmień na docelową ścieżkę do obrazków budynków
		# tile_sprites[pos].texture = load("res://assets/buildings/" + building_name + ".png")
		pass

	if label_nodes.has(pos):
		label_nodes[pos].text = "%s\n(Lvl 1)" % building_name

func upgrade_building(pos: Vector2) -> void:
	var tile = map_data[pos]
	var b_name = tile["building"]
	if b_name == "Brak" or b_name == "Centrum Miasta": return
	if EconomyManager.can_afford_upgrade(b_name, tile["level"]):
		EconomyManager.deduct_upgrade_costs(b_name, tile["level"])
		tile["level"] += 1
		if label_nodes.has(pos):
			label_nodes[pos].text = "%s\n(Lvl %d)" % [b_name, tile["level"]]

func _get_building_color(building_name: String) -> Color:
	match building_name:
		"Farma": return Color(0.7, 0.6, 0.2)
		"Pastwisko": return Color(0.6, 0.5, 0.15)
		"Dom mieszkalny": return Color(0.65, 0.45, 0.35)
		"Laboratorium": return Color(0.2, 0.5, 0.8)
		"Warsztat": return Color(0.5, 0.4, 0.2)
		"Biblioteka": return Color(0.6, 0.3, 0.6)
		"Świątynia": return Color(0.8, 0.7, 0.3)
		"Baraki": return Color(0.75, 0.2, 0.2)
		"Akademia generałów": return Color(0.4, 0.2, 0.6)
		_: return Color(0.85, 0.65, 0.15)

func get_active_buildings_list() -> Array:
	var list = []
	for pos in map_data:
		var tile = map_data[pos]
		if tile["building"] != "Brak":
			list.append({
				"name": tile["building"],
				"level": tile["level"],
				"deposit_size": tile["deposit_size"],
				"fertility": tile["fertility"]
			})
	return list

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton): return

	var camera = get_node_or_null("StrategyCamera")
	if camera and camera.is_drag_motion:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			camera.is_drag_motion = false
			return

	if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		if hud_node and hud_node.has_method("any_menu_visible") and hud_node.any_menu_visible():
			hud_node.hide_all_menus()
			return

	var global_mouse_pos = get_global_mouse_position()
	var pos = _get_tile_at_world_pos(global_mouse_pos)

	if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if character: character.set_selected(false)
		if pos == null: return
		if character and character.selected: return
		_show_context_menu_for(pos)

	elif event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		if pos == null: return
		_handle_left_click_on_tile(pos, global_mouse_pos)

func _get_tile_at_world_pos(world_pos: Vector2) -> Variant:
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = world_pos
	query.collide_with_areas = true
	var results = space_state.intersect_point(query)
	if results.is_empty(): return null
	var hit_area = results[0]["collider"] as Area2D
	for pos in tile_nodes:
		if tile_nodes[pos] == hit_area: return pos
	return null

func _show_context_menu_for(pos: Vector2) -> void:
	var tile = map_data[pos]
	var is_owned = owned_tiles.has(pos)
	var borders_owned = false
	for n in HexUtils.get_neighbors(pos):
		if owned_tiles.has(n):
			borders_owned = true
			break

	var screen_mouse_pos = get_viewport().get_mouse_position()
	if hud_node and hud_node.has_method("show_context_menu"):
		hud_node.show_context_menu(
			screen_mouse_pos, pos, tile["type"], tile["building"], tile.get("level", 1),
			is_owned, borders_owned, tile["deposit_size"], tile["fertility"]
		)

func _handle_left_click_on_tile(pos: Vector2, global_mouse_pos: Vector2) -> void:
	if hud_node and hud_node.has_method("any_menu_visible") and hud_node.any_menu_visible(): return
	if character and global_mouse_pos.distance_to(character.global_position) < 35.0:
		character.set_selected(not character.selected)
		return
	if character and character.selected and cell_to_id.has(pos):
		var world_path = get_world_path_to(pos)
		if not world_path.is_empty():
			character.follow_path(world_path)

func build_astar_graph() -> void:
	astar.clear()
	cell_to_id.clear()
	for pos in map_data:
		var id: int = HexUtils.get_cell_id(pos)
		astar.add_point(id, cell_to_world[pos])
		cell_to_id[pos] = id
	for pos in map_data:
		for neighbor in HexUtils.get_neighbors(pos):
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
	var max_steps: int = mini(id_path.size(), character.move_range + 1)
	var world_path: Array[Vector2] = []
	for i in range(max_steps): world_path.append(astar.get_point_position(id_path[i]))
	return world_path

func draw_path_line(world_path: Array[Vector2]) -> void:
	if not path_line: return
	path_line.clear_points()
	for point in world_path: path_line.add_point(point)

func _process(_delta: float) -> void:
	if not character or not path_line: return
	if hud_node and hud_node.has_method("any_menu_visible") and hud_node.any_menu_visible():
		path_line.clear_points()
		return
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
