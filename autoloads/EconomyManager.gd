extends Node
# economy_manager.gd (Autoload / Singleton)

signal economy_updated(balances: Dictionary, current_turn: int, selected_build: String)

var current_turn: int = 1
var player_army: Array = []

var resources: Dictionary = {
	"Złoto": 150,
	"Drewno": 40,
	"Żelazo": 0,
	"Węgiel": 0,
	"Jedzenie": 10,
	"Nauka": 2, 
	"Kultura": 1,
	"Populacja": 1,
	"Maks_Populacja": 5
}

var max_tech_points: float = 100.0
var max_culture_points: float = 100.0

var building_costs: Dictionary = {
	"Chata Drwala": {"Złoto": 30, "Drewno": 10},
	"Kopalnia Żelaza": {"Złoto": 50, "Drewno": 20},
	"Kopalnia Węgla": {"Złoto": 60, "Drewno": 25},
	"Farma": {"Złoto": 25, "Drewno": 15},
	"Pastwisko": {"Złoto": 30, "Drewno": 15},
	"Dom mieszkalny": {"Złoto": 40, "Drewno": 20},
	"Laboratorium": {"Złoto": 100, "Drewno": 50, "Żelazo": 10},
	"Warsztat": {"Złoto": 80, "Drewno": 40, "Żelazo": 5},
	"Biblioteka": {"Złoto": 70, "Drewno": 30},
	"Świątynia": {"Złoto": 150, "Drewno": 40, "Żelazo": 15},
	"Baraki": {"Złoto": 60, "Drewno": 30},
	"Akademia generałów": {"Złoto": 120, "Drewno": 40, "Żelazo": 10}
}

var current_research := ""
var research_turns_left := 0

var current_culture_research := ""
var culture_turns_left := 0

var technology_tree: Dictionary = {
	"Górnictwo": {
		"research_cost": 15,
		"research_time": 2,
		"req": [],
		"unlocked": false,
		"desc": "Podstawy wydobycia.",
		"grid_coords": Vector2(0, 1),
		"icon": "⛏️"
	},
	"Wydajne Maszyny": {
		"research_cost": 45,
		"research_time": 4,
		"req": ["Górnictwo"],
		"unlocked": false,
		"desc": "+3 Żelaza, +2 Węgla.",
		"grid_coords": Vector2(1, 0),
		"icon": "⚙️"
	},
	"Melioracja": {
		"research_cost": 30,
		"research_time": 3,
		"req": [],
		"unlocked": false,
		"desc": "Nawadnianie pól.",
		"grid_coords": Vector2(0, 2),
		"icon": "💧"
	},
	"Płodozmian": {
		"research_cost": 50,
		"research_time": 5,
		"req": ["Melioracja"],
		"unlocked": false,
		"desc": "+3 Jedzenia dla Farm.",
		"grid_coords": Vector2(1, 3),
		"icon": "🌾"
	},
	"Industrializacja": {
		"research_cost": 100,
		"research_time": 8,
		"req": ["Wydajne Maszyny", "Płodozmian"],
		"unlocked": false,
		"desc": "+10 Złota z Centrum Miasta.",
		"grid_coords": Vector2(2, 1.5),
		"icon": "🏭"
	}
}

var culture_tree: Dictionary = {
	"Tradycje": {
		"research_cost": 15,
		"research_time": 2,
		"req": [],
		"unlocked": false,
		"desc": "Podstawy kultury.",
		"grid_coords": Vector2(0,1),
		"icon": "🏛️"
	},

	"Sztuka": {
		"research_cost": 35,
		"research_time": 4,
		"req": ["Tradycje"],
		"unlocked": false,
		"desc": "Rozwój sztuki.",
		"grid_coords": Vector2(1,0),
		"icon": "🎨"
	},

	"Filozofia": {
		"research_cost": 40,
		"research_time": 4,
		"req": ["Tradycje"],
		"unlocked": false,
		"desc": "Rozwój myśli.",
		"grid_coords": Vector2(1,2),
		"icon": "🧠"
	},

	"Teatr": {
		"research_cost": 55,
		"research_time": 6,
		"req": ["Sztuka"],
		"unlocked": false,
		"desc": "+2 Kultury.",
		"grid_coords": Vector2(2,0),
		"icon": "🎭"
	},

	"Edukacja": {
		"research_cost": 70,
		"research_time": 6,
		"req": ["Filozofia"],
		"unlocked": false,
		"desc": "+1 Nauki.",
		"grid_coords": Vector2(2,2),
		"icon": "📚"
	},

	"Renesans": {
		"research_cost": 110,
		"research_time": 10,
		"req": ["Teatr","Edukacja"],
		"unlocked": false,
		"desc": "Złoty wiek kultury.",
		"grid_coords": Vector2(3,1),
		"icon": "🌟"
	}
}

func get_building_tooltip(building_name: String) -> String:
	if not building_costs.has(building_name):
		return ""

	var text = "Wymagania\n"
	match building_name:
		"Chata Drwala": text += "• Wymaga: Drewno\n"
		"Kopalnia Żelaza": text += "• Wymaga: Żelazo\n"
		"Kopalnia Węgla": text += "• Wymaga: Węgiel\n"
		"Farma": text += "• Wymaga: Pszenica\n"
		"Pastwisko": text += "• Wymaga: Bydło\n"
		"Dom mieszkalny", "Laboratorium", "Warsztat", "Biblioteka", "Świątynia", "Baraki", "Akademia generałów":
			text += "• Wymaga: Trawa\n"

	text += "\nKoszt poziomu 1\n"
	for resource in building_costs[building_name]:
		text += "• %s: %d\n" % [resource, building_costs[building_name][resource]]
	return text

func can_afford_and_place(building_name: String, tile_type: String) -> bool:
	if not building_costs.has(building_name): return false
	
	if building_name == "Chata Drwala" and tile_type != "Drewno": return false
	if building_name == "Kopalnia Żelaza" and tile_type != "Żelazo": return false
	if building_name == "Kopalnia Węgla" and tile_type != "Węgiel": return false
	if building_name == "Farma" and tile_type != "Pszenica": return false
	if building_name == "Pastwisko" and tile_type != "Bydło": return false
	if building_name in ["Dom mieszkalny", "Laboratorium", "Warsztat", "Biblioteka", "Świątynia", "Baraki", "Akademia generałów"] and tile_type != "Trawa": return false

	var costs = building_costs[building_name]
	for res in costs:
		if resources.get(res, 0) < costs[res]:
			return false
	return true

func get_upgrade_cost(b_name: String, current_level: int) -> Dictionary:
	var cost = {}
	if building_costs.has(b_name):
		for res in building_costs[b_name]:
			cost[res] = building_costs[b_name][res] * (current_level + 1)
	return cost

func can_afford_upgrade(b_name: String, current_level: int) -> bool:
	if current_level >= 3: return false
	var cost = get_upgrade_cost(b_name, current_level)
	for res in cost:
		if resources.get(res, 0) < cost[res]: return false
	return true

func deduct_upgrade_costs(b_name: String, current_level: int) -> void:
	var cost = get_upgrade_cost(b_name, current_level)
	for res in cost:
		resources[res] -= cost[res]
	notify_change()

func can_afford_tile_purchase() -> bool:
	return resources["Złoto"] >= 50

func deduct_tile_purchase_costs() -> void:
	resources["Złoto"] -= 50
	notify_change()

func deduct_costs(building_name: String) -> void:
	if building_costs.has(building_name):
		var costs = building_costs[building_name]
		for res in costs:
			resources[res] -= costs[res]
		notify_change()

func start_research(tech_name:String):
	if current_research != "":
		return

	var tech = technology_tree[tech_name]

	if resources["Nauka"] < tech["research_cost"]:
		return

	resources["Nauka"] -= tech["research_cost"]
	current_research = tech_name
	research_turns_left = tech["research_time"]
	notify_change()

func start_culture_research(tech_name:String):
	if current_culture_research != "":
		return

	var tech = culture_tree[tech_name]

	if resources["Kultura"] < tech["research_cost"]:
		return

	resources["Kultura"] -= tech["research_cost"]
	current_culture_research = tech_name
	culture_turns_left = tech["research_time"]
	notify_change()

func next_turn(active_buildings_data: Array) -> void:
	current_turn += 1
	var max_pop = 5
	for b_data in active_buildings_data:
		if b_data["name"] == "Dom mieszkalny":
			max_pop += 5 * b_data.get("level", 1)
	resources["Maks_Populacja"] = max_pop
	
	var food_consumption = resources["Populacja"] * 1
	resources["Jedzenie"] -= food_consumption
	
	if current_turn % 3 == 0:
		if resources["Jedzenie"] > 0 and resources["Populacja"] < resources["Maks_Populacja"]:
			resources["Populacja"] += 1
	
	var turn_science = 0
	var turn_culture = 0
	
	for b_data in active_buildings_data:
		var b_name = b_data["name"]
		var b_level = b_data.get("level", 1)
		var size_modifier = 1.0
		
		if b_data.has("deposit_size"):
			match b_data["deposit_size"]:
				"Małe": size_modifier = 0.5
				"Średnie": size_modifier = 1.0
				"Duże": size_modifier = 2.0

		match b_name:
			"Centrum Miasta":
				var gold_bonus = 10 * b_level
				if technology_tree["Industrializacja"]["unlocked"]:
					gold_bonus += 10 * b_level
				resources["Złoto"] += gold_bonus
				resources["Jedzenie"] += 2 * b_level
			"Chata Drwala":
				resources["Drewno"] += int(8 * size_modifier * b_level)
			"Kopalnia Żelaza":
				var iron_yield = 5
				if technology_tree["Wydajne Maszyny"]["unlocked"]: iron_yield += 3
				resources["Żelazo"] += int(iron_yield * size_modifier * b_level)
				resources["Złoto"] -= 2 * b_level
			"Kopalnia Węgla":
				var coal_yield = 4
				if technology_tree["Wydajne Maszyny"]["unlocked"]: coal_yield += 2
				resources["Węgiel"] += int(coal_yield * size_modifier * b_level)
				resources["Złoto"] -= 2 * b_level
			"Farma":
				var farm_yield = 6
				if technology_tree["Płodozmian"]["unlocked"]: farm_yield += 3
				resources["Jedzenie"] += int(farm_yield * size_modifier * b_level)
			"Pastwisko":
				resources["Jedzenie"] += int(5 * size_modifier * b_level)
			"Laboratorium":
				turn_science += 3 * b_level
			"Warsztat":
				turn_science += 1 * b_level
			"Biblioteka":
				turn_science += 2 * b_level
				turn_culture += 1 * b_level
			"Świątynia":
				turn_culture += 3 * b_level
			"Baraki":
				pass # Na razie brak logiki
			"Akademia generałów":
				pass # Na razie brak logiki

	var total_science = 1 + turn_science
	
	resources["Nauka"] = min(
		max_tech_points,
		resources["Nauka"] + total_science
	)

	resources["Kultura"] = min(
		max_culture_points,
		resources["Kultura"] + turn_culture
	)

	if resources["Jedzenie"] < 0:
		resources["Jedzenie"] = 0
		resources["Złoto"] = max(0, resources["Złoto"] - 5)
		if resources["Populacja"] > 1 and randf() < 0.25:
			resources["Populacja"] -= 1

	if current_research != "":
		research_turns_left -= 1
		if research_turns_left <= 0:
			technology_tree[current_research]["unlocked"] = true
			
			match current_research:
				"Industrializacja":
					max_tech_points += 25
			
			current_research = ""
			
	if current_culture_research != "":
		culture_turns_left -= 1
		if culture_turns_left <= 0:
			culture_tree[current_culture_research]["unlocked"] = true
			
			match current_culture_research:
				"Renesans":
					max_culture_points += 25
					
			current_culture_research = ""

	notify_change()

func notify_change() -> void:
	economy_updated.emit(resources, current_turn, "")

func calculate_unit_cost(unit: Dictionary) -> int:
	var hp = unit.get("hp", 0)
	var dmg = unit.get("dmg", 0)
	var def = unit.get("def", 0)
	return int((hp + dmg + def) * 1.5)

func can_recruit_unit(unit: Dictionary) -> bool:
	var cost = calculate_unit_cost(unit)
	return resources.get("Złoto", 0) >= cost

func recruit_unit(unit: Dictionary) -> void:
	var cost = calculate_unit_cost(unit)
	if resources.get("Złoto", 0) >= cost:
		resources["Złoto"] -= cost
		player_army.append(unit)
		notify_change()
