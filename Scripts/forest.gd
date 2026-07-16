# forest.gd
# Localización del bosque — vetas de cristal cliqueables

extends Node2D

@onready var bg: Sprite2D = $Background
@onready var energy_label: Label = $UI/Panel/EnergyLabel
@onready var crystals_label: Label = $UI/Panel/CrystalsLabel

func _ready() -> void:
	_place_veins()
	_refresh_ui()
	GameState.reset_day()
	
	# Instrucciones
	var instr = $UI/Instructions
	if instr:
		instr.text = "Haz clic en una veta para extraer cristales"

func _place_veins() -> void:
	var vein_scene = load("res://Scenes/crystal_vein.tscn")
	
	# Posiciones de vetas (coordenadas del mundo)
	var vein_data = [
		{ "pos": Vector2(100, 80), "tier": "ceniza" },
		{ "pos": Vector2(200, 70), "tier": "ceniza" },
		{ "pos": Vector2(160, 110), "tier": "ceniza" },
		{ "pos": Vector2(260, 90), "tier": "llama" },
		{ "pos": Vector2(70, 120), "tier": "llama" },
	]
	
	for v in vein_data:
		var vein = vein_scene.instantiate()
		vein.position = v["pos"]
		vein.vein_tier = v["tier"]
		vein.vein_harvested.connect(_on_vein_harvested)
		add_child(vein)

func _on_vein_harvested(success: bool, _tier: String, _amount: int) -> void:
	if success:
		_refresh_ui()

func _refresh_ui() -> void:
	energy_label.text = "⚡ %d / %d" % [GameState.energy, GameState.max_energy]
	crystals_label.text = "💎  %d  |  🟠 %d  |  🔵 %d" % [
		GameState.crystals.get("ceniza", 0),
		GameState.crystals.get("llama", 0),
		GameState.crystals.get("cielo", 0)
	]
