extends TextureRect

export(Color) var start_color: Color = Color(0.988235, 0.27451, 0.27451) setget set_start_color
export(Color) var end_color: Color = Color(0.929412, 0.901961, 0.207843) setget set_end_color
export(float) var cutoff: float = 50.0 setget set_cutoff
var noise_seed: int = 0 setget set_seed


func set_cutoff(new_value: float) -> void:
	cutoff = new_value
	material.get_shader_param("colormap").gradient.set_offset(1, cutoff / 100.0)


func set_seed(new_value: int) -> void:
	noise_seed = new_value
	texture.noise.seed = noise_seed


func set_start_color(new_value: Color) -> void:
	start_color = new_value
	material.get_shader_param("colormap").gradient.set_color(0, start_color)


func set_end_color(new_value: Color) -> void:
	end_color = new_value
	material.get_shader_param("colormap").gradient.set_color(1, end_color)


func increase_seed() -> void:
	set_seed(noise_seed + 1)
