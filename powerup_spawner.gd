extends Node2D

# Referência ao player
@onready var player = get_tree().get_first_node_in_group('player')

# Configurações de spawn
var powerup_scene = preload("res://speed_powerup.tscn")
var spawn_interval_min = 20.0  # Mínimo 20 segundos
var spawn_interval_max = 30.0  # Máximo 30 segundos
var spawn_timer = 0.0

# Limites do mapa (mesmos do enemy_spawner)
var map_bounds = Rect2(-1400, -1400, 2800, 2800)

# Distância do player
var min_distance_from_player = 400  # Spawna longe do player
var max_distance_from_player = 800

func _ready():
	# Define o primeiro spawn
	randomize()
	spawn_timer = randf_range(spawn_interval_min, spawn_interval_max)

func _process(delta):
	if not player:
		player = get_tree().get_first_node_in_group('player')
		return

	spawn_timer -= delta
	if spawn_timer <= 0:
		spawn_powerup()
		# Agenda próximo spawn
		spawn_timer = randf_range(spawn_interval_min, spawn_interval_max)

func spawn_powerup():
	if not player:
		return

	# Agora permite múltiplos powerups na cena (removido o limite de 1)
	var spawn_pos = get_random_spawn_position()
	var powerup = powerup_scene.instantiate()
	powerup.global_position = spawn_pos

	get_tree().current_scene.add_child(powerup)

func get_random_spawn_position() -> Vector2:
	var max_attempts = 20

	for attempt in range(max_attempts):
		# Gera posição aleatória dentro dos limites do mapa
		var random_x = randf_range(map_bounds.position.x + 200, map_bounds.end.x - 200)
		var random_y = randf_range(map_bounds.position.y + 200, map_bounds.end.y - 200)
		var spawn_pos = Vector2(random_x, random_y)

		# MELHORADO: Powerup sempre spawna LONGE do player (força movimento)
		var distance_to_player = spawn_pos.distance_to(player.global_position)
		# Aumenta distância mínima para garantir que player precise se mover
		if distance_to_player >= 600 and distance_to_player <= max_distance_from_player:
			return spawn_pos

	# Fallback: spawna em círculo LONGE do player
	var angle = randf() * TAU
	var distance = randf_range(600, max_distance_from_player)  # Mínimo 600
	var fallback_pos = player.global_position + Vector2(cos(angle), sin(angle)) * distance

	# Garante que está dentro dos limites
	fallback_pos.x = clamp(fallback_pos.x, map_bounds.position.x + 200, map_bounds.end.x - 200)
	fallback_pos.y = clamp(fallback_pos.y, map_bounds.position.y + 200, map_bounds.end.y - 200)

	return fallback_pos
