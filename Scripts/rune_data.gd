# RuneData.gd
# Define los patrones de runas que el jugador debe trazar
# Cada runa tiene una serie de puntos (normalizados 0.0-1.0) que forman el símbolo

class_name RuneData

static func get_rune(id: String) -> Dictionary:
	var runes = {
		"arco": {
			"name": "Arco Primero",
			"description": "La runa básica de detección",
			"tier": 1,
			# Puntos que forman un arco simple (de izquierda a derecha, curvándose arriba)
			"points": _make_arc(0.1, 0.7, 0.9, 0.7, 0.2),
			"tolerance": 25.0  # margen de error en píxeles
		},
		"circulo": {
			"name": "Círculo del Enlace",
			"description": "Para vincular energía de cristal",
			"tier": 1,
			"points": _make_circle(0.5, 0.5, 0.35),
			"tolerance": 30.0
		},
		"zigzag": {
			"name": "Diente de Sierra",
			"description": "Sintoniza cristales de Llama",
			"tier": 2,
			"points": _make_zigzag(0.1, 0.3, 0.9, 5),
			"tolerance": 28.0
		},
		"estrella": {
			"name": "Estrella de la Veta",
			"description": "Runa de búsqueda avanzada",
			"tier": 2,
			"points": _make_star(0.5, 0.5, 0.35),
			"tolerance": 22.0
		}
	}
	return runes.get(id, runes["arco"])


static func get_rune_list(tier: int = 0) -> Array:
	var result = []
	for key in ["arco", "circulo", "zigzag", "estrella"]:
		var r = get_rune(key)
		if tier == 0 or r["tier"] == tier:
			result.append(key)
	return result


# --- Generadores de patrones ---

static func _make_arc(x1: float, y1: float, x2: float, y2: float, height: float) -> Array:
	var pts = []
	var steps = 20
	for i in range(steps + 1):
		var t = float(i) / steps
		var x = lerp(x1, x2, t)
		var y = lerp(y1, y2, t) - height * sin(t * PI)
		pts.append(Vector2(x, y))
	return pts

static func _make_circle(cx: float, cy: float, r: float) -> Array:
	var pts = []
	var steps = 24
	for i in range(steps + 1):
		var a = float(i) / steps * TAU
		pts.append(Vector2(cx + cos(a) * r, cy + sin(a) * r))
	return pts

static func _make_zigzag(x1: float, y_center: float, x2: float, spikes: int) -> Array:
	var pts = []
	var amp = 0.2
	var steps = spikes * 2
	for i in range(steps + 1):
		var t = float(i) / steps
		var x = lerp(x1, x2, t)
		var y = y_center + (amp if i % 2 == 0 else -amp)
		pts.append(Vector2(x, y))
	return pts

static func _make_star(cx: float, cy: float, r: float) -> Array:
	var pts = []
	var steps = 10  # 5 puntas = 10 puntos
	for i in range(steps + 1):
		var a = float(i) / steps * TAU - PI / 2
		var radius = r if i % 2 == 0 else r * 0.45
		pts.append(Vector2(cx + cos(a) * radius, cy + sin(a) * radius))
	return pts
