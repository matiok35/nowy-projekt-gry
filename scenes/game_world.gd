extends Node2D
# game_world.gd (Podpięty pod główny węzeł sceny GameWorld)

const MAP_SIZE = 50
const HEX_RADIUS = 80.0

var hex_width: float = sqrt(3) * HEX_RADIUS
var hex_height: float = 2.0 * HEX_RADIUS

var map_data = {}
var tile_nodes = {}
var tile_sprites = {}
var label_nodes = {}
var owned_tiles: Dictionary = {}
var city_centers: Array[Vector2] = []
var camps: Dictionary = {}
var camp_owned_tiles: Dictionary = {}
var camp_territory_overlays: Dictionary = {}
var fraction_data: Dictionary = {}
var territory_overlays: Dictionary = {}
var fog_overlays: Dictionary = {}
var explored_tiles: Dictionary = {}
var last_expansion_turn: int = 1

var map_container: Node2D
var hud_node: Control
var character: Character
var path_line: Line2D

var astar: AStar2D = AStar2D.new()
var cell_to_id: Dictionary = {}
var cell_to_world: Dictionary = {}

const BUILDINGS_RESET_TILE_TO_GRASS = ["Dom mieszkalny", "Laboratorium", "Warsztat", "Biblioteka", "Świątynia", "Baraki"]

func _ready() -> void:
	hud_node = get_tree().current_scene.find_child("UI", true, false)
	if hud_node == null: hud_node = get_tree().current_scene.find_child("HUD", true, false)
	map_container = get_node_or_null("MapContainer")
	if GameSettings.use_custom_seed:
		seed(GameSettings.current_seed)
	else:
		randomize()
	_load_fractions()
	generate_map()
	generate_camps(8)
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
		character.city_creation_requested.connect(_on_character_city_creation_requested)
		var cam = get_node_or_null("StrategyCamera")
		if cam:
			cam.global_position = character.global_position
	EconomyManager.economy_updated.connect(_on_economy_turn_changed)
	EconomyManager.unit_training_complete.connect(_on_unit_training_complete)
	update_fog_of_war()

func generate_map() -> void:
	var sizes = ["Małe", "Średnie", "Duże"]
	var start_pos = Vector2(MAP_SIZE / 2, MAP_SIZE / 2)
	
	for x in range(MAP_SIZE):
		for y in range(MAP_SIZE):
			var pos = Vector2(x, y)
			var type = "Trawa"
			
			# POPRAWKA: Enforce Trawa na polu startowym ZANIM wygenerujemy heksa proceduralnego
			if pos == start_pos:
				type = "Trawa"
			else:
				var rand = randf()
				if rand < 0.04: type = "Drewno"
				elif rand < 0.07: type = "Żelazo"
				elif rand < 0.09: type = "Węgiel"
				elif rand < 0.14: type = "Pszenica"
				elif rand < 0.19: type = "Bydło"

			var deposit_size = ""
			if type != "Trawa":
				deposit_size = sizes[randi() % sizes.size()]

			map_data[pos] = {
				"type": type,
				"building": "Brak",
				"level": 1,
				"deposit_size": deposit_size
			}
			create_procedural_hex(pos, type, deposit_size)

func _load_fractions() -> void:
	var dir = DirAccess.open("res://data/fractions")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".json"):
				var file = FileAccess.open("res://data/fractions/" + file_name, FileAccess.READ)
				if file:
					var json_text = file.get_as_text()
					var json = JSON.new()
					var err = json.parse(json_text)
					if err == OK:
						var data = json.get_data()
						if data.has("faction"):
							var faction_id = data["faction"]["id"]
							fraction_data[faction_id] = data["faction"]
			file_name = dir.get_next()

func generate_camps(count: int) -> void:
	if fraction_data.is_empty(): return
	var available_positions = []
	var start_pos = Vector2(MAP_SIZE / 2, MAP_SIZE / 2)
	for pos in map_data.keys():
		if map_data[pos]["building"] == "Brak" and HexUtils.get_distance(pos, start_pos) >= 5:
			if pos.x >= 2 and pos.x < MAP_SIZE - 2 and pos.y >= 2 and pos.y < MAP_SIZE - 2:
				available_positions.append(pos)
	available_positions.shuffle()
	var faction_keys = fraction_data.keys()
	
	var spawned_count = 0
	for pos in available_positions:
		if spawned_count >= count:
			break
			
		var too_close = false
		for existing_camp_pos in camps.keys():
			if HexUtils.get_distance(pos, existing_camp_pos) < 3:
				too_close = true
				break
				
		if too_close:
			continue
			
		var faction_id = faction_keys[randi() % faction_keys.size()]
		var faction_info = fraction_data[faction_id]
		
		var camp_level = randi_range(1, 3)
		var army = []
		if faction_info.has("units") and faction_info["units"].size() > 0:
			var units = faction_info["units"]
			var min_units = camp_level * 2 - 1
			var max_units = camp_level * 3
			for u in range(randi_range(min_units, max_units)):
				var random_unit = units[randi() % units.size()]
				army.append(random_unit["id"])
		
		var camp_data = {
			"faction": faction_id,
			"faction_name": faction_info.get("name", faction_id),
			"army": army,
			"resources": {
				"gold": randi_range(50, 150) * camp_level,
				"wood": randi_range(20, 80) * camp_level,
				"iron": randi_range(10, 50) * camp_level
			},
			"level": camp_level
		}
		camps[pos] = camp_data
		var building_name = "Obóz " + camp_data["faction_name"]
		map_data[pos]["building"] = building_name
		map_data[pos]["level"] = camp_level
		_update_building_label(pos, building_name, camp_level)
		
		# Claim territory for camp
		_claim_camp_territory(pos, camp_level)
		
		spawned_count += 1

func _claim_camp_territory(center_pos: Vector2, level: int) -> void:
	var to_claim = [center_pos]
	if level >= 2:
		for n in HexUtils.get_neighbors(center_pos):
			to_claim.append(n)
	if level >= 3:
		for n in HexUtils.get_neighbors(center_pos):
			for nn in HexUtils.get_neighbors(n):
				if not to_claim.has(nn):
					to_claim.append(nn)
	
	for tile in to_claim:
		if map_data.has(tile) and not owned_tiles.has(tile) and not camp_owned_tiles.has(tile):
			camp_owned_tiles[tile] = true
			var tile_area = tile_nodes[tile]
			var base_poly = tile_area.get_child(0) as Polygon2D
			if base_poly:
				var overlay = Polygon2D.new()
				overlay.polygon = base_poly.polygon
				overlay.color = Color(0.8, 0.1, 0.1, 0.25)
				overlay.z_index = 1
				tile_area.add_child(overlay)
				camp_territory_overlays[tile] = overlay

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
			zoom_factor = 1.0
			stretch_y = 1.05
		elif type == "Drewno":
			sprite_bg.texture = load("res://assets/tiles/forest.png")
			zoom_factor = 0.85
		elif type == "Pszenica":
			sprite_bg.texture = load("res://assets/tiles/wheat.png")
			zoom_factor = 0.85
		elif type == "Żelazo":
			sprite_bg.texture = load("res://assets/tiles/iron.png")
			zoom_factor = 0.85
		elif type == "Bydło":
			sprite_bg.texture = load("res://assets/tiles/cows.png")
			zoom_factor = 0.85
		elif type == "Węgiel":
			sprite_bg.texture = load("res://assets/tiles/coal.png")
			zoom_factor = 0.85
			
		var tex_size = sprite_bg.texture.get_size()
		# Skalujemy Sprite proporcjonalnie i dopasowujemy powiększenie do konkretnej tekstury
		var s = max(hex_width / tex_size.x, hex_height / tex_size.y) * zoom_factor
		sprite_bg.scale = Vector2(s, s * stretch_y)
		
		if type in ["Drewno", "Pszenica", "Żelazo", "Bydło", "Węgiel"]:
			var grass_bg = Sprite2D.new()
			grass_bg.texture = load("res://assets/tiles/hex_grass.png")
			var grass_s = max(hex_width / grass_bg.texture.get_size().x, hex_height / grass_bg.texture.get_size().y) * 1.0
			grass_bg.scale = Vector2(grass_s, grass_s * 1.05)
			polygon.add_child(grass_bg)
			
		polygon.add_child(sprite_bg)
	else:
		polygon.color = _get_tile_color(type)
	area.add_child(polygon)

	var sprite = Sprite2D.new()
	sprite.texture = null
	sprite.scale = Vector2(0.6, 0.6)
	area.add_child(sprite)
	tile_sprites[pos] = sprite

	# Usunięto Line2D odpowiedzialne za rysowanie zielonych ramek między heksami

	var collision = CollisionPolygon2D.new()
	collision.polygon = points
	area.add_child(collision)

	var fog_poly = Polygon2D.new()
	fog_poly.polygon = points
	fog_poly.color = Color(0.5, 0.5, 0.5, 0.85) # Szary overlay, 85% opacity
	fog_poly.z_index = 4 # Poniżej badge (z_index=5), ale nad płytką
	area.add_child(fog_poly)
	fog_overlays[pos] = fog_poly

	var label = _create_building_badge(area)
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

func _create_building_badge(area: Area2D) -> PanelContainer:
	# Kontener-kotwica o rozmiarze heksu, wewnątrz którego plakietka
	# jest przypięta do dolnej krawędzi kafelka i rośnie w górę wraz z treścią.
	var anchor_ctrl = Control.new()
	anchor_ctrl.size = Vector2(hex_width, hex_height)
	anchor_ctrl.position = Vector2(-hex_width / 2.0, -hex_height / 2.0)
	anchor_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	area.add_child(anchor_ctrl)

	var badge = PanelContainer.new()
	badge.name = "BuildingBadge"
	badge.visible = false
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.z_index = 5
	badge.anchor_left = 0.5
	badge.anchor_right = 0.5
	badge.anchor_top = 1.0
	badge.anchor_bottom = 1.0
	badge.grow_horizontal = Control.GROW_DIRECTION_BOTH
	badge.grow_vertical = Control.GROW_DIRECTION_BEGIN
	badge.offset_bottom = -30
	badge.offset_top = -30

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.07, 0.09, 0.85)
	style.set_corner_radius_all(8)
	style.set_border_width_all(1)
	style.border_color = Color(0.85, 0.7, 0.35, 0.9)
	style.content_margin_left = 8.0
	style.content_margin_right = 8.0
	style.content_margin_top = 3.0
	style.content_margin_bottom = 3.0
	style.shadow_color = Color(0, 0, 0, 0.45)
	style.shadow_size = 5
	badge.add_theme_stylebox_override("panel", style)
	badge.set_meta("style_box", style)

	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	vbox.add_theme_constant_override("separation", 1)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	badge.add_child(vbox)

	var top_row = HBoxContainer.new()
	top_row.name = "TopRow"
	top_row.alignment = BoxContainer.ALIGNMENT_CENTER
	top_row.add_theme_constant_override("separation", 4)
	vbox.add_child(top_row)

	var icon_lbl = Label.new()
	icon_lbl.name = "Icon"
	icon_lbl.add_theme_font_size_override("font_size", 13)
	top_row.add_child(icon_lbl)

	var name_lbl = Label.new()
	name_lbl.name = "NameLabel"
	name_lbl.add_theme_font_size_override("font_size", 12)
	name_lbl.add_theme_color_override("font_color", Color(0.97, 0.95, 0.9))
	name_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	name_lbl.add_theme_constant_override("shadow_offset_x", 1)
	name_lbl.add_theme_constant_override("shadow_offset_y", 1)
	name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top_row.add_child(name_lbl)

	var level_row = HBoxContainer.new()
	level_row.name = "LevelRow"
	level_row.alignment = BoxContainer.ALIGNMENT_CENTER
	level_row.add_theme_constant_override("separation", 2)
	vbox.add_child(level_row)

	anchor_ctrl.add_child(badge)
	return badge

func _update_building_label(pos: Vector2, building_name: String, level: int) -> void:
	if not label_nodes.has(pos): return
	var badge: PanelContainer = label_nodes[pos]

	var icon_lbl: Label = badge.get_node("VBox/TopRow/Icon")
	var name_lbl: Label = badge.get_node("VBox/TopRow/NameLabel")
	var level_row: HBoxContainer = badge.get_node("VBox/LevelRow")

	if building_name == "Brak":
		badge.visible = false
		return

	icon_lbl.text = _get_building_icon(building_name)
	name_lbl.text = building_name

	var style: StyleBoxFlat = badge.get_meta("style_box")
	if style:
		style.border_color = _get_building_accent_color(building_name)

	for child in level_row.get_children():
		child.queue_free()

	var max_level := 3
	if building_name == "Centrum Miasta":
		level_row.visible = false
	else:
		level_row.visible = true
		for i in range(max_level):
			var star = Label.new()
			star.add_theme_font_size_override("font_size", 10)
			if i < level:
				star.text = "★"
				star.add_theme_color_override("font_color", Color(1.0, 0.82, 0.25))
			else:
				star.text = "★"
				star.add_theme_color_override("font_color", Color(0.4, 0.4, 0.45, 0.5))
			level_row.add_child(star)

	if explored_tiles.has(pos):
		badge.visible = true
	else:
		badge.visible = false

func _get_building_icon(building_name: String) -> String:
	if building_name.begins_with("Obóz"): return "⛺"
	match building_name:
		"Centrum Miasta": return "🏛️"
		"Dom mieszkalny": return "🏠"
		"Chata Drwala": return "🪓"
		"Kopalnia Żelaza": return "⛏️"
		"Kopalnia Węgla": return "🪨"
		"Farma": return "🌾"
		"Pastwisko": return "🐄"
		"Laboratorium": return "🔬"
		"Warsztat": return "🔧"
		"Biblioteka": return "📚"
		"Świątynia": return "⛩️"
		"Baraki": return "🏹"
		_: return "🏗️"

func _get_building_accent_color(building_name: String) -> Color:
	if building_name.begins_with("Obóz"): return Color(0.8, 0.2, 0.2, 0.9)
	match building_name:
		"Centrum Miasta": return Color(1.0, 0.85, 0.35, 0.95)
		"Dom mieszkalny": return Color(0.95, 0.62, 0.4, 0.9)
		"Chata Drwala": return Color(0.5, 0.78, 0.4, 0.9)
		"Kopalnia Żelaza": return Color(0.68, 0.72, 0.78, 0.9)
		"Kopalnia Węgla": return Color(0.55, 0.55, 0.6, 0.9)
		"Farma": return Color(0.85, 0.75, 0.3, 0.9)
		"Pastwisko": return Color(0.78, 0.62, 0.38, 0.9)
		"Laboratorium": return Color(0.4, 0.68, 0.95, 0.9)
		"Warsztat": return Color(0.72, 0.52, 0.3, 0.9)
		"Biblioteka": return Color(0.72, 0.46, 0.85, 0.9)
		"Świątynia": return Color(0.92, 0.82, 0.5, 0.9)
		"Baraki": return Color(0.86, 0.2, 0.2, 0.9)
		_: return Color(0.85, 0.7, 0.35, 0.9)

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
	_update_building_label(pos, "Centrum Miasta", 1)

	_update_tile_texture_for_building(pos, "Centrum Miasta")

	claim_tile(pos)
	for neighbor in HexUtils.get_neighbors(pos):
		if map_data.has(neighbor): claim_tile(neighbor)

	# Zmiana: Postać nie znika (usuwamy queue_free()), odznaczamy ją jedynie dla porządku wizualnego
	if character:
		character.set_selected(false)

func claim_tile(pos: Vector2) -> void:
	if owned_tiles.has(pos): return
	# Zabezpieczenie: pole obozowiska wroga lub jego terytorium nigdy nie może
	# zostać automatycznie (ani ręcznie) przyznane graczowi.
	if camps.has(pos) or camp_owned_tiles.has(pos): return
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

func destroy_camp(pos: Vector2) -> void:
	if not camps.has(pos):
		return
	var camp_data = camps[pos]
	var level = camp_data.get("level", 1)

	# Zwalniamy dokładnie ten sam zestaw pól, który obóz zajął w
	# _claim_camp_territory przy swoim powstaniu.
	var to_release = [pos]
	if level >= 2:
		for n in HexUtils.get_neighbors(pos):
			to_release.append(n)
	if level >= 3:
		for n in HexUtils.get_neighbors(pos):
			for nn in HexUtils.get_neighbors(n):
				if not to_release.has(nn):
					to_release.append(nn)

	for tile in to_release:
		if camp_owned_tiles.has(tile):
			camp_owned_tiles.erase(tile)
		if camp_territory_overlays.has(tile):
			var overlay = camp_territory_overlays[tile]
			if is_instance_valid(overlay):
				overlay.queue_free()
			camp_territory_overlays.erase(tile)

	camps.erase(pos)

	if map_data.has(pos):
		map_data[pos]["building"] = "Brak"
		map_data[pos]["level"] = 1
		map_data[pos]["type"] = "Trawa"
		map_data[pos]["deposit_size"] = ""

	_update_building_label(pos, "Brak", 1)

	# Przywracamy wygląd zwykłej trawy (bez tekstury/sprite'u budynku obozowiska).
	if tile_nodes.has(pos):
		var poly = tile_nodes[pos].get_child(0) as Polygon2D
		if poly:
			poly.clip_children = CanvasItem.CLIP_CHILDREN_DISABLED
			for child in poly.get_children():
				if child is Sprite2D:
					child.queue_free()
			poly.color = _get_tile_color("Trawa")

func buy_tile(pos: Vector2) -> void:
	if owned_tiles.has(pos): return
	# Nie pozwalamy kupić pola obozowiska wroga ani pola należącego do jego terytorium
	if camps.has(pos) or camp_owned_tiles.has(pos): return
	var borders_owned_territory = false
	for neighbor in HexUtils.get_neighbors(pos):
		if owned_tiles.has(neighbor):
			borders_owned_territory = true
			break
	if not borders_owned_territory: return
	if EconomyManager.can_afford_tile_purchase():
		EconomyManager.deduct_tile_purchase_costs()
		claim_tile(pos)

func _on_unit_training_complete(unit: Dictionary) -> void:
	# Jednostka kończy rekrutację dopiero po wymaganej liczbie tur - dopiero
	# wtedy przypisujemy ją automatycznie do generała.
	if character:
		character.assign_army([unit])

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
				# Pomijamy pola zajęte przez obozowisko wroga lub należące do jego terytorium -
				# takie pola nie mogą zostać automatycznie przyznane graczowi.
				if camps.has(neighbor) or camp_owned_tiles.has(neighbor):
					continue
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

	tile["building"] = building_name
	tile["level"] = 1

	_update_tile_texture_for_building(pos, building_name)

	_update_building_label(pos, building_name, 1)

func upgrade_building(pos: Vector2) -> void:
	var tile = map_data[pos]
	var b_name = tile["building"]
	if b_name == "Brak" or b_name == "Centrum Miasta": return
	if EconomyManager.can_afford_upgrade(b_name, tile["level"]):
		EconomyManager.deduct_upgrade_costs(b_name, tile["level"])
		tile["level"] += 1
		_update_building_label(pos, b_name, tile["level"])
		if b_name == "Baraki" and hud_node and hud_node.barracks_menu:
			hud_node.barracks_menu.upgrade_barracks_units()

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
		_: return Color(0.85, 0.65, 0.15)

func _update_tile_texture_for_building(pos: Vector2, building_name: String) -> void:
	var poly = tile_nodes[pos].get_child(0) as Polygon2D
	if not poly: return
	
	var texture_path = ""
	var zoom_factor = 1.0
	var stretch_y = 1.0
	
	match building_name:
		"Centrum Miasta":
			texture_path = "res://assets/tiles/city_center.png"
			zoom_factor = 0.85
		"Dom mieszkalny":
			texture_path = "res://assets/tiles/residential_house.png"
			zoom_factor = 0.85
		"Chata Drwala": 
			texture_path = "res://assets/tiles/sawmill.png"
			zoom_factor = 0.85
		"Kopalnia Żelaza": 
			texture_path = "res://assets/tiles/iron_mine.png"
			zoom_factor = 0.85
		"Kopalnia Węgla": 
			texture_path = "res://assets/tiles/coal_mine.png"
			zoom_factor = 0.85
		"Farma": 
			texture_path = "res://assets/tiles/farm.png"
			zoom_factor = 0.85
		"Pastwisko": 
			texture_path = "res://assets/tiles/pasture.png"
			zoom_factor = 0.85
		"Laboratorium": 
			texture_path = "res://assets/tiles/lab.png"
			zoom_factor = 0.85
		"Warsztat": 
			texture_path = "res://assets/tiles/workshop.png"
			zoom_factor = 0.85
		"Biblioteka": 
			texture_path = "res://assets/tiles/library.png"
			zoom_factor = 0.85
		"Świątynia": 
			texture_path = "res://assets/tiles/temple.png"
			zoom_factor = 0.85
		"Baraki": 
			texture_path = "res://assets/tiles/barracks.png"
			zoom_factor = 0.85
	
	if texture_path != "":
		poly.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
		poly.color = Color(1, 1, 1, 1)
		
		for child in poly.get_children():
			if child is Sprite2D:
				child.queue_free()
				
		var overlay_buildings = ["Chata Drwala", "Kopalnia Węgla", "Kopalnia Żelaza", "Świątynia", "Baraki", "Centrum Miasta", "Farma", "Pastwisko", "Dom mieszkalny", "Laboratorium", "Warsztat", "Biblioteka"]
		if building_name in overlay_buildings:
			var grass_bg = Sprite2D.new()
			grass_bg.texture = load("res://assets/tiles/hex_grass.png")
			var grass_s = max(hex_width / grass_bg.texture.get_size().x, hex_height / grass_bg.texture.get_size().y) * 1.0
			grass_bg.scale = Vector2(grass_s, grass_s * 1.05)
			poly.add_child(grass_bg)
			
		var sprite_bg = Sprite2D.new()
		poly.add_child(sprite_bg)
			
		var tex = load(texture_path)
		if tex:
			sprite_bg.texture = tex
			var tex_size = tex.get_size()
			var s = max(hex_width / tex_size.x, hex_height / tex_size.y) * zoom_factor
			sprite_bg.scale = Vector2(s, s * stretch_y)
	else:
		poly.clip_children = CanvasItem.CLIP_CHILDREN_DISABLED
		for child in poly.get_children():
			if child is Sprite2D:
				child.queue_free()
		poly.color = _get_building_color(building_name)

func get_active_buildings_list() -> Array:
	var list = []
	for pos in map_data:
		var tile = map_data[pos]
		if tile["building"] != "Brak":
			list.append({
				"name": tile["building"],
				"level": tile["level"],
				"deposit_size": tile["deposit_size"]
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
			is_owned, borders_owned, tile["deposit_size"]
		)

func _handle_left_click_on_tile(pos: Vector2, global_mouse_pos: Vector2) -> void:
	if hud_node and hud_node.has_method("any_menu_visible") and hud_node.any_menu_visible(): return
	if character and global_mouse_pos.distance_to(character.global_position) < 35.0:
		character.set_selected(not character.selected)
		return
	if character and character.selected and cell_to_id.has(pos):
		var world_path = get_world_path_to(pos)
		if not world_path.is_empty():
			var steps = world_path.size() - 1
			character.moves_left -= steps
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
	var max_steps: int = mini(id_path.size(), character.moves_left + 1)
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

func update_fog_of_war() -> void:
	if not character: return
	var char_cell = world_to_nearest_cell(character.global_position)
	for pos in tile_nodes:
		var dist = HexUtils.get_distance(pos, char_cell)
		var tile_area = tile_nodes[pos]
		tile_area.modulate = Color(1.0, 1.0, 1.0, 1.0) # Resetujemy modulate
		
		var fog = fog_overlays.get(pos)
		if not fog: continue
		
		var is_explored = false
		if dist <= 4:
			explored_tiles[pos] = true
			fog.visible = false
			is_explored = true
		elif explored_tiles.has(pos):
			fog.visible = true
			fog.color = Color(0.5, 0.5, 0.5, 0.45) # Częściowo przezroczysty szary
			is_explored = true
		else:
			fog.visible = true
			fog.color = Color(0.5, 0.5, 0.5, 0.85) # Mocno nieprzezroczysty szary
			
		if label_nodes.has(pos) and map_data.has(pos) and map_data[pos].get("building", "Brak") != "Brak":
			label_nodes[pos].visible = is_explored
			
		if camp_territory_overlays.has(pos):
			camp_territory_overlays[pos].visible = is_explored
