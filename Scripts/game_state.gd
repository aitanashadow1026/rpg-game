# game_state.gd
# Estado global del juego: energía, inventario y progreso
# Autoload — accesible desde cualquier script como GameState

extends Node

# Recursos del jugador
var energy: int = 10          # Energía para buscar cristales
var max_energy: int = 10

var crystals: Dictionary = {   # cristales por tier
	"ceniza": 0,
	"llama": 0,
	"cielo": 0
}

# Progreso de la historia
var story_flags: Dictionary = {}  # ej: "first_crystal_found": true
var learned_runes: Array = []     # runas que Lira ha aprendido
var current_chapter: int = 1

# Runas aprendidas por defecto
func _ready() -> void:
	learned_runes.append("arco")
	reset_day()

# Reinicio diario (al volver al bosque)
func reset_day() -> void:
	energy = max_energy

# Gasta energía, devuelve true si pudo
func spend_energy(amount: int) -> bool:
	if energy >= amount:
		energy -= amount
		return true
	return false

# Añade cristales al inventario
func add_crystal(tier: String, amount: int = 1) -> void:
	if crystals.has(tier):
		crystals[tier] += amount
	else:
		crystals[tier] = amount

# Consulta si tiene suficiente energía
func has_energy(amount: int) -> bool:
	return energy >= amount

# Marca un flag de historia
func set_flag(flag: String, value = true) -> void:
	story_flags[flag] = value

func has_flag(flag: String) -> bool:
	return story_flags.get(flag, false)

# Aprender una runa nueva
func learn_rune(rune_id: String) -> void:
	if not learned_runes.has(rune_id):
		learned_runes.append(rune_id)

func knows_rune(rune_id: String) -> bool:
	return learned_runes.has(rune_id)

# Debug
func _to_string() -> String:
	return "GameState(energy=%d/%d, crystals=%s, flags=%s)" % [
		energy, max_energy, 
		JSON.new().stringify(crystals),
		JSON.new().stringify(story_flags)
	]
