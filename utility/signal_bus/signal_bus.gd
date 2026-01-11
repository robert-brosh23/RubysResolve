extends Node

signal new_day_started(num_day: int)

signal alter_cost(multiplier: float)
var cost_multiplier := 1.0

var pending := []
signal start_card_played(card: Card, target: Project)
signal card_played(card: Card, target: Project)
signal card_played_chained(card: Card, target: Project)

signal reward_choice_made(choice: Variant)

signal node_hovered(node: Node)
signal node_stop_hovered(node: Node)

func _ready() -> void:
	start_card_played.connect(
		func(card: Card, project: Project):
			pending.append(card)
	)
	card_played.connect(
		func(card: Card, project: Project):
			if pending.has(card):
				card_played_chained.emit(card, project)
				pending.erase(card)
	)
	
func reset():
	pending.clear()
	cost_multiplier = 1.0
	for signal_name in ["card_played", "start_card_played", "card_played_chained", "alter_cost", "new_day_started"]:
		for conn in get_signal_connection_list(signal_name):
			disconnect(signal_name, conn.callable)
			
			
			
