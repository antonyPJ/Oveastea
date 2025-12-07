extends Area2D

# Configurações do powerup
var speed_multiplier = 2.5  # Velocidade aumenta em 2.5x
var duration = 10.0  # Dura 10 segundos
var picked_up = false

# Efeito visual de rotação
var rotation_speed = 2.0

func _ready():
	# Adiciona ao grupo de powerups
	add_to_group("powerups")

	# Conecta o sinal de colisão
	body_entered.connect(_on_body_entered)

	# Auto-destruct após 40 segundos se não for pego
	var lifetime_timer = Timer.new()
	lifetime_timer.wait_time = 40.0
	lifetime_timer.one_shot = true
	lifetime_timer.timeout.connect(_despawn)
	add_child(lifetime_timer)
	lifetime_timer.start()

func _process(delta):
	# Efeito visual: rotação contínua
	rotation += rotation_speed * delta

	# Efeito de pulsação
	var pulse = 1.0 + sin(Time.get_ticks_msec() / 200.0) * 0.2
	scale = Vector2(pulse, pulse)

func _on_body_entered(body):
	if picked_up:
		return

	if body.is_in_group('player'):
		if body.has_method('apply_speed_boost'):
			body.apply_speed_boost(speed_multiplier, duration)
			picked_up = true

			# Efeito visual de coleta
			_play_pickup_effect()

			# Remove o powerup
			queue_free()

func _play_pickup_effect():
	# Cria um pequeno efeito visual antes de desaparecer
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(2, 2), 0.2)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.2)

func _despawn():
	# Fade out antes de desaparecer
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 1.0)
	tween.finished.connect(queue_free)
