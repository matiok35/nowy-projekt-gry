extends Camera2D
# StrategyCamera.gd

@export var SPEED: float = 400.0

# Ograniczenia poruszania się (dopasowane do wielkości mapy 25x25 kafelków)
@export var LIMIT_LEFT: float = -100.0
@export var LIMIT_RIGHT: float = 2200.0
@export var LIMIT_TOP: float = -100.0
@export var LIMIT_BOTTOM: float = 1600.0

# --- NOWE ZMIENNE DLA PRZYBLIŻANIA (ZOOM) ---
@export var ZOOM_SPEED: float = 0.1
@export var MIN_ZOOM: float = 0.5  # Maksymalne oddalenie (im mniej, tym dalej)
@export var MAX_ZOOM: float = 2.0  # Maksymalne przybliżenie

func _process(delta: float):
	# 1. POBIERANIE KIERUNKU Z KLAWIATURY
	var move_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# 2. PRZESUWANIE KAMERY
	var current_speed = SPEED * (1.0 / zoom.x)
	position += move_dir * current_speed * delta
	
	# 3. NAŁOŻENIE LIMITÓW (clamp)
	position.x = clamp(position.x, LIMIT_LEFT, LIMIT_RIGHT)
	position.y = clamp(position.y, LIMIT_TOP, LIMIT_BOTTOM)

# --- NOWA FUNKCJA DO OBSŁUGI MYSZY ---
func _unhandled_input(event: InputEvent):
	# Sprawdzamy, czy zdarzenie to użycie przycisku/rolki myszy
	if event is InputEventMouseButton and event.pressed:
		
		# Rolka w górę (przybliżanie)
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			change_zoom(ZOOM_SPEED)
			
		# Rolka w dół (oddalanie)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			change_zoom(-ZOOM_SPEED)

# Funkcja pomocnicza do zmiany zooma
func change_zoom(amount: float):
	var new_zoom = zoom + Vector2(amount, amount)
	new_zoom.x = clamp(new_zoom.x, MIN_ZOOM, MAX_ZOOM)
	new_zoom.y = clamp(new_zoom.y, MIN_ZOOM, MAX_ZOOM)
	zoom = new_zoom
