extends Node2D

# Sistema de pontuação
var score = 0
var score_per_kill = 100

# UI - será acessada via CanvasLayer
var score_label
var wave_label

# Called when the node enters the scene tree for the first time.
func _ready():
	# Procura pelo ScoreLabel no CanvasLayer existente
	score_label = get_tree().get_first_node_in_group('score_label')
	if not score_label:
		# Fallback: procura em qualquer CanvasLayer
		var canvas_layers = get_tree().get_nodes_in_group('canvas_layer')
		if canvas_layers.size() > 0:
			score_label = canvas_layers[0].get_node_or_null('ScoreLabel')
	
	# Procura pelo WaveLabel
	wave_label = get_tree().get_first_node_in_group('wave_label')
	
	update_score_display()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# REMOVIDO: Sistema antigo de reiniciar quando todos os mobs morrem
	# Agora o spawner controla as waves
	pass

# Função para adicionar pontos quando inimigo morre
func add_score(points: int = 0):
	if points > 0:
		score += points  # Pontos personalizados (ex: boss)
	else:
		score += score_per_kill  # Pontos normais
	update_score_display()

# Atualiza o display do score
func update_score_display():
	if score_label:
		score_label.text = "Score: " + str(score)
