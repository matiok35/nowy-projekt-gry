extends Node2D
class_name Character
# character.gd

signal city_creation_requested(global_pos: Vector2)

const MOVE_SPEED: float = 200.0
const ARRIVAL_THRESHOLD: float = 4.0

@export var move_range: int = 5
var moves_left: int = 5
var _last_turn: int = 1 # POPRAWKA: Śledzenie ostatniej tury zapobiegające exploitowi ruchu

var selected: bool = false  
var _sprite: Sprite2D  
var path: Array[Vector2] = []

var army: Array = []
var _army_label: Label

func _ready() -> void:
	_sprite = Sprite2D.new()
	var tex = load("res://assets/characters/gen.png")
	if tex:
		_sprite.texture = tex
		var tex_size = tex.get_size()
		var scale_factor = 72.0 / max(tex_size.x, tex_size.y)
		_sprite.scale = Vector2(scale_factor, scale_factor)
	add_child(_sprite)

	_army_label = Label.new()
	_army_label.add_theme_font_size_override("font_size", 15)
	_army_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	_army_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_army_label.add_theme_constant_override("shadow_offset_x", 1)
	_army_label.add_theme_constant_override("shadow_offset_y", 1)
	_army_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_army_label.position = Vector2(-40, 28)
	_army_label.size = Vector2(80, 20)
	_army_label.visible = false
	add_child(_army_label)
	_update_army_label()
	if not EconomyManager.economy_updated.is_connected(_on_economy_updated):
		EconomyManager.economy_updated.connect(_on_economy_updated)

func _on_economy_updated(_balances: Dictionary, current_turn: int, _b: String) -> void:
	_update_army_label()
	
	# POPRAWKA: moves_left odnawia się tylko wtedy, gdy faktycznie nastąpiła nowa tura
	if current_turn > _last_turn:
		_last_turn = current_turn
		var current_max = move_range
		if EconomyManager.culture_tree["Ruch generała I"]["unlocked"]: current_max += 1
		if EconomyManager.culture_tree["Ruch generała II"]["unlocked"]: current_max += 1
		if EconomyManager.culture_tree["Ruch generała III"]["unlocked"]: current_max += 1
		moves_left = current_max
		
	if get_parent() and get_parent().has_method("update_fog_of_war"):
		get_parent().update_fog_of_war()

func assign_army(units: Array) -> void:
	for u in units:
		if not army.has(u):
			army.append(u)
	_update_army_label()

func unassign_unit(unit) -> void:
	if army.has(unit):
		army.erase(unit)
	_update_army_label()

func has_army() -> bool:
	return army.size() > 0

func get_army_size() -> int:
	var count = 0
	for u in EconomyManager.player_army:
		if u.get("turns_in_recruitment", 0) >= u.get("turns_to_recruit", 0):
			count += 1
	return count

func _update_army_label() -> void:
	if not _army_label: return
	var size = get_army_size()
	if size == 0:
		_army_label.visible = false
	else:
		_army_label.visible = true
		_army_label.text = "⚔️ %d" % size

func set_selected(value: bool) -> void:
	selected = value
	if _sprite:
		_sprite.modulate = Color(1.5, 1.5, 1.0) if selected else Color(1.0, 1.0, 1.0)

func is_selected() -> bool:
	return selected

func follow_path(new_path: Array[Vector2]) -> void:
	path = new_path
	# Pierwszy punkt zwrócony przez A* to bieżąca pozycja postaci (start
	# ścieżki). Jeśli go nie usuniemy, _physics_process "skonsumuje" go
	# natychmiast i policzy jako wykonany krok, mimo że postać nigdzie się
	# jeszcze nie ruszyła.
	if not path.is_empty() and path[0].distance_to(global_position) < ARRIVAL_THRESHOLD:
		path.pop_front()
	
	if not path.is_empty():
		if AudioManager: AudioManager.play_steps()

func _physics_process(_delta: float) -> void:
	if path.is_empty():
		if AudioManager: AudioManager.stop_steps()
		return
		
	var target: Vector2 = path[0]
	var to_target: Vector2 = target - global_position
	
	if to_target.length() < ARRIVAL_THRESHOLD:
		path.pop_front()
		# Punkty ruchu (moves_left) są odejmowane dopiero w chwili, gdy
		# postać faktycznie dotrze do kolejnego pola — a nie z góry, w
		# momencie kliknięcia docelowego pola na mapie. Dzięki temu np.
		# przerwanie ruchu w połowie ścieżki nie zabiera punktów, których
		# postać nigdy nie wykorzystała.
		moves_left = max(0, moves_left - 1)
		if get_parent() and get_parent().has_method("update_fog_of_war"):
			get_parent().update_fog_of_war()
		if path.is_empty():
			set_selected(false) 
			if AudioManager: AudioManager.stop_steps()
	else:
		global_position += to_target.normalized() * MOVE_SPEED * _delta

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if event.double_click:
			if get_global_mouse_position().distance_to(global_position) < 35.0:
				city_creation_requested.emit(global_position)
				get_viewport().set_input_as_handled()
