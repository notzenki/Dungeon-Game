extends Label

@onready var counter = $counter

var enemy_counter = 0

func enemies_killed():
	enemy_counter += 1

func _process(delta):
	counter.text = str(enemy_counter)
