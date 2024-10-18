extends Label

var previous_points: int = Globals.points
var current_visible_points: int = Globals.points

onready var ticktimer: Timer = $ticktimer


func _process(delta: float) -> void:
	if Globals.points != previous_points:
		if Globals.points == 0:
			current_visible_points = Globals.points
		else:
			ticktimer.start()
	
	previous_points = Globals.points
	text = str(current_visible_points)


func _on_ticktimer_timeout() -> void:
	current_visible_points += 1
	if current_visible_points >= Globals.points:
		ticktimer.stop()
