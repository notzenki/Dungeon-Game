extends CharacterBody2D


const SPEED = 50.0

@onready var animated_sprite = $AnimatedSprite2D

enum enemy_state {IDLE, RUN, DEAD, HIT, ATTACK}
var current_state = enemy_state

var player_chase = false
var player = null

#Combat Variables
var health = 20
var player_in_attack_zone = false



func _ready():
	pass

func _physics_process(delta):
	
	damage_received()
	play_animation()
	handle_movement(delta)

func handle_movement(delta):
	if player_chase:
		position += (player.position - position) / SPEED
		current_state = enemy_state.RUN
		
#Sprite Flip
		if (player.position.x - position.x) > 0:
			animated_sprite.flip_h = false
		elif (player.position.x - position.x) < 0:
			animated_sprite.flip_h = true

func _on_detection_area_body_entered(body):
	player = body
	player_chase = true
	


func _on_detection_area_body_exited(body):
	player = null
	player_chase = false
	current_state = enemy_state.IDLE

func play_animation():
	match current_state:
		enemy_state.IDLE:
			animated_sprite.play("idle")
		enemy_state.RUN:
			animated_sprite.play("walk")
		enemy_state.DEAD:
			animated_sprite.play("dead")
		enemy_state.HIT:
			animated_sprite.play("hit")
		enemy_state.ATTACK:
			animated_sprite.play("attack")
		_:
			animated_sprite.play("idle")



#Handle Combat

func enemy():
	pass



func _on_enemy_hitbox_body_entered(body):
	if body.has_method("player"):
		player_in_attack_zone = true


func _on_enemy_hitbox_body_exited(body):
	if body.has_method("player"):
		player_in_attack_zone = false 

func damage_received():
	if player_in_attack_zone and global.player_current_attack == true:
		health = health - 10
		print("slime health = ", health)
		if health <= 0:
			self.queue_free()
