# rune_minigame.gd
# Minijuego de trazado de runas: aparece un patrón que el jugador debe dibujar

class_name RuneMinigame
extends CanvasLayer

signal rune_completed(success: bool, rune_id: String)

var _rune_data: Dictionary
var _drawing: bool = false
var _drawn_points: PackedVector2Array = []
var _ghost_points: PackedVector2Array = []

# Referencias a nodos (se resuelven por nombre)
@onready var background: ColorRect = $Background
@onready var center_panel: Control = $CenterPanel
@onready var rune_name_label: Label = $CenterPanel/RuneName
@onready var drawing_area: Control = $CenterPanel/DrawingArea
@onready var ghost_line: Line2D = $CenterPanel/DrawingArea/GhostLine
@onready var draw_line: Line2D = $CenterPanel/DrawingArea/DrawLine
@onready var instruction_label: Label = $CenterPanel/Instruction
@onready var feedback_label: Label = $CenterPanel/Feedback

func setup(rune_id: String) -> void:
	_rune_data = RuneData.get_rune(rune_id)
	
	# Configurar UI
	rune_name_label.text = _rune_data["name"]
	instruction_label.text = "Traza la runa con el ratón"
	feedback_label.text = ""
	
	# Esperar un frame para que el drawing_area tenga tamaño real
	await get_tree().process_frame
	_refresh_ghost()

func _refresh_ghost() -> void:
	var area_size = drawing_area.size
	if area_size.x <= 0 or area_size.y <= 0:
		return
	
	_ghost_points.clear()
	for p in _rune_data["points"]:
		_ghost_points.append(Vector2(p.x * area_size.x, p.y * area_size.y))
	
	ghost_line.points = _ghost_points
	draw_line.clear_points()

func _ready() -> void:
	# Conectar eventos de dibujo
	drawing_area.gui_input.connect(_on_drawing_input)

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
	draw_line.clear_points()
	feedback_label.text = ""

func _continue_draw(pos: Vector2) -> void:
	_drawn_points.append(pos)
	draw_line.points = _drawn_points

func _end_draw(_pos: Vector2) -> void:
	_drawing = false
	if _drawn_points.size() < 5:
		feedback_label.text = "Demasiado corto. Inténtalo de nuevo."
		return
	
	_check_accuracy()

func _check_accuracy() -> void:
	if _ghost_points.size() < 2 or _drawn_points.size() < 2:
		return
	
	# Muestrear ambas curvas al mismo número de puntos
	var sample_count = 30
	var sampled_ghost = _sample_curve(_ghost_points, sample_count)
	var sampled_drawn = _sample_curve(_drawn_points, sample_count)
	
	# Calcular error medio
	var total_error := 0.0
	for i in sample_count:
		total_error += sampled_ghost[i].distance_to(sampled_drawn[i])
	var avg_error := total_error / sample_count
	
	var tolerance = _rune_data.get("tolerance", 30.0)
	
	if avg_error <= tolerance:
		feedback_label.text = "✓ ¡Runa trazada con éxito!"
		feedback_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.4))
		rune_completed.emit(true, _rune_data.get("id", "arco"))
		# Cerrar tras breve pausa
		await get_tree().create_timer(0.8).timeout
		queue_free()
	else:
		var pct = maxf(0, 100.0 - (avg_error - tolerance) / tolerance * 50)
		feedback_label.text = "✗ Precisión: %d%%  —  Inténtalo de nuevo" % pct
		feedback_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
		_drawn_points.clear()
		draw_line.clear_points()
		rune_completed.emit(false, _rune_data.get("id", "arco"))

# Remuestrea una curva a N puntos equidistantes
static func _sample_curve(points: PackedVector2Array, n: int) -> PackedVector2Array:
	if points.size() <= 1:
		return points
	
	# Calcular longitud total
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

# Permitir cerrar con Escape
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		rune_completed.emit(false, _rune_data.get("id", "arco"))
		queue_free()
