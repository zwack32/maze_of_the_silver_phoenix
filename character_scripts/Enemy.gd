extends CharacterBody2D
class_name Enemy

@export var room_battle_instance: RoomBattleInstance
@export var indicator_border: IndicatorBorder
@export var player: Player
@export var room_level: int

var enemy_particles = preload("res://scenes/enemy_particles.tscn")

var is_dead = false
var is_active = false
var is_burning = false
var is_frozen = false
var is_glowing = false
var indicator_id

@export var spawn_delay: float
@export var spawn_delay_rand_range: float

@export var burn_duration: float = 5.0
@export var burn_tick_duration: float = 1.0
@export var freeze_duration: float = 10.0

var enemy_max_health
var enemy_atk
var enemy_def
var enemy_health
var enemy_speed

var idle_animation_name
var die_animation_name
var crumble_animation_name

var enemy_die_callback: Callable

var animated_sprite_2d: AnimatedSprite2D
var health_bar: ProgressBar

var spawned_particles: Array[EnemyParticles] = []

enum EnemyElemental {
	Normal,
	Fire,
	Ice,
	_Count,
}

func on_enemy_ready():
	enemy_atk += randi_range((-1 + roundf(room_level/2)), (2+room_level))
	enemy_def += randi_range((-1 + roundf(room_level/2)), (2+room_level))
	enemy_health += randi_range((-2 + roundf(room_level/2)), 5+(2*room_level))
	
	health_bar.max_value = enemy_max_health

	var elemental_type = EnemyElemental.Normal
	if room_level >= 3:
		elemental_type = randi_range(-1, EnemyElemental._Count)
		if elemental_type == -1:
			elemental_type = EnemyElemental.Normal

	var tween = get_tree().create_tween()
	animated_sprite_2d.modulate = Color(1.0, 1.0, 1.0, 0.0)
	tween.tween_property(animated_sprite_2d, "modulate", Color(1.0, 1.0, 1.0, 1.0), spawn_delay)
	
	var original_layer = collision_layer
	var original_mask = collision_mask
	
	collision_layer = 0
	collision_mask = 0
	
	animated_sprite_2d.play(idle_animation_name)
	await get_tree().create_timer(spawn_delay).timeout
	is_active = true
	collision_layer = original_layer
	collision_mask = original_mask
	indicator_id = indicator_border.enable_indicator()	
	await get_tree().create_timer(randf_range(0.0, spawn_delay_rand_range)).timeout
	
func on_enemy_process() -> bool:
	if !is_active || is_dead:
		return false
		
	health_bar.value = enemy_health
	
	move_and_slide()
	
	if indicator_id != null:
		indicator_border.set_indicator_position(indicator_id, self)
	
	return true

func enemy_take_damage(player_atk,enemy_def,enemy_health, sword_str, area):
	var dmg = clamp(clamp(player_atk+sword_str-enemy_def, 0, 9999999)+sword_str, 0, 9999999)
	
	if !is_glowing or is_glowing and !area.type=="glow":
		enemy_health -= dmg
	if area.type == "glow" and is_glowing:
		enemy_health -= dmg * 2
	
	if enemy_health <= 0:
		enemy_health = 0
		health_bar.hide()
		on_enemy_die()
	health_bar.value = enemy_health
	print("Enemy takes " + str(dmg) + " damage and has " + str(enemy_health) + " hp left")
	return enemy_health

func on_enemy_die():
	if is_dead:
		return
		
	for particles in spawned_particles:
		particles.stop()
		
	indicator_border.disable_indicator(indicator_id)
	
	if enemy_die_callback:
		enemy_die_callback.call()
		
	is_dead = true
	velocity = Vector2.ZERO
	animated_sprite_2d.play(die_animation_name)
	is_burning = false
	is_frozen = false
	room_battle_instance.pop_enemy()
	
	await get_tree().create_timer(15.0).timeout
	animated_sprite_2d.play(crumble_animation_name)
	collision_layer = 0
	collision_mask = 0
	# STUB: Remove this gross hardcoded time
	await get_tree().create_timer(3).timeout
	queue_free()

func on_enemy_area_entered(area):
	if !is_active:
		return
		
	if area is MeleeWeapon:
		#enemy takes damage
		enemy_health = enemy_take_damage(player.get_player_atk(), enemy_def, enemy_health, area.str, area)
		if area.type == "fire":
			on_burn()
		if area.type == "ice":
			on_freeze()
		if area.type == "glow":
			on_glow()
	elif area.owner is Player:
		#player takes damage
		player.take_damage(enemy_atk)
		player.bounce_towards((player.position - position).normalized())
	elif area is Tome:
		#enemy takes damage
		enemy_health = enemy_take_damage(player.get_player_atk(), enemy_def, enemy_health, area.str, area)
		if area.type == "fire":
			on_burn()
		if area.type == "ice":
			on_freeze()
		if area.type == "glow":
			on_glow()
			
func on_burn():
	if is_burning:
		return
	is_burning = true
	var particles = enemy_particles.instantiate()
	particles.play_burn()
	spawned_particles.push_back(particles)
	add_child(particles)
	var total_burn_time = 0

	while total_burn_time < burn_duration:
		set_enemy_health(enemy_health - 2)
		total_burn_time += burn_tick_duration
		await get_tree().create_timer(burn_tick_duration).timeout
		
	is_burning = false
	particles.stop()
	
func on_freeze():
	if is_frozen:
		return
	is_frozen = true
	var particles = enemy_particles.instantiate()
	particles.play_freeze()
	spawned_particles.push_back(particles)
	add_child(particles)
	enemy_speed /= 2
	await get_tree().create_timer(freeze_duration).timeout
	enemy_speed *= 2
	is_frozen = false
	particles.stop()

func on_glow():
	var particles = enemy_particles.instantiate()
	particles.play_glow()
	spawned_particles.push_back(particles)
	add_child(particles)
	is_glowing = true

func get_enemy_atk():
	return enemy_atk

func get_enemy_def():
	return enemy_def

func get_enemy_max_hp():
	return enemy_max_health

func set_enemy_health(val: float):
	enemy_health = clamp(val, 0, 999999)
	health_bar.value = enemy_health

func get_enemy_health():
	return enemy_health

