class_name PlayerStatus extends Effect

signal delete_status(status: PlayerStatus)

@onready var texture : TextureRect = $Texture
@onready var tooltip_container : PanelContainer = $Tooltip
@onready var tooltip_label : Label = $Tooltip/MarginContainer/TooltipText
@onready var counter_label : Label = $CounterLabel

var status_data: PlayerStatusData

static func create_player_status(data: PlayerStatusData) -> PlayerStatus:
	var instance : PlayerStatus = preload("res://status/player_status/player_status.tscn").instantiate()
	instance.status_data = data
	instance.init()
	return instance
	
func _process(delta: float) -> void:
	if counter < 2:
		counter_label.visible = false
	else:
		counter_label.visible = true
		counter_label.text = str(counter)
	
func _ready() -> void:
	tooltip_container.visible = false

func _on_panel_mouse_entered() -> void:
	tooltip_container.visible = true

func _on_panel_mouse_exited() -> void:
	tooltip_container.visible = false

## Overridable methods
func apply_draw_consuming_effect(card: Card) -> void:
	pass

func handle_card_drawn_impl(card: Card):
	pass
	
