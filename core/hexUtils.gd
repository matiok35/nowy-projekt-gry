class_name HexUtils
extends RefCounted
# hex_utils.gd

static func get_neighbors(pos: Vector2) -> Array[Vector2]:
	var x: int = int(pos.x)
	var y: int = int(pos.y)
	var neighbors: Array[Vector2]
	if y % 2 == 0:
		neighbors = [
			Vector2(x + 1, y), Vector2(x - 1, y),
			Vector2(x,     y - 1), Vector2(x - 1, y - 1),
			Vector2(x,     y + 1), Vector2(x - 1, y + 1),
		]
	else:
		neighbors = [
			Vector2(x + 1, y), Vector2(x - 1, y),
			Vector2(x + 1, y - 1), Vector2(x,     y - 1),
			Vector2(x + 1, y + 1), Vector2(x,     y + 1),
		]
	return neighbors
 
static func get_distance(a: Vector2, b: Vector2) -> int:
	# UWAGA: użycie int(a.y) / 2 obcinałoby wynik dzielenia w stronę zera
	# zamiast w dół, co dla ujemnych nieparzystych wierszy dawało błędny
	# offset kolumny (a w efekcie zawyżony dystans dla par sąsiadujących
	# pól). floori() zawsze zaokrągla w dół, niezależnie od znaku.
	var az = a.y
	var ax = a.x - floori(a.y / 2.0)
	var ay = -ax - az
	var bz = b.y
	var bx = b.x - floori(b.y / 2.0)
	var by = -bx - bz
	return int((abs(ax - bx) + abs(ay - by) + abs(az - bz)) / 2.0)
 
static func get_cell_id(pos: Vector2) -> int:
	return int(pos.x) + 1000 + (int(pos.y) + 1000) * 2000
