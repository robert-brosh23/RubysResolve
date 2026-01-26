class_name Effect
extends Node

@export var priority := 0
var consuming = false
var counter = -1
var counter_needs_update := false

func get_event_handlers() -> Dictionary:
	return {}

func update_counter() -> void:
	pass
