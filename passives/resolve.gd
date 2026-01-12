class_name Resolve
extends Control

@export var texture : TextureRect

@export var tooltip_container : PanelContainer
@export var tooltip_label : Label
@export var counter_label : Label

var resolve_data: ResolveData

static func create_resolve(data: ResolveData) -> Resolve:
	var instance : Resolve = preload("res://passives/resolve.tscn").instantiate()
	instance.resolve_data = data
	instance.init()
	return instance
	
func _process(delta: float) -> void:
	if resolve_data.counter < 0:
		counter_label.visible = false
	else:
		counter_label.visible = true
		counter_label.text = str(resolve_data.counter)
	
func init():
	tooltip_container.visible = false
	texture.texture = resolve_data.texture_png
	resolve_data.get_effect_callable(resolve_data.effect).call()
	tooltip_label.text = resolve_data.resolve_name + ": " + resolve_data.tooltip

func _on_panel_mouse_entered() -> void:
	tooltip_container.visible = true

func _on_panel_mouse_exited() -> void:
	tooltip_container.visible = false
