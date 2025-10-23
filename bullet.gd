extends Area2D

const speed = 750
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	position += transform.x * speed * delta


func _on_body_entered(body):
	if body.has_method('kill'):
		if !body.dead:
			# Passa a direção do projétil para o mob
			body.kill(transform.x)
			queue_free()
	else:
		queue_free()
