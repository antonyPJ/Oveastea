extends CanvasLayer

func _ready():
	self.hide()
	# Garante que o process_mode permite funcionar quando pausado
	process_mode = Node.PROCESS_MODE_ALWAYS

func _on_start_pressed() -> void:
	# Despausa o jogo antes de recarregar
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_quit_pressed() -> void:
	get_tree().quit()
	
func game_over():
	# Pausa o jogo
	get_tree().paused = true
	# Mostra a tela de game over
	self.show()
