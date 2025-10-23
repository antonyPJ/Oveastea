extends CharacterBody2D

@onready var player = get_tree().get_first_node_in_group('player')
var speed = 350
var dead = false



func _physics_process(delta):
	if dead:
		return

	if player.global_position.x < global_position.x:
		$AnimatedSprite2D.flip_h = true 
	elif player.global_position.x > global_position.x:
		$AnimatedSprite2D.flip_h = false
	velocity = global_position.direction_to(player.global_position) * speed
	move_and_slide()
	
func kill(bullet_direction: Vector2 = Vector2.ZERO):
	if dead:
		return  # Evita múltiplas execuções
		
	$AnimatedSprite2D.hide()
	$SEnemyDead.show()
	$deathSound.play()
	set_collision_layer_value(3, false)
	set_collision_mask_value(3, false)
	dead = true
	
	# Gera sangue quando o inimigo morre, passando a direção do projétil
	spawn_blood(bullet_direction)
	
	# Coloca sprite de sangue no chão
	spawn_blood_decal()
	
	# Adiciona pontos ao score
	var world = get_tree().get_first_node_in_group('world')
	if world and world.has_method('add_score'):
		world.add_score()
	
	# CRÍTICO: Remove o inimigo após um pequeno delay (para o som tocar)
	await get_tree().create_timer(0.5).timeout
	queue_free()

func spawn_blood(bullet_direction: Vector2):
	# Carrega a cena da partícula de sangue
	var blood_scene = preload("res://blood_particle.tscn")
	var blood_particles_count = 30  # Reduzido para melhor performance
	
	# Cria partículas de sangue na posição do inimigo
	for i in range(blood_particles_count):
		var blood_instance = blood_scene.instantiate()
		blood_instance.global_position = global_position
		
		# Passa a direção do projétil para a partícula
		if bullet_direction != Vector2.ZERO:
			blood_instance.bullet_direction = bullet_direction
		
		get_tree().current_scene.add_child(blood_instance)

func spawn_blood_decal():
	# Cria um sprite de sangue no chão
	var blood_decal = Sprite2D.new()
	
	# Array com os caminhos das diferentes texturas de sangue
	var blood_textures = [
		"res://artwork/TDS/blood_decal_0.png",
		"res://artwork/TDS/blood_decal_1.png",
		"res://artwork/TDS/blood_decal_2.png",
		"res://artwork/TDS/blood_decal_3.png",
		"res://artwork/TDS/blood_decal_4.png",
		"res://artwork/TDS/blood_decal_5.png",
		"res://artwork/TDS/blood_decal_6.png",
		"res://artwork/TDS/blood_decal_7.png",
		"res://artwork/TDS/blood_decal_8.png",
		"res://artwork/TDS/blood_decal_9.png",
		"res://artwork/TDS/blood_decal_10.png",
		"res://artwork/TDS/blood_decal_11.png",
		"res://artwork/TDS/blood_decal_12.png",
		"res://artwork/TDS/blood_decal_13.png",
		"res://artwork/TDS/blood_decal_14.png",
		"res://artwork/TDS/blood_decal_15.png",
		"res://artwork/TDS/blood_decal_16.png",
		"res://artwork/TDS/blood_decal_17.png",
		"res://artwork/TDS/blood_decal_18.png",
		"res://artwork/TDS/blood_decal_19.png",
		"res://artwork/TDS/blood_decal_20.png",
		"res://artwork/TDS/blood_decal_21.png",
		"res://artwork/TDS/blood_decal_29.png"
	]
	
	# Escolhe uma textura aleatória
	var random_index = randi() % blood_textures.size()
	var texture_path = blood_textures[random_index]
	
	# Tenta carregar a textura
	if ResourceLoader.exists(texture_path):
		blood_decal.texture = load(texture_path)
	else:
		# Fallback: usa a textura de sangue existente
		blood_decal.texture = load("res://artwork/TDS/blood.png")
	
	# Configura o sprite
	blood_decal.global_position = global_position
	blood_decal.z_index = -1  # Coloca abaixo de tudo
	
	# Rotação aleatória para variedade
	blood_decal.rotation = randf_range(0, TAU)
	
	# Escala aleatória para variedade (aumentada)
	var random_scale = randf_range(3.0, 5.0)
	blood_decal.scale = Vector2(random_scale, random_scale)
	
	# Adiciona à cena
	get_tree().current_scene.add_child(blood_decal)


func _on_attack_zone_body_entered(body):
	if body.is_in_group('player') and not dead:
		# Busca o GameOver canvas layer e chama a função
		var game_over_screen = get_tree().get_first_node_in_group('game_over')
		if game_over_screen and game_over_screen.has_method('game_over'):
			game_over_screen.game_over()
