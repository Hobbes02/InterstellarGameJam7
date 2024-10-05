extends Node2D

const ENEMY = preload("res://objects/enemy.tscn")
const BULLET = preload("res://objects/bullet.tscn")

var enemy_spawn_rate: int = 10

onready var enemies: Node2D = $enemies
onready var bullets: Node2D = $bullets
onready var background: ColorRect = $background
onready var enemyspawntimer: Timer = $enemyspawntimer
onready var overlay: ColorRect = $overlay
onready var player: KinematicBody2D = $player
onready var enemy_target: Node = player

onready var rng = RandomNumberGenerator.new()


func _ready() -> void:
	rng.randomize()
	enemyspawntimer.wait_time = 60.0 / enemy_spawn_rate
	enemyspawntimer.start()
	spawn_enemy()
	
	if player.current_possessing_node != null:
		player.current_possessing_node.is_player_controlling = true
		player.current_possessing_node.target = enemy_target


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("elevate"):
		Globals.elevated = true
		enemyspawntimer.paused = true
		for e in enemies.get_children():
			e.is_player_controlling = false
	elif Input.is_action_just_released("elevate"):
		Globals.elevated = false
		enemyspawntimer.paused = false
		for e in enemies.get_children():
				e.is_player_controlling = false
		if player.current_hovering_enemy != null:
			player.current_hovering_enemy.is_player_controlling = true
			player.current_possessing_node = player.current_hovering_enemy
		else:
			player.current_possessing_node.is_player_controlling = true
		
	
	if Input.is_action_pressed("elevate"):
		overlay.modulate.a = lerp(overlay.modulate.a, 1, 0.05)
		Globals.speed_scale = lerp(Globals.speed_scale, 0.2, 0.05)
	else:
		overlay.modulate.a = lerp(overlay.modulate.a, 0.0, 0.05)
		Globals.speed_scale = lerp(Globals.speed_scale, 1.0, 0.05)


func _on_shoot_bullet(from: Vector2, speed: int, target: Vector2, collision_mask: int, color: Color = Color(1, 0.658824, 0.172549)) -> void:
	var b = BULLET.instance()
	b.global_position = from
	bullets.add_child(b)
	b.shoot(speed, target, collision_mask, color)


func _on_player_die(node: Node) -> void:
	player.current_possessing_node = null
	node.queue_free()
	enemyspawntimer.stop()
	for e in enemies.get_children():
		e.queue_free()
	for b in bullets.get_children():
		b.queue_free()


func spawn_enemy() -> void:
	var spawn_location: Vector2
	var side = rng.randi_range(0, 3)
	match side:
		0:
			spawn_location = Vector2(-5, rng.randi_range(-5, 155))
		1:
			spawn_location = Vector2(rng.randi_range(-5, 262), -5)
		2:
			spawn_location = Vector2(276, rng.randi_range(-5, 155))
		3:
			spawn_location = Vector2(rng.randi_range(-5, 262), 155)
	
	var enemy = ENEMY.instance()
	enemy.connect("shoot_bullet", self, "_on_shoot_bullet")
	enemy.connect("player_die", self, "_on_player_die")
	enemies.add_child(enemy)
	enemy.global_position = spawn_location
	enemy.target = enemy_target


func _on_enemyspawntimer_timeout() -> void:
	enemyspawntimer.wait_time = 60.0 / enemy_spawn_rate
	spawn_enemy()
	enemyspawntimer.start()
