extends Node2D
# Character.gd

const MOVE_SPEED: float = 200.0
const ARRIVAL_THRESHOLD: float = 4.0

@export var move_range: int = 4

var path: Array[Vector2] = []

func _ready() -> void:
	var polygon = Polygon2D.new()
	var points = PackedVector2Array()
	for i in range(16):
		var angle = (TAU / 16.0) * i
		points.append(Vector2(cos(angle), sin(angle)) * 18.0)
	polygon.polygon = points
	polygon.color = Color(0.9, 0.2, 0.2)
	add_child(polygon)

func follow_path(new_path: Array[Vector2]) -> void:
	path = new_path

func _physics_process(_delta: float) -> void:
	if path.is_empty():
		return

	var target: Vector2 = path[0]
	var to_target: Vector2 = target - global_position

	if to_target.length() < ARRIVAL_THRESHOLD:
		path.pop_front()
	else:
		global_position += to_target.normalized() * MOVE_SPEED * _delta
