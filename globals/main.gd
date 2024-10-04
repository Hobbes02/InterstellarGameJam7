extends Control

export var start_scene = ""

var current_scene_node: Node = null

onready var viewport: Viewport = $ViewportContainer/Viewport


func _ready() -> void:
	SceneManager.connect("change_scene", self, "_on_change_scene_requested")
	_on_change_scene_requested(start_scene)


func _on_change_scene_requested(scene_path: String) -> void:
	if current_scene_node != null:
		current_scene_node.queue_free()
		current_scene_node = null
	
	current_scene_node = load(scene_path).instance()
	viewport.call_deferred("add_child", current_scene_node)
