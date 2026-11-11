extends CharacterBody2D

const SPEED = 125
const JUMP_VELOCITY = -400
const COYOTE_TIME = 0.1
const JUMP_BUFFER_TIME = 0.1
const JUMP_CUT_MULTIPLIER = 0.4
const GRAVITY_MULTIPLIER = 1

var coyote_timer = 0.0
var jump_buffer_timer = 0.0

const ATTACK_DURATION = 0.15
const ATTACK_COOLDOWN = 0.3
const ATTACK_OFFSET = 16.0

var facing = 1
var attack_timer = 0.0
var attack_cooldown_timer = 0.0
var hit_targets = []

var recoil_velocity = 0.0

@onready var attack_hitbox = $MainAttackHitbox
@onready var attack_visual = $MainAttackHitbox/ColorRect

func _ready():
	add_to_group("player")
	attack_hitbox.monitoring = false
	attack_visual.visible = false
	attack_hitbox.body_entered.connect(_on_attack_hit)

func _physics_process(delta):
	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * GRAVITY_MULTIPLIER * delta

	#Hopelijk coyote time
	if is_on_floor():
		coyote_timer = COYOTE_TIME
	else:
		coyote_timer -= delta

	#Jump
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = JUMP_BUFFER_TIME
	else:
		jump_buffer_timer -= delta

	if jump_buffer_timer > 0 and coyote_timer > 0:
		velocity.y = JUMP_VELOCITY
		jump_buffer_timer = 0
		coyote_timer = 0

	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= JUMP_CUT_MULTIPLIER

	# Left/right movement
	var direction = Input.get_axis("move_left", "move_right")
	velocity.x = direction * SPEED + recoil_velocity
	recoil_velocity = move_toward(recoil_velocity, 0.0, 600.0 * delta)
	
	if direction != 0:
		facing = sign(direction)
	
	attack_cooldown_timer -= delta
	if Input.is_action_just_pressed("main_attack") and attack_cooldown_timer <= 0:
		start_attack()
		
	if attack_timer > 0:
		attack_timer -= delta
		if attack_timer <= 0:
			end_attack()
	
	move_and_slide()

func start_attack():
	print("Attack at ", Time.get_ticks_msec(), " cooldown was ", attack_cooldown_timer)
	attack_timer = ATTACK_DURATION
	attack_cooldown_timer = ATTACK_COOLDOWN
	hit_targets.clear()
	attack_hitbox.position.x = facing * ATTACK_OFFSET
	attack_hitbox.monitoring = true
	attack_visual.visible = true
	
func end_attack():
	attack_hitbox.monitoring = false
	attack_visual.visible = false
	
func _on_attack_hit(body):
	if body == self or body in hit_targets:
		return
	if body.has_method("take_damage"):
		hit_targets.append(body)
		body.take_damage(1, global_position)
		hitstop()
		recoil()
		
func hitstop(duration := 0.05):
	Engine.time_scale = 0.05
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0
	
func recoil():
	recoil_velocity = -facing * 90.0
