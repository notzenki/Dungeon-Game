extends CharacterBody2D

class_name Enemy

const SPEED = 100.0

@onready var animated_sprite = $AnimatedSprite2D
@onready var enemy_hurtbox = $enemy_hurtbox
@onready var attack_animation = $attack_animation_timer
@onready var attack_damage_cooldown = $attack_damage_cooldown
@onready var hit_animation = $hit_animation_timer
@onready var healthbar = $Healthbar
@onready var death_timer = $death_timer



enum EnemyState {IDLE, RUN, DEAD, HIT, ATTACK}
var current_state: EnemyState = EnemyState.IDLE

var player_chase = false
var player_entity = null

#Combat Variables
var enemy_health = 20
var enemy_armor = 0
var enemy_damage = 5
var enemy_buffs = []
var enemy_alive = true
var player_in_attack_range = false
var is_attacking = false
var enemy_can_attack = true

# Death Animation Flag
var has_played_death_animation: bool = false


func _ready():
	pass
	healthbar.init_health(enemy_health)

func _physics_process(delta):
	if enemy_alive:
		handle_movement(delta)
		handle_attack()
	else:
		if not has_played_death_animation:
			play_death_animation()
	play_animation()
	move_and_slide()



#Handle Enemy Movement toward Player

func handle_movement(delta):
	var direction = get_direction_to_player()
	if player_chase and current_state != EnemyState.ATTACK and current_state != EnemyState.HIT:
	#if abs(direction.x) < 150 and abs(direction.y) < 150 and current_state != EnemyState.ATTACK and current_state != EnemyState.HIT:
		#position += ((player_entity.position - position) / SPEED)
		velocity = direction.normalized() * SPEED
		current_state = EnemyState.RUN
	else:
		velocity = Vector2.ZERO

	#Sprite Flip
		#if (player_entity.position.x - position.x) > 0:
			#animated_sprite.flip_h = false
			#enemy_hurtbox.scale.x = 1
		#elif (player_entity.position.x - position.x) < 0:
			#animated_sprite.flip_h = true
			#enemy_hurtbox.scale.x = -1
	if velocity.x != 0:
		animated_sprite.flip_h = velocity.x < 0
		enemy_hurtbox.scale.x = -1 if velocity.x < 0 else 1

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

func get_direction_to_player():
	var player_node = get_tree().get_first_node_in_group("player") as Node2D #Gets the player
	
	if player_node != null:      #If there's a player
		return (player_node.global_position - global_position)     #We get the position of the player minus our position and normalize it to get vector we can use
	return Vector2.ZERO



#Handle Enemy Animations

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
	#var player_dead = Player.connect("player_died", Player)
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
	
	if is_instance_valid(healthbar):
		healthbar.health = enemy_health  
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
	death_timer.start()

func _on_death_timer_timeout():
	queue_free()
