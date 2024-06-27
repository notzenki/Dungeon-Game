extends Area2D

@onready var hitbox_shape = $hitbox_shape
@onready var player_knight = $".."



# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	dodging()

func dodging():
	if player_knight.is_dodging:
		hitbox_shape.disabled = true
		#print("iframe")
	else:
		hitbox_shape.disabled = false
