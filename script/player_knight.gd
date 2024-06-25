extends CharacterBody2D

class_name Player

const SPEED = 250

@onready var animated_sprite = $AnimatedSprite2D
@onready var player_collition = $player_collition
@onready var player_hitbox = $player_hitbox
@onready var player_hurtbox = $player_hurtbox
@onready var timer = $Timer
@onready var take_damage_cooldown = $take_damage_cooldown
@onready var attack_cooldown = $attack_cooldown





enum player_state {IDLE, RUN, DODGE, DEAD, HIT, ATTACK}
var current_state: player_state
var can_dodge: bool = true
var input = Vector2.ZERO

#Dodge Variables
var dodge_speed: float = 500.0
var dodge_duration: float = 0.5
var dodge_cooldown: float = 0.5
var is_dodging: bool = false
var dodge_timer: float = 0.0
var dodge_cooldown_timer: float = 0.0
var dodge_direction: Vector2 = Vector2.ZERO

#Combat Variables
var enemy_in_attack_range = false
var enemy_attack_cooldown = true
var health = 100
var player_alive = true
var is_attacking = false
var damage = 2



func _ready():
	current_state = player_state.IDLE

func _physics_process(delta):
	
	get_input()
	handle_dodge(delta)
	player_movement(delta)
	handle_attack()
	play_animation()
	enemy_attack()
	player_death()
	move_and_slide()
	
#Inputs for movement
func get_input():
	input = Input.get_vector("move_left", "move_right", "move_up", "move_down").normalized()
	
func player_movement(delta):

	if !player_alive:
		current_state = player_state.DEAD
		animated_sprite.pause()
	else:
#Dodging
		if is_dodging:
			velocity = dodge_direction * dodge_speed
		else:
#Movement
			if input == Vector2.ZERO:
				velocity = Vector2.ZERO
			else:
				velocity = input * SPEED
#Attack
			if is_attacking:
				current_state = player_state.ATTACK
			else:
	
#Flip the sprite
				if input.x > 0:
					animated_sprite.flip_h = false
					player_collition.position.x = -4
					player_hurtbox.scale.x = 1
					player_hitbox.scale.x = 1
				elif input.x < 0:
					animated_sprite.flip_h = true
					player_collition.position.x = 4
					player_hurtbox.scale.x = -1
					player_hitbox.scale.x = -1
		
	#Character Animations
				if velocity.length() > 0.0 :
					current_state = player_state.RUN
				else:
					current_state = player_state.IDLE
	
	
func  handle_dodge(delta):
	if Input.is_action_just_pressed("dodge") and dodge_cooldown_timer <= 0.0 and input != Vector2.ZERO:
		start_dodge()
		
	if is_dodging:
		dodge_timer -= delta
		if dodge_timer <= 0.0:
			end_dodge()
	else:
		dodge_cooldown_timer = max(dodge_cooldown_timer - delta, 0)
	
	
func start_dodge():
	is_dodging = true
	current_state = player_state.DODGE
	dodge_timer = dodge_duration
	dodge_cooldown_timer = dodge_cooldown
	dodge_direction = input
	set_collision_mask_value(2,0)
	
func end_dodge():
	is_dodging = false
	velocity = Vector2.ZERO
	current_state = player_state.IDLE
	set_collision_mask_value(2,1)
	
	
func play_animation():
	match current_state:
		player_state.IDLE:
			animated_sprite.play("idle")
		player_state.RUN:
			animated_sprite.play("run")
		player_state.DEAD:
			animated_sprite.play("dead")
		player_state.HIT:
			animated_sprite.play("hit")
		player_state.ATTACK:
			animated_sprite.play("attack")
		player_state.DODGE:
			animated_sprite.play("roll")
		_:
			animated_sprite.play("idle")


#Handle Combat

func player():
	pass

#Player Attack
func handle_attack():
	if Input.is_action_just_pressed("attack") and !is_attacking:
		start_attack()

func start_attack():
	var overlapping_objects = player_hurtbox.get_overlapping_areas()
	
	for area in overlapping_objects:
		var parent = area.get_parent()
		if parent.has_method("enemy"):
			parent.health -= damage
			print(parent.health)
	
	global.player_current_attack = true
	is_attacking = true
	attack_cooldown.start()

func end_attack():
	global.player_current_attack = false
	is_attacking = false

func _on_attack_cooldown_timeout():
	end_attack()




func player_death():
	if health <= 0:
		player_alive = false
		health = 0
		print("player has died")





func _on_take_damage_cooldown_timeout():
	enemy_attack_cooldown = true


func _on_player_hitbox_body_entered(body):
	if body.has_method("enemy"):
		enemy_in_attack_range = true
	
	pass

func _on_player_hitbox_body_exited(body):
	if body.has_method("enemy"):
		enemy_in_attack_range = false
		
	pass
	
func enemy_attack():
	if enemy_in_attack_range and enemy_attack_cooldown == true:
		health = health - 25
		enemy_attack_cooldown = false
		take_damage_cooldown.start()
		print(health)
	pass


	
