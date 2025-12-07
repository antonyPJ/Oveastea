extends CharacterBody2D


const SPEED = 400.0  # Aumentado de 300 para 400

var can_shoot = true
var bullet = preload("res://bullet.tscn")

# Sistema de powerup de velocidade (com stacking)
var speed_boost_stacks = []  # Array de {multiplier, timer}
var total_speed_multiplier = 1.0

func _process(delta):
	# Gerencia timer dos speed boosts (múltiplos stacks)
	if speed_boost_stacks.size() > 0:
		# Atualiza cada stack
		for i in range(speed_boost_stacks.size() - 1, -1, -1):
			speed_boost_stacks[i].timer -= delta
			if speed_boost_stacks[i].timer <= 0:
				speed_boost_stacks.remove_at(i)

		# Recalcula multiplicador total
		update_speed_multiplier()

	var mouse_pos = get_global_mouse_position()
	$PlayerSprite/SGun.look_at(mouse_pos)
	if mouse_pos.x < global_position.x:
		$PlayerSprite/SGun.flip_v = true
	elif mouse_pos.x > global_position.x:
		$PlayerSprite/SGun.flip_v = false

	if mouse_pos.y > global_position.y:
		$PlayerSprite/SGun.show_behind_parent = false
	elif mouse_pos.y < global_position.y:
		$PlayerSprite/SGun.show_behind_parent = true



	if Input.is_action_pressed("shoot"):
		if can_shoot:
			var b = bullet.instantiate()
			owner.add_child(b)
			b.global_transform = $PlayerSprite/SGun/muzzle.global_transform
			$shootSound.play()
			can_shoot = false
			$ShotCoolDown.start()
		

func _physics_process(delta):

	var mouse_pos = get_global_mouse_position()
	var direction = Input.get_vector("left", "right", "up", "down")
	velocity = direction * SPEED * total_speed_multiplier
 

	if velocity.length() > 0:
		$PlayerSprite.animation = 'walk'
	else:
		$PlayerSprite.animation = 'idle'

	if mouse_pos.x < global_position.x:
		$PlayerSprite.flip_h = true 
	elif mouse_pos.x > global_position.x:
		$PlayerSprite.flip_h = false
	move_and_slide()



func _on_shot_cool_down_timeout():
	can_shoot = true

# Sistema de powerup de velocidade (com stacking)
func apply_speed_boost(multiplier: float, duration: float):
	# Adiciona novo stack
	speed_boost_stacks.append({
		"multiplier": multiplier,
		"timer": duration
	})

	# Recalcula multiplicador total
	update_speed_multiplier()

	# Feedback visual: intensidade do cyan aumenta com mais stacks
	var cyan_intensity = min(1.0, 0.3 + (speed_boost_stacks.size() * 0.2))
	$PlayerSprite.modulate = Color(1.0 - cyan_intensity, 1.0, 1.0)

func update_speed_multiplier():
	if speed_boost_stacks.size() == 0:
		total_speed_multiplier = 1.0
		$PlayerSprite.modulate = Color.WHITE
		return

	# Soma todos os multiplicadores (stacking aditivo)
	# Exemplo: 2.5x + 2.5x = 5.0x
	total_speed_multiplier = 1.0
	for stack in speed_boost_stacks:
		total_speed_multiplier += (stack.multiplier - 1.0)

	# Feedback visual baseado no multiplicador
	var cyan_intensity = min(1.0, (total_speed_multiplier - 1.0) / 5.0)
	$PlayerSprite.modulate = Color(1.0 - cyan_intensity, 1.0, 1.0)
