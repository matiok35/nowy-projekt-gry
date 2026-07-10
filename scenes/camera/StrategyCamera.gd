extends Camera2D
# StrategyCamera.gd

@export var SPEED: float = 400.0

# Ograniczenia poruszania się rozszerzone pod kątem kafelków o promieniu 80.0
@export var LIMIT_LEFT: float = -200.0
@export var LIMIT_RIGHT: float = 7200.0
@export var LIMIT_TOP: float = -200.0
@export var LIMIT_BOTTOM: float = 6200.0

# --- ZMIENNE DLA PRZYBLIŻANIA (ZOOM) ---
@export var ZOOM_SPEED: float = 0.1
@export var MIN_ZOOM: float = 0.5  
@export var MAX_ZOOM: float = 2.0  

# --- ZMIENNE DLA PRZESUWANIA MYSZKĄ (LPM) ---
var _is_dragging: bool = false
var _drag_start_pos: Vector2 = Vector2.ZERO
var is_drag_motion: bool = false # Flaga informująca inne skrypty o ruchu przeciągania

func _process(delta: float):
	var move_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var current_speed = SPEED * (1.0 / zoom.x)
	position += move_dir * current_speed * delta
	_clamp_position()

func _unhandled_input(event: InputEvent):
	if event is InputEventMouseButton:
		# ZOOM (rolka myszy)
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				change_zoom(ZOOM_SPEED)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				change_zoom(-ZOOM_SPEED)
		
		# ROZPOCZĘCIE / ZAKOŃCZENIE PRZECIĄGANIA LPM
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_is_dragging = true
				_drag_start_pos = event.position
				is_drag_motion = false
			else:
				_is_dragging = false
				# Uwaga: Nie zerujemy 'is_drag_motion' natychmiast tutaj, 
				# aby game_world mógł odczytać stan w tej samej klatce puszczenia przycisku.

	# RUCH MYSZĄ
	elif event is InputEventMouseMotion and _is_dragging:
		if event.position.distance_to(_drag_start_pos) > 10.0:
			is_drag_motion = true
			
		if is_drag_motion:
			position -= event.relative / zoom
			_clamp_position()

func change_zoom(amount: float):
	var new_zoom = zoom + Vector2(amount, amount)
	new_zoom.x = clamp(new_zoom.x, MIN_ZOOM, MAX_ZOOM)
	new_zoom.y = clamp(new_zoom.y, MIN_ZOOM, MAX_ZOOM)
	zoom = new_zoom

func _clamp_position():
	position.x = clamp(position.x, LIMIT_LEFT, LIMIT_RIGHT)
	position.y = clamp(position.y, LIMIT_TOP, LIMIT_BOTTOM)
