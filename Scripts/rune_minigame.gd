# rune_minigame.gd
# Minijuego de trazado de runas: aparece un patrón que el jugador debe dibujar

class_name RuneMinigame
extends CanvasLayer

signal rune_completed(success: bool, rune_id: String)

var _rune_data: Dictionary
var _drawing: bool = false
var _drawn_points: PackedVector2Array = []
var _ghost_points: PackedVector2Array = []

# Referencias a nodos (se resuelven manualmente en _ready)
var _background: ColorRect
var _rune_name_label: Label
var _drawing_area: Control
var _ghost_line: Line2D
var _draw_line: Line2D
var _instruction_label: Label
var _feedback_label: Label

func setup(rune_id: String) -> void:
	_rune_data = RuneData.get_rune(rune_id)
	
	_rune_name_label.text = _rune_data["name"]
	_instruction_label.text = "Traza la runa con el ratón"
	_feedback_label.text = ""
	
	await get_tree().process_frame
	_refresh_ghost()

func _refresh_ghost() -> void:
	if not _drawing_area or _drawing_area.size.x <= 0:
		return
	
	var area_size = _drawing_area.size
	_ghost_points.clear()
	for p in _rune_data["points"]:
		_ghost_points.append(Vector2(p.x * area_size.x, p.y * area_size.y))
	
	if _ghost_line:
		_ghost_line.points = _ghost_points
	if _draw_line:
		_draw_line.clear_points()

func _ready() -> void:
	# Resolver nodos manualmente para evitar problemas de ruta
	_background = find_child("Background", true, false)
	_rune_name_label = find_child("RuneName", true, false)
	_drawing_area = find_child("DrawingArea", true, false)
	_ghost_line = find_child("GhostLine", true, false)
	_draw_line = find_child("DrawLine", true, false)
	_instruction_label = find_child("Instruction", true, false)
	_feedback_label = find_child("Feedback", true, false)
	
	# Verificar que encontramos todo
	if not _drawing_area:
		push_error("RuneMinigame: no se encontró DrawingArea")
		return
	if not _ghost_line or not _draw_line:
		push_error("RuneMinigame: no se encontraron las líneas de dibujo")
		return
	
	# Conectar eventos de dibujo
	_drawing_area.gui_input.connect(_on_drawing_input)
	_drawing_area.mouse_filter = Control.MOUSE_FILTER_STOP

func _on_drawing_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_start_draw(event.position)
			else:
				_end_draw(event.position)
	elif event is InputEventMouseMotion and _drawing:
		_continue_draw(event.position)

func _start_draw(pos: Vector2) -> void:
	_drawing = true
	_drawn_points.clear()
	_drawn_points.append(pos)
	if _draw_line:
		_draw_line.clear_points()
	if _feedback_label:
		_feedback_label.text = ""

func _continue_draw(pos: Vector2) -> void:
	_drawn_points.append(pos)
	if _draw_line:
		_draw_line.points = _drawn_points

func _end_draw(_pos: Vector2) -> void:
	_drawing = false
	if _drawn_points.size() < 5:
		if _feedback_label:
			_feedback_label.text = "Demasiado corto. Inténtalo de nuevo."
		return
	
	_check_accuracy()

func _check_accuracy() -> void:
	if _ghost_points.size() < 2 or _drawn_points.size() < 2:
		return
	
	var sample_count = 30
	var sampled_ghost = _sample_curve(_ghost_points, sample_count)
	var sampled_drawn = _sample_curve(_drawn_points, sample_count)
	
	var total_error: float = 0.0
	for i in sample_count:
		total_error += sampled_ghost[i].distance_to(sampled_drawn[i])
	var avg_error: float = total_error / sample_count
	
	var tolerance = _rune_data.get("tolerance", 30.0)
	
	if _feedback_label:
		if avg_error <= tolerance:
			_feedback_label.text = "✓ ¡Runa trazada con éxito!"
			_feedback_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.4))
			rune_completed.emit(true, _rune_data.get("id", "arco"))
			await get_tree().create_timer(0.8).timeout
			queue_free()
		else:
			var pct = maxf(0, 100.0 - (avg_error - tolerance) / tolerance * 50)
			_feedback_label.text = "✗ Precisión: %d%%  —  Inténtalo de nuevo" % pct
			_feedback_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
			_drawn_points.clear()
			if _draw_line:
				_draw_line.clear_points()
			rune_completed.emit(false, _rune_data.get("id", "arco"))

static func _sample_curve(points: PackedVector2Array, n: int) -> PackedVector2Array:
	if points.size() <= 1:
		return points
	
	var lengths: Array[float] = [0.0]
	for i in range(1, points.size()):
		lengths.append(lengths[-1] + points[i-1].distance_to(points[i]))
	var total_length = lengths[-1]
	if total_length <= 0:
		return points
	
	var result: PackedVector2Array = []
	result.resize(n)
	var step = total_length / (n - 1)
	var current_idx = 0
	
	for i in range(n):
		var target_dist = i * step
		while current_idx < lengths.size() - 2 and lengths[current_idx + 1] < target_dist:
			current_idx += 1
		var seg_start = lengths[current_idx]
		var seg_end = lengths[current_idx + 1]
		var seg_len = seg_end - seg_start
		var t = 0.0 if seg_len <= 0 else (target_dist - seg_start) / seg_len
		result[i] = points[current_idx].lerp(points[current_idx + 1], t)
	
	return result

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		rune_completed.emit(false, _rune_data.get("id", "arco"))
		queue_free()
