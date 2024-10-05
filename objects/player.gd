extends KinematicBody2D

var player_speed: int = 50

var velocity: Vector2

var current_hovering_enemy: Node = null

export(NodePath) var _current_possessing_node

onready var current_possessing_node: Node = get_node(_current_possessing_node)
onready var area: Area2D = $Area2D


func _physics_process(_delta: float) -> void:
	if current_hovering_enemy != null:
		current_hovering_enemy.selected.show()
	
	if !Globals.elevated:
		hide()
		if current_possessing_node.is_inside_tree():
			global_position = current_possessing_node.global_position
		return
	show()
	
	var input_vector: Vector2 = Vector2.ZERO
	input_vector.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	input_vector.y = Input.get_action_strength("down") - Input.get_action_strength("up")
	
	if input_vector == Vector2.ZERO:
		velocity = lerp(velocity, Vector2.ZERO, 0.5)
	else:
		velocity = input_vector.normalized() * player_speed
	
	move_and_slide(velocity)


func _on_Area2D_body_entered(body: Node) -> void:
	if !Globals.elevated:
		return
	current_hovering_enemy = body
	
	for b in area.get_overlapping_bodies():
		if b != body:
			b.selected.hide()


func _on_Area2D_body_exited(body: Node) -> void:
	current_hovering_enemy = null
	body.selected.hide()
