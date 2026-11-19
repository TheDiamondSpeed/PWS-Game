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
@onready var feet_glow = $FeetGlow

var attack_dir = Vector2.RIGHT

var max_health = 10
const INVINCIBLE_TIME = 1.0
var max_charge = 100.0
var charge = 0.0

var health = max_health
var invincible_timer = 0.0
var hurt_knockback = 0.0

enum State { NORMAL, HURT, DASH, MAGNET }
var state = State.NORMAL
var hurt_timer = 0.0

const DASH_SPEED = 260.0
const DASH_DURATION = 0.18
const DASH_COOLDOWN = 0.4

var dash_timer = 0.0
var dash_cooldown_timer = 0.0
var dash_dir = 1
var can_air_dash = true

const MAGNET_SPEED = 70.0
const LAUNCH_SPEED = 330.0
const LAUNCH_DRIFT_DECAY = 120.0

var polarity = 1
var launch_vx = 0.0
var magnet_lockout = 0.0

@onready var ray_left = $MagnetLeft
@onready var ray_right = $MagnetRight
@onready var ray_up = $MagnetUp
@onready var ray_down = $MagnetDown

func _ready():
	add_to_group("player")
	attack_hitbox.monitoring = false
	attack_visual.visible = false
	attack_hitbox.body_entered.connect(_on_attack_hit)
	GameState.unlock("dash")
	charge = max_charge
	GameState.unlock("magnetic_feet")
	_update_polarity_tint()

func _physics_process(delta):
	_tick_timers(delta)
	
	match state:
		State.NORMAL:
			_normal_state(delta)
		State.HURT:
			_hurt_state(delta)
		State.DASH:
			_dash_state(delta)
		State.MAGNET:
			_magnet_state(delta)
	
	_update_flicker(delta)

func _update_flicker(delta):
	if invincible_timer > 0:
		invincible_timer -= delta
		if int(invincible_timer * 20) % 2 == 0:
			sprite.modulate.a = 0.3
		else:
			sprite.modulate.a = 1.0
	else:
		sprite.modulate.a = 1.0

func _tick_timers(delta):
	attack_cooldown_timer -= delta
	dash_cooldown_timer -= delta
	if is_on_floor():
		can_air_dash = true
	if Input.is_action_just_pressed("switch_polarity"):
		polarity *= -1
		_update_polarity_tint()
	if is_on_floor() and velocity.y >= 0:
		launch_vx = 0.0
	magnet_lockout -= delta

func _normal_state(delta):
	if Input.is_action_just_pressed("dash") and try_dash():
		return
	if _try_magnet():
		return
	_try_launch()
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
	velocity.x = direction * SPEED + recoil_velocity + hurt_knockback + launch_vx
	recoil_velocity = move_toward(recoil_velocity, 0.0, 600.0 * delta)
	hurt_knockback = move_toward(hurt_knockback, 0.0, 500.0 * delta)
	launch_vx = move_toward(launch_vx, 0.0, LAUNCH_DRIFT_DECAY * delta)
	
	if direction != 0:
		facing = sign(direction)
	
	if Input.is_action_just_pressed("main_attack") and attack_cooldown_timer <= 0:
		start_attack()
		
	if attack_timer > 0:
		attack_timer -= delta
		if attack_timer <= 0:
			end_attack()
	
	move_and_slide()

func _hurt_state(delta):
	velocity += get_gravity() * delta
	velocity.x = hurt_knockback
	hurt_knockback = move_toward(hurt_knockback, 0.0, 500.0 * delta)
	move_and_slide()
	
	hurt_timer -= delta
	if hurt_timer <= 0:
		state = State.NORMAL

func _dash_state(delta):
	velocity.x = dash_dir * DASH_SPEED
	velocity.y = 0
	move_and_slide()
	
	dash_timer -= delta
	if dash_timer <= 0:
		velocity.x = dash_dir * SPEED
		state = State.NORMAL

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
		charge = min(charge + 10.0, max_charge)
		body.take_damage(1, global_position)
		hitstop()
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
	state = State.HURT
	hurt_timer = 0.25
	hurt_knockback	= sign(global_position.x - from_pos.x) * 150.0
	velocity.y = -150.0
	hitstop(0.08)
	print("Player health: ", health)
	
	if health <= 0:
		die()

func die():
	print("Player died")
	health = max_health
	invincible_timer = 0.0
	var main = get_tree().current_scene
	main.call_deferred("change_room", main.current_room.scene_file_path, "Spawn_Left")

func try_dash():
	if not GameState.has_ability("dash"):
		return false
	if dash_cooldown_timer >0:
		return false
	if not is_on_floor() and not can_air_dash:
		return false
	
	if not is_on_floor():
		can_air_dash = false
	var dir = Input.get_axis("move_left", "move_right")
	dash_dir = sign(dir) if dir != 0 else facing
	facing = dash_dir
	dash_timer = DASH_DURATION
	dash_cooldown_timer = DASH_COOLDOWN
	state = State.DASH
	return true

func _update_polarity_tint():
	sprite.modulate = Color(1, 1, 1, sprite.modulate.a)
	feet_glow.modulate = Color("ff5a52") if polarity > 0 else Color("4d8dff")
	feet_glow.visible = GameState.has_ability("magnetic_feet")

func _find_attracting_ray():
	for ray in [ray_left, ray_right, ray_up]:
		if ray.is_colliding():
			var surface = ray.get_collider()
			if surface.is_in_group("magnetic") and surface.polarity != polarity:
				return ray
	return null

func _try_magnet():
	if magnet_lockout > 0:
		return false
	if not GameState.has_ability("magnetic_feet"):
		return false
	if not Input.is_action_pressed("magnet"):
		return false
	if _find_attracting_ray() == null:
		return false
	launch_vx = 0.0
	velocity = Vector2.ZERO
	state = State.MAGNET
	return true

func _magnet_state(delta):
	var ray = _find_attracting_ray()
	if ray == null or not Input.is_action_pressed("magnet"):
		state = State.NORMAL
		return
		
	if Input.is_action_just_pressed("jump"):
		velocity.y = JUMP_VELOCITY if ray != ray_up else 0.0
		if ray == ray_left:
			recoil_velocity = 120.0
		elif ray == ray_right:
			recoil_velocity	= -120.0
		magnet_lockout = 0.25
		state = State.NORMAL
		return
	
	var h = Input.get_axis("move_left", "move_right")
	var v = Input.get_axis("move_up", "move_down")
	
	if ray == ray_up:
		velocity = Vector2(h * MAGNET_SPEED, 0)
	else:
		velocity = Vector2(0, v * MAGNET_SPEED)
	
	velocity += ray.target_position.normalized() * 20.0
	move_and_slide()
	
func _find_repelling_ray():
	for ray in [ray_left, ray_right, ray_up, ray_down]:
		if ray.is_colliding():
			var surface = ray.get_collider()
			if surface.is_in_group("magnetic") and surface.polarity == polarity:
				return ray
	return null
	
func _try_launch():
	if not GameState.has_ability("magnetic_feet"):
		return
	if not Input.is_action_just_pressed("magnet"):
		return
	var ray = _find_repelling_ray()
	if ray == null:
		return
	var h = Input.get_axis("move_left", "move_right")
	if ray == ray_down:
		velocity.y = -LAUNCH_SPEED
		launch_vx = h * LAUNCH_SPEED * 0.6
	elif ray == ray_up:
		velocity.y = LAUNCH_SPEED * 0.6
	else:
		var away = 1.0 if ray == ray_left else -1.0
		launch_vx = away * LAUNCH_SPEED * 0.8
		velocity.y = -120.0
	can_air_dash = true
