class_name Hand
extends Control

const CENTER_X = 320
const DEFAULT_Y = 350
const DEFAULT_CARD_SEPARATION = 150
const HAND_BASE_Z_INDEX = 200
const MAX_HAND_SIZE = 10

@export var selecting_cards_container : PanelContainer
@export var selecting_cards_label : Label
@export var confirm_button : Button

var projects_manager: ProjectsManager
var hours_tracker: HoursTracker

var promise_queue: PromiseQueue
var hovered_card: Card = null
var drag_offset: Vector2
var dragged_card: Card
var state := states.READY
var selected_cards : Array[Card] = []
var max_selected: int
var selection_conditions : Array[Callable]
var deck: Deck
var cursor: Cursor

enum states {READY, DRAGGING, SELECTING}

func _ready() -> void:
	projects_manager = get_tree().get_first_node_in_group("projects_manager")
	hours_tracker = get_tree().get_first_node_in_group("hours_tracker")
	selecting_cards_container.visible = false
	confirm_button.focus_mode = FOCUS_NONE
	_update_hand()
	deck = get_tree().get_first_node_in_group("deck")
	cursor = get_tree().get_first_node_in_group("cursor")
	
func _process(_delta: float) -> void:
	_handle_input()
		
	if hovered_card != null:
		hours_tracker.end_day_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	else:
		hours_tracker.end_day_button.mouse_filter = Control.MOUSE_FILTER_STOP
		
func add_card(card: Card) -> void:
	CardsCollection.cards_in_hand.append(card)
	if CardsCollection.cards_in_hand.size() >= MAX_HAND_SIZE + 1:
		print("Too many cards")
		cursor.play_message("My hand is full!")
		CardsController._discard_card_from_hand(card)
		deck.show_too_many_label()
		return
	
	card.flip_card_up()
	card.state = Card.states.READY
	if not card.panel.mouse_exited.is_connected(_stop_hover_card):
		card.panel.mouse_exited.connect(_stop_hover_card)
	if not card.panel.mouse_entered.is_connected(_hover_card):
		card.panel.mouse_entered.connect(_hover_card.bind(card))
	_update_hand()
	
func select_cards(max_cards: int, conditions: Array[Callable] = [], played_card : Card = null) -> Array[Card]:
	state = states.SELECTING
	max_selected = max_cards
	selection_conditions = conditions
	selecting_cards_label.text = "Select up to " + str(max_selected) + " card(s)"
	if played_card != null:
		selecting_cards_label.text += " for " + played_card.card_data.card_name
	selecting_cards_container.visible = true
	
	await confirm_button.pressed
	var dup := selected_cards.duplicate()
	for card in selected_cards:
		card.apply_card_visual_faceup()
	selected_cards.clear()
	selection_conditions.clear()
	selecting_cards_container.visible = false
	state = states.READY
	_update_hand()
	hours_tracker.check_cards_playable(null, null)
	return dup
	
	
func remove_card_from_hand(card: Card) -> Card:
	if card == hovered_card:
		hovered_card = null
	if card == dragged_card:
		dragged_card = null
	card.state = Card.states.NOT_IN_HAND
	CardsCollection.cards_in_hand.erase(card)
	_update_hand()
	return card

func _handle_input() -> void:
	if !CardsController.receiving_input():
		state = states.READY
		_stop_hover_card()
		dragged_card = null
		return
		
	if Input.is_action_just_pressed("click"):
		if hovered_card != null:
			if state == states.SELECTING:
				if selected_cards.has(hovered_card):
					selected_cards.erase(hovered_card)
					hovered_card.apply_card_visual_faceup()
					return
				if selected_cards.size() == max_selected:
					return
				for condition in selection_conditions:
					if !condition.call(hovered_card):
						return
				selected_cards.append(hovered_card)
				hovered_card.apply_card_visual_selected()
				return
			hovered_card.state = Card.states.DRAGGING
			hovered_card.movement_tween_manager.pos_tween.stop()
			state = states.DRAGGING
			dragged_card = hovered_card
			drag_offset = hovered_card.global_position - get_viewport().get_mouse_position()
			_show_target_area(hovered_card)
		else:
			for node in cursor.hovering_nodes:
				if node.get_parent() is Card:
					var c : Card = node.get_parent()
					c.state = Card.states.DRAGGING
					c.movement_tween_manager.pos_tween.stop()
					state = states.DRAGGING
					dragged_card = c
					drag_offset = c.global_position - get_viewport().get_mouse_position()
					_show_target_area(c)
			
	if state == states.DRAGGING:
		if dragged_card == null:
			return
		dragged_card.global_position = get_viewport().get_mouse_position() + drag_offset
		var mouse_pos = get_viewport().get_mouse_position()
		if dragged_card.card_data.get_target_type() == CardData.target_type.SINGLE:
			for project in projects_manager.projects:
				var target := project.targetable_indicator
				if project.targetable: 
					if mouse_pos.y > target.global_position.y && mouse_pos.y < target.global_position.y + target.size.y && mouse_pos.x > target.global_position.x && mouse_pos.x < target.global_position.x + target.size.x:
						target.color = Constants.COLOR_HOT_PINK
					else:
						target.color = Constants.COLOR_LIGHT_PINK
		if dragged_card.card_data.get_target_type() == CardData.target_type.ALL:
			var stylebox: StyleBox = projects_manager.get_theme_stylebox("panel")
			if projects_manager.check_mouse_in_area(mouse_pos):
				stylebox.bg_color = Constants.COLOR_HOT_PINK
				projects_manager.add_theme_stylebox_override("panel", stylebox)
			else:
				stylebox.bg_color = Constants.COLOR_LIGHT_PINK
				projects_manager.add_theme_stylebox_override("panel", stylebox)
		
	if Input.is_action_just_released("click"):
		if state != states.DRAGGING:
			return
		state = states.READY
		hovered_card = null
		var returning_card = dragged_card
		dragged_card = null
		
		var mouse_pos = get_viewport().get_mouse_position()
		if returning_card.card_data.get_target_type() == CardData.target_type.ALL:
			if projects_manager.check_mouse_in_area(mouse_pos):
				returning_card.state = Card.states.PLAYING
				CardsController.enqueue_play_card(returning_card)
				_hide_target_area()
				return
		else:
			for project in projects_manager.projects:
				var target := project.targetable_indicator
				if project.targetable && mouse_pos.y > target.global_position.y && mouse_pos.y < target.global_position.y + target.size.y && mouse_pos.x > target.global_position.x && mouse_pos.x < target.global_position.x + target.size.x:
					returning_card.state = Card.states.PLAYING
					if returning_card.card_data.get_target_type() == CardData.target_type.SINGLE:
						CardsController.enqueue_play_card(returning_card, project)
					else: # MULTI
						CardsController.enqueue_play_card(returning_card)
					_hide_target_area()
					return
		
		_hide_target_area()
		return_card(returning_card)
	
	
func _show_target_area(card: Card) -> void:
	if card.card_data.get_target_type() == card.card_data.target_type.UNPLAYABLE: 
		return
	var target_type := card.card_data.get_target_type()
	if target_type == card.card_data.target_type.ALL:
		for condition in card.card_data.get_target_conditions():
			if condition is Callable:
				if condition.call() == false:
					return
		projects_manager.enable_full_area_target()
		return
	
	for project in projects_manager.projects:
		if !project.active:
			continue
		var conditions : Array[Callable] = []
		for condition in card.card_data.get_target_conditions():
			if condition is Callable:
				conditions.append(condition.bind(project))
		project.check_targetable(conditions)
	
func _hide_target_area() -> void:
	projects_manager.disable_full_area_target()
	for project in projects_manager.projects:
		project.hide_targetable()
	
func _hover_card(card: Card) -> void:
	if !card.state == Card.states.READY || state == states.DRAGGING:
		return
		
	# There is a bug with panel's mouse signals. When two nodes have the same parent, the node that is lower will take priority for these signals regardless of z index.
	# That's why we need to move nodes around.
	card.state = Card.states.HOVERING
	CardsCollection.move_card_node_in_hand(card,CardsCollection.cards_in_hand.size() + CardsCollection.cards_in_deck.size() + CardsCollection.cards_in_discard_pile.size())
	hovered_card = card
	card.z_index = CardsCollection.cards_in_hand.size() + CardsCollection.cards_in_deck.size() + CardsCollection.cards_in_discard_pile.size()
	card.hover_card()
	
## Called when mouse exits panel
func _stop_hover_card() -> void:
	if hovered_card != null && hovered_card.state == Card.states.HOVERING:
		hovered_card.state = Card.states.READY
	hovered_card = null
	_update_hand()
	
func return_card(returning_card: Card) -> void:
	returning_card.state = Card.states.RETURNING
	_update_hand()
	
	var tween = create_tween()
	tween.tween_callback(func():
		if returning_card.state != Card.states.DRAGGING:
			returning_card.state = Card.states.READY
	).set_delay(1.0 * Globals.animation_speed_scale)
	

func _update_hand():
	var card_separation: int = _determine_card_separation()
	var hand_length: int = card_separation * (CardsCollection.cards_in_hand.size() - 1)
	var x_pos: int = CENTER_X - hand_length / 2
	var z_index: int = CardsCollection.cards_in_deck.size() + CardsCollection.cards_in_discard_pile.size()
	
	for card in CardsCollection.cards_in_hand:
		if card.state == Card.states.PLAYING || card.state == Card.states.DRAGGING:
			continue
		if !selected_cards.has(card):
			var y_pos = card.position.y if card == hovered_card else DEFAULT_Y
			card.movement_tween_manager.tween_to_pos(card, Vector2(x_pos, y_pos))
		if card.state != card.states.HOVERING and card.state != card.states.DUSK:
			card.z_index = z_index
			
			# There is a bug with panel's mouse signals. When two nodes have the same parent, the node that is lower will take priority for these signals regardless of z index.
			# That's why we need to move nodes around.
			CardsCollection.move_card_node_in_hand(card, z_index)
			
			z_index += 1
		x_pos += card_separation

func _determine_card_separation() -> int:
	return DEFAULT_CARD_SEPARATION / 4 + DEFAULT_CARD_SEPARATION * 3 / 4 / (CardsCollection.cards_in_hand.size() + 1)
	


func _on_confirm_button_mouse_entered() -> void:
	SignalBus.node_hovered.emit(self)


func _on_confirm_button_mouse_exited() -> void:
	SignalBus.node_stop_hovered.emit(self)
