extends Node2D

# Tamanho de cada chunk (ajuste conforme necessário)
const CHUNK_SIZE = 512
const CHUNK_TEXTURE_SIZE = 512

# Dicionário de chunks ativos
var chunks: Dictionary = {}  # Key: Vector2i (chunk coords), Value: BloodChunk
var blood_image: Image

class BloodChunk:
	var sprite: Sprite2D
	var image: Image
	var dirty: bool = false
	var last_update: float = 0.0
	
	func _init(parent: Node2D, chunk_pos: Vector2):
		sprite = Sprite2D.new()
		sprite.z_index = -1  # Entre o chão (-2) e as árvores (0)
		sprite.centered = false
		sprite.global_position = chunk_pos
		parent.add_child(sprite)
		
		# Cria imagem menor para este chunk
		image = Image.create(CHUNK_TEXTURE_SIZE, CHUNK_TEXTURE_SIZE, false, Image.FORMAT_RGBA8)
		image.fill(Color(0, 0, 0, 0))

func _ready() -> void:
	var tex_blood := load("res://artwork/TDS/blood.png") as Texture2D
	blood_image = tex_blood.get_image()
	blood_image.convert(Image.FORMAT_RGBA8)

func draw_blood(draw_pos: Vector2):
	# Calcula qual chunk essa posição pertence
	var chunk_coord = Vector2i(
		floor(draw_pos.x / CHUNK_SIZE),
		floor(draw_pos.y / CHUNK_SIZE)
	)
	
	# Cria chunk se não existir
	if not chunks.has(chunk_coord):
		var chunk_world_pos = Vector2(chunk_coord) * CHUNK_SIZE
		chunks[chunk_coord] = BloodChunk.new(self, chunk_world_pos)
	
	var chunk = chunks[chunk_coord]
	
	# Posição local dentro do chunk
	var local_pos = draw_pos - (Vector2(chunk_coord) * CHUNK_SIZE)
	
	# GORY: Desenha múltiplas camadas de sangue
	for i in range(6):
		var offset = Vector2(randf_range(-10, 10), randf_range(-10, 10))
		var scaled_size = blood_image.get_size() * randf_range(2.5, 3.5)
		var final_pos = local_pos + offset - (scaled_size / 2)
		
		# Cria versão variada do sangue
		var tinted_blood = blood_image.duplicate()
		var alpha_mult = randf_range(0.6, 1.0)
		
		# Otimização: modifica apenas pixels não-transparentes
		for x in range(tinted_blood.get_width()):
			for y in range(tinted_blood.get_height()):
				var pixel = tinted_blood.get_pixel(x, y)
				if pixel.a > 0:
					pixel.r = clamp(pixel.r * randf_range(0.85, 1.0), 0, 1)
					pixel.a *= alpha_mult
					tinted_blood.set_pixel(x, y, pixel)
		
		# Verifica limites antes de blitar
		if final_pos.x >= 0 and final_pos.y >= 0:
			chunk.image.blit_rect(
				tinted_blood,
				Rect2i(Vector2.ZERO, blood_image.get_size()),
				final_pos
			)
	
	chunk.dirty = true

var update_timer = 0.0
const UPDATE_INTERVAL = 0.1

func _physics_process(delta: float) -> void:
	update_timer += delta
	
	if update_timer >= UPDATE_INTERVAL:
		update_timer = 0.0
		
		# Atualiza apenas chunks que foram modificados
		for chunk in chunks.values():
			if chunk.dirty:
				chunk.sprite.texture = ImageTexture.create_from_image(chunk.image)
				chunk.dirty = false
				chunk.last_update = Time.get_ticks_msec() / 1000.0

func clear_blood():
	for chunk in chunks.values():
		chunk.image.fill(Color(0, 0, 0, 0))
		chunk.dirty = true

# Opcional: Remove chunks inativos para economizar memória
func cleanup_old_chunks(max_age_seconds: float = 60.0):
	var current_time = Time.get_ticks_msec() / 1000.0
	var to_remove = []
	
	for coord in chunks.keys():
		var chunk = chunks[coord]
		if current_time - chunk.last_update > max_age_seconds:
			to_remove.append(coord)
	
	for coord in to_remove:
		chunks[coord].sprite.queue_free()
		chunks.erase(coord)
