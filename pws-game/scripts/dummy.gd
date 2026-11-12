extends StaticBody2D

var health = 100

func take_damage(amount, from_pos):
	var start_x = position.x
	var shake = create_tween()
	shake.tween_property(self, "position:x", start_x + 3, 0.03)
	shake.tween_property(self, "position:x", start_x - 3, 0.03)
	shake.tween_property(self, "position:x", start_x, 0.03)
	health -= amount
	print ("Dummy hit! Health: ", health)
	
	modulate = Color(3, 3, 3)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)
	
	if health <= 0:
		queue_free()
