extends Enemy
class_name Bat

@export var speed: float = 500.0

#velocity = Vector2.ZERO

@onready var death_timer = $DeathTimer
@onready var attack_timer = $AttackTimer
@onready var fire_tick_timer = $FireTickTimer
@onready var frozen_timer = $FrozenTimer
@onready var sprite = $Sprite2D

var enemy_max_health = 20
var enemy_atk = 7
var enemy_def = 3

var enemy_health

@onready var bat_health_bar = $BatHealthBar

var dead = false

var on_fire = false
var frozen = true
var frozen_process = false

#annoying functions so that we can use these in other scripts
func get_enemy_atk():
	return enemy_atk
func get_enemy_def():
	return enemy_def
func get_enemy_max_hp():
	return enemy_max_health
func get_enemy_health():
	return enemy_health

func _ready():
	bat_health_bar.max_value = enemy_max_health
	fire_tick_timer.start()
	sprite.texture = load("res://icon.svg")
	enemy_health = enemy_max_health
	#randomize stats
	enemy_atk += randi_range((-1 + roundf(room_level/2)), (2+room_level))
	enemy_def += randi_range((-1 + roundf(room_level/2)), (2+room_level))
	enemy_health += randi_range((-2 + roundf(room_level/2)), 5+(2*room_level))
	
	collision_layer |= 0
	
	#if on room 3 or higher, start adding elemental enemies
	var type = "normal"
	if room_level >= 3:
		var type_determiner = randi_range(1, 4)
		if type_determiner == 1 or 2:
			type = "normal"
		elif type_determiner == 3:
			type = "fire"
			#load red godot icon here
		elif type_determiner == 4:
			type = "ice"
			#load cyan godot logo here
	
	print(str(enemy_atk) + "atk")
	print(str(enemy_def) + "def")
	print(str(enemy_health) + "health")
	
	attack_timer.start()

#Move toward player
func _process(delta):
	if !dead:
		if attack_timer.time_left <= 0:
			var direction = (player.position - position).normalized()
			velocity = direction * speed
			check_attack_timer()
			if check_attack_timer():
				await get_tree().create_timer(2).timeout
			
			attack_timer.start()
	if death_timer.time_left <= 0 and dead:
		queue_free()
	position += velocity * delta
	
	bat_health_bar.value = enemy_health
	#print(attack_timer.time_left)
	if on_fire:
		if fire_tick_timer.time_left == 0:
			enemy_health -= 2
			print(enemy_health)
			fire_tick_timer.start()
		if enemy_health <= 0:
			enemy_health = 0
			bat_health_bar.hide()
			enemy_die()
	
	if frozen:
		frozen_timer.start()
		frozen = false
		frozen_process = true
		speed /= 2
	
	if frozen_process and frozen_timer.time_left == 0:
		frozen_process = false
		speed *= 2
	

func check_attack_timer():
	if attack_timer.timeout:
		return true
		velocity = Vector2.ZERO
	else:
		return false


#differentiate between player hitting enemy and enemy hitting player
func _on_area_entered(area):
	if !dead:
		if area is MeleeWeapon:
			#enemy takes damage
			enemy_health = enemy_take_damage(player.get_player_atk(), enemy_def, enemy_health, area.str)
			velocity = Vector2.ZERO
			print("enemy take damage")
		elif area.owner is Player:
			#player takes damage
			player.take_damage(enemy_atk)
			print("player take damage")
		elif area is Tome:
			enemy_health = enemy_take_damage(player.get_player_atk(), enemy_def, enemy_health, area.str)
	

func enemy_take_damage(player_atk,enemy_def,enemy_health, sword_str):
	var dmg = (clamp(player_atk+sword_str-enemy_def, 0, 9999999))+sword_str
	enemy_health -= dmg
	if enemy_health <= 0:
		enemy_health = 0
		bat_health_bar.hide()
		enemy_die()
	bat_health_bar.value = enemy_health
	print("Enemy takes " + str(dmg) + " damage and has " + str(enemy_health) + " hp left")
	return enemy_health

func enemy_die():
	print("did you die again")
	dead = true
	velocity = Vector2.ZERO
	death_timer.start()
	collision_layer |= 2
	sprite.texture = load("res://art/rect1.svg")
	
	on_fire = false
	frozen = false


