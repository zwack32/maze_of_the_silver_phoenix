extends StaticBody2D
class_name Door

@export var direction: Vector2
@export var original_room_idx: int
@export var room_manager: RoomManager

@onready var enter_trigger = $EnterTrigger
@onready var collider = $CollisionShape2D
@onready var sprite_2d = $Sprite2D

func _ready():
	enter_trigger.position = -Vector2.UP * 100.0
	rotation = direction.angle() + PI / 2

func set_disabled(disabled: bool):
	collider.disabled = disabled

func _on_enter_trigger_area_entered(area):
	if area.owner is Player:
		print("enter", original_room_idx)
		room_manager.enter_room(original_room_idx)

func _on_enter_trigger_area_exited(area):
	if area.owner is Player:
		print("exit", original_room_idx)
		room_manager.exit_room(original_room_idx)
