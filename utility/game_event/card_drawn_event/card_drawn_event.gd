class_name CardDrawnEvent
extends GameEvent

static func create_card_drawn_event(_card: Card):
	var new_event := CardDrawnEvent.new()
	new_event.type = event_type.CARD_DRAWN
	new_event.card = _card
	return new_event
	
