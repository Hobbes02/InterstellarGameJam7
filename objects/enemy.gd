extends KinematicBody2D

var velocity: Vector2 = Vector2.ZERO
var ai_speed: int = 8
var player_speed: int = 40

var target: Node = null
var is_player_controlling: bool = false

onready var line_2d: Line2D = $Line2D


func _physics_process(delta: float) -> void:
	if Globals.elevated:
		line_2d.show()
	else:
		line_2d.hide()
	
	if is_player_controlling:
		var input_vector: Vector2
		input_vector.x = Input.get_action_strength("right") - Input.get_action_strength("left")
		input_vector.y = Input.get_action_strength("down") - Input.get_action_strength("up")
		if input_vector == Vector2.ZERO:
			velocity = lerp(velocity, Vector2.ZERO, 0.2)
		else:
			velocity = input_vector.normalized() * player_speed
		look_at(SceneManager.mouse_position)
	else:
		if target != null and target.is_inside_tree():
			velocity = global_position.direction_to(target.global_position) * ai_speed
			look_at(target.global_position)
		else:
			velocity = lerp(velocity, Vector2.ZERO, 0.2)
	
	move_and_slide(velocity * Globals.speed_scale)
