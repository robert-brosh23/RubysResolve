extends Node

var deck: Deck
var hand: Hand
var discard_pile: DiscardPile
var promise_queue: PromiseQueue = PromiseQueue.new()
var main_ui: MainUi
var hours_tracker: HoursTracker

var sound_discard_card := preload("res://audio/sfx/place_card.wav")
var sound_draw_card := preload("res://audio/sfx/draw_card.wav")
var shuffle_sfx := preload("res://audio/sfx/shuffle_sfx.wav")

func ready() -> void:
	deck = get_tree().get_first_node_in_group("deck")
	discard_pile = get_tree().get_first_node_in_group("discard_pile")
	hand = get_tree().get_first_node_in_group("hand")
	main_ui = get_tree().get_first_node_in_group("main_ui")
	hours_tracker = get_tree().get_first_node_in_group("hours_tracker")
	
	deck.promise_queue = promise_queue
	hand.promise_queue = promise_queue

## Creates a new card and adds it to the deck. Returns reference to the card created.
func enqueue_create_card(card_data: CardData) -> Signal:
	promise_queue.enqueue(_create_card.bind(card_data))
	var result_signal = promise_queue.enqueue_delay(.2)
	return result_signal
	
func _create_card(card_data: CardData, spawn_pos: Vector2 = Vector2(300,100), pause_time := 0.0, discard := false, shuffle := false) -> Card:
	AudioPlayer.play_sound(sound_discard_card)
	var card = Card.create_card(card_data)
	card.global_position = spawn_pos
	card.promise_queue = promise_queue
	CardsCollection.add_child(card)
	await get_tree().create_timer(pause_time).timeout
	if discard:
		discard_pile.add_card(card)
	else:
		deck.add_card(card)
		if shuffle:
			await _shuffle_deck()
	return card

## Creates new cards and adds them to the deck.
func enqueue_create_cards(card_datas: Array[CardData]) -> Signal:
	var result_signal: Signal
	for i in range(0, card_datas.size() - 1):
		enqueue_create_card(card_datas[i])
	return enqueue_create_card(card_datas[card_datas.size()-1])


# DECK FUNCTIONS
func enqueue_draw_card_from_deck() -> void:
	var result_signal = promise_queue.enqueue(draw_card_from_deck)
	promise_queue.enqueue_delay(.2)
	
func draw_card_from_deck() -> void:
	if deck == null:
		return
	var card = await deck.draw_card()
	if card == null:
		return
	hand.add_card(card)
	#SignalBus.card_drawn.emit(card)
	var effects: Array[Effect] = []
	for status in GameManager.player_status_manager.statuses:
		effects.append(status)
	
	GameManager.event_dispatcher.dispatch_event(CardDrawnEvent.create_card_drawn_event(card), effects)
	
func peek_at_top_card_of_deck() -> Card:
	if CardsCollection.cards_in_deck.is_empty() and !CardsCollection.cards_in_discard_pile.is_empty():
		await move_cards_from_discard_pile_to_deck_and_shuffle()
	return deck.peek_top_card()

func enqueue_draw_multiple_cards(num_cards: int) -> void:
	for i in range(0, num_cards):
		enqueue_draw_card_from_deck()
		
func enqueue_discard_card_from_deck() -> void:
	var result_signal = promise_queue.enqueue(_discard_card_from_deck)
	promise_queue.enqueue_delay(.2)
	
func _discard_card_from_deck() -> void:
	AudioPlayer.play_sound(sound_draw_card)
	var card = await deck.draw_card()
	if card == null:
		print("no card in deck")
		return
	discard_pile.add_card(card)
	
func enqueue_shuffle_deck() -> Signal:
	var result_signal = promise_queue.enqueue(_shuffle_deck)
	return result_signal
	
func _shuffle_deck() -> void:
	promise_queue.paused += 1
	await get_tree().create_timer(0.5).timeout
	AudioPlayer.play_sound(shuffle_sfx)
	deck.shuffling_label.visible = true
	deck.shuffle_deck()
	await get_tree().create_timer(1.0).timeout
	deck.shuffling_label.visible = false
	promise_queue.paused -= 1


# HAND FUNCTIONS
## Try to play the card. Returns true if the card was played, false otherwise.
func enqueue_play_card(card: Card, target: Project = null) -> bool:
	var result_signal = promise_queue.enqueue(_play_card.bind(card, target))
	promise_queue.enqueue_delay(.2)
	var result = await result_signal
	return result

func _play_card(card: Card, target = null) -> bool:
	if target == null and typeof(target) != TYPE_NIL:
		print("Project was previously freed.")
		hand.return_card(card)
		return false
		
	var result = await card.play_card(target)
	if result == true:
		if card == null || card.state == Card.states.DELETING:
			return true
		_discard_card_from_hand(card)
		return true
	hand.return_card(card)
	return false

func enqueue_discard_card_from_hand(card: Card) -> void:
	var result_signal = promise_queue.enqueue(_discard_card_from_hand.bind(card))
	promise_queue.enqueue_delay(.2)

func _discard_card_from_hand(card: Card) -> void:
	AudioPlayer.play_sound(sound_discard_card, AudioPlayer.Bus.SFX)
	card.state = Card.states.NOT_IN_HAND
	hand.remove_card_from_hand(card)
	discard_pile.add_card(card)
	
func enqueue_select_cards(num_cards: int, conditions: Array[Callable] = []) -> Array[Card]:
	var result_signal = promise_queue.enqueue(select_cards.bind(num_cards, conditions))
	promise_queue.enqueue_delay(.2)
	var result = await result_signal
	return result
	
func select_cards(num_cards: int, conditions: Array[Callable] = [], card: Card = null) -> Array[Card]:
	var selected = await hand.select_cards(num_cards, conditions, card)
	return selected
	
func enqueue_discard_all_cards_from_hand() -> Signal:
	promise_queue.enqueue(_discard_all_cards_from_hand)
	var result_signal = promise_queue.enqueue_delay(.5)
	return result_signal
	
func _discard_all_cards_from_hand() -> void:
	while !CardsCollection.cards_in_hand.is_empty():
		var card = CardsCollection.cards_in_hand.front()
		if GameManager.state == GameManager.states.ENDING_DAY:
			await card.dusk_card_effect()
			
		hand.remove_card_from_hand(card)
		AudioPlayer.play_sound(sound_discard_card)
		card.state = Card.states.NOT_IN_HAND
		discard_pile.add_card(card)
		await get_tree().create_timer(0.2).timeout
	
	
# DISCARD PILE FUNCTIONS
func _add_card_to_discard_pile(card: Card) -> void:
	if card == null:
		print("Error: no card to append to discard pile")
		return
	discard_pile.add_card(card)
	
func enqueue_move_cards_from_discard_pile_to_deck_and_shuffle() -> Signal:
	var result_signal = promise_queue.enqueue(move_cards_from_discard_pile_to_deck_and_shuffle)
	return result_signal
	
func move_cards_from_discard_pile_to_deck_and_shuffle() -> void:
	var arr: Array[Card] = discard_pile.remove_all_cards_from_discard_pile()
	deck.add_cards(arr)
	await _shuffle_deck()
	
func receiving_input() -> bool:
	return GameManager.receiving_input
	
func pause_queue() -> void:
	promise_queue.paused += 1
	
func unpause_queue() -> void:
	promise_queue.paused -= 1
	
func reset():
	promise_queue.clear_queue()
	ready()
