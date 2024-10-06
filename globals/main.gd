extends Control

export(String) var start_scene = ""

var current_scene_node: Node = null

onready var viewport: Viewport = $ViewportContainer/Viewport
onready var fpslabel: Label = $debug/fpslabel
onready var debug: Control = $debug


func _ready() -> void:
	SceneManager.connect("change_scene", self, "_on_change_scene_requested")
	_on_change_scene_requested(start_scene)
	Engine.target_fps = 120


func _process(_delta: float) -> void:
	fpslabel.text = str(Engine.get_frames_per_second())
	if viewport.is_inside_tree():
		SceneManager.mouse_position = (get_global_mouse_position() / 4) - viewport.canvas_transform.origin


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("debug"):
		debug.visible = !debug.visible


func _on_change_scene_requested(scene_path: String) -> void:
	if current_scene_node != null:
		current_scene_node.queue_free()
		current_scene_node = null
	
	current_scene_node = load(scene_path).instance()
	viewport.call_deferred("add_child", current_scene_node)
