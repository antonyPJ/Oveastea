extends Node2D

# Referências
@onready var player = get_tree().get_first_node_in_group('player')
var mob_scene = preload("res://mob.tscn")
var boss_scene = preload("res://boss_mob.tscn")

# Sistema de Boss
var boss_wave_interval = 3  # Boss aparece a cada 3 waves (waves 3, 6, 9, etc)

# Sistema de Heat Zone - incentiva movimento
var player_last_position = Vector2.ZERO
var player_stationary_time = 0.0
var player_heat_penalty = 0  # Reduz distância segura de spawn
var heat_zone_radius = 200  # Raio para considerar "parado"

# Sistema de Waves
var current_wave = 0
var enemies_in_wave = 8  # Aumentado de 5 para 8
var enemies_spawned = 0
var enemies_alive = 0
var wave_active = false
var max_enemies_on_screen = 15  # Limite de inimigos simultâneos (aumentado de 10 para 15)
var max_enemies_per_wave = 30  # CAP máximo de inimigos por wave

# Dificuldade progressiva
var base_enemy_speed = 350  # Velocidade base dos inimigos
var speed_increase_per_wave = 35  # Aumenta 35 de velocidade por wave (aumentado)
var enemies_increase_per_wave = 3  # Aumenta 3 inimigos por wave (aumentado)

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

	# Sistema de Heat Zone - rastreia movimento do player
	update_player_heat(delta)

	# Aguarda delay entre waves
	if waiting_for_next_wave:
		wave_delay_timer -= delta
		if wave_delay_timer <= 0:
			start_new_wave()
		return
	
	# Spawna inimigos durante a wave - RESPEITANDO LIMITE NA TELA
	if wave_active and enemies_spawned < enemies_in_wave:
		# Só spawna se não atingiu o limite de inimigos na tela (dinâmico por wave)
		if enemies_alive < get_max_enemies_on_screen():
			# Heat zone ACELERA o spawn (quanto mais parado, mais rápido spawna)
			var heat_multiplier = 1.0 + (player_heat_penalty / 300.0) * 0.8  # Max +80% velocidade
			spawn_timer -= delta * heat_multiplier
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

	# Aplica CAP de 30 inimigos por wave
	enemies_in_wave = min(enemies_in_wave, max_enemies_per_wave)

	enemies_spawned = 0
	enemies_alive = 0
	wave_active = true
	waiting_for_next_wave = false

	# Sistema de spawn interval balanceado com soft cap
	spawn_interval = calculate_spawn_interval()
	spawn_timer = 0.3  # Primeiro spawn rápido

	update_wave_display()

func calculate_spawn_interval() -> float:
	# Sistema de spawn interval balanceado
	# Waves 1-10: Redução normal (0.03s por wave)
	# Waves 11+: Redução muito mais lenta (soft cap)

	var interval: float

	if current_wave <= 10:
		# Waves iniciais: redução linear de 0.03s por wave
		interval = base_spawn_interval - (current_wave - 1) * 0.03
	else:
		# Waves tardias (11+): soft cap - redução muito mais lenta
		var base_at_wave_10 = base_spawn_interval - 9 * 0.03  # 1.0 - 0.27 = 0.73
		var waves_after_10 = current_wave - 10
		# Redução de apenas 0.01s por wave após wave 10
		interval = base_at_wave_10 - (waves_after_10 * 0.01)

	# Mínimo absoluto de 0.5s (antes era 0.2s)
	return max(0.5, interval)

func get_max_enemies_on_screen() -> int:
	# Aumenta gradualmente o limite de inimigos na tela em waves tardias
	# Para compensar spawn_interval mais lento e manter o desafio
	if current_wave <= 10:
		return 15
	elif current_wave <= 20:
		return 18  # +3 inimigos simultâneos
	else:
		return 20  # +5 inimigos simultâneos para waves muito tardias

func end_wave():
	wave_active = false
	waiting_for_next_wave = true
	wave_delay_timer = wave_delay

func spawn_enemy():
	if not player:
		return

	var spawn_pos = get_spawn_position()

	# Incrementa ANTES do await para controle correto de spawn
	enemies_spawned += 1

	# NOVO: Cria indicador visual antes do spawn
	create_spawn_indicator(spawn_pos)

	# Agenda o spawn real após delay
	await get_tree().create_timer(0.5).timeout

	# Verifica se a wave ainda está ativa
	if not wave_active:
		return

	var enemy

	# Verifica se deve spawnar um boss (a cada 3 waves, spawna 1 boss)
	if should_spawn_boss():
		enemy = boss_scene.instantiate()
	else:
		enemy = mob_scene.instantiate()

	# Define posição
	enemy.global_position = spawn_pos

	# Adiciona à cena PRIMEIRO
	get_tree().current_scene.add_child(enemy)

	# Ajusta velocidade baseado na wave
	if enemy.has_method("is_boss"):
		# Boss é mais lento (70% da velocidade normal)
		enemy.speed = get_current_enemy_speed() * 0.7
	else:
		enemy.speed = get_current_enemy_speed()

	# Conecta à função de tracking quando o inimigo morrer
	enemy.tree_exited.connect(_on_enemy_died)

	enemies_alive += 1

func create_spawn_indicator(pos: Vector2):
	# Cria indicador visual de spawn
	var indicator = Node2D.new()
	indicator.global_position = pos

	# Anexa o script
	var script = load("res://spawn_indicator.gd")
	indicator.set_script(script)

	get_tree().current_scene.add_child(indicator)

func should_spawn_boss() -> bool:
	# Boss spawna nas waves 3, 6, 9, etc
	if current_wave % boss_wave_interval == 0:
		# 20% de chance de spawnar boss nessa wave
		return randf() < 0.2
	return false

func get_spawn_position() -> Vector2:
	# Limites do mapa
	var map_bounds = Rect2(-1400, -1400, 2800, 2800)

	var camera = get_viewport().get_camera_2d()
	if not camera:
		# Fallback sem câmera
		return get_fallback_spawn_position(map_bounds)

	# Pega informações da viewport
	var viewport_size = get_viewport().get_visible_rect().size
	var cam_pos = camera.global_position
	var cam_zoom = camera.zoom
	var screen_size = viewport_size / cam_zoom

	# Calcula bordas visíveis da tela
	var screen_left = cam_pos.x - screen_size.x / 2
	var screen_right = cam_pos.x + screen_size.x / 2
	var screen_top = cam_pos.y - screen_size.y / 2
	var screen_bottom = cam_pos.y + screen_size.y / 2

	# Offset para spawnar FORA da tela
	var offscreen_offset = 350

	# Determina quais lados têm ESPAÇO no mapa para spawn offscreen
	var valid_sides = []

	# CIMA: verifica se há espaço acima da tela
	if screen_top - offscreen_offset > map_bounds.position.y + 100:
		valid_sides.append(0)  # Topo

	# DIREITA: verifica se há espaço à direita da tela
	if screen_right + offscreen_offset < map_bounds.end.x - 100:
		valid_sides.append(1)  # Direita

	# BAIXO: verifica se há espaço abaixo da tela
	if screen_bottom + offscreen_offset < map_bounds.end.y - 100:
		valid_sides.append(2)  # Baixo

	# ESQUERDA: verifica se há espaço à esquerda da tela
	if screen_left - offscreen_offset > map_bounds.position.x + 100:
		valid_sides.append(3)  # Esquerda

	# Se não há lados válidos (player muito na borda), usa todos
	if valid_sides.size() == 0:
		valid_sides = [0, 1, 2, 3]

	# Pega direção que o player está mirando
	var player_aim_direction = get_player_aim_direction()

	var max_attempts = 30

	for attempt in range(max_attempts):
		# Escolhe um lado válido aleatório
		var side = valid_sides[randi() % valid_sides.size()]
		var spawn_pos = Vector2.ZERO

		# Spawna no lado escolhido (SEMPRE offscreen)
		match side:
			0:  # CIMA
				spawn_pos.x = randf_range(screen_left, screen_right)
				spawn_pos.y = screen_top - offscreen_offset
			1:  # DIREITA
				spawn_pos.x = screen_right + offscreen_offset
				spawn_pos.y = randf_range(screen_top, screen_bottom)
			2:  # BAIXO
				spawn_pos.x = randf_range(screen_left, screen_right)
				spawn_pos.y = screen_bottom + offscreen_offset
			3:  # ESQUERDA
				spawn_pos.x = screen_left - offscreen_offset
				spawn_pos.y = randf_range(screen_top, screen_bottom)

		# Clamp para garantir dentro do mapa
		spawn_pos.x = clamp(spawn_pos.x, map_bounds.position.x + 100, map_bounds.end.x - 100)
		spawn_pos.y = clamp(spawn_pos.y, map_bounds.position.y + 100, map_bounds.end.y - 100)

		# Verifica se não está na direção que o player está mirando
		var to_spawn = (spawn_pos - player.global_position).normalized()
		var dot_product = to_spawn.dot(player_aim_direction)
		var is_in_front = dot_product > 0.3  # Cone frontal

		if not is_in_front:
			return spawn_pos

	# Fallback: spawna em qualquer lado válido (ignorando direção da mira)
	var side = valid_sides[randi() % valid_sides.size()]
	var fallback_pos = Vector2.ZERO

	match side:
		0:  # CIMA
			fallback_pos.x = randf_range(screen_left, screen_right)
			fallback_pos.y = screen_top - offscreen_offset
		1:  # DIREITA
			fallback_pos.x = screen_right + offscreen_offset
			fallback_pos.y = randf_range(screen_top, screen_bottom)
		2:  # BAIXO
			fallback_pos.x = randf_range(screen_left, screen_right)
			fallback_pos.y = screen_bottom + offscreen_offset
		3:  # ESQUERDA
			fallback_pos.x = screen_left - offscreen_offset
			fallback_pos.y = randf_range(screen_top, screen_bottom)

	fallback_pos.x = clamp(fallback_pos.x, map_bounds.position.x + 100, map_bounds.end.x - 100)
	fallback_pos.y = clamp(fallback_pos.y, map_bounds.position.y + 100, map_bounds.end.y - 100)
	return fallback_pos

func get_player_aim_direction() -> Vector2:
	# Pega direção que o player está mirando
	if not player:
		return Vector2.RIGHT

	var mouse_pos = get_viewport().get_mouse_position()
	var camera = get_viewport().get_camera_2d()
	if not camera:
		return Vector2.RIGHT

	var world_mouse_pos = camera.global_position + (mouse_pos - get_viewport().get_visible_rect().size / 2) / camera.zoom
	return (world_mouse_pos - player.global_position).normalized()

func get_fallback_spawn_position(map_bounds: Rect2) -> Vector2:
	# Fallback quando não há câmera
	var angle = randf() * TAU
	var distance = 700
	var pos = player.global_position + Vector2(cos(angle), sin(angle)) * distance
	pos.x = clamp(pos.x, map_bounds.position.x + 100, map_bounds.end.x - 100)
	pos.y = clamp(pos.y, map_bounds.position.y + 100, map_bounds.end.y - 100)
	return pos


func update_player_heat(delta: float):
	# Rastreia se o player está se movendo ou ficando parado
	var current_pos = player.global_position
	var distance_moved = current_pos.distance_to(player_last_position)

	# Se o player se moveu significativamente
	if distance_moved > heat_zone_radius:
		# Reseta o timer e penalidade
		player_stationary_time = 0.0
		player_heat_penalty = max(0, player_heat_penalty - 50)  # Reduz penalidade gradualmente
		player_last_position = current_pos
	else:
		# Player está parado na mesma área
		player_stationary_time += delta

		# Aumenta penalidade progressivamente (max 300 = spawns a 400px)
		if player_stationary_time > 3.0:  # Após 3 segundos parado
			player_heat_penalty = min(300, player_heat_penalty + delta * 30)  # +30 por segundo


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
