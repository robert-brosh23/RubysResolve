class_name PlayerStatusManager
extends Control

@export var hbox_container: HBoxContainer

var statuses: Array[PlayerStatus]

func _ready():
	pass
	
func add_status(player_status_data: PlayerStatusData):
	var new_status = PlayerStatus.create_player_status(player_status_data.duplicate(true))
	statuses.append(new_status)
	new_status.status_data.clear_status.connect(func(): statuses.erase(new_status))
	hbox_container.add_child(new_status)
