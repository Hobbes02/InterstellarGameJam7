extends Node2D

const ENEMY = preload("res://objects/enemy.tscn")
const BULLET = preload("res://objects/bullet.tscn")
const GRENADE = preload("res://objects/grenade.tscn")
const TREE = preload("res://objects/tree.tscn")

var enemy_spawn_rate: int = 5
var enemy_spawn_increase_rate: int = 4

var has_game_started = false

var dodger_amount: int = 0

onready var enemies: Node2D = $enemies
onready var bullets: Node2D = $bullets
onready var background: ColorRect = $background
onready var enemyspawntimer: Timer = $enemyspawntimer
onready var overlay: ColorRect = $HUD/overlay
onready var suboverlay: TextureRect = $HUD/overlay/overlay
onready var possesstext: TextureRect = $HUD/overlay/text
onready var player: KinematicBody2D = $player
onready var enemy_target: Node = player
onready var weaponlabel: Label = $HUD/weaponlabel
onready var pointslabel: Label = $HUD/pointslabel
onready var animation_player: AnimationPlayer = $HUD/AnimationPlayer
onready var scorelabel: Label = $HUD/deathlabel/score
onready var highscorelabel: Label = $HUD/deathlabel/highscore
onready var music: AudioStreamPlayer = $music
onready var elevatedmusic: AudioStreamPlayer = $elevatedmusic
onready var hud: Node2D = $HUD

onready var rng = RandomNumberGenerator.new()


func start() -> void:
	rng.randomize()
	enemyspawntimer.wait_time = 60.0 / enemy_spawn_rate
	enemy_spawn_rate = 5
	enemyspawntimer.start()
	
	player.current_possessing_node = spawn_enemy(Vector2(128, 75), Enemy.ENEMY_TYPES.BASIC)
	
	$HUD/deathlabel.hide()
	
	dodger_amount = 0
	
	Globals.points = 0
	pointslabel.show()
	
	if player.current_possessing_node != null:
		player.current_possessing_node.is_player_controlling = true
		player.current_possessing_node.target = enemy_target
	
	weaponlabel.text = player.current_possessing_node.weapon_type
	
	has_game_started = true


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("restart") and Globals.dead:
		Globals.dead = false
		animation_player.play("start")
		return


func _process(delta: float) -> void:
	if enemies.get_child_count() < 2 and !Globals.dead and has_game_started:
		spawn_enemy()
	if Input.is_action_just_pressed("elevate") and !Globals.dead:
		Globals.elevated = true
		enemyspawntimer.paused = true
		for e in enemies.get_children():
			e.is_player_controlling = false
	elif Input.is_action_just_released("elevate"):
		possesstext.modulate.a = 1
		Globals.elevated = false
		enemyspawntimer.paused = false
		for e in enemies.get_children():
				e.is_player_controlling = false
		if player.current_hovering_enemy != null:
			player.current_hovering_enemy.is_player_controlling = true
			player.current_possessing_node = player.current_hovering_enemy
			SignalBus.emit_signal("possess")
		elif player.current_possessing_node != null:
			player.current_possessing_node.is_player_controlling = true
		if player.current_possessing_node != null:
			weaponlabel.text = player.current_possessing_node.weapon_type
	
	if Input.is_action_pressed("elevate") and !Globals.dead:
		overlay.modulate.a = lerp(overlay.modulate.a, 1, 8.0 * delta)
		Globals.speed_scale = lerp(Globals.speed_scale, 0.2, 8.0 * delta)
		music.volume_db = -80
		elevatedmusic.volume_db = 0
		if player.current_hovering_enemy != null:
			suboverlay.start_color = lerp(
				suboverlay.start_color,
				player.current_hovering_enemy.color,
				10.0 * delta
			)
			weaponlabel.text = player.current_hovering_enemy.weapon_type
		else:
			suboverlay.start_color = lerp(
				suboverlay.start_color,
				Color(0.988235, 0.27451, 0.27451),
				10.0 * delta
			)
			weaponlabel.text = ""
	else:
		possesstext.modulate.a = lerp(possesstext.modulate.a, 0, 8.0 * delta)
		overlay.modulate.a = lerp(overlay.modulate.a, 0, 10.0 * delta)
		Globals.speed_scale = lerp(Globals.speed_scale, 1, 10.0 * delta)
		music.volume_db = 0
		elevatedmusic.volume_db = -80


func _on_shoot_bullet(from: Vector2, speed: int, target: Vector2, collision_mask: int, color: Color = Color(1, 0.658824, 0.172549), is_player: bool = false) -> void:
	var b = BULLET.instance()
	b.global_position = from
	bullets.add_child(b)
	b.shoot(speed, target, collision_mask, color)


func _on_throw_grenade(from: Vector2, target: Vector2, collision_mask: int, color: Color = Color(1, 0.658824, 0.172549)) -> void:
	var g = GRENADE.instance()
	g.global_position = from
	bullets.add_child(g)
	g.throw(target, collision_mask, color)


func _on_player_die(node: Node) -> void:
	player.current_possessing_node = null
	node.queue_free()
	enemyspawntimer.stop()
	for e in enemies.get_children():
		e.queue_free()
	for b in bullets.get_children():
		b.queue_free()
	$HUD/deathlabel.show()
	
	if Globals.points > Globals.highscore:
		Globals.highscore = Globals.points
	scorelabel.text = "Score: " + str(Globals.points)
	highscorelabel.text = "Highscore: " + str(Globals.highscore)
	weaponlabel.text = ""
	pointslabel.hide()
	
	Globals.points = 0
	Globals.dead = true
	has_game_started = false


func _on_enemy_die(enemy_type: int) -> void:
	if enemy_type == Enemy.ENEMY_TYPES.DODGER:
		dodger_amount -= 1


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
	enemy.connect("throw_grenade", self, "_on_throw_grenade")
	enemy.connect("player_die", self, "_on_player_die")
	enemy.connect("enemy_die", self, "_on_enemy_die")
	if enemy_type == -1:
		enemy_type = rng.randi_range(0, 2 if dodger_amount < 2 else 1)
	if enemy_type == Enemy.ENEMY_TYPES.DODGER:
		dodger_amount += 1
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


func _on_treetimer_timeout() -> void:
	var tree = TREE.instance()
	bullets.add_child(tree)
	tree.global_position = Vector2(
		rng.randi_range(20, 236), 
		rng.randi_range(20, 130)
	)
