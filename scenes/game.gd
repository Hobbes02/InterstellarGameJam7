extends Node2D

const ENEMY = preload("res://objects/enemy.tscn")
const BULLET = preload("res://objects/bullet.tscn")

var enemy_spawn_rate: int = 5
var enemy_spawn_increase_rate: int = 8

onready var enemies: Node2D = $enemies
onready var bullets: Node2D = $bullets
onready var background: ColorRect = $background
onready var enemyspawntimer: Timer = $enemyspawntimer
onready var overlay: TextureRect = $overlay
onready var player: KinematicBody2D = $player
onready var enemy_target: Node = player
onready var weaponlabel: Label = $weaponlabel

onready var rng = RandomNumberGenerator.new()


func _ready() -> void:
	rng.randomize()
	enemyspawntimer.wait_time = 60.0 / enemy_spawn_rate
	enemy_spawn_rate = 20
	enemyspawntimer.start()
	spawn_enemy()
	
	player.current_possessing_node = spawn_enemy(Vector2(128, 75), Enemy.ENEMY_TYPES.BASIC)
	
	$deathlabel.hide()
	
	if player.current_possessing_node != null:
		player.current_possessing_node.is_player_controlling = true
		player.current_possessing_node.target = enemy_target
	
	weaponlabel.text = player.current_possessing_node.weapon_type


func _process(_delta: float) -> void:
	if enemies.get_child_count() < 2 and !Globals.dead:
		spawn_enemy()
	if Input.is_action_just_pressed("elevate"):
		if Globals.dead:
			Globals.dead = false
			_ready()
			return
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
		elif player.current_possessing_node != null:
			player.current_possessing_node.is_player_controlling = true
		
		weaponlabel.text = player.current_possessing_node.weapon_type
	
	if Input.is_action_pressed("elevate"):
		overlay.modulate.a = lerp(overlay.modulate.a, 1, 0.05)
		Globals.speed_scale = lerp(Globals.speed_scale, 0.2, 0.05)
		if player.current_hovering_enemy != null:
			overlay.start_color = player.current_hovering_enemy.color
		else:
			overlay.start_color = Color(0.988235, 0.27451, 0.27451)
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
	$deathlabel.show()
	weaponlabel.text = ""
	
	Globals.dead = true


func spawn_enemy(spawn_location: Vector2 = Vector2.ZERO, enemy_type: int = -1) -> Node:
	if spawn_location == Vector2.ZERO:
		var side = rng.randi_range(0, 3)
		match side:
			0:
				spawn_location = Vector2(-10, rng.randi_range(-10, 160))
			1:
				spawn_location = Vector2(rng.randi_range(-10, 266), -10)
			2:
				spawn_location = Vector2(276, rng.randi_range(-10, 160))
			3:
				spawn_location = Vector2(rng.randi_range(-10, 266), 160)
	
	var enemy = ENEMY.instance()
	enemy.connect("shoot_bullet", self, "_on_shoot_bullet")
	enemy.connect("player_die", self, "_on_player_die")
	enemy.enemy_type = enemy_type
	enemies.add_child(enemy)
	enemy.global_position = spawn_location
	enemy.target = enemy_target
	return enemy


func _on_enemyspawntimer_timeout() -> void:
	enemy_spawn_rate = clamp(
		enemy_spawn_rate + enemy_spawn_increase_rate, 
		1, 60
	)
	enemy_spawn_increase_rate = clamp(enemy_spawn_increase_rate - 1, 1, 12)
	enemyspawntimer.wait_time = 60.0 / enemy_spawn_rate
	spawn_enemy()
	enemyspawntimer.start()
