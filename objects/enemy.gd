class_name Enemy
extends KinematicBody2D

enum ENEMY_TYPES {
	BASIC, 
	SHOOTER, 
	DODGER, 
	TUTORIAL, 
}

onready var enemy_stats: Dictionary = {
	ENEMY_TYPES.BASIC: {
		"node": $basic, 
		"line": $basic/Line2D, 
		"color": $basic/Polygon2D.color, 
		"speed": 10, 
		"bullet_speed": 60, 
		"bullets_per_mag": 6, 
		"max_health": 4, 
		"cooldown_time": 0.2, 
		"reload_time": 1.4, 
		"reload_sound": preload("res://assets/sfx/pistol_reload.mp3"), 
		"weapon_type": "pistol", 
		"points": 5, 
		"damage_function": "basic_damage"
	}, 
	ENEMY_TYPES.SHOOTER: {
		"node": $shooter, 
		"line": $shooter/Line2D, 
		"color": $shooter/Polygon2D.color, 
		"speed": 6, 
		"bullet_speed": 80, 
		"bullets_per_mag": 9, 
		"max_health": 4, 
		"cooldown_time": 0.1, 
		"reload_time": 1.8, 
		"reload_sound": preload("res://assets/sfx/shotgun_reload.mp3"), 
		"weapon_type": "shotgun", 
		"points": 10, 
		"damage_function": "shooter_damage"
	}, 
	ENEMY_TYPES.DODGER: {
		"node": $dodger, 
		"line": $dodger/Line2D, 
		"color": $dodger/circle.modulate, 
		"speed": 11, 
		"bullet_speed": 55, 
		"bullets_per_mag": 1, 
		"max_health": 5, 
		"cooldown_time": 0.0, 
		"reload_time": 1.0, 
		"reload_sound": null, 
		"weapon_type": "grenade", 
		"points": 15, 
		"damage_function": "dodger_damage"
	}, 
	ENEMY_TYPES.TUTORIAL: {
		"node": $dodger, 
		"line": $dodger/Line2D, 
		"color": $dodger/circle.modulate, 
		"speed": 8, 
		"bullet_speed": 60, 
		"bullets_per_mag": 2, 
		"max_health": 3, 
		"cooldown_time": 0.2, 
		"reload_time": 1.4, 
		"reload_sound": preload("res://assets/sfx/pistol_reload.mp3"), 
		"weapon_type": "pistol", 
		"points": 0, 
		"damage_function": "dodger_damage"
	}
}


signal shoot_bullet(from, speed, target, mask, color, is_player)
signal throw_grenade(from, target, mask, color)
signal player_die(node)
signal enemy_die(enemy_type)

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

var points: int = 0

onready var line_2d: Line2D
onready var selected: Sprite = $selected
onready var rng = RandomNumberGenerator.new()
onready var reloadtimer: Timer = $reloadtimer
onready var cooldowntimer: Timer = $cooldowntimer
onready var reloadindicator: ProgressBar = $indicators/reloadindicator
onready var indicators: Node2D = $indicators
onready var enemyshoottimer: Timer = $enemyshoottimer
onready var healthbar: ProgressBar = $indicators/healthbar
onready var deathparticles: CPUParticles2D = $deathparticles
onready var damageparticles: CPUParticles2D = $damageparticles
onready var shoot: AudioStreamPlayer2D = $shoot
onready var hit: AudioStreamPlayer2D = $hit
onready var throw: AudioStreamPlayer2D = $throw
onready var reload: AudioStreamPlayer2D = $reload


func _ready() -> void:
	# set up stats:
	
	var e = enemy_stats[enemy_type]
	
	e.node.show()
	line_2d = e.line
	color = e.color
	deathparticles.color = color
	damageparticles.color = color
	ai_speed = e.speed
	player_speed = ai_speed * 4.5
	bullet_speed = e.bullet_speed
	bullets_per_mag = e.bullets_per_mag
	bullets_left_in_mag = bullets_per_mag
	max_health = e.max_health
	health = max_health
	healthbar.max_value = max_health
	cooldowntimer.wait_time = e.cooldown_time if e.cooldown_time > 0 else 1
	reloadtimer.wait_time = e.reload_time
	enemyshoottimer.wait_time = e.reload_time * 4
	reload.stream = e.reload_sound
	weapon_type = e.weapon_type
	points = e.points
	
	if enemy_type == ENEMY_TYPES.DODGER:
		shoot.stream = preload("res://assets/sfx/throw.wav")
		enemyshoottimer.wait_time = 12


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
				pass
			elif !cooldowntimer.is_stopped():
				return
			else:
				shoot.volume_db = 0
				shoot.play()
				if enemy_stats[enemy_type].cooldown_time > 0:
					cooldowntimer.start()
				var bullet_target: Vector2 = SceneManager.mouse_position
				if enemy_type == ENEMY_TYPES.DODGER:
					emit_signal("throw_grenade", global_position, bullet_target, 8, Color(1, 0.658824, 0.172549))
					bullets_left_in_mag -= 1
				elif enemy_type == ENEMY_TYPES.SHOOTER:
					for i in [bullet_target, bullet_target + Vector2(40, 40), bullet_target - Vector2(40, 40)]:
						emit_signal("shoot_bullet", global_position, bullet_speed, i, 8, Color(1, 0.658824, 0.172549), true)
					bullets_left_in_mag -= 3
				else:
					emit_signal("shoot_bullet", global_position, bullet_speed, bullet_target, 8, Color(1, 0.658824, 0.172549), true)
					bullets_left_in_mag -= 1
				
				if bullets_left_in_mag <= 0:
					if reloadtimer.is_stopped():
						reloadtimer.start()
						reloadindicator.show()
						reload.play()
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
	
	call(enemy_stats[enemy_type].damage_function)
	
	if is_player_controlling:
		SignalBus.emit_signal("player_hit")
	
	if health <= 0:
		if !is_player_controlling:
			$basic.hide()
			$shooter.hide()
			$dodger.hide()
			healthbar.hide()
			deathparticles.emitting = true
			enemyshoottimer.stop()
			$CollisionShape2D.set_deferred("disabled", true)
			Globals.points += points
			emit_signal("enemy_die", enemy_type)
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
	var bullet_target: Vector2 = target.global_position + Vector2(rng.randi_range(-20, 20), rng.randi_range(-20, 20))
	if enemy_type != ENEMY_TYPES.TUTORIAL:
		shoot.volume_db = -10
		shoot.play()
	match enemy_type:
		ENEMY_TYPES.BASIC:
			emit_signal("shoot_bullet", global_position, bullet_speed, bullet_target, 16, Color(0.988235, 0.27451, 0.27451))
		ENEMY_TYPES.DODGER:
			emit_signal("throw_grenade", global_position, bullet_target, 16, Color(0.988235, 0.27451, 0.27451))
		ENEMY_TYPES.SHOOTER:
			for i in [bullet_target, bullet_target + Vector2(40, 40), bullet_target - Vector2(40, 40)]:
				emit_signal("shoot_bullet", global_position, bullet_speed, i, 16, Color(0.988235, 0.27451, 0.27451))


func basic_damage() -> void:
	$basic/Polygon2D.color = Color(1, 1, 1)
	yield(get_tree().create_timer(0.1), "timeout")
	$basic/Polygon2D.color = color

func shooter_damage() -> void:
	$shooter/Polygon2D.color = Color(1, 1, 1)
	yield(get_tree().create_timer(0.1), "timeout")
	$shooter/Polygon2D.color = color

func dodger_damage() -> void:
	$dodger/circle.modulate = Color(1, 1, 1)
	yield(get_tree().create_timer(0.1), "timeout")
	$dodger/circle.modulate = color

