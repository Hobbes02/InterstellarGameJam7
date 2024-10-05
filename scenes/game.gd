extends Node2D

const ENEMY = preload("res://objects/enemy.tscn")

var enemy_spawn_rate: int = 20

onready var enemy_target: Node = $base
onready var enemies: Node2D = $enemies
onready var animation_player: AnimationPlayer = $AnimationPlayer
onready var enemyspawntimer: Timer = $enemyspawntimer
onready var base_outline: Line2D = $base/Line2D
onready var overlay: ColorRect = $overlay
onready var basehealth: ProgressBar = $basehealth
onready var player: KinematicBody2D = $player

onready var rng = RandomNumberGenerator.new()


func _ready() -> void:
	rng.randomize()
	enemyspawntimer.wait_time = 60.0 / enemy_spawn_rate
	enemyspawntimer.start()
	spawn_enemy()


func _process(_delta: float) -> void:
	animation_player.playback_speed = Globals.speed_scale
	if Globals.elevated:
		base_outline.show()
	else:
		base_outline.hide()
	
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
		
	
	if Input.is_action_pressed("elevate"):
		overlay.modulate.a = lerp(overlay.modulate.a, 1, 0.05)
		Globals.speed_scale = lerp(Globals.speed_scale, 0.2, 0.05)
	else:
		overlay.modulate.a = lerp(overlay.modulate.a, 0.0, 0.05)
		Globals.speed_scale = lerp(Globals.speed_scale, 1.0, 0.05)


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
	enemies.add_child(enemy)
	enemy.global_position = spawn_location
	enemy.target = enemy_target


func _on_enemyspawntimer_timeout() -> void:
	enemyspawntimer.wait_time = 60.0 / enemy_spawn_rate
	spawn_enemy()
	enemyspawntimer.start()
