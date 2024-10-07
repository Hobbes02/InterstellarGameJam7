extends StaticBody2D

onready var deathparticles: CPUParticles2D = $deathparticles
onready var trunk: Polygon2D = $trunk
onready var tree: Polygon2D = $tree
onready var collisions: CollisionPolygon2D = $CollisionPolygon2D


func take_damage() -> void:
	collisions.set_deferred("disabled", true)
	trunk.hide()
	tree.hide()
	deathparticles.emitting = true
	Globals.points += 50
	get_tree().create_timer(1.8).connect("timeout", self, "_on_death")


func _on_death() -> void:
	queue_free()
