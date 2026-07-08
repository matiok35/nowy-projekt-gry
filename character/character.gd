extends Node2D
class_name Character
# character.gd

signal city_creation_requested(global_pos: Vector2)

const MOVE_SPEED: float = 200.0
const ARRIVAL_THRESHOLD: float = 4.0

@export var move_range: int = 4

var selected: bool = false  
var _sprite: Sprite2D  
var path: Array[Vector2] = []

func _ready() -> void:
	_sprite = Sprite2D.new()
	var tex = load("res://assets/characters/gen.png")
	if tex:
		_sprite.texture = tex
		var tex_size = tex.get_size()
		var scale_factor = 72.0 / max(tex_size.x, tex_size.y)
		_sprite.scale = Vector2(scale_factor, scale_factor)
	add_child(_sprite)

func set_selected(value: bool) -> void:
	selected = value
	if _sprite:
		# Highlight character when selected by brightening the sprite
		_sprite.modulate = Color(1.5, 1.5, 1.0) if selected else Color(1.0, 1.0, 1.0)

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
