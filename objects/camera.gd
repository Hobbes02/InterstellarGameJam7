extends Camera2D

var current_noise_position: float = 0
var shake_strength: float = 0.0

export(OpenSimplexNoise) var noise
export(int) var max_shake_strength = 20.0


func _process(delta: float) -> void:
	shake_strength = lerp(shake_strength, 0.0, 10.0 * delta)
	
	offset = get_camera_offset(delta)


func shake() -> void:
	shake_strength = max_shake_strength


func get_camera_offset(delta: float) -> Vector2:
	current_noise_position += delta * max_shake_strength
	
	return Vector2(
		noise.get_noise_2d(1, current_noise_position) * shake_strength, 
		noise.get_noise_2d(100, current_noise_position) * shake_strength
	)
