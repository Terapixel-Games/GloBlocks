extends GPUParticles2D
class_name ShardParticles

var _texture_cache: Texture2D

func _ready() -> void:
	if texture == null:
		texture = _build_shard_texture(18)
	if process_material == null:
		var mat := ParticleProcessMaterial.new()
		mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINT
		mat.direction = Vector3(1.0, 0.0, 0.0)
		mat.spread = 180.0
		mat.gravity = Vector3(0.0, 540.0, 0.0)
		mat.initial_velocity_min = 280.0
		mat.initial_velocity_max = 520.0
		mat.scale_min = 0.08
		mat.scale_max = 0.2
		mat.angular_velocity_min = -16.0
		mat.angular_velocity_max = 16.0
		process_material = mat

func burst(tint: Color) -> void:
	modulate = Color(tint.r, tint.g, tint.b, 0.95)
	restart()
	emitting = true
	_cleanup_async()

func _cleanup_async() -> void:
	await get_tree().create_timer(lifetime + 0.18).timeout
	if is_instance_valid(self):
		queue_free()

func _build_shard_texture(size: int) -> Texture2D:
	if _texture_cache != null:
		return _texture_cache
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size * 0.5, size * 0.5)
	var radius: float = size * 0.5
	for y in range(size):
		for x in range(size):
			var p: Vector2 = Vector2(x, y)
			var d: float = center.distance_to(p) / radius
			var a: float = clamp(1.0 - d, 0.0, 1.0)
			a = pow(a, 1.65)
			if x < size * 0.3:
				a *= 0.88
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, a))
	_texture_cache = ImageTexture.create_from_image(image)
	return _texture_cache
