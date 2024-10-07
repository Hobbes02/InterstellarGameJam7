extends KinematicBody2D

var velocity: Vector2

var beeps_left: int = 3

onready var explosiontimer: Timer = $explosiontimer
onready var area: Sprite = $area
onready var cpu_particles_2d: CPUParticles2D = $CPUParticles2D
onready var area_2d: Area2D = $Area2D
onready var circle: Sprite = $circle


func _ready() -> void:
	set_physics_process(false)


func _process(delta: float) -> void:
	explosiontimer.paused = Globals.elevated


func _physics_process(delta: float) -> void:
	velocity = lerp(velocity, Vector2.ZERO, 5.0 * delta)
	
	move_and_slide(velocity)
	
	if velocity <= Vector2(1, 1):
		explosiontimer.start()
		set_physics_process(false)


func throw(target: Vector2, mask: int, color: Color = Color(1, 0.658824, 0.172549)):
	look_at(target)
	area_2d.collision_layer = mask
	area_2d.collision_mask = mask
	velocity = Vector2(300, 0).rotated(rotation)
	area.modulate = Color(color.r, color.g, color.b, 0.2)
	circle.modulate = color
	set_physics_process(true)


func _on_explosiontimer_timeout() -> void:
	beeps_left -= 1
	area.show()
	yield(get_tree().create_timer(0.5), "timeout")
	area.hide()
	
	if beeps_left <= 0:
		circle.hide()
		cpu_particles_2d.emitting = true
		$explode.play()
		for i in area_2d.get_overlapping_bodies():
			if i.has_method("take_damage"):
				i.take_damage()
				i.take_damage()
		get_tree().create_timer(1.2).connect("timeout", self, "_on_explode")
	else:
		explosiontimer.start()


func _on_explode() -> void:
	queue_free()
