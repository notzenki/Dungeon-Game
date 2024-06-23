extends CharacterBody2D

const SPEED = 500

@onready var animated_sprite = $AnimatedSprite2D
@onready var timer = $Timer

enum player_state {IDLE, RUN, DODGE, DEAD, HIT, ATTACK}
var current_state: player_state
var can_dodge: bool = true
var input = Vector2.ZERO

#Dodge Variables
var dodge_speed: float = 800.0
var dodge_duration: float = 0.5
var dodge_cooldown: float = 0.5
var is_dodging: bool = false

var dodge_timer: float = 0.0
var cooldown_timer: float = 0.0
var dodge_direction: Vector2 = Vector2.ZERO


func _ready():
	current_state = player_state.IDLE

func _physics_process(delta):
	
	get_input()
	handle_dodge(delta)
	player_movement(delta)
	play_animation()
	move_and_slide()
	
#Inputs for movement
func get_input():
	input = Input.get_vector("move_left", "move_right", "move_up", "move_down").normalized()
	
func player_movement(delta):
#Dodging
	if is_dodging:
		velocity = dodge_direction * dodge_speed
	else:
#Movement
		if input == Vector2.ZERO:
			velocity = Vector2.ZERO
		else:
			velocity = input * SPEED
	
#Flip the sprite
		if input.x > 0:
			animated_sprite.flip_h = false
		elif input.x < 0:
			animated_sprite.flip_h = true
	
#Character Animations
		if velocity.length() > 0.0 :
			current_state = player_state.RUN
		else:
			current_state = player_state.IDLE
	
	
func  handle_dodge(delta):
	if Input.is_action_just_pressed("dodge") and cooldown_timer <= 0.0 and input != Vector2.ZERO:
		start_dodge()
		
	if is_dodging:
		dodge_timer -= delta
		if dodge_timer <= 0.0:
			end_dodge()
	else:
		cooldown_timer = max(cooldown_timer - delta, 0)
	
	
func start_dodge():
	is_dodging = true
	current_state = player_state.DODGE
	dodge_timer = dodge_duration
	cooldown_timer = dodge_cooldown
	dodge_direction = input
	
func end_dodge():
	is_dodging = false
	velocity = Vector2.ZERO
	current_state = player_state.IDLE
	
	
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
	
	
