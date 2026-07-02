extends Camera2D
# StrategyCamera.gd

@export var SPEED: float = 400.0
@export var EDGE_MARGIN: float = 25.0 # margines w pikselach od krawędzi ekranu

# Ograniczenia poruszania się (dopasowane do wielkości mapy 25x25 kafelków heksagonalnych)
@export var LIMIT_LEFT: float = -100.0
@export var LIMIT_RIGHT: float = 2200.0
@export var LIMIT_TOP: float = -100.0
@export var LIMIT_BOTTOM: float = 1600.0

func _process(delta: float):
	var viewport_size = get_viewport().get_mouse_position()
	var window_size = get_viewport().get_visible_rect().size
	var move_dir = Vector2.ZERO

	# Ruch w lewo / prawo
	if viewport_size.x < EDGE_MARGIN:
		move_dir.x = -1
	elif viewport_size.x > window_size.x - EDGE_MARGIN:
		move_dir.x = 1

	# Ruch w górę / dół
	if viewport_size.y < EDGE_MARGIN:
		move_dir.y = -1
	elif viewport_size.y > window_size.y - EDGE_MARGIN:
		move_dir.y = 1

	# Przesunięcie pozycji kamery z uwzględnieniem delta-time
	position += move_dir.normalized() * SPEED * delta
	
	# Nałożenie limitów (clamp), aby kamera nie uciekła w nieskończoność
	position.x = clamp(position.x, LIMIT_LEFT, LIMIT_RIGHT)
	position.y = clamp(position.y, LIMIT_TOP, LIMIT_BOTTOM)
