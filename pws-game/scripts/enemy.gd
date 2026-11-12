class_name Enemy
extends CharacterBody2D

@export var max_health := 3
@export var contact_damage := 1
@export var knockback_strength := 120.0
@export var uses_gravity := true

var health := 0
var knockback := 0.0
var hurt_timer := 0.0

@onready var contact_area: Area2D = $ContactArea

func _ready():
	health = max_health
	
func _physics_process(delta):
	if uses_gravity and not is_on_floor():
		velocity.y += get_gravity().y * delta
	hurt_timer -= delta
	
	_behavior(delta)
	
	velocity.x += knockback
	knockback = move_toward(knockback, 0.0, 400.0 * delta)
	move_and_slide()
	
	for body in contact_area.get_overlapping_bodies():
		print("Touching: ", body.name)
		if body.is_in_group("player") and body.has_method("take_damage"):
			body.take_damage(contact_damage, global_position)

func _behavior(_delta):
	pass
	
func take_damage(amount, from_pos):
	health -= amount
	hurt_timer = 0.2
	knockback = sign(global_position.x - from_pos.x) * knockback_strength
	modulate = Color(3, 3, 3)
	create_tween().tween_property(self, "modulate", Color.WHITE, 0.1)
	if health <= 0:
		_on_death()
		
func _on_death():
	queue_free()
