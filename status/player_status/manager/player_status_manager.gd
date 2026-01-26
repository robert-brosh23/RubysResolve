class_name PlayerStatusManager
extends Control

@export var hbox_container: HBoxContainer

var statuses: Array[PlayerStatus]

func _ready():
	pass
	
func add_status(new_status: PlayerStatus):
	statuses.append(new_status)
	hbox_container.add_child(new_status)
	new_status.delete_status.connect(delete_status)
	
func delete_status(status: PlayerStatus):
	statuses.erase(status)
	status.visible = false
	await get_tree().create_timer(10).timeout
	hbox_container.remove_child(status)
	status.queue_free()
