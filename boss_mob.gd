extends CharacterBody2D

@onready var player = get_tree().get_first_node_in_group('player')
var speed = 300  # Boss é um pouco mais lento
var dead = false
var health = 3  # Boss aguenta 3 tiros

# Guarda a cor original do boss (configurada no editor)
var original_color: Color

func _ready():
	# Salva a cor original configurada no editor
	original_color = $AnimatedSprite2D.modulate

func is_boss() -> bool:
	return true

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

	# Boss aguenta múltiplos tiros
	health -= 1

	# Feedback visual de dano (pisca vermelho)
	flash_damage()

	# Se ainda tem vida, não morre
	if health > 0:
		# Spawn menos sangue para indicar que levou dano mas não morreu
		spawn_blood(bullet_direction, 10)  # Apenas 10 partículas
		return

	# Morte do boss (mesma lógica do mob normal, mas com mais sangue)
	$AnimatedSprite2D.hide()
	$SEnemyDead.show()
	$deathSound.play()
	set_collision_layer_value(3, false)
	set_collision_mask_value(3, false)
	dead = true

	# Boss gera MUITO mais sangue quando morre
	spawn_blood(bullet_direction, 60)  # Boss gera 60 partículas (2x mob normal)
	spawn_blood_decal()

	# Adiciona pontos ao score (boss vale mais pontos)
	var world = get_tree().get_first_node_in_group('world')
	if world and world.has_method('add_score'):
		world.add_score(300)  # Boss vale 300 pontos (3x normal)

	# Dropa powerup de velocidade
	spawn_powerup()

	# Remove o boss após delay
	await get_tree().create_timer(0.5).timeout
	queue_free()

func flash_damage():
	# Cria efeito visual de dano (pisca vermelho)
	var tween = create_tween()
	tween.tween_property($AnimatedSprite2D, "modulate", Color.RED, 0.1)
	tween.tween_property($AnimatedSprite2D, "modulate", original_color, 0.1)

func spawn_blood(bullet_direction: Vector2, particle_count: int = 30):
	# Carrega a cena da partícula de sangue
	var blood_scene = preload("res://blood_particle.tscn")

	# Cria partículas de sangue na posição do boss
	for i in range(particle_count):
		var blood_instance = blood_scene.instantiate()
		blood_instance.global_position = global_position

		# Passa a direção do projétil para a partícula
		if bullet_direction != Vector2.ZERO:
			blood_instance.bullet_direction = bullet_direction

		get_tree().current_scene.call_deferred("add_child", blood_instance)

func spawn_blood_decal():
	# Cria um sprite de sangue no chão (mesma lógica do mob.gd)
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

	if ResourceLoader.exists(texture_path):
		blood_decal.texture = load(texture_path) as Texture2D
	else:
		blood_decal.texture = preload("res://artwork/TDS/blood.png")

	# Configura o sprite
	blood_decal.global_position = global_position
	blood_decal.z_index = -1

	# Rotação aleatória
	blood_decal.rotation = randf_range(0, TAU)

	# Boss gera decal MAIOR
	var random_scale = randf_range(5.0, 7.0)  # Maior que mob normal
	blood_decal.scale = Vector2(random_scale, random_scale)

	blood_decal.add_to_group("blood_decals")

	# Timer para cleanup
	var cleanup_timer = Timer.new()
	cleanup_timer.wait_time = 60.0
	cleanup_timer.one_shot = true
	cleanup_timer.timeout.connect(func(): blood_decal.queue_free())
	blood_decal.add_child(cleanup_timer)
	cleanup_timer.tree_entered.connect(func(): cleanup_timer.start())

	get_tree().current_scene.call_deferred("add_child", blood_decal)


func spawn_powerup():
	# Dropa powerup de velocidade na posição do boss
	var powerup_scene = preload("res://speed_powerup.tscn")
	var powerup = powerup_scene.instantiate()
	powerup.global_position = global_position
	get_tree().current_scene.call_deferred("add_child", powerup)

func _on_attack_zone_body_entered(body):
	if body.is_in_group('player') and not dead:
		# Busca o GameOver canvas layer e chama a função
		var game_over_screen = get_tree().get_first_node_in_group('game_over')
		if game_over_screen and game_over_screen.has_method('game_over'):
			game_over_screen.game_over()
