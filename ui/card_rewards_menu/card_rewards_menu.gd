class_name CardRewardsMenu
extends Control

const NUM_CARD_CHOICES = 3

@export var cards_hbox_container: HBoxContainer
@export var skip_button: Button
@export var pick_label: Label

@export var logic_cards_resource_preloader: ResourcePreloader
@export var creativity_cards_resource_preloader: ResourcePreloader
@export var wisdom_cards_resource_preloader: ResourcePreloader
@export var obstacle_cards_resource_preloader: ResourcePreloader

var resolve_manager : ResolveManager
var promise_queue : PromiseQueue

var logic_card_resources_pool: Array[Resource]
var creativity_card_resources_pool : Array[Resource]
var wisdom_card_resources_pool : Array[Resource]
var obstacle_card_resources_pool : Array[Resource]
var curr_choices: Array[Card]
var curr_resolve_choices: Array[ResolvePreview]

## Bug fix for when multiple projects are completed at the same time
var queue_selection: Array[ProjectResource] = []

var applause_sfx := preload("res://audio/sfx/applause.wav")

enum reward_type {
	CARD,
	RESOLVE
}
	
func create_random_card(global_pos := Vector2(0,0), pause_time := 0.0, include_obstacle := false, discard := false) -> Card:
	var card_type = randi() % 4 if include_obstacle else randi() % 3
	var pool : Array[Resource]
	match card_type:
		0: pool = logic_card_resources_pool
		1: pool = creativity_card_resources_pool
		2: pool = wisdom_card_resources_pool
		3: pool = obstacle_card_resources_pool
	var pick = randi() % pool.size()
	return await CardsController._create_card(pool[pick], global_pos, pause_time, discard)
	
func _process(delta: float) -> void:
	if !visible:
		return
	if !Input.is_action_just_pressed("click"):
		return
	var mouse_pos = get_viewport().get_mouse_position()
	if !curr_choices.is_empty():
		for card in curr_choices:
			if mouse_pos.y > card.panel.global_position.y && \
					mouse_pos.y < card.panel.global_position.y + card.panel.size.y && \
					mouse_pos.x > card.panel.global_position.x && \
					mouse_pos.x < card.panel.global_position.x + card.panel.size.x:
				card_picked(card)
				return
	if !curr_resolve_choices.is_empty():
		for preview in curr_resolve_choices:
			if preview.hovering:
				resolve_picked(preview)
				return
	
func add_random_obstacle_card_to_deck() -> void:
	var pick = obstacle_card_resources_pool[randi() % obstacle_card_resources_pool.size()]
	var card = Card.create_card(pick)
	await CardsController._create_card(card.card_data, Vector2(580,220), 2.0, false, true)

func create_card_preview(card_data: CardData) -> Card:
	return Card.create_card(card_data)

func preview_rewards(data : ProjectResource):
	CardsController.pause_queue()
	await get_tree().process_frame
	if !cards_hbox_container.get_children().is_empty():
		queue_selection.push_back(data)
		return
		
	AudioPlayer.play_sound(applause_sfx)
	visible = true
	if data.type == ProjectResource.project_type.OBSTACLE:
		preview_resolves()
	else:
		preview_cards(data)

func preview_resolves():
	pick_label.text = "Resolve Strengthened!\nPick a resolution to add to your deck."
	cards_hbox_container.add_theme_constant_override("separation", 250)
	
	for i in range(0,2):
		var data := resolve_manager.get_random_resolve_data()
		while !curr_resolve_choices.is_empty() && curr_resolve_choices[0].resolve_data.resolve_name == data.resolve_name:
			data = resolve_manager.get_random_resolve_data()
		var preview = ResolvePreview.create_resolve_preview(data)
		cards_hbox_container.add_child(preview)
		curr_resolve_choices.append(preview)
		
func resolve_picked(resolve_preview: ResolvePreview):
	visible = false
	if resolve_preview != null:
		resolve_manager.add_resolve(resolve_preview.resolve_data)
		SignalBus.reward_choice_made.emit(resolve_preview.resolve_data)
	
	curr_resolve_choices.clear()

	for child in cards_hbox_container.get_children():
		child.queue_free()
		
	if !queue_selection.is_empty():
		preview_rewards(queue_selection.pop_front())
	else:	
		CardsController.unpause_queue()
		
func preview_cards(data: ProjectResource):
	pick_label.text = data.displayName + " completed!\nPick a card to add to your deck."
	cards_hbox_container.add_theme_constant_override("separation", 150)
	var pool: Array[Resource]
	match data.type:
		ProjectResource.project_type.LOGIC:
			pool = logic_card_resources_pool
		ProjectResource.project_type.CREATIVITY:
			pool = creativity_card_resources_pool
		ProjectResource.project_type.WISDOM:
			pool = wisdom_card_resources_pool
			
	var picks : Array[int] = []
	for i in range (0, NUM_CARD_CHOICES):
		var pick : int = randi() % pool.size()
		while picks.has(pick):
			pick = randi() % pool.size()
		picks.append(pick)
		var card_preview = create_card_preview(pool[pick])
		card_preview.state = Card.states.PREVIEW_PICKING
		cards_hbox_container.add_child(card_preview)
		curr_choices.append(card_preview)

## Ends the card selection with a choice.
## card: the chosen card being added to the deck. If null, skip was chosen.
func card_picked(card: Card):
	visible = false
	if card != null:
		promise_queue = GameManager.promise_queue
		promise_queue.paused += 1
		CardsController._create_card(card.card_data, card.global_position)
		CardsController._shuffle_deck()
		promise_queue.unpause_after_delay(3)
		SignalBus.reward_choice_made.emit()
	
	curr_choices.clear()
	for child in cards_hbox_container.get_children():
		child.queue_free()
		
	print(queue_selection.size())
	if !queue_selection.is_empty():
		preview_rewards(queue_selection.pop_front())
	else:
		CardsController.unpause_queue()

func _ready() -> void:
	visible = false
	skip_button.focus_mode = FOCUS_NONE
	
	logic_card_resources_pool = _load_cards(logic_cards_resource_preloader)
	creativity_card_resources_pool = _load_cards(creativity_cards_resource_preloader)
	wisdom_card_resources_pool = _load_cards(wisdom_cards_resource_preloader)
	obstacle_card_resources_pool = _load_cards(obstacle_cards_resource_preloader)
	
	resolve_manager = get_tree().get_first_node_in_group("resolve_manager")

func _load_cards(preloader: ResourcePreloader) -> Array[Resource]:
	var arr : Array[Resource] = []
	for resource in preloader.get_resource_list():
		arr.append(preloader.get_resource(resource))
	return arr

func _on_skip_button_pressed() -> void:
	resolve_picked(null)
	card_picked(null)
	SignalBus.reward_choice_made.emit(null)

func _on_skip_button_mouse_entered() -> void:
	SignalBus.node_hovered.emit(skip_button)

func _on_skip_button_mouse_exited() -> void:
	SignalBus.node_stop_hovered.emit(skip_button)
