class_name PlayerStatusData
extends Resource

signal clear_status

@export var name: String

@export var effect: player_status_effect 

@export var texture_png: CompressedTexture2D

@export var tooltip: String

var counter := 1

enum player_status_effect {
	FORGOT_LUNCH,
	ADDICTION,
	CUTE_DOG
}

var effect_map: Dictionary[player_status_effect, Callable] = {
	player_status_effect.FORGOT_LUNCH : _create_forgot_lunch,
	player_status_effect.ADDICTION : _create_addiction,
	player_status_effect.CUTE_DOG: _create_cute_dog
}

func get_effect_callable(_effect: player_status_effect) -> Callable:
	return effect_map[_effect]

func _create_cute_dog():
	SignalBus.card_drawn.connect(
		_activate_cute_dog
	)
	
func _activate_cute_dog(card: Card):
	if card.card_data.card_type != CardData.CARD_TYPE.OBSTACLE:
		return

	CardsController._discard_card_from_hand(card)
	for connection in SignalBus.card_drawn.get_connections():
		var callable : Callable = connection["callable"]
		if callable.get_method() == "_activate_cute_dog":
			counter -= 1
			if counter == 0:
				SignalBus.card_drawn.disconnect(callable)
				clear_status.emit()
				break

func _create_forgot_lunch():
	SignalBus.new_day_started.connect(_forgot_my_lunch_activate_multiplier)
	SignalBus.card_played.connect(_forgot_my_lunch_reset_card_played)
	SignalBus.dusk_started.connect(_forgot_my_lunch_reset_dusk)

func _create_addiction():
	SignalBus.new_day_started.connect(
		func(day: int): GameManager.hours -= 3, CONNECT_ONE_SHOT
	)
	SignalBus.dusk_started.connect(
		func(): clear_status.emit(), CONNECT_ONE_SHOT
	)

func _forgot_my_lunch_activate_multiplier(day: int):
	SignalBus.cost_multiplier *= 2.0
	SignalBus.alter_cost.emit()
	
func _forgot_my_lunch_reset_card_played(card: Card, target: Project):
	_forgot_my_lunch_reset()

func _forgot_my_lunch_reset_dusk():
	_forgot_my_lunch_reset()
	
func _forgot_my_lunch_reset():
	SignalBus.cost_multiplier *= 0.5
	SignalBus.alter_cost.emit()
	for connection in SignalBus.card_played.get_connections():
		var callable : Callable = connection["callable"]
		if callable.get_method() == "_forgot_my_lunch_reset_card_played":
			SignalBus.card_played.disconnect(callable)
			break
	for connection in SignalBus.new_day_started.get_connections():
		var callable : Callable = connection["callable"]
		if callable.get_method() == "_forgot_my_lunch_activate_multiplier":
			SignalBus.new_day_started.disconnect(callable)
			break
	for connection in SignalBus.new_day_started.get_connections():
		var callable : Callable = connection["callable"]
		if callable.get_method() == "_forgot_my_lunch_reset_dusk":
			SignalBus.new_day_started.disconnect(callable)
			break
	clear_status.emit()
