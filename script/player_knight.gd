extends CharacterBody2D

class_name Player

const SPEED = 250

@onready var animated_sprite = $AnimatedSprite2D
@onready var player_collition = $player_collition
@onready var player_hitbox = $player_hitbox
@onready var player_hurtbox = $player_hurtbox
@onready var take_damage_cooldown = $take_damage_cooldown
@onready var attack_animation = $attack_animation_timer
@onready var hit_animation_timer = $hit_animation_timer


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
var player_health = 100
var player_armor = 0
var player_buffs = [{"damage_bonus":2}]
var player_damage = 5
var player_alive = true
var is_attacking = false
var can_receive_damage = true

#Signals
signal attack_started
signal attack_ended
signal player_died

# Attack Animation Variables
var attack_animation_index: int = 0  # Keep track of which attack animation to use

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
			if attack_animation_index == 0:
				animated_sprite.play("attack")
			else:
				animated_sprite.play("attack_2")
		PlayerState.DODGE:
			animated_sprite.play("roll")
		_:
			animated_sprite.play("idle")

#Movement Input
func get_input():
	input = Input.get_vector("move_left", "move_right", "move_up", "move_down").normalized()

func update_velocity():
	if is_dodging and current_state != PlayerState.HIT:
		velocity = dodge_direction * dodge_speed
	elif is_attacking and current_state != PlayerState.HIT:
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
	if current_state == PlayerState.HIT:
		return
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
	attack_animation_index = (attack_animation_index + 1) % 2  # Alternate between 0 and 1
	for area in player_hurtbox.get_overlapping_areas():
		var parent = area.get_parent()
		if parent is Enemy:
			parent.receive_damage(calculate_total_damage())
			print(parent.enemy_health)

func calculate_total_damage() -> int:
	var total_damage = player_damage
	for buff in player_buffs:
		total_damage += buff.damage_bonus
	return total_damage

func end_attack():
	is_attacking = false

func _on_attack_animation_timer_timeout():
	end_attack()

func receive_damage(damage:int):
	var effective_damage = calculate_effective_damage(damage)
	if can_receive_damage:
		player_health -= effective_damage
		can_receive_damage = false
		take_damage_cooldown.start()
		current_state = PlayerState.HIT
		hit_animation_timer.start()
		if player_health <= 0:
			player_death()

func _on_hit_animation_timer_timeout():
	if player_alive:
		current_state = PlayerState.IDLE

func _on_take_damage_cooldown_timeout():
	if player_alive:
		can_receive_damage = true

func calculate_effective_damage(damage:int) -> int:
	var effective_damage = damage - player_armor
	return max(effective_damage, 0)  # Ensures damage is not negative

func player_death():
	if player_health <= 0 and player_alive:
		player_alive = false
		player_health = 0
		print("player has died")
		emit_signal("player_died")

func play_death_animation():
	current_state = PlayerState.DEAD
	play_animation()
