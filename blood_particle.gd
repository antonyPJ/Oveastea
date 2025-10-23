extends Area2D

var is_colliding = false

# Direção do projétil que matou o inimigo
var bullet_direction: Vector2 = Vector2.ZERO

func _ready() -> void:
	# Adiciona ao grupo para controle
	add_to_group("blood_particles")
	
	# Configura velocidades baseadas na direção do projétil
	if bullet_direction != Vector2.ZERO:
		# Sangue vai na MESMA direção do projétil (atravessa o inimigo)
		
		# Velocidade base na mesma direção + variação aleatória
		vspeed = bullet_direction.y * randf_range(6.0, 10.0) + randf_range(-3.0, 3.0)
		hspeed = bullet_direction.x * randf_range(6.0, 10.0) + randf_range(-3.0, 3.0)
	else:
		# Fallback para direções aleatórias se não houver direção do projétil
		vspeed = randf_range(-8.0, 8.0)
		hspeed = randf_range(-8.0, 8.0)

# Movimento inicial aleatório do sangue
var vspeed : float = 0.0
var hspeed : float = 0.0
var blood_acc : float = randf_range(0.02, 0.05)

var do_wobble = false

# Contador para tempo no ar
var air_time = 0
var max_air_time = 120  # 2 segundos a 60 FPS no ar

func _physics_process(delta: float) -> void:
	HandleBloodMovement()
	
	if is_colliding:
		# Desenha sangue na superfície imediatamente
		var blood_surface = get_tree().get_first_node_in_group('blood_surface')
		if not blood_surface:
			# Se não encontrar pelo grupo, procura pelo nome
			blood_surface = get_tree().get_first_node_in_group('world').get_node('BloodSurface')
		
		if blood_surface:
			blood_surface.draw_blood(global_position)
		
		# Deleta a partícula imediatamente após colidir
		queue_free()
		return
		
	if position.y > 3000 or position.y < -3000 or position.x > 3000 or position.x < -3000:
		queue_free()

func HandleBloodMovement():
	if !is_colliding: # no ar
		do_wobble = false
		
		# Conta tempo no ar e deleta após 2 segundos
		air_time += 1
		if air_time > max_air_time:
			queue_free()
			return
		
		# Mantém movimento em todas as direções no ar
		vspeed = lerp(vspeed, randf_range(-2.0, 2.0), 0.01)
		hspeed = lerp(hspeed, randf_range(-2.0, 2.0), 0.01)
		visible = true
		
	else: # tocando plataforma
		# Partícula já foi deletada no início da função
		pass
		
	# Adicionamos oscilação aleatória constante no ar
	if do_wobble and !is_colliding:
		vspeed += randf_range(-0.2, 0.2)
		hspeed += randf_range(-0.2, 0.2)
		vspeed = clamp(vspeed, -4.0, 4.0)
		hspeed = clamp(hspeed, -4.0, 4.0)
		
	# Atualizamos nossa posição baseada na vspeed e hspeed
	position.y += vspeed
	position.x += hspeed

func _on_body_entered(body: Node2D) -> void:
	# Só detecta colisão com o mapa/chão (StaticBody2D)
	if body is StaticBody2D:
		is_colliding = true

func _on_body_exited(body: Node2D) -> void:
	# Só detecta saída do mapa/chão
	if body is StaticBody2D:
		is_colliding = false
