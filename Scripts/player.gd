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
	
	# Abrir minijuego de runas con E (para pruebas)
	if Input.is_action_just_pressed("ui_accept"):
		_open_rune_minigame()

func _update_sprite_direction(input_dir: Vector2) -> void:
	if input_dir.length() > 0:
		if input_dir.x < 0:
			sprite.flip_h = true
		elif input_dir.x > 0:
			sprite.flip_h = false

func _open_rune_minigame() -> void:
	# Cargar y abrir el minijuego de runas
	var minigame_scene = load("res://Scenes/rune_minigame.tscn")
	if minigame_scene:
		var minigame = minigame_scene.instantiate()
		add_child(minigame)
		minigame.setup("arco")
		minigame.rune_completed.connect(_on_rune_result)

func _on_rune_result(success: bool, _rune_id: String) -> void:
	if success:
		print("✅ Runa completada con éxito!")
	else:
		print("❌ Runa fallida, se puede reintentar")
