# feedback.gd
# Sistema simple de mensajes en pantalla
# Autoload — usar Feedback.show("texto")

extends CanvasLayer

@onready var label: Label = $Label

func _ready() -> void:
	label.hide()

func show(text: String, duration: float = 1.5) -> void:
	label.text = text
	label.modulate = Color(1, 1, 1, 1)
	label.show()
	
	# Animación de fundido
	var tween = create_tween()
	tween.tween_property(label, "modulate:a", 1.0, 0.1)
	tween.tween_interval(duration)
	tween.tween_property(label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(label.hide)
