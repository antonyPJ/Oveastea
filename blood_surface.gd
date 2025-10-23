extends Sprite2D

# Imagens
var surface_image : Image = Image.new()
var blood_image : Image = Image.new()

# O que usamos para converter imagens em texturas
var surface_texture : ImageTexture = ImageTexture.new()

var blood_size : Vector2

func _ready() -> void:
	# Cria imagem transparente muito maior para cobrir paredes do mapa
	surface_image = Image.create(5000, 5000, false, Image.FORMAT_RGBA8)
	surface_image.fill(Color(0, 0, 0, 0))
	
	# Carrega nossa imagem de sangue, garante que os formatos coincidam
	blood_image.load("res://artwork/TDS/blood.png")
	blood_image.convert(Image.FORMAT_RGBA8)
	blood_size = blood_image.get_size()
	
	# Posiciona a superfície para cobrir paredes do mapa
	global_position = Vector2(-2500, -2500)
	
func draw_blood(draw_pos : Vector2):
	# Ajusta a posição para a nova posição da superfície
	var adjusted_pos = draw_pos - global_position
	
	# GORY: Aumenta MUITO o tamanho do sangue (de 2x para 3x)
	var scaled_blood_size = blood_size * 3.0
	var scaled_pos = adjusted_pos - (scaled_blood_size / 2)
	
	# Verifica se a posição está dentro dos limites da imagem
	if scaled_pos.x >= 0 and scaled_pos.y >= 0 and scaled_pos.x < surface_image.get_width() and scaled_pos.y < surface_image.get_height():
		# GORY: Mais camadas com maior variação para sangue mais denso e irregular
		for i in range(8):  # Aumentado de 5 para 8 camadas
			var offset = Vector2(randf_range(-12, 12), randf_range(-12, 12))  # Maior espalhamento
			var final_pos = scaled_pos + offset
			
			# GORY: Varia a opacidade de cada camada para profundidade
			var alpha_mult = randf_range(0.6, 1.0)
			var tinted_blood = blood_image.duplicate()
			
			# Aplica uma leve variação de cor vermelha para realismo
			for x in range(tinted_blood.get_width()):
				for y in range(tinted_blood.get_height()):
					var pixel = tinted_blood.get_pixel(x, y)
					if pixel.a > 0:  # Só modifica pixels não transparentes
						pixel.r = clamp(pixel.r * randf_range(0.85, 1.0), 0, 1)
						pixel.a *= alpha_mult
						tinted_blood.set_pixel(x, y, pixel)
			
			surface_image.blit_rect(tinted_blood, Rect2i(Vector2(0, 0), blood_size), final_pos)
	
var update_timer = 0.0
var update_interval = 0.08  # GORY: Atualiza mais rápido (de 0.1 para 0.08) para feedback mais imediato

func _physics_process(delta: float) -> void:
	update_timer += delta
	
	# Só atualiza a textura a cada intervalo para reduzir lag
	if update_timer >= update_interval:
		update_timer = 0.0
		texture = ImageTexture.create_from_image(surface_image)
	
func SaveBloodTexture():
	surface_image.save_png("res://BloodTexture.png")
	
func LoadBloodTexture():
	surface_image = Image.load_from_file("res://BloodTexture.png")
	texture = ImageTexture.create_from_image(surface_image)
	
func ClearTexture():
	surface_image.fill(Color(0, 0, 0, 0))
