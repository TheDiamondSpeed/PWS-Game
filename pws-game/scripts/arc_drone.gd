extends Enemy

enum AI { IDLE, CHASE, WINDUP, LUNGE, RECOVER }

const DETECT_RANGE = 120.0
const LUNGE_TRIGER_RANGE = 64.0
const CHASE_SPEED = 40.0
const LUNGE_SPEED = 220.0
const WINDUP_TIME = 0.5
const LUNGE_TIME = 0.3
const RECOVER_TIME = 0.7

var ai_state = AI.IDLE
var state_timer = 0.0
var lunge_dir = Vector2.ZERO
var target = null
var time = 0.0

@onready var body_rect = $ColorRect
@onready var base_color = $ColorRect.color

func _ready():
	super()
	uses_gravity = false

func _set_ai(new_state, duration := 0.0):
	ai_state = new_state
	state_timer = duration
	body_rect.color = Color("f2c94c") if new_state == AI.WINDUP else base_color
	
func _behavior(delta):
	time += delta
	if target == null:
		target = get_tree().get_first_node_in_group("player")
	if target == null:
		return
	
	if hurt_timer > 0:
		if ai_state == AI.WINDUP or ai_state == AI.LUNGE:
			_set_ai(AI.RECOVER, 0.4)
		velocity = Vector2.ZERO
		return
	var to_player = target.global_position - global_position
	var dist = to_player.length()
	state_timer -= delta
	
	match ai_state:
		AI.IDLE:
			velocity = Vector2(0, cos(time * 3.0) * 10.0)
			if dist < DETECT_RANGE:
				_set_ai(AI.CHASE)
		AI.CHASE:
			velocity = to_player.normalized() * CHASE_SPEED
			if dist < LUNGE_TRIGER_RANGE:
				_set_ai(AI.WINDUP, WINDUP_TIME)
			elif dist > DETECT_RANGE * 1.5:
				_set_ai(AI.IDLE)
		AI.WINDUP:
			velocity = Vector2.ZERO
			if state_timer <= 0:
				lunge_dir = to_player.normalized()
				_set_ai(AI.LUNGE, LUNGE_TIME)
		AI.LUNGE:
			velocity = lunge_dir * LUNGE_SPEED
			if state_timer <= 0:
				_set_ai(AI.RECOVER, RECOVER_TIME)
		AI.RECOVER:
			velocity = Vector2.ZERO
			if state_timer <= 0:
				_set_ai(AI.CHASE)
