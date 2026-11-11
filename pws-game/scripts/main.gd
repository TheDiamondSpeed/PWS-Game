extends Node

@onready var world = $World
@onready var player = $Player

var current_room = null
var changing = false

func _ready():
    change_room("res://scenes/test_room.tscn", "Spawn_Left")
    
func change_room(room_path: String, spawn_name: String):
    if changing:
        return
    changing = true
    
    if current_room:
        current_room.queue_free()
        await current_room.tree_exited
        
    var room = load(room_path).instantiate()
    world.add_child(room)
    current_room = room
    
    player.global_position = room.get_node(spawn_name).global_position
    player.velocity = Vector2.ZERO
    set_camera_limits(room)
    
    await get_tree().physics_frame
    changing = false
    
func set_camera_limits(room):
    var tilemap = room.get_node("TileMapLayer")
    var rect = tilemap.get_used_rect()
    var tile_size = tilemap.tile_set.tile_size
    var cam = player.get_node("Camera2D")
    
    cam.limit_left = rect.position.x * tile_size.x
    cam.limit_right = rect.end.x * tile_size.x
    cam.limit_top = rect.position.y * tile_size.y
    cam.limit_bottom = rect.end.y * tile_size.y
    cam.reset_smoothing()
    print("Room rect: ", rect, " limits: ", cam.limit_left, " ", cam.limit_right, " ", cam.limit_top, " ", cam.limit_bottom)
