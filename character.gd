extends Node2D
class_name Character
# character.gd

# Sygnał wysyłany przy podwójnym kliknięciu w postać
signal city_creation_requested(global_pos: Vector2)

const MOVE_SPEED: float = 200.0
const ARRIVAL_THRESHOLD: float = 4.0

@export var move_range: int = 4

# GŁÓWNA ZMIENNA STANU (Kluczowa dla naprawy błędów scope w game_world.gd)
var selected: bool = false  

var _polygon: Polygon2D  

func _ready() -> void:
	# Tworzenie wizualnego kształtu postaci (koło) z kodu
	_polygon = Polygon2D.new()
	var points = PackedVector2Array()
	for i in range(16):
		var angle = (TAU / 16.0) * i
		points.append(Vector2(cos(angle), sin(angle)) * 18.0)
	_polygon.polygon = points
	_polygon.color = Color(0.9, 0.2, 0.2) # Domyślny czerwony
	add_child(_polygon)

# Bezpieczny setter wywoływany przez game_world.gd za pomocą .call() lub bezpośrednio
func set_selected(value: bool) -> void:
	selected = value
	# Zmiana koloru: pomarańczowy jeśli zaznaczony, czerwony jeśli nie
	if _polygon:
		_polygon.color = Color(1.0, 0.6, 0.0) if selected else Color(0.9, 0.2, 0.2)

# Bezpieczny getter dla świata gry
func is_selected() -> bool:
	return selected

# Przypisanie nowej ścieżki ruchu do celu
func follow_path(new_path: Array[Vector2]) -> void:
	path = new_path

# Tablica punktów Vector2 do przebycia (używana przez pathfinding)
var path: Array[Vector2] = []

func _physics_process(_delta: float) -> void:
	if path.is_empty():
		return
		
	var target: Vector2 = path[0]
	var to_target: Vector2 = target - global_position
	
	if to_target.length() < ARRIVAL_THRESHOLD:
		path.pop_front()
		if path.is_empty():
			set_selected(false) # Odznacz postać po dotarciu do celu
	else:
		global_position += to_target.normalized() * MOVE_SPEED * _delta

# Wykrywanie podwójnego kliknięcia bezpośrednio w obszar ludzika
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if event.double_click:
			# Sprawdzenie, czy kliknięto dostatecznie blisko pozycji postaci (promień 20 pikseli)
			if get_global_mouse_position().distance_to(global_position) < 20.0:
				city_creation_requested.emit(global_position)
				get_viewport().set_input_as_handled()
