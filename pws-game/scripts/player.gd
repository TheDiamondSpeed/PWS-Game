extends CharacterBody2D

const SPEED = 125
const JUMP_VELOCITY = -400
const COYOTE_TIME = 0.1
const JUMP_BUFFER_TIME = 0.1
const JUMP_CUT_MULTIPLIER = 0.4
const GRAVITY_MULTIPLIER = 1

var coyote_timer = 0.0
var jump_buffer_timer = 0.0

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
	velocity.x = direction * SPEED

	move_and_slide()
