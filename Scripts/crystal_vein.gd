# crystal_vein.gd
# Una veta de cristal cliqueable en el bosque

class_name CrystalVein
extends Area2D

signal vein_harvested(success: bool, tier: String, amount: int)

@export var vein_tier: String = "ceniza"        # ceniza / llama / cielo
@export var energy_cost: int = 1
@export var base_yield: int = 1

var _hovered: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var glow: Sprite2D = $Glow
@onready var label: Label = $Label

func _ready() -> void:
	mouse_default_cursor_shape = CURSOR_POINTING_HAND
	
	# Configurar stats según tier
	match vein_tier:
		"ceniza":
			energy_cost = 1
			base_yield = 1
			if sprite:
				sprite.modulate = Color(0.6, 0.6, 0.7)
		"llama":
			energy_cost = 2
			base_yield = 2
			if sprite:
				sprite.modulate = Color(1.0, 0.6, 0.2)
		"cielo":
			energy_cost = 3
			base_yield = 3
			if sprite:
				sprite.modulate = Color(0.3, 0.5, 1.0)
	
	# Mostrar label de costo
	_label_update()
	
	# Conectar señales
	input_event.connect(_on_click)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	# Glow inicial apagado
	if glow:
		glow.hide()
	if label:
		label.hide()

func _label_update() -> void:
	if label:
		label.text = "⚡%d" % energy_cost

func _on_click(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_try_harvest()

func _try_harvest() -> void:
	if not GameState.has_energy(energy_cost):
		Feedback.show("Sin energía")
		return
	
	# Iniciar minijuego de runa
	var rune_id = _get_rune_for_tier()
	
	var minigame_scene = load("res://Scenes/rune_minigame.tscn")
	if minigame_scene:
		var minigame = minigame_scene.instantiate()
		# Añadir al árbol completo para que CanvasLayer funcione
		get_tree().current_scene.add_child(minigame)
		minigame.setup(rune_id)
		minigame.rune_completed.connect(_on_minigame_result)

func _on_minigame_result(success: bool, _rune_id: String) -> void:
	if success:
		GameState.spend_energy(energy_cost)
		var bonus = 0
		# De momento yield fijo, luego combo de precisión
		var amount = base_yield + bonus
		GameState.add_crystal(vein_tier, amount)
		vein_harvested.emit(true, vein_tier, amount)
		
		# Feedback de cosecha
		Feedback.show("+%d %s" % [amount, vein_tier.capitalize()])
		
		# Desaparecer veta (se regenerará al reiniciar día)
		queue_free()
	else:
		vein_harvested.emit(false, vein_tier, 0)

func _get_rune_for_tier() -> String:
	match vein_tier:
		"ceniza":
			return "arco"
		"llama":
			return "zigzag"
		"cielo":
			return "estrella"
		_:
			return "arco"

func _on_mouse_entered() -> void:
	_hovered = true
	if glow:
		glow.show()
	if label:
		label.show()

func _on_mouse_exited() -> void:
	_hovered = false
	if glow:
		glow.hide()
	if label:
		label.hide()
