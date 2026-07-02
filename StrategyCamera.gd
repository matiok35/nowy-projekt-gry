extends Camera2D
# StrategyCamera.gd

@export var SPEED: float = 400.0
<<<<<<< HEAD
@export var EDGE_MARGIN: float = 25.0 # margines w pikselach od krawędzi ekranu

# Ograniczenia poruszania się (dopasowane do wielkości mapy 25x25 kafelków heksagonalnych)
=======
# Usunęliśmy EDGE_MARGIN, bo nie używamy już myszki do poruszania

# Ograniczenia poruszania się (dopasowane do wielkości mapy 25x25 kafelków)
>>>>>>> 984e8282779e960859e324d58ef809eaedf03205
@export var LIMIT_LEFT: float = -100.0
@export var LIMIT_RIGHT: float = 2200.0
@export var LIMIT_TOP: float = -100.0
@export var LIMIT_BOTTOM: float = 1600.0

<<<<<<< HEAD
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
=======
# --- NOWE ZMIENNE DLA PRZYBLIŻANIA (ZOOM) ---
@export var ZOOM_SPEED: float = 0.1
@export var MIN_ZOOM: float = 0.5  # Maksymalne oddalenie (im mniej, tym dalej)
@export var MAX_ZOOM: float = 2.0  # Maksymalne przybliżenie

func _process(delta: float):
	# 1. POBIERANIE KIERUNKU Z KLAWIATURY
	# Input.get_vector to świetna funkcja w Godocie, która sama robi z 4 przycisków
	# jeden wektor kierunku (np. wciśnięcie w prawo da (1, 0)).
	# "ui_left", "ui_right" itd. to domyślne akcje przypisane pod strzałki (i często WSAD).
	var move_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# 2. PRZESUWANIE KAMERY
	# Mnożymy przez (1.0 / zoom.x), żeby po oddaleniu mapa przesuwała się szybciej.
	# Zapewnia to lepsze wrażenie płynności, niezależnie od tego jak blisko jesteś.
	var current_speed = SPEED * (1.0 / zoom.x)
	position += move_dir * current_speed * delta
	
	# 3. NAŁOŻENIE LIMITÓW (clamp)
	# clamp sprawdza czy nasza pozycja (np. position.x) mieści się między minimum (LIMIT_LEFT) a maksimum (LIMIT_RIGHT).
	# Jeśli nie, to "przycina" ją do tej wartości. Dzięki temu nie uciekniemy poza mapę.
	position.x = clamp(position.x, LIMIT_LEFT, LIMIT_RIGHT)
	position.y = clamp(position.y, LIMIT_TOP, LIMIT_BOTTOM)

# --- NOWA FUNKCJA DO OBSŁUGI MYSZY ---
# _unhandled_input uruchamia się tylko wtedy, gdy kliknięcia nie wyłapie HUD / Interfejs.
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
	# Zmieniamy zoom dodając wartość amount zarówno do osi X jak i Y
	var new_zoom = zoom + Vector2(amount, amount)
	
	# Ponownie używamy clamp, żeby gracz nie przybliżył w nieskończoność
	new_zoom.x = clamp(new_zoom.x, MIN_ZOOM, MAX_ZOOM)
	new_zoom.y = clamp(new_zoom.y, MIN_ZOOM, MAX_ZOOM)
	
	zoom = new_zoom
>>>>>>> 984e8282779e960859e324d58ef809eaedf03205
