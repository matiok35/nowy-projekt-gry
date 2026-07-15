extends Node
# economy_manager.gd (Autoload / Singleton)

signal economy_updated(balances: Dictionary, current_turn: int, selected_build: String)
signal unit_training_complete(unit: Dictionary)

var current_turn: int = 1
var player_army: Array = []

var army_bonus_hp: int = 0
var army_bonus_dmg: int = 0
var army_bonus_def: int = 0

var resources: Dictionary = {
	"Złoto": 150,
	"Drewno": 40,
	"Żelazo": 0,
	"Węgiel": 0,
	"Jedzenie": 10,
	"Nauka": 2, 
	"Kultura": 1,
	"Populacja": 1,
	"Maks_Populacja": 5,
	"Głoduje": false
}

var max_tech_points: float = 350.0
var max_culture_points: float = 350.0 # POPRAWKA: Zwiększono limit, aby nowe węzły były osiągalne

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
	"Baraki": {"Złoto": 60, "Drewno": 30}
}

var current_research := ""
var research_turns_left := 0

var current_culture_research := ""
var culture_turns_left := 0

var building_tech_requirements: Dictionary = {
	"Chata Drwala": "Chata drwala",
	"Pastwisko": "Hodowla bydła",
	"Kopalnia Żelaza": "Górnictwo",
	"Kopalnia Węgla": "Górnictwo",
	"Warsztat": "Warsztat",
	"Świątynia": "Świątynia",
	"Baraki": "Baraki",
	"Laboratorium": "Laboratorium",
	"Biblioteka": "Biblioteka"
}

var upgrade_tech_requirements: Dictionary = {
	"Chata Drwala": {2: "2lvl Chata drwala", 3: "3lvl Chata drwala"},
	"Farma": {2: "Hodowla + farma 2lvl", 3: "3lvl Hodowla + farma"},
	"Pastwisko": {2: "Hodowla + farma 2lvl", 3: "3lvl Hodowla + farma"},
	"Kopalnia Żelaza": {2: "2lvl Górnictwo", 3: "3lvl Górnictwo"},
	"Kopalnia Węgla": {2: "2lvl Górnictwo", 3: "3lvl Górnictwo"},
	"Warsztat": {2: "2lvl Warsztat", 3: "Warsztat 3 lvl"},
	"Świątynia": {2: "Świątynia 2lvl", 3: "Świątynia 3lvl"},
	"Baraki": {2: "Baraki 2lvl", 3: "Baraki 3lvl"},
	"Laboratorium": {2: "Laboratorium 2lvl", 3: "Laboratorium 3lvl"},
	"Biblioteka": {2: "Biblioteka 2lvl", 3: "Biblioteka 3lvl"},
	"Dom mieszkalny": {2: "Dom mieszkalny 2lvl", 3: "Dom mieszkalny 3lvl"}
}

var technology_tree: Dictionary = {
	"Chata drwala": {
		"research_cost": 10, "research_time": 1, "req": [], "unlocked": false, "desc": "Podstawa.", "grid_coords": Vector2(0, 3), "icon": "🪓"
	},
	"2lvl Chata drwala": {
		"research_cost": 30, "research_time": 3, "req": ["Chata drwala"], "unlocked": false, "desc": "Większy drwal.", "grid_coords": Vector2(1, 2), "icon": "🪓"
	},
	"3lvl Chata drwala": {
		"research_cost": 50, "research_time": 5, "req": ["2lvl Chata drwala"], "unlocked": false, "desc": "Wielki drwal.", "grid_coords": Vector2(2, 1), "icon": "🪓"
	},
	"Hodowla bydła": {
		"research_cost": 20, "research_time": 2, "req": ["Chata drwala"], "unlocked": false, "desc": "Zwierzęta.", "grid_coords": Vector2(1, 4), "icon": "🐄"
	},
	"Hodowla + farma 2lvl": {
		"research_cost": 40, "research_time": 4, "req": ["Hodowla bydła", "2lvl Chata drwala"], "unlocked": false, "desc": "Rozwój rolnictwa.", "grid_coords": Vector2(2, 3), "icon": "🌾"
	},
	"Górnictwo": {
		"research_cost": 40, "research_time": 4, "req": ["Hodowla bydła"], "unlocked": false, "desc": "Wydobycie surowców.", "grid_coords": Vector2(2, 5), "icon": "⛏️"
	},
	"3lvl Hodowla + farma": {
		"research_cost": 60, "research_time": 6, "req": ["Hodowla + farma 2lvl", "3lvl Chata drwala"], "unlocked": false, "desc": "Zaawansowane rolnictwo.", "grid_coords": Vector2(3, 1), "icon": "🚜"
	},
	"Warsztat": {
		"research_cost": 60, "research_time": 6, "req": ["Hodowla + farma 2lvl", "Górnictwo"], "unlocked": false, "desc": "Produkcja rzemieślnicza.", "grid_coords": Vector2(3, 3), "icon": "⚒️"
	},
	"2lvl Górnictwo": {
		"research_cost": 60, "research_time": 6, "req": ["Górnictwo"], "unlocked": false, "desc": "Głębsze szyby.", "grid_coords": Vector2(3, 5), "icon": "🗻"
	},
	"2lvl Warsztat": {
		"research_cost": 80, "research_time": 8, "req": ["3lvl Hodowla + farma", "Warsztat"], "unlocked": false, "desc": "Złożone narzędzia.", "grid_coords": Vector2(4, 2), "icon": "⚙️"
	},
	"Świątynia": {
		"research_cost": 80, "research_time": 8, "req": ["Warsztat", "2lvl Górnictwo"], "unlocked": false, "desc": "Miejsce kultu.", "grid_coords": Vector2(4, 4), "icon": "🕍"
	},
	"Warsztat 3 lvl": {
		"research_cost": 100, "research_time": 10, "req": ["2lvl Warsztat"], "unlocked": false, "desc": "Wielka produkcja.", "grid_coords": Vector2(5, 2), "icon": "🏭"
	},
	"Świątynia 2lvl": {
		"research_cost": 100, "research_time": 10, "req": ["Świątynia"], "unlocked": false, "desc": "Rozwój religii.", "grid_coords": Vector2(5, 4), "icon": "🛕"
	},
	"Baraki": {
		"research_cost": 120, "research_time": 12, "req": ["Warsztat 3 lvl", "Świątynia 2lvl"], "unlocked": false, "desc": "Wojsko stacjonarne.", "grid_coords": Vector2(6, 3), "icon": "⚔️"
	},
	"Świątynia 3lvl": {
		"research_cost": 150, "research_time": 15, "req": ["Baraki"], "unlocked": false, "desc": "Cuda wiary.", "grid_coords": Vector2(7, 1), "icon": "⛪"
	},
	"Baraki 2lvl": {
		"research_cost": 150, "research_time": 15, "req": ["Baraki"], "unlocked": false, "desc": "Szkolenie taktyczne.", "grid_coords": Vector2(7, 3), "icon": "🛡️"
	},
	"3lvl Górnictwo": {
		"research_cost": 150, "research_time": 15, "req": ["Baraki"], "unlocked": false, "desc": "Zaawansowane wydobycie.", "grid_coords": Vector2(7, 5), "icon": "🌋"
	},
	"Laboratorium": {
		"research_cost": 180, "research_time": 18, "req": ["Świątynia 3lvl", "Baraki 2lvl"], "unlocked": false, "desc": "Eksperymenty naukowe.", "grid_coords": Vector2(8, 2), "icon": "🧪"
	},
	"Konnica": {
		"research_cost": 180, "research_time": 18, "req": ["Baraki 2lvl", "3lvl Górnictwo"], "unlocked": false, "desc": "Szybki zwiad i szturm.", "grid_coords": Vector2(8, 4), "icon": "🐎"
	},
	"Biblioteka": {
		"research_cost": 220, "research_time": 22, "req": ["Laboratorium", "Konnica"], "unlocked": false, "desc": "Centrum wiedzy.", "grid_coords": Vector2(9, 3), "icon": "📚"
	},
	"Laboratorium 2lvl": {
		"research_cost": 260, "research_time": 26, "req": ["Biblioteka"], "unlocked": false, "desc": "Zaawansowane badania.", "grid_coords": Vector2(10, 1), "icon": "🔬"
	},
	"Biblioteka 2lvl": {
		"research_cost": 260, "research_time": 26, "req": ["Biblioteka"], "unlocked": false, "desc": "Zbiory specjalne.", "grid_coords": Vector2(10, 3), "icon": "📖"
	},
	"Dom mieszkalny 2lvl": {
		"research_cost": 260, "research_time": 26, "req": ["Biblioteka"], "unlocked": false, "desc": "Rozwój urbanizacji.", "grid_coords": Vector2(10, 5), "icon": "🏘️"
	},
	"Laboratorium 3lvl": {
		"research_cost": 300, "research_time": 30, "req": ["Laboratorium 2lvl"], "unlocked": false, "desc": "Akademia Nauk.", "grid_coords": Vector2(11, 1), "icon": "🌌"
	},
	"Biblioteka 3lvl": {
		"research_cost": 300, "research_time": 30, "req": ["Biblioteka 2lvl"], "unlocked": false, "desc": "Wielkie Archiwum.", "grid_coords": Vector2(11, 3), "icon": "🏛️"
	},
	"Baraki 3lvl": {
		"research_cost": 300, "research_time": 30, "req": ["Dom mieszkalny 2lvl"], "unlocked": false, "desc": "Forteca szkoleniowa.", "grid_coords": Vector2(11, 5), "icon": "🏰"
	},
	"Mag": {
		"research_cost": 350, "research_time": 35, "req": ["Laboratorium 3lvl", "Biblioteka 3lvl"], "unlocked": false, "desc": "Sztuki magiczne.", "grid_coords": Vector2(12, 2), "icon": "🧙"
	},
	"Dom mieszkalny 3lvl": {
		"research_cost": 350, "research_time": 35, "req": ["Biblioteka 3lvl", "Baraki 3lvl"], "unlocked": false, "desc": "Metropolia.", "grid_coords": Vector2(12, 4), "icon": "🏙️"
	}
}

var culture_tree: Dictionary = {
	"Kultura +2/tura": {
		"research_cost": 10, "research_time": 1, "req": [], "unlocked": false, "desc": "Kultura +2 kultury/turę", "grid_coords": Vector2(0, 3), "icon": "🏛️"
	},
	"Jedzenie +10%": {
		"research_cost": 30, "research_time": 3, "req": ["Kultura +2/tura"], "unlocked": false, "desc": "+10% jedzenia z farm i hodowli", "grid_coords": Vector2(1, 1), "icon": "🌾"
	},
	"Żelazo i węgiel +5%": {
		"research_cost": 30, "research_time": 3, "req": ["Kultura +2/tura"], "unlocked": false, "desc": "+5% żelaza i węgla z kopalń", "grid_coords": Vector2(1, 5), "icon": "⛏️"
	},
	"Złoto z domów": {
		"research_cost": 40, "research_time": 4, "req": ["Jedzenie +10%"], "unlocked": false, "desc": "+2 złota z budynku mieszkalnego", "grid_coords": Vector2(2, 1), "icon": "💰"
	},
	"Ruch generała I": {
		"research_cost": 40, "research_time": 4, "req": ["Żelazo i węgiel +5%"], "unlocked": false, "desc": "+1 ruchu generała", "grid_coords": Vector2(2, 5), "icon": "🏇"
	},
	"Złoto za mieszkańca": {
		"research_cost": 60, "research_time": 6, "req": ["Złoto z domów"], "unlocked": false, "desc": "+1 złota za każdego mieszkańca", "grid_coords": Vector2(3, 1), "icon": "🪙"
	},
	"Drewno +5%": {
		"research_cost": 60, "research_time": 6, "req": ["Ruch generała I"], "unlocked": false, "desc": "+5% drewna z tartaku", "grid_coords": Vector2(3, 5), "icon": "🪵"
	},
	"Złoto za świątynie": {
		"research_cost": 80, "research_time": 8, "req": ["Złoto za mieszkańca", "Drewno +5%"], "unlocked": false, "desc": "+2 złota za świątynię", "grid_coords": Vector2(4, 3), "icon": "🕍"
	},
	"Szybsze badania": {
		"research_cost": 100, "research_time": 10, "req": ["Złoto za świątynie"], "unlocked": false, "desc": "-1 tura do badań", "grid_coords": Vector2(5, 1), "icon": "⏳"
	},
	"Nauka z warsztatu": {
		"research_cost": 100, "research_time": 10, "req": ["Złoto za świątynie"], "unlocked": false, "desc": "+1 pkt nauki za warsztat", "grid_coords": Vector2(5, 3), "icon": "🧪"
	},
	"Szybsza rekrutacja": {
		"research_cost": 100, "research_time": 10, "req": ["Złoto za świątynie"], "unlocked": false, "desc": "-1 tura do rekrutacji", "grid_coords": Vector2(5, 5), "icon": "⚔️"
	},
	"Tańsze domy": {
		"research_cost": 120, "research_time": 12, "req": ["Szybsze badania", "Nauka z warsztatu"], "unlocked": false, "desc": "-10% ceny domów", "grid_coords": Vector2(6, 2), "icon": "🏠"
	},
	"Tańsze farmy": {
		"research_cost": 120, "research_time": 12, "req": ["Nauka z warsztatu", "Szybsza rekrutacja"], "unlocked": false, "desc": "-10% ceny farm", "grid_coords": Vector2(6, 4), "icon": "🚜"
	},
	"Tańsze bud. naukowe": {
		"research_cost": 150, "research_time": 15, "req": ["Tańsze domy"], "unlocked": false, "desc": "-10% ceny budynków naukowych", "grid_coords": Vector2(7, 1), "icon": "🔬"
	},
	"Ruch generała II": {
		"research_cost": 150, "research_time": 15, "req": ["Tańsze domy", "Tańsze farmy"], "unlocked": false, "desc": "+1 ruchu generała", "grid_coords": Vector2(7, 3), "icon": "🐎"
	},
	"Tańsze bud. kulturowe": {
		"research_cost": 150, "research_time": 15, "req": ["Tańsze farmy"], "unlocked": false, "desc": "-10% ceny budynków kulturowych", "grid_coords": Vector2(7, 5), "icon": "🎭"
	},
	"Tańsza rekrutacja": {
		"research_cost": 180, "research_time": 18, "req": ["Tańsze bud. naukowe"], "unlocked": false, "desc": "-10% koszt rekrutacji", "grid_coords": Vector2(8, 1), "icon": "🛡️"
	},
	"Kultura z domów": {
		"research_cost": 180, "research_time": 18, "req": ["Tańsze bud. kulturowe"], "unlocked": false, "desc": "+1 pkt kultury za dom na turę", "grid_coords": Vector2(8, 5), "icon": "🏘️"
	},
	"Złoto co turę": {
		"research_cost": 220, "research_time": 22, "req": ["Tańsza rekrutacja"], "unlocked": false, "desc": "+1 złoto na turę", "grid_coords": Vector2(9, 1), "icon": "💸"
	},
	"Tech z baraków": {
		"research_cost": 220, "research_time": 22, "req": ["Kultura z domów"], "unlocked": false, "desc": "+1 pkt technologii za każdy barak", "grid_coords": Vector2(9, 5), "icon": "⚙️"
	},
	"Złoto z drwala": {
		"research_cost": 260, "research_time": 26, "req": ["Złoto co turę", "Tech z baraków"], "unlocked": false, "desc": "+1 złoto/tura za dom drwala", "grid_coords": Vector2(10, 3), "icon": "🪓"
	},
	"Tańsza chata drwala": {
		"research_cost": 300, "research_time": 30, "req": ["Złoto z drwala"], "unlocked": false, "desc": "-10% koszt chaty drwala", "grid_coords": Vector2(11, 1), "icon": "📉"
	},
	"Tańsze baraki": {
		"research_cost": 300, "research_time": 30, "req": ["Złoto z drwala"], "unlocked": false, "desc": "-10% koszt budowy baraków", "grid_coords": Vector2(11, 3), "icon": "🏯"
	},
	"Ruch generała III": {
		"research_cost": 300, "research_time": 30, "req": ["Złoto z drwala"], "unlocked": false, "desc": "+1 ruch generała na turę", "grid_coords": Vector2(11, 5), "icon": "🏇"
	},
	"Złoto z baraków": {
		"research_cost": 350, "research_time": 35, "req": ["Tańsza chata drwala", "Tańsze baraki", "Ruch generała III"], "unlocked": false, "desc": "+1 złota/tura za każdy barak", "grid_coords": Vector2(12, 3), "icon": "🤑"
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
		"Dom mieszkalny", "Laboratorium", "Warsztat", "Biblioteka", "Świątynia", "Baraki":
			text += "• Wymaga: Trawa (lub nadpisanie dowolnego złoża)\n"

	var mod_costs = get_modified_building_costs(building_name)
	text += "\nKoszt poziomu 1\n"
	for resource in mod_costs:
		text += "• %s: %d\n" % [resource, mod_costs[resource]]
	return text

func get_modified_building_costs(building_name: String) -> Dictionary:
	if not building_costs.has(building_name): return {}
	var costs = building_costs[building_name].duplicate()
	var modifier = 1.0
	
	if building_name == "Dom mieszkalny" and culture_tree["Tańsze domy"]["unlocked"]:
		modifier -= 0.1
	if building_name == "Farma" and culture_tree["Tańsze farmy"]["unlocked"]:
		modifier -= 0.1
	if building_name in ["Laboratorium", "Warsztat"] and culture_tree["Tańsze bud. naukowe"]["unlocked"]:
		modifier -= 0.1
	if building_name in ["Biblioteka", "Świątynia"] and culture_tree["Tańsze bud. kulturowe"]["unlocked"]:
		modifier -= 0.1
	if building_name == "Chata Drwala" and culture_tree["Tańsza chata drwala"]["unlocked"]:
		modifier -= 0.1
	if building_name == "Baraki" and culture_tree["Tańsze baraki"]["unlocked"]:
		modifier -= 0.1
		
	if modifier != 1.0:
		for res in costs:
			costs[res] = int(ceil(costs[res] * modifier))
	return costs

func can_afford_and_place(building_name: String, tile_type: String) -> bool:
	if not building_costs.has(building_name): return false
	
	if building_name == "Chata Drwala" and tile_type != "Drewno": return false
	if building_name == "Kopalnia Żelaza" and tile_type != "Żelazo": return false
	if building_name == "Kopalnia Węgla" and tile_type != "Węgiel": return false
	if building_name == "Farma" and tile_type != "Pszenica": return false
	if building_name == "Pastwisko" and tile_type != "Bydło": return false
	
	# POPRAWKA: Usunięto sztywne blokowanie typów innych niż Trawa dla budynków miejskich,
	# aby kod niszczenia złóż w game_world.gd stał się osiągalny.
	var costs = get_modified_building_costs(building_name)
	for res in costs:
		if resources.get(res, 0) < costs[res]:
			return false
	return true

func get_upgrade_cost(b_name: String, current_level: int) -> Dictionary:
	var cost = {}
	if building_costs.has(b_name):
		var mod_costs = get_modified_building_costs(b_name)
		for res in mod_costs:
			cost[res] = mod_costs[res] * (current_level + 1)
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
		var costs = get_modified_building_costs(building_name)
		for res in costs:
			resources[res] -= costs[res]
		notify_change()

func start_research(tech_name:String):
	if current_research != "":
		return

	var tech = technology_tree[tech_name]
	if resources["Nauka"] < tech["research_cost"]:
		return

	var time = tech["research_time"]
	if culture_tree["Szybsze badania"]["unlocked"]:
		time = max(1, time - 1)

	resources["Nauka"] -= tech["research_cost"]
	current_research = tech_name
	research_turns_left = time
	notify_change()

func start_culture_research(tech_name:String):
	if current_culture_research != "":
		return

	var tech = culture_tree[tech_name]
	if resources["Kultura"] < tech["research_cost"]:
		return

	var time = tech["research_time"]
	if culture_tree["Szybsze badania"]["unlocked"]:
		time = max(1, time - 1)

	resources["Kultura"] -= tech["research_cost"]
	current_culture_research = tech_name
	culture_turns_left = time
	notify_change()

func get_missing_tech_for_building(building_name: String) -> String:
	if building_tech_requirements.has(building_name):
		var req_tech = building_tech_requirements[building_name]
		if technology_tree.has(req_tech) and not technology_tree[req_tech]["unlocked"]:
			return req_tech
	return ""

func get_missing_tech_for_upgrade(building_name: String, target_level: int) -> String:
	if upgrade_tech_requirements.has(building_name) and upgrade_tech_requirements[building_name].has(target_level):
		var req_tech = upgrade_tech_requirements[building_name][target_level]
		if technology_tree.has(req_tech) and not technology_tree[req_tech]["unlocked"]:
			return req_tech
	return ""

func next_turn(active_buildings_data: Array) -> void:
	current_turn += 1
	var max_pop = 5
	for b_data in active_buildings_data:
		if b_data["name"] == "Dom mieszkalny":
			max_pop += 5 * b_data.get("level", 1)
	resources["Maks_Populacja"] = max_pop
	
	var food_consumption = resources["Populacja"] * 1
	resources["Jedzenie"] -= food_consumption
	
	var turn_science = 0
	var turn_culture = 0
	
	var food_multiplier = 1.0
	if culture_tree["Jedzenie +10%"]["unlocked"]: food_multiplier = 1.1

	var iron_coal_multiplier = 1.0
	if culture_tree["Żelazo i węgiel +5%"]["unlocked"]: iron_coal_multiplier = 1.05

	var wood_multiplier = 1.0
	if culture_tree["Drewno +5%"]["unlocked"]: wood_multiplier = 1.05

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
			"Dom mieszkalny":
				if culture_tree["Złoto z domów"]["unlocked"]:
					resources["Złoto"] += 2 * b_level
				if culture_tree["Kultura z domów"]["unlocked"]:
					turn_culture += 1 * b_level
			"Centrum Miasta":
				var gold_bonus = 10 * b_level
				resources["Złoto"] += gold_bonus
				resources["Jedzenie"] += 2 * b_level
				resources["Drewno"] += 2 * b_level
			"Chata Drwala":
				resources["Drewno"] += int(8 * size_modifier * b_level * wood_multiplier)
				if culture_tree["Złoto z drwala"]["unlocked"]:
					resources["Złoto"] += 1 * b_level
			"Kopalnia Żelaza":
				var iron_yield = 5
				resources["Żelazo"] += int(iron_yield * size_modifier * b_level * iron_coal_multiplier)
				resources["Złoto"] -= 2 * b_level
			"Kopalnia Węgla":
				var coal_yield = 4
				resources["Węgiel"] += int(coal_yield * size_modifier * b_level * iron_coal_multiplier)
				resources["Złoto"] -= 2 * b_level
			"Farma":
				var farm_yield = 6
				resources["Jedzenie"] += int(farm_yield * size_modifier * b_level * food_multiplier)
			"Pastwisko":
				resources["Jedzenie"] += int(8 * size_modifier * b_level * food_multiplier)
			"Laboratorium":
				turn_science += 3 * b_level
			"Warsztat":
				turn_science += 1 * b_level
				if culture_tree["Nauka z warsztatu"]["unlocked"]:
					turn_science += 1 * b_level
			"Biblioteka":
				turn_science += 2 * b_level
				turn_culture += 1 * b_level
			"Świątynia":
				turn_culture += 3 * b_level
				if culture_tree["Złoto za świątynie"]["unlocked"]:
					resources["Złoto"] += 2 * b_level
			"Baraki":
				if culture_tree["Tech z baraków"]["unlocked"]:
					turn_science += 1 * b_level
				if culture_tree["Złoto z baraków"]["unlocked"]:
					resources["Złoto"] += 1 * b_level

	if culture_tree["Kultura +2/tura"]["unlocked"]:
		turn_culture += 2
	if culture_tree["Złoto za mieszkańca"]["unlocked"]:
		resources["Złoto"] += resources["Populacja"] * 1
	if culture_tree["Złoto co turę"]["unlocked"]:
		resources["Złoto"] += 1

	var total_science = 1 + turn_science
	
	resources["Nauka"] = min(
		max_tech_points,
		resources["Nauka"] + total_science
	)

	resources["Kultura"] = min(
		max_culture_points,
		resources["Kultura"] + turn_culture
	)

	resources["Głoduje"] = resources["Jedzenie"] <= 0

	if resources["Jedzenie"] < 0:
		resources["Jedzenie"] = 0
		resources["Złoto"] = max(0, resources["Złoto"] - 5)
		if resources["Populacja"] > 1 and randf() < 0.25:
			resources["Populacja"] -= 1
	elif current_turn % 3 == 0:
		var surplus_needed = resources["Populacja"] * 2
		if resources["Jedzenie"] > surplus_needed and resources["Populacja"] < resources["Maks_Populacja"]:
			resources["Populacja"] += 1

	if current_research != "":
		research_turns_left -= 1
		if research_turns_left <= 0:
			technology_tree[current_research]["unlocked"] = true
			current_research = ""
			
	if current_culture_research != "":
		culture_turns_left -= 1
		if culture_turns_left <= 0:
			culture_tree[current_culture_research]["unlocked"] = true
			match current_culture_research:
				"Renesans":
					max_culture_points += 25
			current_culture_research = ""

	for unit in player_army:
		var turns_to_recruit = unit.get("turns_to_recruit", 0)
		var turns_in_recruitment = unit.get("turns_in_recruitment", 0)
		if turns_in_recruitment < turns_to_recruit:
			turns_in_recruitment += 1
			unit["turns_in_recruitment"] = turns_in_recruitment
			if turns_in_recruitment >= turns_to_recruit:
				unit_training_complete.emit(unit)

	notify_change()

func notify_change() -> void:
	economy_updated.emit(resources, current_turn, "")

func calculate_recruitment_turns(unit: Dictionary) -> int:
	var hp = unit.get("hp", 0)
	var dmg = unit.get("dmg", 0)
	var def = unit.get("def", 0)
	var time = max(1, int((hp + dmg + def) / 10))
	if culture_tree["Szybsza rekrutacja"]["unlocked"]:
		time = max(1, time - 1)
	return time

func calculate_unit_cost(unit: Dictionary) -> Dictionary:
	var hp = unit.get("hp", 0)
	var dmg = unit.get("dmg", 0)
	var def = unit.get("def", 0)
	var cost = {
		"Złoto": int((hp + dmg + def) * 1.5),
		"Żelazo": int((dmg * 2.0) + (def * 1.0)),
		"Jedzenie": int(hp * 1.5),
		"Populacja": 1
	}
	
	if culture_tree["Tańsza rekrutacja"]["unlocked"]:
		cost["Złoto"] = int(ceil(cost["Złoto"] * 0.9))
		cost["Żelazo"] = int(ceil(cost["Żelazo"] * 0.9))
		cost["Jedzenie"] = int(ceil(cost["Jedzenie"] * 0.9))
		
	return cost

func can_recruit_unit(unit: Dictionary) -> bool:
	var cost = calculate_unit_cost(unit)
	if resources.get("Populacja", 0) - cost.get("Populacja", 0) < 1:
		return false
	for res in cost:
		if resources.get(res, 0) < cost[res]:
			return false
	return true

func recruit_unit(unit: Dictionary) -> void:
	if can_recruit_unit(unit):
		var cost = calculate_unit_cost(unit)
		for res in cost:
			resources[res] -= cost[res]
		
		var new_unit = unit.duplicate()
		new_unit["turns_to_recruit"] = calculate_recruitment_turns(new_unit)
		new_unit["turns_in_recruitment"] = 0
		
		if army_bonus_hp > 0: new_unit["hp"] += army_bonus_hp
		if army_bonus_dmg > 0: new_unit["dmg"] += army_bonus_dmg
		if army_bonus_def > 0: new_unit["def"] += army_bonus_def
		
		player_army.append(new_unit)
		notify_change()

func remove_unit(unit: Dictionary) -> void:
	if unit in player_army:
		player_army.erase(unit)
		var cost = calculate_unit_cost(unit)
		if cost.has("Populacja"):
			resources["Populacja"] += cost["Populacja"]
		notify_change()

func clear_army() -> void:
	for unit in player_army:
		var cost = calculate_unit_cost(unit)
		if cost.has("Populacja"):
			resources["Populacja"] += cost["Populacja"]
	player_army.clear()
	notify_change()

func reset() -> void:
	current_turn = 1
	player_army = []
	army_bonus_hp = 0
	army_bonus_dmg = 0
	army_bonus_def = 0
	
	resources = {
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
	
	max_tech_points = 350.0
	max_culture_points = 350.0
	
	current_research = ""
	research_turns_left = 0
	
	current_culture_research = ""
	culture_turns_left = 0
	
	for tech in technology_tree.values():
		tech["unlocked"] = false
		
	for tech in culture_tree.values():
		tech["unlocked"] = false
