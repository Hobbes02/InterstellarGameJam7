extends Node2D

const ENEMY = preload("res://objects/enemy.tscn")
const BULLET = preload("res://objects/bullet.tscn")

var enemy_spawn_rate: int = 5
var enemy_spawn_increase_rate: int = 8

var current_tutorial_step: int = -1

var tutorial_enemy: Node = null

onready var enemies: Node2D = $enemies
onready var bullets: Node2D = $bullets
onready var background: ColorRect = $background
onready var overlay: TextureRect = $overlay
onready var player: KinematicBody2D = $player
onready var enemy_target: Node = player
onready var tutorialnodes: Node2D = $tutorialnodes

onready var rng = RandomNumberGenerator.new()


func _ready() -> void:
	for l in tutorialnodes.get_children():
		l.hide()
	
	player.current_possessing_node = spawn_enemy(Vector2(128, 75), Enemy.ENEMY_TYPES.TUTORIAL)
	player.current_possessing_node.can_shoot = false
	
	if player.current_possessing_node != null:
		player.current_possessing_node.is_player_controlling = true
		player.current_possessing_node.target = enemy_target


func _process(delta: float) -> void:
	match current_tutorial_step:
		0:
			if player.current_possessing_node.velocity != Vector2.ZERO:
				current_tutorial_step = 1
				tutorial_enemy = spawn_enemy(Vector2(190, 75), Enemy.ENEMY_TYPES.TUTORIAL)
				$tutorialnodes/wasdtomove.hide()
				player.current_possessing_node.can_shoot = true
				$tutorialnodes/clicktoshoot.show()
				$game.global_position = Vector2(128, 100)
		1:
			if !is_instance_valid(tutorial_enemy):
				current_tutorial_step = 2
				$tutorialnodes/clicktoshoot.hide()
				$tutorialnodes/spacetoelevate.show()
		2:
			if Input.is_action_pressed("elevate"):
				$wasdtomove.show()
			if Input.is_action_just_released("elevate"):
				$wasdtomove.hide()
				$tutorialnodes/spacetoelevate.hide()
				current_tutorial_step = 3
				tutorial_enemy = spawn_enemy(Vector2(190, 75), Enemy.ENEMY_TYPES.TUTORIAL)
				$tutorialnodes/elevatepossess.show()
				player.current_possessing_node.can_shoot = false
		3:
			if player.current_possessing_node == tutorial_enemy:
				$tutorialnodes/elevatepossess.hide()
				$game.show()
				$game/text.hide()
				$game/startgame.show()
				current_tutorial_step = 4
	
	if Input.is_action_just_pressed("elevate"):
		if current_tutorial_step < 2:
			return
		if Globals.dead:
			Globals.dead = false
			_ready()
			return
		Globals.elevated = true
		for e in enemies.get_children():
			e.is_player_controlling = false
	elif Input.is_action_just_released("elevate"):
		Globals.elevated = false
		for e in enemies.get_children():
			e.is_player_controlling = false
		if player.current_hovering_enemy != null:
			player.current_hovering_enemy.is_player_controlling = true
			player.current_possessing_node = player.current_hovering_enemy
		elif player.current_possessing_node != null:
			player.current_possessing_node.is_player_controlling = true
	
	if Input.is_action_pressed("elevate"):
		if current_tutorial_step < 2:
			return
		overlay.modulate.a = lerp(overlay.modulate.a, 1, 8.0 * delta)
		Globals.speed_scale = lerp(Globals.speed_scale, 0.2, 8.0 * delta)
		if player.current_hovering_enemy != null:
			overlay.start_color = lerp(
				overlay.start_color,
				player.current_hovering_enemy.color,
				10.0 * delta
			)
		else:
			overlay.start_color = lerp(
				overlay.start_color,
				Color(0.988235, 0.27451, 0.27451),
				10.0 * delta
			)
	else:
		overlay.modulate.a = lerp(overlay.modulate.a, 0, 10.0 * delta)
		Globals.speed_scale = lerp(Globals.speed_scale, 1, 10.0 * delta)


func _on_shoot_bullet(from: Vector2, speed: int, target: Vector2, collision_mask: int, color: Color = Color(1, 0.658824, 0.172549)) -> void:
	var b = BULLET.instance()
	b.global_position = from
	bullets.add_child(b)
	b.shoot(speed, target, collision_mask, color)


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


func _on_tutorial_body_entered(body: Node) -> void:
	if not current_tutorial_step in [-1]:
		return
	current_tutorial_step = 0
	player.current_possessing_node.global_position = Vector2(85, 75)
	$tutorial.hide()
	$game.hide()
	$tutorialnodes/wasdtomove.show()


func _on_game_body_entered(body: Node) -> void:
	if not current_tutorial_step in [-1, 4]:
		return
	SceneManager.emit_signal("change_scene", "res://scenes/game.tscn")
