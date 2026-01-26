class_name HoursTracker
extends Control

@export var hours_label : Label
@export var end_day_button : Button
@export var big_arrow : Control
@export var animation_player: AnimationPlayer

var cursor: Cursor

var big_arrow_enabled := false:
	set(value):
		big_arrow_enabled = true
		if !GameManager.receiving_input:
			big_arrow.visible = false
			return
		if value:
			check_cards_playable(null, null)
		else:
			big_arrow.visible = false
			

func _ready() -> void:
	end_day_button.focus_mode = FOCUS_NONE
	big_arrow.visible = false
	animation_player.play("wave_arrow")
	cursor = get_tree().get_first_node_in_group("cursor")
	call_deferred("_connect_signals")
	
func _connect_signals():
	if not SignalBus.card_played.is_connected(check_cards_playable):
		SignalBus.card_played.connect(check_cards_playable)
	if not SignalBus.card_drawn.is_connected(handle_card_drawn):
		SignalBus.card_played.connect(handle_card_drawn)
		
func handle_card_drawn(c: Card = null, project: Project = null):
	if c.card_data.card_type != CardData.CARD_TYPE.OBSTACLE:
		check_cards_playable(c, project)
			
func check_cards_playable(c: Card = null, project: Project = null):
	for card in CardsCollection.cards_in_hand:
		if card != c && card.card_data.get_target_type() != CardData.target_type.UNPLAYABLE && card.cost <= GameManager.hours:
			big_arrow.visible = false
			return
	big_arrow.visible = true

func _on_end_day_button_pressed() -> void:
	if !CardsController.receiving_input():
		return
	big_arrow.visible = false
	GameManager.go_to_next_day()
	
	
func set_hours_label(hours: int):
	hours_label.text = "Hours: " + str(hours)

func _on_end_day_button_mouse_entered() -> void:
	SignalBus.node_hovered.emit(end_day_button)

func _on_end_day_button_mouse_exited() -> void:
	SignalBus.node_stop_hovered.emit(end_day_button)
