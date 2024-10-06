class_name Enemy
extends KinematicBody2D

enum ENEMY_TYPES {
	BASIC, 
	SHOOTER, 
	DRUNK, 
	TUTORIAL, 
}

signal shoot_bullet(from, speed, target, mask)
signal player_die(node)

var velocity: Vector2

var max_health: int = 2
var health: int = 2

var ai_speed: int = 6
var player_speed: int = 40

var bullet_speed: int = 60
var bullets_per_mag: int = 5
var reload_time: float = 1.4

var bullets_left_in_mag: int = bullets_per_mag

var target: Node = null
var is_player_controlling: bool = false

var enemy_type: int = -1
var weapon_type: String = ""

var can_shoot: bool = true

var color: Color

onready var line_2d: Line2D
onready var selected: Sprite = $selected
onready var rng = RandomNumberGenerator.new()
onready var reloadtimer: Timer = $reloadtimer
onready var reloadindicator: ProgressBar = $indicators/reloadindicator
onready var indicators: Node2D = $indicators
onready var enemyshoottimer: Timer = $enemyshoottimer
onready var healthbar: ProgressBar = $indicators/healthbar
onready var deathparticles: CPUParticles2D = $deathparticles
onready var damageparticles: CPUParticles2D = $damageparticles
onready var shoot: AudioStreamPlayer = $shoot
onready var hit: AudioStreamPlayer = $hit
onready var throw: AudioStreamPlayer = $throw
onready var reload: AudioStreamPlayer = $reload


func _ready() -> void:
	rng.randomize()
	if enemy_type == -1:
		enemy_type = rng.randi_range(0, 2)
	
	match enemy_type:
		ENEMY_TYPES.BASIC:
			$basic.show()
			line_2d = $basic/Line2D
			ai_speed = 10
			bullet_speed = 60
			bullets_per_mag = 6
			reload_time = 1.4
			max_health = 3
			weapon_type = "pistol"
			color = $basic/Polygon2D.color
			reload.stream = preload("res://assets/sfx/pistol_reload.mp3")
		ENEMY_TYPES.SHOOTER:
			$shooter.show()
			line_2d = $shooter/Line2D
			ai_speed = 8
			bullet_speed = 80
			bullets_per_mag = 9
			reload_time = 1.8
			max_health = 4
			weapon_type = "shotgun"
			color = $shooter/Polygon2D.color
			reload.stream = preload("res://assets/sfx/shotgun_reload.mp3")
			reload.volume_db = 5
		ENEMY_TYPES.DRUNK:
			$drunk.show()
			line_2d = $drunk/Line2D
			ai_speed = 12
			bullet_speed = 55
			bullets_per_mag = 6
			reload_time = 1.0
			max_health = 5
			weapon_type = "random"
			color = $drunk/circle.modulate
			reload.stream = preload("res://assets/sfx/random_reload.mp3")
		ENEMY_TYPES.TUTORIAL:
			$drunk.show()
			line_2d = $drunk/Line2D
			ai_speed = 8
			bullet_speed = 60
			bullets_per_mag = 2
			reload_time = 1.4
			max_health = 3
			weapon_type = "pistol"
			color = $drunk/circle.modulate
			reload.stream = preload("res://assets/sfx/pistol_reload.mp3")
	
	health = max_health
	player_speed = ai_speed * 4.5
	bullets_left_in_mag = bullets_per_mag
	reloadtimer.wait_time = reload_time
	
	enemyshoottimer.wait_time = reload_time * 4
	
	healthbar.max_value = max_health
	
	deathparticles.color = color
	damageparticles.color = color


func _physics_process(delta: float) -> void:
	if Globals.elevated and line_2d.is_inside_tree():
		line_2d.show()
	else:
		line_2d.hide()
	
	if reloadtimer.time_left > 0.05:
		reloadindicator.value = 100 / (reloadtimer.wait_time / reloadtimer.time_left)
	else:
		reloadindicator.hide()
	
	if is_player_controlling and !Globals.elevated:
		healthbar.show()
		collision_layer = 3
		collision_mask = 17
		var input_vector: Vector2
		input_vector.x = Input.get_action_strength("right") - Input.get_action_strength("left")
		input_vector.y = Input.get_action_strength("down") - Input.get_action_strength("up")
		if input_vector == Vector2.ZERO:
			velocity = lerp(velocity, Vector2.ZERO, 0.2)
		else:
			velocity = input_vector.normalized() * player_speed
		look_at(SceneManager.mouse_position)
		
		if Input.is_action_just_pressed("shoot"):
			if !can_shoot:
				return
			if bullets_left_in_mag <= 0:
				if reloadtimer.is_stopped():
					reloadtimer.start()
					reloadindicator.show()
					reload.play()
			else:
				shoot.volume_db = 0
				shoot.play()
				var bullet_target: Vector2 = SceneManager.mouse_position
				if enemy_type == ENEMY_TYPES.DRUNK:
					bullet_target = Vector2(rng.randi_range(0, 256), rng.randi_range(0, 150))
				if enemy_type == ENEMY_TYPES.SHOOTER:
					for i in [bullet_target, bullet_target + Vector2(40, 40), bullet_target - Vector2(40, 40)]:
						emit_signal("shoot_bullet", global_position, bullet_speed, i, 8, Color(1, 0.658824, 0.172549))
					bullets_left_in_mag -= 3
				else:
					emit_signal("shoot_bullet", global_position, bullet_speed, bullet_target, 8, Color(1, 0.658824, 0.172549))
					bullets_left_in_mag -= 1
	else:
		if health == max_health:
			healthbar.hide()
		collision_layer = 1
		collision_mask = 11
		if target != null and target.is_inside_tree():
			velocity = global_position.direction_to(target.global_position) * ai_speed
			look_at(target.global_position)
		else:
			velocity = lerp(velocity, Vector2.ZERO, 0.2)
		
		if enemy_type == ENEMY_TYPES.TUTORIAL:
			velocity = Vector2.ZERO
	
	move_and_slide(velocity * Globals.speed_scale)


func _process(delta: float) -> void:
	indicators.rotation_degrees = -rotation_degrees


func take_damage() -> void:
	health -= 1
	
	hit.play()
	
	healthbar.show()
	healthbar.value = health
	
	damageparticles.emitting = true
	
	if health <= 0:
		if !is_player_controlling:
			$basic.hide()
			$shooter.hide()
			$drunk.hide()
			healthbar.hide()
			deathparticles.emitting = true
			enemyshoottimer.stop()
			$CollisionShape2D.set_deferred("disabled", true)
			get_tree().create_timer(1).connect("timeout", self, "_on_particles_finished")
		else:
			emit_signal("player_die", self)


func _on_particles_finished() -> void:
	queue_free()


func _on_reloadtimer_timeout() -> void:
	bullets_left_in_mag = bullets_per_mag


func _on_enemyshoottimer_timeout() -> void:
	enemyshoottimer.start()
	if is_player_controlling or Globals.elevated:
		return
	var bullet_target: Vector2
	if enemy_type != ENEMY_TYPES.TUTORIAL:
		shoot.volume_db = -10
		shoot.play()
	match enemy_type:
		ENEMY_TYPES.BASIC:
			bullet_target = target.global_position + Vector2(rng.randi_range(-20, 20), rng.randi_range(-20, 20))
			emit_signal("shoot_bullet", global_position, bullet_speed, bullet_target, 16, Color(0.988235, 0.27451, 0.27451))
		ENEMY_TYPES.DRUNK:
			bullet_target = Vector2(rng.randi_range(0, 256), rng.randi_range(0, 150))
			emit_signal("shoot_bullet", global_position, bullet_speed, bullet_target, 16, Color(0.988235, 0.27451, 0.27451))
		ENEMY_TYPES.SHOOTER:
			bullet_target = target.global_position + Vector2(rng.randi_range(-20, 20), rng.randi_range(-20, 20))
			for i in [bullet_target, bullet_target + Vector2(40, 40), bullet_target - Vector2(40, 40)]:
				emit_signal("shoot_bullet", global_position, bullet_speed, i, 16, Color(0.988235, 0.27451, 0.27451))
