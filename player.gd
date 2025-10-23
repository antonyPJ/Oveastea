extends CharacterBody2D


const SPEED = 300.0

var can_shoot = true

var bullet = preload("res://bullet.tscn")

func _process(delta):
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
	velocity = direction * SPEED
 

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
