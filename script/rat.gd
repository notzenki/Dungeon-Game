extends CharacterBody2D

class_name Enemy

const SPEED = 50.0

@onready var animated_sprite = $AnimatedSprite2D
@onready var enemy_hurtbox = $enemy_hurtbox
@onready var attack_cooldown = $attack_cooldown




enum enemy_state {IDLE, RUN, DEAD, HIT, ATTACK}
var current_state = enemy_state

var player_chase = false
var player_entity = null

#Combat Variables
var enemy_health = 20
var enemy_armor = 2
var enemy_damage = 2
var enemy_buff = 0
var enemy_alive = true
var player_in_attack_zone = false
var is_attacking = false



func _ready():
	pass

func _physics_process(delta):
	
	#start_attack()
	play_animation()
	handle_movement(delta)

func handle_movement(delta):
	
	if !enemy_alive:
		current_state = enemy_state.DEAD
		#animated_sprite.set_frame_and_progress(5,5)
		velocity = Vector2.ZERO
		
		
		
	else:
	
		if player_chase:
			position += (player_entity.position - position) / SPEED
			current_state = enemy_state.RUN
		
#Sprite Flip
			if (player_entity.position.x - position.x) > 0:
				animated_sprite.flip_h = false
				enemy_hurtbox.scale.x = 1
			elif (player_entity.position.x - position.x) < 0:
				animated_sprite.flip_h = true
				enemy_hurtbox.scale.x = -1

func _on_detection_area_body_entered(body):
	player_entity = body
	player_chase = true
	


func _on_detection_area_body_exited(body):
	player_entity = null
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

func start_attack():
	is_attacking = true
	global.enemy_current_attack = true
	current_state = enemy_state.ATTACK
	attack_cooldown.start()
	for area in enemy_hurtbox.get_overlapping_areas():
		var parent = area.get_parent()
		if parent is Player: #and attack_cooldown.time_left <= 0:
			parent.health -= enemy_damage
			print(parent.health)

func end_attack():
	global.enemy_current_attack = false
	is_attacking = false

func _on_attack_cooldown_timeout():
	end_attack()

func receive_damage(damage:int):
	var effective_damage = calculate_effective_damage(damage)
	enemy_health -= effective_damage
	if enemy_health <= 0:
		death()


func calculate_effective_damage(damage:int) -> int:
	var effective_damage = damage - enemy_armor
	return max(effective_damage, 0)  # Ensures damage is not negative

func death():
	enemy_alive = false
	enemy_health = 0
	print("enemy has died")






