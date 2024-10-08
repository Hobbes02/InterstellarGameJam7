extends Node


var speed_scale: float = 1
var elevated: bool = false


var dead: bool = false

var points: int = 0
var highscore: int = 0

var music_muted: bool = false
var sfx_muted: bool = false


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("mute_music"):
		music_muted = !music_muted
		AudioServer.set_bus_mute(2, music_muted)
	if event.is_action_pressed("mute_sfx"):
		sfx_muted = !sfx_muted
		AudioServer.set_bus_mute(1, sfx_muted)
