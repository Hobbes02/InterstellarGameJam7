extends KinematicBody2D

var bullet_speed: int = 100

var velocity: Vector2


func _ready() -> void:
	set_physics_process(false)


func shoot(speed: int, target: Vector2, mask: int, color: Color = Color(1, 0.658824, 0.172549), scale_factor: int = 1) -> void:
	$Area2D.collision_mask = mask
	$Area2D.collision_layer = mask
	$Polygon2D.color = color
	look_at(target)
	bullet_speed = speed
	scale = Vector2(scale_factor, scale_factor)
	set_physics_process(true)


func _physics_process(delta: float) -> void:
	velocity = Vector2(bullet_speed, 0).rotated(rotation)
	
	move_and_slide(velocity * Globals.speed_scale)


func _on_Area2D_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		body.take_damage()
	
	queue_free()
