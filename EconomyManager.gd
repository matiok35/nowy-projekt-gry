extends Node
# EconomyManager.gd (Autoload / Singleton)

signal economy_updated(balances: Dictionary, current_turn: int, selected_build: String)

var current_turn: int = 1

var resources: Dictionary = {
	"Złoto": 150,
	"Drewno": 40,
	"Żelazo": 0,
	"Węgiel": 0,
	"Jedzenie": 10 # Dodany nowy surowiec
}

var building_costs: Dictionary = {
	"Chata Drwala": {"Złoto": 30, "Drewno": 10},
	"Kopalnia Żelaza": {"Złoto": 50, "Drewno": 20},
	"Kopalnia Węgla": {"Złoto": 60, "Drewno": 25},
	"Farma": {"Złoto": 25, "Drewno": 15} # Koszt Farmy
}

func can_afford_and_place(building_name: String, tile_type: String) -> bool:
	if not building_costs.has(building_name): return false
	
	# Sprawdzanie poprawności podłoża
	if building_name == "Farma" and tile_type != "Trawa":
		return false
	if building_name == "Chata Drwala" and tile_type != "Drewno":
		return false
	if building_name == "Kopalnia Żelaza" and tile_type != "Żelazo":
		return false
	if building_name == "Kopalnia Węgla" and tile_type != "Węgiel":
		return false

	var costs = building_costs[building_name]
	for res in costs:
		if resources[res] < costs[res]:
			return false
	return true

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

# Przerobiona funkcja tury: przyjmuje słownik obiektów z danymi o złożach/żyzności
func next_turn(active_buildings_data: Array) -> void:
	current_turn += 1
	
	# Koszt utrzymania państwa (konsumpcja jedzenia przez mieszkańców)
	resources["Jedzenie"] -= 2 
	
	# Naliczanie przychodów z budynków na podstawie ich cech geometrycznych
	for b_data in active_buildings_data:
		var b_name = b_data["name"]
		var size_modifier = 1.0
		
		# Modyfikator wielkości złoża
		if b_data.has("deposit_size"):
			match b_data["deposit_size"]:
				"Małe": size_modifier = 0.5
				"Średnie": size_modifier = 1.0
				"Duże": size_modifier = 2.0

		match b_name:
			"Centrum Miasta":
				resources["Złoto"] += 10
				resources["Jedzenie"] += 2
			"Chata Drwala":
				resources["Drewno"] += int(8 * size_modifier)
			"Kopalnia Żelaza":
				resources["Żelazo"] += int(5 * size_modifier)
				resources["Złoto"] -= 2
			"Kopalnia Węgla":
				resources["Węgiel"] += int(4 * size_modifier)
				resources["Złoto"] -= 2
			"Farma":
				# Produkcja zależna bezpośrednio od żyzności (np. 4 * współczynnik żyzności)
				var fertility = b_data.get("fertility", 1.0)
				resources["Jedzenie"] += int(6 * fertility)

	# Zabezpieczenie przed ujemnym jedzeniem (głód niszczy gospodarkę)
	if resources["Jedzenie"] < 0:
		resources["Jedzenie"] = 0
		resources["Złoto"] = max(0, resources["Złoto"] - 5)

	notify_change()

func notify_change() -> void:
	economy_updated.emit(resources, current_turn, "")
