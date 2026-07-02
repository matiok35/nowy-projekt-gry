extends Control
# HUD.gd (Podpięty pod węzeł CanvasLayer/UI)

@onready var resources_label = $Panel/ResourcesLabel
@onready var turn_button = $TurnButton
@onready var build_chata = $MenuBudowania/BuildChata
@onready var build_iron = $MenuBudowania/BuildKopalniaZelaza
@onready var build_coal = $MenuBudowania/BuildKopalniaWegla

# Świat gry przekaże nam tablicę postawionych budynków przy końcu tury
var world_ref: Node2D 

func _ready():
	# Szukamy głównego świata w drzewie, aby móc pobrać stan budynków
	world_ref = get_tree().current_scene
	
	# Podpinamy się pod globalny menadżer ekonomii
	EconomyManager.economy_updated.connect(_on_economy_updated)
	
	# Podpinamy przyciski interfejsu
	turn_button.pressed.connect(_on_turn_pressed)
	build_chata.pressed.connect(func(): EconomyManager.select_building("Chata Drwala"))
	build_iron.pressed.connect(func(): EconomyManager.select_building("Kopalnia Żelaza"))
	build_coal.pressed.connect(func(): EconomyManager.select_building("Kopalnia Węgla"))
	
	# Wymuszamy pierwsze odświeżenie napisów na starcie
	EconomyManager.notify_change()

func _on_economy_updated(balances: Dictionary, turn: int, selected_build: String):
	resources_label.text = " Tura: %d | Złoto: %d | Drewno: %d | Żelazo: %d | Węgiel: %d" % [
		turn, balances["Złoto"], balances["Drewno"], balances["Żelazo"], balances["Węgiel"]
	]
	if selected_build != "":
		resources_label.text += " | Wybrano: " + selected_build

func _on_turn_pressed():
	# Pobieramy listę postawionych budynków ze świata gry i zlecamy nową turę
	var buildings = world_ref.get_active_buildings_list()
	EconomyManager.next_turn(buildings)
