extends Node
# economy_manager.gd (Autoload / Singleton)

signal economy_updated(balances: Dictionary, current_turn: int, selected_build: String)
signal unit_training_complete(unit: Dictionary)

var current_turn: int = 1
var player_army: Array = []
const MAX_ARMY_SIZE: int = 50

# Koszt zakupu jednego pola terytorium. Trzymany w jednym miejscu (zamiast
# zaszytej na sztywno liczby w hud.gd), żeby zmiana ceny w przyszłości nie
# rozjeżdżała interfejsu z faktyczną logiką ekonomii.
const TILE_PURCHASE_GOLD_COST: int = 50


var owned_potions: Dictionary = {}
var active_potions: Dictionary = {}
var potion_bonus_hp: int = 0
var potion_bonus_dmg: int = 0
var potion_bonus_def: int = 0
var potion_bonus_speed: int = 0

const POTIONS_DATA: Dictionary = {
	"potka_sily_1": {
		"name": "Potka Siły (1 tura)",
		"desc": "+2 DMG dla wszystkich jednostek na 1 turę.",
		"effect": "dmg",
		"value": 2,
		"duration": 1,
		"cost": {"Złoto": 50}
	},
	"potka_sily_10": {
		"name": "Większa Potka Siły (10 tur)",
		"desc": "+1 DMG dla wszystkich jednostek na 10 tur.",
		"effect": "dmg",
		"value": 1,
		"duration": 10,
		"cost": {"Złoto": 150}
	},
	"potka_wit_1": {
		"name": "Potka Witalności (1 tura)",
		"desc": "+5 HP dla wszystkich jednostek na 1 turę.",
		"effect": "hp",
		"value": 5,
		"duration": 1,
		"cost": {"Złoto": 50}
	},
	"potka_wit_10": {
		"name": "Większa Potka Witalności (10 tur)",
		"desc": "+2 HP dla wszystkich jednostek na 10 tur.",
		"effect": "hp",
		"value": 2,
		"duration": 10,
		"cost": {"Złoto": 150}
	},
	"potka_obrony_1": {
		"name": "Potka Kamiennej Skóry (1 tura)",
		"desc": "+2 DEF dla wszystkich jednostek na 1 turę.",
		"effect": "def",
		"value": 2,
		"duration": 1,
		"cost": {"Złoto": 50}
	},
	"potka_obrony_10": {
		"name": "Większa Potka Kamiennej Skóry (10 tur)",
		"desc": "+1 DEF dla wszystkich jednostek na 10 tur.",
		"effect": "def",
		"value": 1,
		"duration": 10,
		"cost": {"Złoto": 150}
	},
	"potka_szybkosci_1": {
		"name": "Potka Wiatru (1 tura)",
		"desc": "+2 RUCH dla wszystkich jednostek na 1 turę.",
		"effect": "speed",
		"value": 2,
		"duration": 1,
		"cost": {"Złoto": 50}
	},
	"potka_szybkosci_10": {
		"name": "Większa Potka Wiatru (10 tur)",
		"desc": "+1 RUCH dla wszystkich jednostek na 10 tur.",
		"effect": "speed",
		"value": 1,
		"duration": 10,
		"cost": {"Złoto": 150}
	}
}

# --- SYSTEM BŁOGOSŁAWIEŃSTWA ŚWIĄTYNI --------------------------------------
# Aktywowane z okna TempleMenu (przycisk na polu ze Świątynią). Efekt: +10%
# produkcji wszystkich surowców materialnych przez TEMPLE_BLESSING_DURATION
# tur, z odnowieniem (cooldown) liczonym od momentu aktywacji.
const TEMPLE_BLESSING_DURATION: int = 10
const TEMPLE_BLESSING_COOLDOWN: int = 30
var temple_blessing_turns_left: int = 0
var temple_blessing_cooldown_left: int = 0

# --- DRZEWO UMIEJĘTNOŚCI (BIBLIOTEKA) --------------------------------------
# Badane z okna LibraryResearchMenu (przycisk na polu z Biblioteką). Zakup
# jest jednorazowy i natychmiastowy (bez tur oczekiwania) — odblokowuje
# umiejętność na stałe dla powiązanej jednostki.
var skill_tree: Dictionary = {
	"zelazna_kurtyna": {"name": "Żelazna Kurtyna", "unit": "Rycerze", "desc": "Rycerze zyskują tymczasową odporność na obrażenia.", "cost_gold": 120, "cost_tech": 40, "unlocked": false},
	"tarcza": {"name": "Tarcza", "unit": "Rycerze", "desc": "Rycerze mogą osłonić sojusznika, przejmując część obrażeń.", "cost_gold": 100, "cost_tech": 30, "unlocked": false},
	"szarza": {"name": "Szarża", "unit": "Konnica", "desc": "Konnica zadaje dodatkowe obrażenia przy szarży na wroga.", "cost_gold": 110, "cost_tech": 35, "unlocked": false},
	"przyspieszenie": {"name": "Przyspieszenie", "unit": "Konnica", "desc": "Konnica zyskuje dodatkowy zasięg ruchu na turę.", "cost_gold": 90, "cost_tech": 25, "unlocked": false},
	"sokole_oko": {"name": "Sokole Oko", "unit": "Łucznicy", "desc": "Łucznicy zyskują zwiększony zasięg ataku.", "cost_gold": 100, "cost_tech": 30, "unlocked": false},
	"precyzyjny_strzal": {"name": "Precyzyjny Strzał", "unit": "Łucznicy", "desc": "Łucznicy mają szansę na trafienie krytyczne.", "cost_gold": 130, "cost_tech": 40, "unlocked": false},
	"lodowe_podloze": {"name": "Lodowe Podłoże", "unit": "Magowie", "desc": "Magowie spowalniają wrogów na polu bitwy.", "cost_gold": 140, "cost_tech": 45, "unlocked": false},
	"medytacja": {"name": "Medytacja", "unit": "Magowie", "desc": "Magowie szybciej się regenerują i zadają więcej obrażeń.", "cost_gold": 120, "cost_tech": 35, "unlocked": false},
}

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

var turn_warnings: Array = []

var max_tech_points: float = 600.0
var max_culture_points: float = 600.0

# Koszty budynków podniesione o 100% względem wartości bazowych.
var building_costs: Dictionary = {
	"Chata Drwala": {"Złoto": 60, "Drewno": 20},
	"Kopalnia Żelaza": {"Złoto": 100, "Drewno": 40, "Węgiel": 30},
	"Kopalnia Węgla": {"Złoto": 120, "Drewno": 50},
	"Farma": {"Złoto": 50, "Drewno": 30},
	"Pastwisko": {"Złoto": 60, "Drewno": 30},
	"Dom mieszkalny": {"Złoto": 80, "Drewno": 40},
	"Laboratorium": {"Złoto": 200, "Drewno": 100, "Żelazo": 20},
	"Warsztat": {"Złoto": 160, "Drewno": 80, "Żelazo": 10},
	"Biblioteka": {"Złoto": 140, "Drewno": 60},
	"Świątynia": {"Złoto": 300, "Drewno": 80, "Żelazo": 30},
	"Baraki": {"Złoto": 120, "Drewno": 60}
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
	"Chata Drwala": {2: "Piła Dwuręczna", 3: "Tartak Mechaniczny"},
	"Farma": {2: "Płodozmian", 3: "Agronomia"},
	"Pastwisko": {2: "Płodozmian", 3: "Agronomia"},
	"Kopalnia Żelaza": {2: "Głębokie Szyby", 3: "Metalurgia"},
	"Kopalnia Węgla": {2: "Głębokie Szyby", 3: "Metalurgia"},
	"Warsztat": {2: "Precyzyjne Narzędzia", 3: "Manufaktura"},
	"Świątynia": {2: "Odnowa Wiary", 3: "Sanktuarium"},
	"Baraki": {2: "Musztra", 3: "Twierdza"},
	"Laboratorium": {2: "Alchemia", 3: "Akademia Nauk"},
	"Biblioteka": {2: "Archiwa", 3: "Wielkie Archiwum"},
	"Dom mieszkalny": {2: "Urbanizacja", 3: "Metropolia"}
}

# SKRÓCONE OPISY ("desc") DLA ZAPEWNIENIA MAŁYCH KAFELKÓW
var technology_tree: Dictionary = {
	"Chata drwala": {
		"research_cost": 5, "research_time": 1, "req": [], "unlocked": false, "desc": "Budowa Chaty Drwala.", "grid_coords": Vector2(0, 3), "icon": "🪓"
	},
	"Piła Dwuręczna": {
		"research_cost": 15, "research_time": 3, "req": ["Chata drwala"], "unlocked": false, "desc": "Chata Drwala Lvl 2.", "grid_coords": Vector2(1, 2), "icon": "🪚"
	},
	"Tartak Mechaniczny": {
		"research_cost": 25, "research_time": 5, "req": ["Piła Dwuręczna"], "unlocked": false, "desc": "Chata Drwala Lvl 3.", "grid_coords": Vector2(2, 1), "icon": "🪵"
	},
	"Hodowla bydła": {
		"research_cost": 10, "research_time": 2, "req": ["Chata drwala"], "unlocked": false, "desc": "Budowa Pastwiska.", "grid_coords": Vector2(1, 4), "icon": "🐄"
	},
	"Płodozmian": {
		"research_cost": 20, "research_time": 4, "req": ["Hodowla bydła", "Piła Dwuręczna"], "unlocked": false, "desc": "Farma/Pastwisko Lvl 2.", "grid_coords": Vector2(3, 3), "icon": "🌾"
	},
	"Górnictwo": {
		"research_cost": 20, "research_time": 4, "req": ["Hodowla bydła"], "unlocked": false, "desc": "Kopalnie Żelaza i Węgla.", "grid_coords": Vector2(2, 5), "icon": "⛏️"
	},
	"Agronomia": {
		"research_cost": 30, "research_time": 6, "req": ["Płodozmian", "Tartak Mechaniczny"], "unlocked": false, "desc": "Farma/Pastwisko Lvl 3.", "grid_coords": Vector2(3, 1), "icon": "🚜"
	},
	"Warsztat": {
		"research_cost": 30, "research_time": 6, "req": ["Hodowla bydła", "Górnictwo"], "unlocked": false, "desc": "Budowa Warsztatu.", "grid_coords": Vector2(2, 3), "icon": "⚒️"
	},
	"Głębokie Szyby": {
		"research_cost": 30, "research_time": 6, "req": ["Górnictwo"], "unlocked": false, "desc": "Kopalnie Lvl 2.", "grid_coords": Vector2(3, 5), "icon": "🗻"
	},
	"Precyzyjne Narzędzia": {
		"research_cost": 40, "research_time": 8, "req": ["Agronomia", "Warsztat"], "unlocked": false, "desc": "Warsztat Lvl 2.", "grid_coords": Vector2(4, 2), "icon": "⚙️"
	},
	"Świątynia": {
		"research_cost": 40, "research_time": 8, "req": ["Warsztat", "Głębokie Szyby"], "unlocked": false, "desc": "Budowa Świątyni.", "grid_coords": Vector2(4, 4), "icon": "🕍"
	},
	"Manufaktura": {
		"research_cost": 50, "research_time": 10, "req": ["Precyzyjne Narzędzia"], "unlocked": false, "desc": "Warsztat Lvl 3.", "grid_coords": Vector2(5, 2), "icon": "🏭"
	},
	"Odnowa Wiary": {
		"research_cost": 50, "research_time": 10, "req": ["Świątynia"], "unlocked": false, "desc": "Świątynia Lvl 2.", "grid_coords": Vector2(5, 4), "icon": "🛕"
	},
	"Baraki": {
		"research_cost": 120, "research_time": 12, "req": ["Manufaktura", "Odnowa Wiary"], "unlocked": false, "desc": "Budowa Baraków.", "grid_coords": Vector2(6, 3), "icon": "⚔️"
	},
	"Sanktuarium": {
		"research_cost": 225, "research_time": 8, "req": ["Baraki"], "unlocked": false, "desc": "Świątynia Lvl 3.", "grid_coords": Vector2(7, 1), "icon": "⛪"
	},
	"Musztra": {
		"research_cost": 225, "research_time": 8, "req": ["Baraki"], "unlocked": false, "desc": "Baraki Lvl 2.", "grid_coords": Vector2(7, 3), "icon": "🛡️"
	},
	"Metalurgia": {
		"research_cost": 225, "research_time": 8, "req": ["Baraki"], "unlocked": false, "desc": "Kopalnie Lvl 3.", "grid_coords": Vector2(7, 5), "icon": "🌋"
	},
	"Laboratorium": {
		"research_cost": 270, "research_time": 9, "req": ["Sanktuarium", "Musztra"], "unlocked": false, "desc": "Budowa Laboratorium.", "grid_coords": Vector2(8, 2), "icon": "🧪"
	},
	"Konnica": {
		"research_cost": 270, "research_time": 9, "req": ["Musztra", "Metalurgia"], "unlocked": false, "desc": "Jednostki konne.", "grid_coords": Vector2(8, 4), "icon": "🐎"
	},
	"Biblioteka": {
		"research_cost": 330, "research_time": 11, "req": ["Laboratorium", "Konnica"], "unlocked": false, "desc": "Budowa Biblioteki.", "grid_coords": Vector2(9, 3), "icon": "📚"
	},
	"Alchemia": {
		"research_cost": 390, "research_time": 13, "req": ["Biblioteka"], "unlocked": false, "desc": "Laboratorium Lvl 2.", "grid_coords": Vector2(10, 1), "icon": "🔬"
	},
	"Archiwa": {
		"research_cost": 390, "research_time": 13, "req": ["Biblioteka"], "unlocked": false, "desc": "Biblioteka Lvl 2.", "grid_coords": Vector2(10, 3), "icon": "📖"
	},
	"Urbanizacja": {
		"research_cost": 390, "research_time": 13, "req": ["Biblioteka"], "unlocked": false, "desc": "Domy Lvl 2.", "grid_coords": Vector2(10, 5), "icon": "🏘️"
	},
	"Akademia Nauk": {
		"research_cost": 450, "research_time": 15, "req": ["Alchemia"], "unlocked": false, "desc": "Laboratorium Lvl 3.", "grid_coords": Vector2(11, 1), "icon": "🌌"
	},
	"Wielkie Archiwum": {
		"research_cost": 450, "research_time": 15, "req": ["Archiwa"], "unlocked": false, "desc": "Biblioteka Lvl 3.", "grid_coords": Vector2(11, 3), "icon": "🏛️"
	},
	"Twierdza": {
		"research_cost": 450, "research_time": 15, "req": ["Urbanizacja"], "unlocked": false, "desc": "Baraki Lvl 3.", "grid_coords": Vector2(11, 5), "icon": "🏰"
	},
	"Mag": {
		"research_cost": 525, "research_time": 18, "req": ["Akademia Nauk", "Wielkie Archiwum"], "unlocked": false, "desc": "Rekrutacja Magów.", "grid_coords": Vector2(12, 2), "icon": "🧙"
	},
	"Metropolia": {
		"research_cost": 525, "research_time": 18, "req": ["Wielkie Archiwum", "Twierdza"], "unlocked": false, "desc": "Domy Lvl 3.", "grid_coords": Vector2(12, 4), "icon": "🏙️"
	}
}

# Koszty badań kultury podniesione o ~20% względem wartości bazowych.
var culture_tree: Dictionary = {
	"Kultura +2/tura": {
		"research_cost": 12, "research_time": 1, "req": [], "unlocked": false, "desc": "+2 Kultury/turę.", "grid_coords": Vector2(0, 3), "icon": "🏛️"
	},
	"Jedzenie +2": {
		"research_cost": 36, "research_time": 3, "req": ["Kultura +2/tura"], "unlocked": false, "desc": "+2 Jedzenia/turę z Farm.", "grid_coords": Vector2(1, 1), "icon": "🌾"
	},
	"Więcej surowców": {
		"research_cost": 36, "research_time": 3, "req": ["Kultura +2/tura"], "unlocked": false, "desc": "+1 Żelaza/Węgla z Kopalń.", "grid_coords": Vector2(1, 5), "icon": "⛏️"
	},
	"Złoto z domów": {
		"research_cost": 48, "research_time": 4, "req": ["Jedzenie +2"], "unlocked": false, "desc": "+2 Złota z domów.", "grid_coords": Vector2(2, 1), "icon": "💰"
	},
	"Ruch generała I": {
		"research_cost": 48, "research_time": 4, "req": ["Więcej surowców"], "unlocked": false, "desc": "+1 Ruch generała.", "grid_coords": Vector2(2, 5), "icon": "🏇"
	},
	"Złoto za mieszkańca": {
		"research_cost": 72, "research_time": 6, "req": ["Złoto z domów"], "unlocked": false, "desc": "+1 Złota/mieszkańca.", "grid_coords": Vector2(3, 1), "icon": "🪙"
	},
	"Drewno +2": {
		"research_cost": 72, "research_time": 6, "req": ["Ruch generała I"], "unlocked": false, "desc": "+2 Drewna/turę z Chaty.", "grid_coords": Vector2(3, 5), "icon": "🪵"
	},
	"Złoto za świątynie": {
		"research_cost": 96, "research_time": 8, "req": ["Złoto za mieszkańca", "Drewno +2"], "unlocked": false, "desc": "+2 Złota/świątynię.", "grid_coords": Vector2(4, 3), "icon": "🕍"
	},
	"Szybsze badania": {
		"research_cost": 100, "research_time": 10, "req": ["Złoto za świątynie"], "unlocked": false, "desc": "-25 koszt badań, -1 Tura.", "grid_coords": Vector2(5, 1), "icon": "⏳"
	},
	"Nauka z warsztatu": {
		"research_cost": 120, "research_time": 10, "req": ["Złoto za świątynie"], "unlocked": false, "desc": "+1 pkt tech./warsztat.", "grid_coords": Vector2(5, 3), "icon": "🧪"
	},
	"Szybsza rekrutacja": {
		"research_cost": 120, "research_time": 10, "req": ["Złoto za świątynie"], "unlocked": false, "desc": "-1 Tura rekrutacji.", "grid_coords": Vector2(5, 5), "icon": "⚔️"
	},
	"Tańsze domy": {
		"research_cost": 144, "research_time": 12, "req": ["Szybsze badania", "Nauka z warsztatu"], "unlocked": false, "desc": "-10 Złota za Dom.", "grid_coords": Vector2(6, 2), "icon": "🏠"
	},
	"Tańsze farmy": {
		"research_cost": 144, "research_time": 12, "req": ["Nauka z warsztatu", "Szybsza rekrutacja"], "unlocked": false, "desc": "-10 Złota za Farmę.", "grid_coords": Vector2(6, 4), "icon": "🚜"
	},
	"Tańsze bud. naukowe": {
		"research_cost": 180, "research_time": 15, "req": ["Tańsze domy"], "unlocked": false, "desc": "-20 Złota za b. nauk.", "grid_coords": Vector2(7, 1), "icon": "🔬"
	},
	"Ruch generała II": {
		"research_cost": 180, "research_time": 15, "req": ["Tańsze domy", "Tańsze farmy"], "unlocked": false, "desc": "+1 Ruch generała.", "grid_coords": Vector2(7, 3), "icon": "🐎"
	},
	"Tańsze bud. kulturowe": {
		"research_cost": 180, "research_time": 15, "req": ["Tańsze farmy"], "unlocked": false, "desc": "-20 Złota za b. kult.", "grid_coords": Vector2(7, 5), "icon": "🎭"
	},
	"Tańsza rekrutacja": {
		"research_cost": 216, "research_time": 18, "req": ["Tańsze bud. naukowe"], "unlocked": false, "desc": "-10 Złota, -2 Żelaza (rekr.).", "grid_coords": Vector2(8, 1), "icon": "🛡️"
	},
	"Kultura z domów": {
		"research_cost": 216, "research_time": 18, "req": ["Tańsze bud. kulturowe"], "unlocked": false, "desc": "+1 Kultury/dom.", "grid_coords": Vector2(8, 5), "icon": "🏘️"
	},
	"Złoto co turę": {
		"research_cost": 264, "research_time": 22, "req": ["Tańsza rekrutacja"], "unlocked": false, "desc": "+1 Złoto/turę.", "grid_coords": Vector2(9, 1), "icon": "💸"
	},
	"Tech z baraków": {
		"research_cost": 264, "research_time": 22, "req": ["Kultura z domów"], "unlocked": false, "desc": "+1 pkt tech./barak.", "grid_coords": Vector2(9, 5), "icon": "⚙️"
	},
	"Złoto z drwala": {
		"research_cost": 312, "research_time": 26, "req": ["Złoto co turę", "Tech z baraków"], "unlocked": false, "desc": "+1 Złoto/drwala.", "grid_coords": Vector2(10, 3), "icon": "🪓"
	},
	"Tańsza chata drwala": {
		"research_cost": 360, "research_time": 30, "req": ["Złoto z drwala"], "unlocked": false, "desc": "-10 Złota za drwala.", "grid_coords": Vector2(11, 1), "icon": "📉"
	},
	"Tańsze baraki": {
		"research_cost": 360, "research_time": 30, "req": ["Złoto z drwala"], "unlocked": false, "desc": "-20 Złota za baraki.", "grid_coords": Vector2(11, 3), "icon": "🏯"
	},
	"Ruch generała III": {
		"research_cost": 360, "research_time": 30, "req": ["Złoto z drwala"], "unlocked": false, "desc": "+1 Ruch generała.", "grid_coords": Vector2(11, 5), "icon": "🏇"
	},
	"Złoto z baraków": {
		"research_cost": 420, "research_time": 35, "req": ["Tańsza chata drwala", "Tańsze baraki", "Ruch generała III"], "unlocked": false, "desc": "+1 Złoto/barak.", "grid_coords": Vector2(12, 3), "icon": "🤑"
	}
}

func get_building_tooltip(building_name: String) -> String:
	if not building_costs.has(building_name):
		return ""

	var text = "Wymagania\n"
	match building_name:
		"Chata Drwala": text += "• Wymaga: Drewno\n"
		"Kopalnia Żelaza": text += "• Wymaga: złoże Żelaza\n• Zużywa Węgiel co turę\n"
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
	
	if building_name == "Dom mieszkalny" and culture_tree["Tańsze domy"]["unlocked"]:
		costs["Złoto"] = max(0, costs["Złoto"] - 10)
	if building_name == "Farma" and culture_tree["Tańsze farmy"]["unlocked"]:
		costs["Złoto"] = max(0, costs["Złoto"] - 10)
	if building_name in ["Laboratorium", "Warsztat"] and culture_tree["Tańsze bud. naukowe"]["unlocked"]:
		costs["Złoto"] = max(0, costs["Złoto"] - 20)
	if building_name in ["Biblioteka", "Świątynia"] and culture_tree["Tańsze bud. kulturowe"]["unlocked"]:
		costs["Złoto"] = max(0, costs["Złoto"] - 20)
	if building_name == "Chata Drwala" and culture_tree["Tańsza chata drwala"]["unlocked"]:
		costs["Złoto"] = max(0, costs["Złoto"] - 10)
	if building_name == "Baraki" and culture_tree["Tańsze baraki"]["unlocked"]:
		costs["Złoto"] = max(0, costs["Złoto"] - 20)
		
	return costs

func can_afford_and_place(building_name: String, tile_type: String) -> bool:
	if not building_costs.has(building_name): return false
	
	if building_name == "Chata Drwala" and tile_type != "Drewno": return false
	if building_name == "Kopalnia Żelaza" and tile_type != "Żelazo": return false
	if building_name == "Kopalnia Węgla" and tile_type != "Węgiel": return false
	if building_name == "Farma" and tile_type != "Pszenica": return false
	if building_name == "Pastwisko" and tile_type != "Bydło": return false
	
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
			var amount = mod_costs[res] * (current_level + 1)
			if res == "Drewno":
				amount = int(amount * 2.5)
			cost[res] = amount
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
	return resources["Złoto"] >= TILE_PURCHASE_GOLD_COST

func deduct_tile_purchase_costs() -> void:
	resources["Złoto"] -= TILE_PURCHASE_GOLD_COST
	notify_change()

func deduct_costs(building_name: String) -> void:
	if building_costs.has(building_name):
		var costs = get_modified_building_costs(building_name)
		for res in costs:
			resources[res] -= costs[res]
		notify_change()

func get_tech_cost(tech_name: String) -> int:
	var base_cost = technology_tree[tech_name]["research_cost"]
	if culture_tree["Szybsze badania"]["unlocked"]:
		return max(1, base_cost - 25)
	return base_cost

func start_research(tech_name: String) -> bool:
	# Zwraca false (bez żadnej zmiany stanu), jeśli badanie nie mogło zostać
	# rozpoczęte — dzięki temu UI może pokazać graczowi komunikat zamiast
	# po cichu ignorować kliknięcie.
	if current_research != "":
		return false

	var tech = technology_tree[tech_name]
	var cost = get_tech_cost(tech_name)
	
	if resources["Nauka"] < cost:
		return false

	var time = tech["research_time"]
	if culture_tree["Szybsze badania"]["unlocked"]:
		time = max(1, time - 1)

	resources["Nauka"] -= cost
	current_research = tech_name
	research_turns_left = time
	notify_change()
	return true

func start_culture_research(tech_name: String) -> bool:
	if current_culture_research != "":
		return false

	var tech = culture_tree[tech_name]
	if resources["Kultura"] < tech["research_cost"]:
		return false

	var time = tech["research_time"]
	if culture_tree["Szybsze badania"]["unlocked"]:
		time = max(1, time - 1)

	resources["Kultura"] -= tech["research_cost"]
	current_culture_research = tech_name
	culture_turns_left = time
	notify_change()
	return true

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
	turn_warnings.clear()
	current_turn += 1
	var max_pop = 5
	for b_data in active_buildings_data:
		if b_data["name"] == "Dom mieszkalny":
			max_pop += 5 * b_data.get("level", 1)
	resources["Maks_Populacja"] = max_pop
	
	if resources["Populacja"] > resources["Maks_Populacja"]:
		resources["Populacja"] = resources["Maks_Populacja"]
	
	var food_consumption = resources["Populacja"] * 1
	resources["Jedzenie"] -= food_consumption
	
	var turn_science = 0
	var turn_culture = 0
	
	var flat_food_bonus = 0
	if culture_tree["Jedzenie +2"]["unlocked"]: flat_food_bonus = 2

	var flat_iron_coal_bonus = 0
	if culture_tree["Więcej surowców"]["unlocked"]: flat_iron_coal_bonus = 1

	var flat_wood_bonus = 0
	if culture_tree["Drewno +2"]["unlocked"]: flat_wood_bonus = 2

	# Mnożnik z aktywnego błogosławieństwa Świątyni (+10% produkcji surowców
	# materialnych, dopóki temple_blessing_turns_left > 0).
	var temple_multiplier = 1.0
	if temple_blessing_turns_left > 0:
		temple_multiplier = 1.1

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
					resources["Złoto"] += int(2 * b_level * temple_multiplier)
				if culture_tree["Kultura z domów"]["unlocked"]:
					turn_culture += 1 * b_level
			"Centrum Miasta":
				var gold_bonus = int(10 * b_level * temple_multiplier)
				resources["Złoto"] += gold_bonus
				resources["Jedzenie"] += int(2 * b_level * temple_multiplier)
				resources["Drewno"] += int(2 * b_level * temple_multiplier)
			"Chata Drwala":
				resources["Drewno"] += int(4 * size_modifier * b_level * temple_multiplier) + flat_wood_bonus * b_level
				if culture_tree["Złoto z drwala"]["unlocked"]:
					resources["Złoto"] += int(1 * b_level * temple_multiplier)
			"Kopalnia Żelaza":
				var iron_yield = 2
				var produced_iron = int(iron_yield * size_modifier * b_level * temple_multiplier) + flat_iron_coal_bonus * b_level
				var coal_consumed = int(3 * size_modifier * b_level)
				var gold_cost = 2 * b_level
				if resources.get("Złoto", 0) < gold_cost:
					if not turn_warnings.has("Brak złota! Kopalnie wstrzymały produkcję."):
						turn_warnings.append("Brak złota! Kopalnie wstrzymały produkcję.")
				elif resources.get("Węgiel", 0) >= coal_consumed:
					resources["Węgiel"] -= coal_consumed
					resources["Żelazo"] += produced_iron
					resources["Złoto"] -= gold_cost
				else:
					if not turn_warnings.has("Brak węgla! Kopalnie żelaza wstrzymały produkcję."):
						turn_warnings.append("Brak węgla! Kopalnie żelaza wstrzymały produkcję.")
			"Kopalnia Węgla":
				var coal_yield = 2
				var gold_cost = 2 * b_level
				if resources.get("Złoto", 0) < gold_cost:
					if not turn_warnings.has("Brak złota! Kopalnie wstrzymały produkcję."):
						turn_warnings.append("Brak złota! Kopalnie wstrzymały produkcję.")
				else:
					resources["Węgiel"] += int(coal_yield * size_modifier * b_level * temple_multiplier) + flat_iron_coal_bonus * b_level
					resources["Złoto"] -= gold_cost
			"Farma":
				var farm_yield = 6
				resources["Jedzenie"] += int(farm_yield * size_modifier * b_level * temple_multiplier) + flat_food_bonus * b_level
			"Pastwisko":
				resources["Jedzenie"] += int(4 * size_modifier * b_level * temple_multiplier) + flat_food_bonus * b_level
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
					resources["Złoto"] += int(2 * b_level * temple_multiplier)
			"Baraki":
				if culture_tree["Tech z baraków"]["unlocked"]:
					turn_science += 1 * b_level
				if culture_tree["Złoto z baraków"]["unlocked"]:
					resources["Złoto"] += int(1 * b_level * temple_multiplier)

	if culture_tree["Kultura +2/tura"]["unlocked"]:
		turn_culture += 2
	if culture_tree["Złoto za mieszkańca"]["unlocked"]:
		resources["Złoto"] += int(resources["Populacja"] * 1 * temple_multiplier)
	if culture_tree["Złoto co turę"]["unlocked"]:
		resources["Złoto"] += int(1 * temple_multiplier)

	var total_science = 1 + turn_science
	var total_culture = 1 + turn_culture
	
	resources["Nauka"] = min(
		max_tech_points,
		resources["Nauka"] + total_science
	)

	resources["Kultura"] = min(
		max_culture_points,
		resources["Kultura"] + total_culture
	)

	# Flaga "Głoduje" oraz kara za brak jedzenia muszą używać tego samego
	# progu (<=0), inaczej gracz widzi ostrzeżenie o karze, która jeszcze
	# faktycznie nie działa (np. przy jedzeniu dokładnie równym 0).
	resources["Głoduje"] = resources["Jedzenie"] <= 0

	if resources["Jedzenie"] <= 0:
		var deficit = 0
		if resources["Jedzenie"] < 0:
			deficit = -resources["Jedzenie"]
			
		var current_demand = max(1, resources["Populacja"] * 1)
		var starvation_ratio = float(deficit) / float(current_demand)
		var starving_pop = resources["Populacja"] * starvation_ratio
		
		var loss_percent = starving_pop * 0.05
		var gold_loss = int(resources["Złoto"] * loss_percent)
		
		if deficit > 0:
			gold_loss = max(5, gold_loss)
			
		resources["Jedzenie"] = 0
		resources["Złoto"] = max(0, resources["Złoto"] - gold_loss)
		
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

	# Odliczanie czasu aktywnego błogosławieństwa Świątyni oraz jego cooldownu.
	if temple_blessing_turns_left > 0:
		temple_blessing_turns_left -= 1
	if temple_blessing_cooldown_left > 0:
		temple_blessing_cooldown_left -= 1

	for unit in player_army:
		var turns_to_recruit = unit.get("turns_to_recruit", 0)
		var turns_in_recruitment = unit.get("turns_in_recruitment", 0)
		if turns_in_recruitment < turns_to_recruit:
			turns_in_recruitment += 1
			unit["turns_in_recruitment"] = turns_in_recruitment
			if turns_in_recruitment >= turns_to_recruit:
				unit_training_complete.emit(unit)

	var expired_potions = []
	for p_id in active_potions.keys():
		active_potions[p_id] -= 1
		if active_potions[p_id] <= 0:
			expired_potions.append(p_id)
	
	for p_id in expired_potions:
		active_potions.erase(p_id)
		
	potion_bonus_hp = 0
	potion_bonus_dmg = 0
	potion_bonus_def = 0
	potion_bonus_speed = 0
	for p_id in active_potions.keys():
		var effect = POTIONS_DATA[p_id]["effect"]
		var val = POTIONS_DATA[p_id]["value"]
		if effect == "hp": potion_bonus_hp += val
		elif effect == "dmg": potion_bonus_dmg += val
		elif effect == "def": potion_bonus_def += val
		elif effect == "speed": potion_bonus_speed += val

	notify_change()

func notify_change() -> void:
	economy_updated.emit(resources, current_turn, "")

func calculate_recruitment_turns(unit: Dictionary) -> int:
	var hp = unit.get("hp", 0)
	var dmg = unit.get("dmg", 0)
	var def = unit.get("def", 0)
	var attack_range = unit.get("attack_range", 1)
	var speed = unit.get("speed", 1)
	var move_range = unit.get("move_range", 1)
	
	var range_multiplier = 1.0 + (attack_range - 1) * 0.3
	var mobility_score = (speed + move_range * 2.0) / 5.0
	var mobility_multiplier = 1.0 + max(0.0, mobility_score - 1.0) * 0.1
	
	var effective_power = (hp + (dmg * range_multiplier) + def) * mobility_multiplier
	
	var time = max(1, int(effective_power / 10.0))
	if culture_tree["Szybsza rekrutacja"]["unlocked"]:
		time = max(1, time - 1)
	return time

func calculate_unit_cost(unit: Dictionary) -> Dictionary:
	var hp = unit.get("hp", 0)
	var dmg = unit.get("dmg", 0)
	var def = unit.get("def", 0)
	var attack_range = unit.get("attack_range", 1)
	var speed = unit.get("speed", 1)
	var move_range = unit.get("move_range", 1)
	
	var range_multiplier = 1.0 + (attack_range - 1) * 0.3
	var mobility_score = (speed + move_range * 2.0) / 5.0
	var mobility_multiplier = 1.0 + max(0.0, mobility_score - 1.0) * 0.1
	
	var effective_dmg = dmg * range_multiplier
	
	var cost = {
		"Złoto": int((hp + effective_dmg + def) * 1.5 * mobility_multiplier),
		"Żelazo": int((effective_dmg * 2.0) + (def * 1.0)),
		"Jedzenie": int(hp * 1.5 * mobility_multiplier),
		"Populacja": 1
	}
	
	if culture_tree["Tańsza rekrutacja"]["unlocked"]:
		cost["Złoto"] = max(0, cost["Złoto"] - 10)
		cost["Żelazo"] = max(0, cost["Żelazo"] - 2)
		
	return cost

func can_recruit_unit(unit: Dictionary) -> bool:
	if player_army.size() >= MAX_ARMY_SIZE:
		return false
	var cost = calculate_unit_cost(unit)
	if resources.get("Populacja", 0) - cost.get("Populacja", 0) < 1:
		return false
	for res in cost:
		if resources.get(res, 0) < cost[res]:
			return false
	return true

func is_army_full() -> bool:
	return player_army.size() >= MAX_ARMY_SIZE

func recruit_unit(unit: Dictionary, source_pos: Vector2 = Vector2(-1, -1)) -> void:
	if can_recruit_unit(unit):
		var cost = calculate_unit_cost(unit)
		for res in cost:
			resources[res] -= cost[res]
		
		var new_unit = unit.duplicate()
		new_unit["turns_to_recruit"] = calculate_recruitment_turns(new_unit)
		new_unit["turns_in_recruitment"] = 0
		new_unit["source_barracks_pos"] = source_pos
		

		# Aktualne HP jednostki (do systemu leczenia w Warsztacie). Na razie
		# gra nie ma jeszcze mechanizmu zadawania obrażeń w walce, więc
		# current_hp startuje zawsze pełne — to pole jest przygotowane pod
		# przyszły system walki, a leczenie po prostu przywraca je do max.
		new_unit["current_hp"] = new_unit["hp"]
		
		player_army.append(new_unit)
		notify_change()

func upgrade_units_from_barracks(pos: Vector2, new_level: int, unit_data_json: Dictionary) -> void:
	if not unit_data_json.has("factions"): return
	
	var target_faction_id = "humans"
	if new_level == 2:
		target_faction_id = "humans_lvl2"
	elif new_level >= 3:
		target_faction_id = "humans_lvl3"
		
	var target_faction = null
	for faction in unit_data_json["factions"]:
		if faction.get("id") == target_faction_id:
			target_faction = faction
			break
			
	if target_faction == null: return
	
	var any_upgraded = false
	for u in player_army:
		if u.get("source_barracks_pos") == pos:
			var base_short = u.get("short_name", "")
			# Znajdź nowy wariant na podstawie short_name
			for new_u in target_faction["units"]:
				if new_u.get("short_name", "") == base_short:
					u["id"] = new_u["id"]
					u["name"] = new_u["name"]
					# HP może być uszkodzone, zaktualizujmy max_hp i wyleczmy (lub zachowajmy procent)
					var hp_diff = new_u["hp"] - u.get("hp", 0)
					u["hp"] = new_u["hp"]
					u["current_hp"] = u.get("current_hp", 0) + hp_diff
					u["dmg"] = new_u["dmg"]
					u["def"] = new_u["def"]
					any_upgraded = true
					break
	
	if any_upgraded:
		notify_change()

func remove_unit(unit: Dictionary) -> void:
	if unit in player_army:
		player_army.erase(unit)
		var cost = calculate_unit_cost(unit)
		if cost.has("Populacja"):
			resources["Populacja"] = min(resources["Populacja"] + cost["Populacja"], resources["Maks_Populacja"])
		notify_change()

func clear_army() -> void:
	for unit in player_army:
		var cost = calculate_unit_cost(unit)
		if cost.has("Populacja"):
			resources["Populacja"] += cost["Populacja"]
	
	resources["Populacja"] = min(resources["Populacja"], resources["Maks_Populacja"])
	player_army.clear()
	notify_change()

func reset() -> void:
	current_turn = 1
	player_army = []

	owned_potions = {}
	active_potions = {}
	potion_bonus_hp = 0
	potion_bonus_dmg = 0
	potion_bonus_def = 0
	potion_bonus_speed = 0

	temple_blessing_turns_left = 0
	temple_blessing_cooldown_left = 0
	for skill in skill_tree.values():
		skill["unlocked"] = false
	
	resources = {
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
	
	# Limity punktów zwiększone, ponieważ przy dotychczasowej wartości 350
	# nie dało się zbadać wszystkich węzłów na końcu drzew (np. wymagających
	# 420 pkt Kultury lub kosztów Technologii sięgających blisko 500 pkt).
	max_tech_points = 500.0
	max_culture_points = 420.0
	
	current_research = ""
	research_turns_left = 0
	
	current_culture_research = ""
	culture_turns_left = 0
	
	for tech in technology_tree.values():
		tech["unlocked"] = false
		
	for tech in culture_tree.values():
		tech["unlocked"] = false

func buy_potion(potion_id: String) -> bool:
	if not POTIONS_DATA.has(potion_id): return false
	var data = POTIONS_DATA[potion_id]
	for res in data["cost"]:
		if resources.get(res, 0) < data["cost"][res]:
			return false
			
	for res in data["cost"]:
		resources[res] -= data["cost"][res]
		
	if not owned_potions.has(potion_id):
		owned_potions[potion_id] = 0
	owned_potions[potion_id] += 1
	notify_change()
	return true

func use_potion(potion_id: String) -> bool:
	if not owned_potions.has(potion_id) or owned_potions[potion_id] <= 0: return false
	
	owned_potions[potion_id] -= 1
	if owned_potions[potion_id] <= 0:
		owned_potions.erase(potion_id)
		
	var data = POTIONS_DATA[potion_id]
	active_potions[potion_id] = data["duration"]
	
	potion_bonus_hp = 0
	potion_bonus_dmg = 0
	potion_bonus_def = 0
	potion_bonus_speed = 0
	for p_id in active_potions.keys():
		var effect = POTIONS_DATA[p_id]["effect"]
		var val = POTIONS_DATA[p_id]["value"]
		if effect == "hp": potion_bonus_hp += val
		elif effect == "dmg": potion_bonus_dmg += val
		elif effect == "def": potion_bonus_def += val
		elif effect == "speed": potion_bonus_speed += val
		
	notify_change()
	return true

# --- ŚWIĄTYNIA: BŁOGOSŁAWIEŃSTWO -------------------------------------------

func can_activate_temple_blessing() -> bool:
	return temple_blessing_cooldown_left <= 0

func activate_temple_blessing() -> bool:
	if not can_activate_temple_blessing():
		return false
	temple_blessing_turns_left = TEMPLE_BLESSING_DURATION
	temple_blessing_cooldown_left = TEMPLE_BLESSING_COOLDOWN
	notify_change()
	return true

# --- WARSZTAT: LECZENIE ARMII -----------------------------------------------

func heal_army_units() -> void:
	for unit in player_army:
		if unit.has("hp"):
			unit["current_hp"] = unit["hp"]
	notify_change()

# --- BIBLIOTEKA: BADANIE UMIEJĘTNOŚCI ---------------------------------------

func can_research_skill(skill_id: String) -> bool:
	if not skill_tree.has(skill_id): return false
	var skill = skill_tree[skill_id]
	if skill["unlocked"]: return false
	if resources.get("Złoto", 0) < skill["cost_gold"]: return false
	if resources.get("Nauka", 0) < skill["cost_tech"]: return false
	return true

func research_skill(skill_id: String) -> bool:
	if not can_research_skill(skill_id): return false
	var skill = skill_tree[skill_id]
	resources["Złoto"] -= skill["cost_gold"]
	resources["Nauka"] -= skill["cost_tech"]
	skill["unlocked"] = true
	notify_change()
	return true

func is_skill_unlocked(skill_id: String) -> bool:
	return skill_tree.has(skill_id) and skill_tree[skill_id]["unlocked"]
