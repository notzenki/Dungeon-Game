extends Node2D
@onready var enemy_container = $enemyContainer
@onready var hud = $CanvasLayer/HUD

var score := 0:
	set(value):
		score = value
		hud.score = score		


# Called when the node enters the scene tree for the first time.
func _ready():
	score =0
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	pass

func _on_enemy_container_child_exiting_tree(node):
	score +=1
