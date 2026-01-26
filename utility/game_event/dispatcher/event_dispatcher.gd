class_name EventDispatcher extends Node

class Handler:
	var effect: Effect
	var callback: Callable

func dispatch_event(event: GameEvent, effects: Array[Effect]):
	var handlers : Array[Handler] = []

	for effect in effects:
		var map = effect.get_event_handlers()
		
		if map.has(event.type):
			var handler = Handler.new()
			handler.effect = effect
			handler.callback = map.get(event.type)
			handlers.append(handler)

	handlers.sort_custom(func(a, b):
		return a.effect.priority > b.effect.priority
	)

	for h in handlers:
		h.callback.call(event.card)
		if h.effect.counter_needs_update:
			h.effect.counter_needs_update = false
			h.effect.update_counter()
			
		if event.consumed:
			break
