extends Camera2D
# StrategyCamera.gd

@export var SPEED: float = 400.0

# Ograniczenia poruszania się (dopasowane do wielkości mapy 25x25 kafelków)
@export var LIMIT_LEFT: float = -100.0
@export var LIMIT_RIGHT: float = 2200.0
@export var LIMIT_TOP: float = -100.0
@export var LIMIT_BOTTOM: float = 1600.0

# --- ZMIENNE DLA PRZYBLIŻANIA (ZOOM) ---
@export var ZOOM_SPEED: float = 0.1
@export var MIN_ZOOM: float = 0.5  # Maksymalne oddalenie (im mniej, tym dalej)
@export var MAX_ZOOM: float = 2.0  # Maksymalne przybliżenie

# --- NOWE ZMIENNE DLA PRZESUWANIA MYSZKĄ ---
var _is_dragging: bool = false

func _process(delta: float):
	# 1. POBIERANIE KIERUNKU Z KLAWIATURY (zostaje bez zmian)
	var move_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# 2. PRZESUWANIE KAMERY KLAWISZAMI
	var current_speed = SPEED * (1.0 / zoom.x)
	position += move_dir * current_speed * delta
	
	# 3. NAŁOŻENIE LIMITÓW (clamp)
	_clamp_position()

# --- ZAKTUALIZOWANA FUNKCJA DO OBSŁUGI MYSZY ---
func _unhandled_input(event: InputEvent):
	# Obsługa wciskania przycisków myszy
	if event is InputEventMouseButton:
		# --- ZOOM (rolka myszy) ---
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				change_zoom(ZOOM_SPEED)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				change_zoom(-ZOOM_SPEED)
		
		# --- ROZPOCZĘCIE / ZAKOŃCZENIE PRZECIĄGANIA MYSZĄ ---
		# Jeśli chcesz zmienić przycisk, zmień MOUSE_BUTTON_MIDDLE na np. MOUSE_BUTTON_RIGHT lub MOUSE_BUTTON_LEFT
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			if event.pressed:
				_is_dragging = true
			else:
				_is_dragging = false
				
	# --- RUCH MYSZĄ (PRZESUWANIE EKRANU) ---
	elif event is InputEventMouseMotion and _is_dragging:
		# Przesuwamy kamerę w kierunku przeciwnym do ruchu myszy
		# Dzielimy przez `zoom`, aby przybliżenie nie psuło czułości przesuwania (tzw. przesunięcie 1:1)
		position -= event.relative / zoom
		_clamp_position()

# Funkcja pomocnicza do zmiany zooma (zostaje bez zmian)
func change_zoom(amount: float):
	var new_zoom = zoom + Vector2(amount, amount)
	new_zoom.x = clamp(new_zoom.x, MIN_ZOOM, MAX_ZOOM)
	new_zoom.y = clamp(new_zoom.y, MIN_ZOOM, MAX_ZOOM)
	zoom = new_zoom

# Funkcja pomocnicza do limitowania pozycji kamery (aby nie powtarzać kodu)
func _clamp_position():
	position.x = clamp(position.x, LIMIT_LEFT, LIMIT_RIGHT)
	position.y = clamp(position.y, LIMIT_TOP, LIMIT_BOTTOM)
