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
@onready var sprite = $Sprite2D

var attack_dir = Vector2.RIGHT

const MAX_HEALTH = 5
const INVINCIBLE_TIME = 1.0

var health = MAX_HEALTH
var invincible_timer = 0.0
var hurt_knockback = 0.0

func _ready():
	add_to_group("player")
	attack_hitbox.monitoring = false
	attack_visual.visible = false
	attack_hitbox.body_entered.connect(_on_attack_hit)

func _physics_process(delta):
	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * GRAVITY_MULTIPLIER * delta
	
	if invincible_timer > 0:
		invincible_timer -= delta
		sprite.visible = int(invincible_timer * 20) % 2 == 0
	else:
		sprite.visible = true
	
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
	velocity.x = direction * SPEED + recoil_velocity + hurt_knockback
	recoil_velocity = move_toward(recoil_velocity, 0.0, 600.0 * delta)
	hurt_knockback = move_toward(hurt_knockback, 0.0, 500.0 * delta)
	
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
	if attack_cooldown_timer > 0 or attack_timer >0:
		return
	
	var vertical = Input.get_axis("move_up", "move_down")
	if vertical < 0:
		attack_dir = Vector2.UP
	elif vertical > 0 and not is_on_floor():
		attack_dir = Vector2.DOWN
	else:
		attack_dir = Vector2(facing, 0)
		
	attack_timer = ATTACK_DURATION
	attack_cooldown_timer = ATTACK_COOLDOWN
	hit_targets.clear()
	attack_hitbox.monitoring = true
	attack_visual.visible = true
	
	if attack_dir.x != 0:
		attack_hitbox.position = Vector2(attack_dir.x * ATTACK_OFFSET, 0)
		attack_hitbox.rotation = 0
	else:
		attack_hitbox.position = Vector2(0, attack_dir.y * 24.0)
		attack_hitbox.rotation = PI / 2
	
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
		if attack_dir == Vector2.DOWN:
			velocity.y = JUMP_VELOCITY * 0.8
			attack_cooldown_timer = 0.0
		else:
			recoil()
		
func hitstop(duration := 0.05):
	Engine.time_scale = 0.05
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0
	
func recoil():
	recoil_velocity = -facing * 90.0

func take_damage(amount, from_pos):
	if invincible_timer > 0:
		return
	
	health -= amount
	invincible_timer = INVINCIBLE_TIME
	hurt_knockback	= sign(global_position.x - from_pos.x) * 150.0
	velocity.y = -150.0
	hitstop(0.08)
	print("Player health: ", health)
	
	if health <= 0:
		die()

func die():
	print("Player died")
	health = MAX_HEALTH
	invincible_timer = 0.0
	var main = get_tree().current_scene
	main.call_deferred("change_room", main.current_room.scene_file_path, "Spawn_Left")
