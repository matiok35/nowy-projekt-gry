extends Node2D
class_name Character
# character.gd

signal city_creation_requested(global_pos: Vector2)

const MOVE_SPEED: float = 200.0
const ARRIVAL_THRESHOLD: float = 4.0

@export var move_range: int = 4

var selected: bool = false  
var _polygon: Polygon2D  
var path: Array[Vector2] = []

func _ready() -> void:
	_polygon = Polygon2D.new()
	var points = PackedVector2Array()
	for i in range(16):
		var angle = (TAU / 16.0) * i
		points.append(Vector2(cos(angle), sin(angle)) * 18.0)
	_polygon.polygon = points
	_polygon.color = Color(0.9, 0.2, 0.2) 
	add_child(_polygon)

func set_selected(value: bool) -> void:
	selected = value
	if _polygon:
		_polygon.color = Color(1.0, 0.6, 0.0) if selected else Color(0.9, 0.2, 0.2)

func is_selected() -> bool:
	return selected

func follow_path(new_path: Array[Vector2]) -> void:
	path = new_path

func _physics_process(_delta: float) -> void:
	if path.is_empty():
		return
		
	var target: Vector2 = path[0]
	var to_target: Vector2 = target - global_position
	
	if to_target.length() < ARRIVAL_THRESHOLD:
		path.pop_front()
		if path.is_empty():
			set_selected(false) 
	else:
		global_position += to_target.normalized() * MOVE_SPEED * _delta

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if event.double_click:
			# Zwiększono dystans kliknięcia do 35 pikseli, dopasowując do większych kafelków
			if get_global_mouse_position().distance_to(global_position) < 35.0:
				city_creation_requested.emit(global_position)
				get_viewport().set_input_as_handled()
