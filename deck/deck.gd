class_name Deck
extends Control

const CARD_MOVEMENT_DURATION := 1.0

@export var card_amount_label: Label
@export var shuffling_label: RichTextLabel
@export var too_many_label: RichTextLabel

var promise_queue: PromiseQueue
var too_many_label_timer: SceneTreeTimer
var sound_draw_card := preload("res://audio/sfx/draw_card.wav")

func _ready() -> void:
	shuffling_label.visible = false
	too_many_label.visible = false
	
	_update_card_number_text()
	
func _process(delta: float) -> void:
	pass

func add_card(card: Card) -> void:
	card.flip_card_down()
	card.movement_tween_manager.tween_to_pos(card, self.global_position, CARD_MOVEMENT_DURATION).finished.connect(func(): _update_card_number_text())
	CardsCollection.cards_in_deck.append(card)
	_update_top_card_z_index()
	
func add_cards(cards: Array[Card]):
	for card in cards:
		add_card(card)
	
func draw_card() -> Card:
	if CardsCollection.cards_in_deck.is_empty():
		if CardsCollection.cards_in_discard_pile.is_empty():
			print("Deck is empty. Cannot draw card")
			return null
		await CardsController.move_cards_from_discard_pile_to_deck_and_shuffle()
	var card = CardsCollection.cards_in_deck[0]
	CardsCollection.cards_in_deck.remove_at(0)
	AudioPlayer.play_sound(sound_draw_card)
	_update_card_number_text()
	_update_top_card_z_index()
	
	card.draw_card_effect()
	return card
	
func peek_top_card() -> Card:
	if CardsCollection.cards_in_deck.is_empty():
		return null
	return CardsCollection.cards_in_deck[0]
	
func shuffle_deck() -> void:
	for i in range(CardsCollection.cards_in_deck.size() - 1, 0, -1):
		var j = randi() % (i + 1)
		var temp = CardsCollection.cards_in_deck[i]
		CardsCollection.cards_in_deck[i] = CardsCollection.cards_in_deck[j]
		CardsCollection.cards_in_deck[j] = temp
	_update_top_card_z_index()
	
func show_too_many_label() -> void:
	if !too_many_label_timer || too_many_label_timer.time_left == 0:
		too_many_label_timer = get_tree().create_timer(1.0)
		too_many_label.visible = true
		too_many_label_timer.timeout.connect(func(): too_many_label.visible = false)
	too_many_label_timer.time_left = 1.0
	
func _update_card_number_text() -> void:
	card_amount_label.text = "Deck: " + str(CardsCollection.cards_in_deck.size())
		
func _update_top_card_z_index() -> void:
	if CardsCollection.cards_in_deck.size() == 0:
		return
	CardsCollection.cards_in_deck[0].z_index = -3
	for i in range(1, CardsCollection.cards_in_deck.size(), 1):
		CardsCollection.cards_in_deck[i].z_index = -4
