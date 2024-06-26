extends CharacterBody2D

class_name Player

const SPEED = 250

@onready var animated_sprite = $AnimatedSprite2D
@onready var player_collition = $player_collition
@onready var player_hitbox = $player_hitbox
@onready var player_hurtbox = $player_hurtbox
@onready var timer = $Timer
@onready var take_damage_cooldown = $take_damage_cooldown
@onready var attack_animation = $attack_animation_timer

enum PlayerState {IDLE, RUN, DODGE, DEAD, HIT, ATTACK}
var current_state: PlayerState = PlayerState.IDLE
var input = Vector2.ZERO

# Dodge Variables
var dodge_speed: float = 500.0
var dodge_duration: float = 0.5
var dodge_cooldown: float = 0.5
var is_dodging: bool = false
var dodge_timer: float = 0.0
var dodge_cooldown_timer: float = 0.0
var dodge_direction: Vector2 = Vector2.ZERO

# Combat Variables
var enemy_in_attack_range = false
var enemy_attack_cooldown = true
var health = 100
var armor = 0
var buffs = 0
var player_damage = 5
var player_alive = true
var is_attacking = false

#Signals
signal attack_started
signal attack_ended
signal player_died



# Death Animation Flag
var has_played_death_animation: bool = false

func _ready():
	current_state = PlayerState.IDLE

func _physics_process(delta):
	get_input()
	if player_alive:
		handle_dodge(delta)
		handle_attack()
		update_velocity()
	else:
		if not has_played_death_animation:
			play_death_animation()
	play_animation()
	player_death()
	move_and_slide()

# State Animations
func play_animation():
	match current_state:
		PlayerState.IDLE:
			animated_sprite.play("idle")
		PlayerState.RUN:
			animated_sprite.play("run")
		PlayerState.DEAD:
			if not has_played_death_animation:
				animated_sprite.play("dead")
				has_played_death_animation = true
		PlayerState.HIT:
			animated_sprite.play("hit")
		PlayerState.ATTACK:
			animated_sprite.play("attack")
		PlayerState.DODGE:
			animated_sprite.play("roll")
		_:
			animated_sprite.play("idle")

#Movement Input
func get_input():
	input = Input.get_vector("move_left", "move_right", "move_up", "move_down").normalized()

func update_velocity():
	if is_dodging:
		velocity = dodge_direction * dodge_speed
	elif is_attacking:
		current_state = PlayerState.ATTACK
		velocity = Vector2.ZERO
	else:
		velocity = input * SPEED if input != Vector2.ZERO else Vector2.ZERO
		update_sprite_direction()
		update_player_state()

func update_sprite_direction():
	if input.x != 0:
		animated_sprite.flip_h = input.x < 0
		player_collition.position.x = 4 if input.x < 0 else -4
		player_hurtbox.scale.x = -1 if input.x < 0 else 1
		player_hitbox.scale.x = -1 if input.x < 0 else 1

func update_player_state():
	current_state = PlayerState.RUN if velocity.length() > 0 else PlayerState.IDLE

func handle_dodge(delta):
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
	current_state = PlayerState.DODGE
	dodge_timer = dodge_duration
	dodge_cooldown_timer = dodge_cooldown
	dodge_direction = input
	set_collision_mask_value(2, 0)

func end_dodge():
	is_dodging = false
	velocity = Vector2.ZERO
	current_state = PlayerState.IDLE
	set_collision_mask_value(2, 1)

func handle_attack():
	if Input.is_action_just_pressed("attack") and not is_attacking:
		start_attack()

func start_attack():
	is_attacking = true
	current_state = PlayerState.ATTACK
	attack_animation.start()
	for area in player_hurtbox.get_overlapping_areas():
		var parent = area.get_parent()
		if parent is Enemy:
			parent.receive_damage(calculate_total_damage())
			print(parent.enemy_health)

func end_attack():
	is_attacking = false

func _on_attack_animation_timer_timeout():
	end_attack()

func play_death_animation():
	current_state = PlayerState.DEAD
	play_animation()

func player_death():
	if health <= 0 and player_alive:
		player_alive = false
		health = 0
		print("player has died")
		emit_signal("player_died")

func calculate_total_damage() -> int:
	var total_damage = player_damage
	for buff in buffs:
		total_damage += buff.damage_bonus
	return total_damage





func _on_take_damage_cooldown_timeout():
	enemy_attack_cooldown = true

func _on_player_hitbox_body_entered(body):
	if body.has_method("enemy"):
		enemy_in_attack_range = true

func _on_player_hitbox_body_exited(body):
	if body.has_method("enemy"):
		enemy_in_attack_range = false



