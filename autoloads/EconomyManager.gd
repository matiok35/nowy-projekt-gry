extends Node
# economy_manager.gd (Autoload / Singleton)

signal economy_updated(balances: Dictionary, current_turn: int, selected_build: String)

var current_turn: int = 1

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
	"Świątynia": {"Złoto": 150, "Drewno": 40, "Żelazo": 15}
}

var current_research: String = ""
var research_progress: Dictionary = {}

var technology_tree: Dictionary = {
	"Górnictwo": {
		"cost": 15,
		"req": [],
		"unlocked": false,
		"desc": "Podstawy wydobycia.",
		"grid_coords": Vector2(0, 1),
		"icon": "⛏️"
	},
	"Wydajne Maszyny": {
		"cost": 45,
		"req": ["Górnictwo"],
		"unlocked": false,
		"desc": "+3 Żelaza, +2 Węgla.",
		"grid_coords": Vector2(1, 0),
		"icon": "⚙️"
	},
	"Melioracja": {
		"cost": 30,
		"req": [],
		"unlocked": false,
		"desc": "Nawadnianie pól.",
		"grid_coords": Vector2(0, 2),
		"icon": "💧"
	},
	"Płodozmian": {
		"cost": 50,
		"req": ["Melioracja"],
		"unlocked": false,
		"desc": "+3 Jedzenia dla Farm.",
		"grid_coords": Vector2(1, 3),
		"icon": "🌾"
	},
	"Industrializacja": {
		"cost": 100,
		"req": ["Wydajne Maszyny", "Płodozmian"],
		"unlocked": false,
		"desc": "+10 Złota z Centrum Miasta.",
		"grid_coords": Vector2(2, 1.5),
		"icon": "🏭"
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
		"Dom mieszkalny", "Laboratorium", "Warsztat", "Biblioteka", "Świątynia":
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
	if building_name in ["Dom mieszkalny", "Laboratorium", "Warsztat", "Biblioteka", "Świątynia"] and tile_type != "Trawa": return false

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

	var total_science = 1 + turn_science
	resources["Nauka"] = total_science
	resources["Kultura"] = min(100, resources["Kultura"] + total_science + turn_culture) 

	if resources["Jedzenie"] < 0:
		resources["Jedzenie"] = 0
		resources["Złoto"] = max(0, resources["Złoto"] - 5)
		if resources["Populacja"] > 1 and randf() < 0.25:
			resources["Populacja"] -= 1

	if current_research != "" and technology_tree.has(current_research):
		if not research_progress.has(current_research):
			research_progress[current_research] = 0
		research_progress[current_research] += total_science
		if research_progress[current_research] >= technology_tree[current_research]["cost"]:
			technology_tree[current_research]["unlocked"] = true
			research_progress[current_research] = technology_tree[current_research]["cost"]
			current_research = ""

	notify_change()

func notify_change() -> void:
	economy_updated.emit(resources, current_turn, "")
