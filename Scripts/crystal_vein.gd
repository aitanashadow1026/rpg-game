extends Area2D

signal vein_harvested(success: bool, tier: String, amount: int)

@export var vein_tier: String = "ceniza"
@export var energy_cost: int = 1
@export var base_yield: int = 1

@onready var sprite: Sprite2D = $Sprite2D
@onready var glow: Sprite2D = $Glow
@onready var label: Label = $Label

func _ready() -> void:
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
	
	_show_label()
	
	input_event.connect(_on_input_event)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	if glow:
		glow.hide()
	if label:
		label.hide()

func _show_label() -> void:
	if label:
		label.text = "⚡" + str(energy_cost)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_try_harvest()

func _try_harvest() -> void:
	if not GameState.has_energy(energy_cost):
		if has_node("/root/Feedback"):
			Feedback.message("Sin energía")
		return
	
	var rune_id = _get_rune_for_tier()
	var minigame_scene = load("res://Scenes/rune_minigame.tscn")
	
	if minigame_scene:
		var minigame = minigame_scene.instantiate()
		get_tree().current_scene.add_child(minigame)
		minigame.setup(rune_id)
		minigame.rune_completed.connect(_on_minigame_result)

func _on_minigame_result(success: bool, _rune_id: String) -> void:
	if success:
		GameState.spend_energy(energy_cost)
		var amount = base_yield
		GameState.add_crystal(vein_tier, amount)
		vein_harvested.emit(true, vein_tier, amount)
		
		if has_node("/root/Feedback"):
			Feedback.message("+" + str(amount) + " " + vein_tier)
		
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
	return "arco"

func _on_mouse_entered() -> void:
	if glow:
		glow.show()
	if label:
		label.show()

func _on_mouse_exited() -> void:
	if glow:
		glow.hide()
	if label:
		label.hide()
