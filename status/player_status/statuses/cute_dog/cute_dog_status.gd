class_name CuteDogStatus extends PlayerStatus

const SCENE : PackedScene = preload("res://status/player_status/statuses/cute_dog/cute_dog_status.tscn")

static func create_cute_dog_status() -> CuteDogStatus:
	for status in GameManager.player_status_manager.statuses:
		if status is CuteDogStatus:
			status.counter += 1
			return null
	var new_status = SCENE.instantiate()
	new_status.counter = 1
	return new_status

func get_event_handlers() -> Dictionary:
	return { GameEvent.event_type.CARD_DRAWN : handle_card_drawn }

func handle_card_drawn(card: Card) -> bool:
	if card.card_data.card_type == CardData.CARD_TYPE.OBSTACLE:
		apply_draw_consuming_effect(card)
		counter_needs_update = true
		return true
	return false

func apply_draw_consuming_effect(card: Card) -> void:
	var callables: Array[Callable] = [
		func(): 
			card.movement_tween_manager.pos_tween.kill()
			await card.animation_player.animation_finished
			card.animation_player.play("activate_dusk_effect")
			await get_tree().create_timer(.5).timeout
			card.animation_player.stop()
			card.dusk_animation_border.visible = false
			CardsController._discard_card_from_hand(card)
			await get_tree().create_timer(.2).timeout
			CardsController.draw_card_from_deck()
	]
	GameManager.promise_queue.pause_queue_and_do_things(callables)

func update_counter() -> void:
	counter -= 1
	if counter == 0:
		delete_status.emit(self)
