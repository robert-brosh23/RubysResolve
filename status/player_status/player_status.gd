class_name PlayerStatus extends Control

@export var texture : TextureRect

@export var tooltip_container : PanelContainer
@export var tooltip_label : Label
@export var counter_label : Label

var status_data: PlayerStatusData

static func create_player_status(data: PlayerStatusData) -> PlayerStatus:
	var instance : PlayerStatus = preload("res://status/player_status/player_status.tscn").instantiate()
	instance.status_data = data
	instance.init()
	return instance
	
func _process(delta: float) -> void:
	if status_data.counter < 2:
		counter_label.visible = false
	else:
		counter_label.visible = true
		counter_label.text = str(status_data.counter)
	
func init():
	tooltip_container.visible = false
	texture.texture = status_data.texture_png
	status_data.get_effect_callable(status_data.effect).call()
	tooltip_label.text = status_data.name + ": " + status_data.tooltip
	status_data.clear_status.connect(
		func(): 
			queue_free()
	)

func _on_panel_mouse_entered() -> void:
	tooltip_container.visible = true

func _on_panel_mouse_exited() -> void:
	tooltip_container.visible = false
