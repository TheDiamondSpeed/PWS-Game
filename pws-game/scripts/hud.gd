extends CanvasLayer

const CELL_SIZE = Vector2(10, 14)
const COLOR_FULL = Color("2ee6ff")
const COLOR_EMPTY = Color("2a2540")

var player = null
var cells = []
var shown_max = -1

@onready var cell_box = $Margin/VBox/HealthCells
@onready var charge_bar = $Margin/VBox/ChargeBar

func _process(_delta):
	if player == null:
		player = get_tree().get_first_node_in_group("player")
		return
	if player.max_health != shown_max:
		_rebuild_cells()
	
	for i in cells.size():
		cells[i].color = COLOR_FULL if i < player.health else COLOR_EMPTY
		
	charge_bar.max_value = player.max_charge
	charge_bar.value = player.charge
	
func _rebuild_cells():
	for c in cells:
		c.queue_free()
	cells.clear()
	for i in player.max_health:
		var cell = ColorRect.new()
		cell.custom_minimum_size = CELL_SIZE
		cell_box.add_child(cell)
		cells.append(cell)
	shown_max = player.max_health
