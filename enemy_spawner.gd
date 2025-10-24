extends Node2D

# Referências
@onready var player = get_tree().get_first_node_in_group('player')
var mob_scene = preload("res://mob.tscn")

# Sistema de Waves
var current_wave = 0
var enemies_in_wave = 8  # Aumentado de 5 para 8
var enemies_spawned = 0
var enemies_alive = 0
var wave_active = false
var max_enemies_on_screen = 10  # Limite de inimigos simultâneos

# Dificuldade progressiva
var base_enemy_speed = 350  # Velocidade base dos inimigos 
var speed_increase_per_wave = 30  # Aumenta 30 de velocidade por wave
var enemies_increase_per_wave = 2  # Aumenta 2 inimigos por wave

# Spawn settings - INTERVALO REDUZIDO
var base_spawn_interval = 1.0  # Reduzido de 1.5 para 1.0
var spawn_interval = 1.0
var spawn_timer = 0.0

# Wave delay
var wave_delay = 3.0
var wave_delay_timer = 0.0
var waiting_for_next_wave = false

# Spawn settings - distâncias
var spawn_distance_min = 600
var spawn_distance_max = 800

# UI
var wave_label

func _ready():
	# Procura o label de wave na UI
	wave_label = get_tree().get_first_node_in_group('wave_label')
	
	# Aguarda 1 frame antes de iniciar para garantir que tudo está carregado
	await get_tree().process_frame
	
	# Inicia primeira wave após delay
	waiting_for_next_wave = true
	wave_delay_timer = wave_delay

func _process(delta):
	if not player:
		player = get_tree().get_first_node_in_group('player')
		return
	
	# Aguarda delay entre waves
	if waiting_for_next_wave:
		wave_delay_timer -= delta
		if wave_delay_timer <= 0:
			start_new_wave()
		return
	
	# Spawna inimigos durante a wave - RESPEITANDO LIMITE NA TELA
	if wave_active and enemies_spawned < enemies_in_wave:
		# Só spawna se não atingiu o limite de inimigos na tela
		if enemies_alive < max_enemies_on_screen:
			spawn_timer -= delta
			if spawn_timer <= 0:
				spawn_enemy()
				spawn_timer = spawn_interval
	
	# Verifica se a wave terminou
	if wave_active and enemies_spawned >= enemies_in_wave:
		if enemies_alive <= 0:
			end_wave()

func start_new_wave():
	current_wave += 1
	enemies_in_wave = 8 + (current_wave - 1) * enemies_increase_per_wave
	enemies_spawned = 0
	enemies_alive = 0
	wave_active = true
	waiting_for_next_wave = false
	
	# Reduz progressivamente o intervalo de spawn (mínimo 0.3s)
	spawn_interval = max(0.3, base_spawn_interval - (current_wave - 1) * 0.05)
	spawn_timer = 0.3  # Primeiro spawn rápido
	
	update_wave_display()

func end_wave():
	wave_active = false
	waiting_for_next_wave = true
	wave_delay_timer = wave_delay

func spawn_enemy():
	if not player:
		return
	
	var spawn_pos = get_spawn_position()
	var enemy = mob_scene.instantiate()
	
	# Define posição
	enemy.global_position = spawn_pos
	
	# Adiciona à cena PRIMEIRO
	get_tree().current_scene.add_child(enemy)
	
	# Ajusta velocidade baseado na wave
	enemy.speed = get_current_enemy_speed()
	
	# Conecta à função de tracking quando o inimigo morrer
	enemy.tree_exited.connect(_on_enemy_died)
	
	enemies_spawned += 1
	enemies_alive += 1

func get_spawn_position() -> Vector2:
	# Limites do mapa (ajuste conforme seu mapa)
	var map_bounds = Rect2(-1400, -1400, 2800, 2800)  # Área jogável do mapa
	
	# Distância mínima segura do player
	var safe_distance_from_player = 700  # Distância mínima do player
	var max_attempts = 20  # Tentativas máximas para encontrar uma posição válida
	
	# Pega a câmera para spawnar fora da visão
	var camera = get_viewport().get_camera_2d()
	
	for attempt in range(max_attempts):
		var spawn_pos = Vector2.ZERO
		
		if not camera:
			# Fallback: spawna ao redor do player em círculo
			var angle = randf() * TAU
			var distance = randf_range(safe_distance_from_player, safe_distance_from_player + 300)
			spawn_pos = player.global_position + Vector2(cos(angle), sin(angle)) * distance
		else:
			# Pega os limites da tela
			var viewport_size = get_viewport().get_visible_rect().size
			var cam_pos = camera.global_position
			var cam_zoom = camera.zoom
			
			# Calcula o tamanho real da tela no mundo
			var screen_size = viewport_size / cam_zoom
			
			# Escolhe um lado aleatório (0=cima, 1=direita, 2=baixo, 3=esquerda)
			var side = randi() % 4
			
			# Offset maior para spawnar bem fora da tela
			var offset = randf_range(300, 500)
			
			match side:
				0:  # Cima
					spawn_pos.x = cam_pos.x + randf_range(-screen_size.x/2, screen_size.x/2)
					spawn_pos.y = cam_pos.y - screen_size.y/2 - offset
				1:  # Direita
					spawn_pos.x = cam_pos.x + screen_size.x/2 + offset
					spawn_pos.y = cam_pos.y + randf_range(-screen_size.y/2, screen_size.y/2)
				2:  # Baixo
					spawn_pos.x = cam_pos.x + randf_range(-screen_size.x/2, screen_size.x/2)
					spawn_pos.y = cam_pos.y + screen_size.y/2 + offset
				3:  # Esquerda
					spawn_pos.x = cam_pos.x - screen_size.x/2 - offset
					spawn_pos.y = cam_pos.y + randf_range(-screen_size.y/2, screen_size.y/2)
		
		# Garante que o spawn está DENTRO dos limites do mapa
		spawn_pos.x = clamp(spawn_pos.x, map_bounds.position.x + 100, map_bounds.end.x - 100)
		spawn_pos.y = clamp(spawn_pos.y, map_bounds.position.y + 100, map_bounds.end.y - 100)
		
		# CRÍTICO: Verifica se está longe o suficiente do player
		var distance_to_player = spawn_pos.distance_to(player.global_position)
		if distance_to_player >= safe_distance_from_player:
			return spawn_pos
	
	# Se não encontrou posição válida após todas as tentativas, usa fallback seguro
	var angle = randf() * TAU
	var emergency_pos = player.global_position + Vector2(cos(angle), sin(angle)) * safe_distance_from_player
	emergency_pos.x = clamp(emergency_pos.x, map_bounds.position.x + 100, map_bounds.end.x - 100)
	emergency_pos.y = clamp(emergency_pos.y, map_bounds.position.y + 100, map_bounds.end.y - 100)
	return emergency_pos

func get_current_enemy_speed() -> float:
	return base_enemy_speed + (current_wave - 1) * speed_increase_per_wave

func _on_enemy_died():
	enemies_alive -= 1

func update_wave_display():
	if wave_label:
		wave_label.text = "Wave: " + str(current_wave)

# Função para resetar o spawner (útil para reiniciar o jogo)
func reset_spawner():
	current_wave = 0
	enemies_in_wave = 8
	enemies_spawned = 0
	enemies_alive = 0
	wave_active = false
	waiting_for_next_wave = true
	wave_delay_timer = wave_delay
	spawn_interval = base_spawn_interval
