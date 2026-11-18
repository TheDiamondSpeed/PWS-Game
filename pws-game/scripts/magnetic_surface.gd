extends StaticBody2D

@export var polarity := 1
@export var size := Vector2(64, 16)

func _ready():
	add_to_group("magnetic")
	var shape = RectangleShape2D.new()
	shape.size = size
	$CollisionShape2D.shape = shape
	$CollisionShape2D/ColorRect.size = size
	$CollisionShape2D/ColorRect.position = -size / 2.0
	$CollisionShape2D/ColorRect.color = Color("d9534f") if polarity > 0 else Color("3b82f6")
	
