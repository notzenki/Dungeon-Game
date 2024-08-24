extends Node2D

@onready var potion_hitbox = $potion_hitbox
@onready var delete_timer = $delete_timer


var potion_health = 10

func heal_damage():
	for area in potion_hitbox.get_overlapping_areas():
			var parent = area.get_parent()
			if parent is Player:
				parent.receive_healing(potion_health)
				print(parent.player_health)
				delete_timer.start()

func _on_potion_hitbox_body_entered(body):
	if body is Player:
		heal_damage()

func _on_delete_timer_timeout():
	queue_free()
