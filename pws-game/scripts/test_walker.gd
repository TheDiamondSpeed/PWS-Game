extends Enemy

const SPEED = 30.0
var direction = 1

@onready var ledge_check = $LedgeCheck
@onready var wall_check = $WallCheck

func _behavior(_delta):
	if is_on_floor() and hurt_timer <= 0:
		if wall_check.is_colliding() or not ledge_check.is_colliding():
			direction *= -1
			ledge_check.position.x = abs(ledge_check.position.x) * direction
			wall_check.target_position.x = abs(wall_check.target_position.x) * direction
	velocity.x = direction * SPEED
