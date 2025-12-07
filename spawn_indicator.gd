extends Node2D

# Tempo até o spawn acontecer
var time_until_spawn = 0.5
var elapsed_time = 0.0

# Visual
var circle_radius = 30.0
var pulse_speed = 10.0

func _ready():
	# Z-index alto para ficar acima de tudo
	z_index = 100

func _process(delta):
	elapsed_time += delta

	# Anima (pulsa e cresce)
	var progress = elapsed_time / time_until_spawn
	circle_radius = 30.0 + sin(elapsed_time * pulse_speed) * 10.0

	queue_redraw()

	# Auto-destruct quando acabar o tempo
	if elapsed_time >= time_until_spawn:
		queue_free()

func _draw():
	# Desenha círculo vermelho pulsante
	var progress = elapsed_time / time_until_spawn
	var alpha = 0.6 + sin(elapsed_time * pulse_speed) * 0.4

	# Círculo externo
	draw_circle(Vector2.ZERO, circle_radius, Color(1, 0, 0, alpha * 0.3))

	# Círculo interno (borda)
	draw_arc(Vector2.ZERO, circle_radius, 0, TAU, 32, Color(1, 0, 0, alpha), 3.0)

	# Cruz no centro
	var cross_size = 15
	draw_line(Vector2(-cross_size, 0), Vector2(cross_size, 0), Color(1, 0, 0, alpha), 2.0)
	draw_line(Vector2(0, -cross_size), Vector2(0, cross_size), Color(1, 0, 0, alpha), 2.0)
