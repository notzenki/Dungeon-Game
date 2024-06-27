extends CharacterBody2D

class_name Enemy

const SPEED = 50.0

@onready var animated_sprite = $AnimatedSprite2D
@onready var enemy_hurtbox = $enemy_hurtbox
@onready var attack_animation = $attack_animation_timer
@onready var attack_damage_cooldown = $attack_damage_cooldown
@onready var hit_animation = $hit_animation_timer



enum EnemyState {IDLE, RUN, DEAD, HIT, ATTACK}
var current_state: EnemyState = EnemyState.IDLE

var player_chase = false
var player_entity = null

#Combat Variables
var enemy_health = 20
var enemy_armor = 2
var enemy_damage = 2
var enemy_buffs = []
var enemy_alive = true
var player_in_attack_range = false
var is_attacking = false
var enemy_can_attack = true

# Death Animation Flag
var has_played_death_animation: bool = false


func _ready():
	pass

func _physics_process(delta):
	if enemy_alive:
		handle_movement(delta)
		handle_attack()
	else:
		if not has_played_death_animation:
			play_death_animation()
	play_animation()
	move_and_slide()

func handle_movement(delta):
	if player_chase and current_state != EnemyState.ATTACK and current_state != EnemyState.HIT:
		position += ((player_entity.position - position) / SPEED)
		current_state = EnemyState.RUN

#Sprite Flip
		if (player_entity.position.x - position.x) > 0:
			animated_sprite.flip_h = false
			enemy_hurtbox.scale.x = 1
		elif (player_entity.position.x - position.x) < 0:
			animated_sprite.flip_h = true
			enemy_hurtbox.scale.x = -1

func _on_detection_area_body_entered(body):
	if body is Player:
		player_entity = body
		player_chase = true
	

func _on_detection_area_body_exited(body):
	if body is Player:
		player_entity = null
		player_chase = false
		if enemy_alive:
			current_state = EnemyState.IDLE

func play_animation():
	match current_state:
		EnemyState.IDLE:
			animated_sprite.play("idle")
		EnemyState.RUN:
			animated_sprite.play("walk")
		EnemyState.DEAD:
			if not has_played_death_animation:
				animated_sprite.play("dead")
				has_played_death_animation = true
		EnemyState.HIT:
			animated_sprite.play("hit")
		EnemyState.ATTACK:
			animated_sprite.play("attack")
		_:
			animated_sprite.play("idle")



#Handle Combat

func handle_attack():
	if player_in_attack_range and enemy_can_attack and not is_attacking:
		start_attack()
		current_state = EnemyState.ATTACK

func _on_enemy_hurtbox_body_entered(body):
	if body is Player:
		player_in_attack_range = true


func _on_enemy_hurtbox_body_exited(body):
	if body is Player:
		player_in_attack_range = false

func start_attack():
	if enemy_can_attack:
		is_attacking = true
		attack_animation.start()
		attack_damage_cooldown.start()
		enemy_can_attack = false
		for area in enemy_hurtbox.get_overlapping_areas():
			var parent = area.get_parent()
			if parent is Player:
				parent.receive_damage(calculate_total_damage())
				print(parent.player_health)

func calculate_total_damage() -> int:
	var total_damage = enemy_damage
	for buff in enemy_buffs:
		total_damage += buff.damage_bonus
	return total_damage

func end_attack():
	is_attacking = false
	if enemy_alive:
		current_state = EnemyState.IDLE

func _on_attack_damage_cooldown_timeout():
	enemy_can_attack = true

func _on_attack_animation_timer_timeout():
	end_attack()
	current_state = EnemyState.IDLE

func receive_damage(damage:int):
	var effective_damage = calculate_effective_damage(damage)
	enemy_health -= effective_damage
	if enemy_alive:
		current_state = EnemyState.HIT
		hit_animation.start()
	if enemy_health <= 0:
		death()

func _on_hit_animation_timer_timeout():
	if enemy_alive:
		current_state = EnemyState.IDLE

func calculate_effective_damage(damage:int) -> int:
	var effective_damage = damage - enemy_armor
	return max(effective_damage, 0)  # Ensures damage is not negative

func death():
	enemy_alive = false
	enemy_health = 0
	print("enemy has died")
	

func play_death_animation():
	current_state = EnemyState.DEAD
	play_animation()







