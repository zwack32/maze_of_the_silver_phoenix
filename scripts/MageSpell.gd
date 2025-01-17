extends Area2D

var str = 15
var velocity = Vector2.ZERO
var speed = 0.8
var type = "glow"
var entered_once = false
var spell_atk = 10

@export var mage: Mage
@export var player: Player

@export var cooldown = 4.0
@onready var bead_sprite = $BeadSprite
#@onready var cpu_particles_2d = $CPUParticles2D
@onready var spell_animation = $"Spell Animation"

# Called when the node enters the scene tree for the first time.
func _ready():
	position = mage.position
	velocity = (player.position - position) * speed
	bead_sprite.show()
	spell_animation.hide()
	
	await get_tree().create_timer(0.3).timeout

func _process(delta):
	position += velocity * delta
	set_collision_layer_value(1, 0)

func _on_area_entered(area):
	if !entered_once && area.owner is Player: 
		player.take_damage(spell_atk)
		entered_once = true
		scale = Vector2(4, 4)
		boom()

func _on_body_entered(body):
	boom()

func boom():
	bead_sprite.hide()
	spell_animation.show()
	spell_animation.play("mage_spell")
	velocity = Vector2.ZERO
		
	await get_tree().create_timer(0.3).timeout
	queue_free()
