extends Area2D

@export_file("*.tscn") var target_room: String
@export var target_spawn: String = "Spawn_Left"

func _ready():
	body_entered.connect(_on_body_entered)
	
func _on_body_entered(body):
	if body.is_in_group("player"):
		get_tree().current_scene.call_deferred("change_room", target_room, target_spawn)
