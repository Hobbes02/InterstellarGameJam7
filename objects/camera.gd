extends Camera2D

const MAX_SHAKE_STRENGTH: float = 30.0

var current_noise_position: float = 0
var shake_strength: float = 0.0

export(OpenSimplexNoise) var noise


func _process(delta: float) -> void:
	shake_strength = lerp(shake_strength, 0.0, 10.0 * delta)
	
	offset = get_camera_offset(delta)


func shake() -> void:
	shake_strength = MAX_SHAKE_STRENGTH


func get_camera_offset(delta: float) -> Vector2:
	current_noise_position += delta * MAX_SHAKE_STRENGTH
	
	return Vector2(
		noise.get_noise_2d(1, current_noise_position) * shake_strength, 
		noise.get_noise_2d(100, current_noise_position) * shake_strength
	)
