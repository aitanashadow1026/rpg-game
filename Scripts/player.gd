extends CharacterBody2D

# Velocidad de movimiento (píxeles/segundo)
@export var speed: float = 60.0

@onready var sprite: Sprite2D = $Sprite2D

func _physics_process(_delta: float) -> void:
	# Input de movimiento
	var input_dir := Vector2.ZERO
	input_dir.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_dir.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	
	# Normalizar para que diagonal no sea más rápido
	if input_dir.length() > 0:
		input_dir = input_dir.normalized()
	
	# Aplicar velocidad
	velocity = input_dir * speed
	move_and_slide()
	
	# Orientar sprite según dirección
	_update_sprite_direction(input_dir)

func _update_sprite_direction(input_dir: Vector2) -> void:
	if input_dir.length() > 0:
		if input_dir.x < 0:
			sprite.flip_h = true
		elif input_dir.x > 0:
			sprite.flip_h = false
