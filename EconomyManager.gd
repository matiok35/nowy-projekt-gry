extends Node
# EconomyManager.gd (AUTOLOAD / SINGLETON)

signal economy_updated(balances: Dictionary, turn: int, selected_build: String)

var turn_number: int = 1
var selected_building_to_place: String = ""

var resources = {
	"Złoto": 100,
	"Drewno": 50,
	"Żelazo": 0,
	"Węgiel": 0
}

var building_types = {
	"Chata Drwala": {"cost": {"Złoto": 20}, "yield": {"Drewno": 10}, "requires_tile": "Drewno"},
	"Kopalnia Żelaza": {"cost": {"Złoto": 40, "Drewno": 20}, "yield": {"Żelazo": 5}, "requires_tile": "Żelazo"},
	"Kopalnia Węgla": {"cost": {"Złoto": 50, "Drewno": 30}, "yield": {"Węgiel": 3}, "requires_tile": "Węgiel"}
}

# --- NOWE: KONFIGURACJA ZAKUPU PÓL TERYTORIUM ---
const TILE_BUY_COST: int = 50 

func can_afford_tile_purchase() -> bool:
	return resources["Złoto"] >= TILE_BUY_COST

func deduct_tile_purchase_costs():
	resources["Złoto"] -= TILE_BUY_COST
	notify_change()

func select_building(building_name: String):
	selected_building_to_place = building_name
	notify_change()

func next_turn(active_buildings: Array):
	turn_number += 1
	resources["Złoto"] += 10 # Bazowy dochód
	
	# Podliczanie zysków z przekazanych budynków
	for building in active_buildings:
		if building_types.has(building):
			var b_yield = building_types[building]["yield"]
			for res in b_yield:
				resources[res] += b_yield[res]
				
	notify_change()

func can_afford_and_place(building_name: String, tile_type: String) -> bool:
	if not building_types.has(building_name): return false
	var b_data = building_types[building_name]
	
	if tile_type != b_data["requires_tile"]: return false
	
	for res in b_data["cost"]:
		if resources[res] < b_data["cost"][res]: return false
		
	return true

func deduct_costs(building_name: String):
	var b_data = building_types[building_name]
	for res in b_data["cost"]:
		resources[res] -= b_data["cost"][res]
	notify_change()

func notify_change():
	economy_updated.emit(resources, turn_number, selected_building_to_place)
