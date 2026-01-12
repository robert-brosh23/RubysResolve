class_name Card
extends Control

const SELECTED_CARD_Y_OFFSET = 48.0
const DEFAULT_POS_Y = 350.0

const TECH_STYLEBOX_PATH = "res://card/card_data/styles/stylebox/tech_stylebox.tres"
const TECH_STYLEBOX_IMAGE_FRAME_PATH = "res://card/card_data/styles/stylebox/image_frame_tech_stylebox.tres"
const ART_STYLEBOX_PATH = "res://card/card_data/styles/stylebox/art_stylebox.tres"
const ART_STYLEBOX_IMAGE_FRAME_PATH = "res://card/card_data/styles/stylebox/image_frame_art_stylebox.tres"
const SPIRIT_STYLEBOX_PATH = "res://card/card_data/styles/stylebox/standard_stylebox.tres"
const SPIRIT_STYLEBOX_IMAGE_FRAME_PATH = "res://card/card_data/styles/stylebox/image_frame_standard_stylebox.tres"
const OBSTACLE_STYLEBOX_PATH = "res://card/card_data/styles/stylebox/obstacle_stylebox.tres"
const OBSTACLE_STYLEBOX_IMAGE_FRAME_PATH = "res://card/card_data/styles/stylebox/image_frame_obstacle_stylebox.tres"
const FACE_DOWN_CARD_STYLEBOX_PATH = "res://card/card_data/styles/stylebox/face_down_card_stylebox.tres"

const FRIENDSHIP_INCREASE := .03

@export var card_data: CardData
@export var movement_tween_manager: MovementTweenManager
var game_manager: GameManager

@onready var panel: Panel = $Panel
@onready var margin_container = $Panel/MarginContainer
@onready var panel_container = $Panel/MarginContainer/VBoxContainer/PanelContainer
@onready var title_label = $Panel/MarginContainer/VBoxContainer/HBoxContainer/TitleLabel
@onready var texture_label = $Panel/MarginContainer/VBoxContainer/PanelContainer/TextureRect
@onready var description_label = $Panel/MarginContainer/VBoxContainer/DescriptionLabel
@onready var animation_player = $AnimationPlayer
@onready var cost_panel_margin_container = $Panel/MarginContainer/VBoxContainer/HBoxContainer/CostPanelMarginContainer
@onready var cost_label = $Panel/MarginContainer/VBoxContainer/HBoxContainer/CostPanelMarginContainer/CostPanel/CostLabel
@onready var dusk_animation_border = $Panel/DuskAnimationBorder

var flipped_up: bool = true
var selected_font = FontFile
var state: states = states.NOT_IN_HAND
var promise_queue: PromiseQueue
var projects_manager: ProjectsManager
var card_rewards_menu: CardRewardsMenu
var main_ui: MainUi
var hours_tracker: HoursTracker
var cursor: Cursor
var player_status_manager: PlayerStatusManager

var cost := 0:
	set(value):
		cost = value
		cost_label.text = str(value)
		
var perm_cost: int

var description: String:
	set(value):
		description = value
		description_label.text = value

var friendship_amount: float = .15

var delete_sound := preload("res://audio/sfx/110931__chrisw92__error2.wav")


enum states {READY, NOT_IN_HAND, HOVERING, DUSK, DRAGGING, PLAYING, RETURNING, PREVIEW_PICKING, DELETING}

## Creates a new card, given the card_data
static func create_card(card_data: CardData) -> Card:
	var instance = preload("res://card/card.tscn").instantiate()
	instance.card_data = card_data
	instance.perm_cost = card_data.card_cost
	instance.z_index = 16
	return instance

func _ready() -> void:
	game_manager = get_tree().get_first_node_in_group("game_manager")
	projects_manager = get_tree().get_first_node_in_group("projects_manager")
	card_rewards_menu = get_tree().get_first_node_in_group("card_rewards_menu")
	main_ui = get_tree().get_first_node_in_group("main_ui")
	hours_tracker = get_tree().get_first_node_in_group("hours_tracker")
	cursor = get_tree().get_first_node_in_group("cursor")
	player_status_manager = get_tree().get_first_node_in_group("player_status_manager")
	animation_player.speed_scale = 1.0 / Globals.animation_speed_scale
	promise_queue = GameManager.promise_queue
	calibrate_cost()
	apply_card_visual_faceup()
	_pull_starting_card_data()
	
	SignalBus.alter_cost.connect(
		func():
			calibrate_cost()
	)

func calibrate_cost() -> void:
	cost = perm_cost * SignalBus.cost_multiplier
	if SignalBus.cost_multiplier > 1.0:
		cost_label.add_theme_color_override("font_color", Constants.COLOR_HOT_PINK)
	else:
		cost_label.add_theme_color_override("font_color", Constants.COLOR_PURPLE)

## Check to see if the card can be played, and play it.
## target: the project targeted with this card. Will be null if the card doesn't need a target
## Returns true if the card was played, false if it cannot be played
func play_card(target: Project) -> bool:
	if cost > game_manager.hours:
		print("This card costs too much.")
		cursor.play_message("Not enough hours...")
		return false
	
	game_manager.hours -= cost
	await play_card_effect(target)
	print (card_data.card_name, " was played.")
	hours_tracker._check_cards_playable(self, target)
	return true
	
func delete_card() -> void:
	state = states.DELETING
	AudioPlayer.play_sound(delete_sound)
	animation_player.play("delete")
	if CardsCollection.cards_in_hand.has(self):
		CardsCollection.cards_in_hand.erase(self)
	elif CardsCollection.cards_in_deck.has(self):
		CardsCollection.cards_in_deck.erase(self)
	elif CardsCollection.cards_in_discard_pile.has(self):
		CardsCollection.cards_in_discard_pile.erase(self)
	else:
		print("ERROR: card not found in deck, hand, or discard pile. Cannot delete.")
	CardsCollection.deleted_cards.append(self)
	
## Execute the card's specific played effect.
func play_card_effect(target: Project) -> void:
	SignalBus.start_card_played.emit(self, target)
	var effect := card_data.effect_map[card_data.card_effect]
	if effect == CardData.NO_EFFECT:
		return
	
	promise_queue.paused += 1
	if target == null:
		await call(card_data.effect_map[card_data.card_effect])
	else:
		await call(card_data.effect_map[card_data.card_effect], target)
		
	SignalBus.card_played.emit(self, target)
	promise_queue.paused -= 1
	
func draw_card_effect() -> void:
	var effect := card_data.draw_effect_map[card_data.card_effect]
	if effect == CardData.NO_EFFECT:
		return
	
	promise_queue.paused += 1
	await call(card_data.draw_effect_map[card_data.card_effect])
	promise_queue.paused -= 1
	
func dusk_card_effect() -> void:
	var effect := card_data.dusk_effect_map[card_data.card_effect]
	if effect == CardData.NO_EFFECT:
		return
	
	promise_queue.paused += 1
	state = states.DUSK
	z_index = 100
	var pos_tween = create_tween()
	pos_tween.tween_property(panel, "position:y", -120, .25 * Globals.animation_speed_scale)
	
	animation_player.play("activate_dusk_effect")
	await call(card_data.dusk_effect_map[card_data.card_effect])
	await get_tree().create_timer(1).timeout
	animation_player.stop()
	dusk_animation_border.visible = false
	state = states.NOT_IN_HAND
	
	var pos_tween2 = create_tween()
	pos_tween2.tween_property(panel, "position:y", -64, .5 * Globals.animation_speed_scale)
	promise_queue.paused -= 1
	
func hover_card() -> void:
	state = states.HOVERING
	movement_tween_manager.tween_to_pos(self, Vector2(position.x, DEFAULT_POS_Y - SELECTED_CARD_Y_OFFSET), .1)
	
func flip_card_up() -> void:
	if flipped_up == true:
		return
	flipped_up = true
	animation_player.play("flip_card_up")
	
func flip_card_down() -> void:
	if flipped_up == false:
		return
	flipped_up = false
	animation_player.play("flip_card_down")
	
func apply_card_visual_selected() -> void:
	var sb := panel.get("theme_override_styles/panel") as StyleBoxFlat
	var copy = sb.duplicate()
	copy.border_color = "ffa7a5"
	panel.add_theme_stylebox_override("panel", copy)

func apply_card_visual_facedown() -> void:
	var stylebox: StyleBoxFlat = preload(FACE_DOWN_CARD_STYLEBOX_PATH)
	panel.add_theme_stylebox_override("panel", stylebox)
	margin_container.visible = false

func apply_card_visual_faceup() -> void:
	if card_data == null:
		return
	
	match card_data.card_type:
		CardData.CARD_TYPE.TECH:
			_apply_card_type_visual_tech()
		CardData.CARD_TYPE.ART:
			_apply_card_type_visual_art()
		CardData.CARD_TYPE.SPIRIT:
			_apply_card_type_visual_spirit()
		CardData.CARD_TYPE.OBSTACLE:
			_apply_card_type_visual_obstacle()
			
	if card_data.get_target_type() == CardData.target_type.UNPLAYABLE:
		cost_panel_margin_container.visible = false
	else:
		cost_panel_margin_container.visible = true	
		
	var font := card_data.get_font()
	title_label.add_theme_font_override("font", font)
	
	margin_container.visible = true

func _pull_starting_card_data() -> void:
	if card_data == null:
		return
	
	title_label.text = card_data.card_name
	texture_label.texture = card_data.card_png
	description = card_data.card_description
	
	description_label.add_theme_constant_override("line_spacing", card_data.desc_line_spacing)
	
	_apply_spacer_container_margin()

## TECH CARD TYPE
func _apply_card_type_visual_tech() -> void:
	panel.add_theme_stylebox_override("panel", _get_tech_stylebox())
	panel_container.add_theme_stylebox_override("panel", _get_tech_image_frame_stylebox())
	_apply_tech_fonts()

func _get_tech_stylebox() -> StyleBox:
	var stylebox: StyleBoxFlat = preload(TECH_STYLEBOX_PATH)
	return stylebox
	
func _get_tech_image_frame_stylebox() -> StyleBox:
	var stylebox: StyleBoxFlat = preload(TECH_STYLEBOX_IMAGE_FRAME_PATH)
	return stylebox
	
func _apply_tech_fonts() -> void:
	title_label.add_theme_color_override("font_color", "ffe7d6")
	description_label.add_theme_color_override("font_color", "ffe7d6")


## ART CARD TYPE
func _apply_card_type_visual_art() -> void:
	panel.add_theme_stylebox_override("panel", _get_art_stylebox())
	panel_container.add_theme_stylebox_override("panel", _get_art_image_frame_stylebox())
	_apply_art_fonts()

func _get_art_stylebox() -> StyleBox:
	var stylebox: StyleBoxFlat = preload(ART_STYLEBOX_PATH)
	return stylebox
	
func _get_art_image_frame_stylebox() -> StyleBox:
	var stylebox: StyleBoxFlat = preload(ART_STYLEBOX_IMAGE_FRAME_PATH)
	return stylebox
	
func _apply_art_fonts() -> void:
	title_label.add_theme_color_override("font_color", "ab5675")
	description_label.add_theme_color_override("font_color", "ab5675")


## SPIRIT CARD TYPE
func _apply_card_type_visual_spirit() -> void:
	panel.add_theme_stylebox_override("panel", _get_spirit_stylebox())
	panel_container.add_theme_stylebox_override("panel", _get_spirit_image_frame_stylebox())
	_apply_standard_fonts()

func _get_spirit_stylebox() -> StyleBox:
	var stylebox: StyleBoxFlat = preload(SPIRIT_STYLEBOX_PATH)
	return stylebox
	
func _get_spirit_image_frame_stylebox() -> StyleBox:
	var stylebox: StyleBoxFlat = preload(SPIRIT_STYLEBOX_IMAGE_FRAME_PATH)
	return stylebox
	
func _apply_standard_fonts() -> void:
	title_label.add_theme_color_override("font_color", Constants.COLOR_PURPLE)
	description_label.add_theme_color_override("font_color", Constants.COLOR_PURPLE)


## OBSTACLE CARD TYPE
func _apply_card_type_visual_obstacle() -> void:
	panel.add_theme_stylebox_override("panel", _get_obstacle_stylebox())
	panel_container.add_theme_stylebox_override("panel", _get_obstacle_image_frame_stylebox())
	_apply_obstacle_fonts()

func _get_obstacle_stylebox() -> StyleBox:
	var stylebox: StyleBoxFlat = preload(OBSTACLE_STYLEBOX_PATH)
	return stylebox
	
func _get_obstacle_image_frame_stylebox() -> StyleBox:
	var stylebox: StyleBoxFlat = preload(OBSTACLE_STYLEBOX_IMAGE_FRAME_PATH)
	return stylebox
	
func _apply_obstacle_fonts() -> void:
	title_label.add_theme_color_override("font_color", "ffe7d6")
	description_label.add_theme_color_override("font_color", "ffe7d6")
	
func _apply_spacer_container_margin() -> void:
	cost_panel_margin_container.add_theme_constant_override("margin_right", -11 + card_data.card_title_offset)
	
	
# CARD EFFECT FUNCTIONS
func _execute_new_day():
	cursor.play_message("Let's start off the day right.")
	for i in range(0,2):
		var card := await CardsController.peek_at_top_card_of_deck()
		if card == null:
			continue
		if card.card_data.card_type == card_data.CARD_TYPE.OBSTACLE:
			await CardsController._discard_card_from_deck()
		else:
			await CardsController.draw_card_from_deck()
		await get_tree().create_timer(.2).timeout
	
	
func _execute_meditation():
	cursor.play_message("Hmmmmmmmm")
	await CardsController.move_cards_from_discard_pile_to_deck_and_shuffle()
	await CardsController.draw_card_from_deck()
	await get_tree().create_timer(.2).timeout
	
func _execute_organize():
	cursor.play_message("Put this here, and that there...")
	SignalBus.new_day_started.connect(
		func(day: int): 
			game_manager.hours += 3
			cursor.play_message("+3 hours (Organized)")
			, CONNECT_ONE_SHOT
	)
	
func _execute_brain_blast():
	cursor.play_message("Got an idea.")

	for i in range(0,3):
		await CardsController.draw_card_from_deck()
		await get_tree().create_timer(.2).timeout
		
func _execute_clean():
	delete_card()
	cursor.play_message("Dusty in here...")
	var conditions: Array[Callable] = [func(card: Card): return card.card_data.card_type != CardData.CARD_TYPE.OBSTACLE]
	var result := await CardsController.select_cards(3, conditions, self)
	
	for card in result:
		card.delete_card()
		
	for i in range(0,result.size()):
		await CardsController.draw_card_from_deck()
		await get_tree().create_timer(.2).timeout
	
func _execute_small_step(target: Project):
	target.add_step_and_progress()
	
func _execute_touch_grass():
	var amount: int = GameManager.stress * 0.2
	
	cursor.play_message("-" + str(amount) + " Stress")
	GameManager.stress -= amount
	
func _execute_friendship():
	var amount: int = GameManager.stress * friendship_amount
	GameManager.stress -= amount
	if friendship_amount != 1.0:
		cursor.play_message("Friendship improved :)")
		cursor.play_message("-" + str(amount) + " Stress")
		friendship_amount += FRIENDSHIP_INCREASE
		description = "Reduce stress by " + str(int(friendship_amount * 100)) + "%, then permanently increase this amount by 3%."
		
func _execute_grind(target: Project):
	target.progress(2)
	
func _execute_inspired(target: Project):
	cursor.play_message("Feeling inspired")
	target.progress(10)
	
func _execute_community_support():
	SignalBus.start_card_played.connect(_trigger_community_support, CONNECT_ONE_SHOT)
	
	SignalBus.new_day_started.connect(
		func(day: int): 
			if SignalBus.start_card_played.is_connected(_trigger_community_support):
				SignalBus.start_card_played.disconnect(_trigger_community_support)
		
	, CONNECT_ONE_SHOT)
	
func _trigger_community_support(card: Card, target: Project):
	if card.card_data.card_effect == CardData.CARD_EFFECT.COMMUNITY_SUPPORT:
		SignalBus.start_card_played.connect(_trigger_community_support, CONNECT_ONE_SHOT)
		return
	
	while true:
		var args = await SignalBus.card_played
		var card_candidate: Card = args[0]
		if card_candidate == card:
			break
	await card.play_card_effect(target)
	cursor.play_message("Supported!")
	
func _delete_self():
	delete_card()
	
func _execute_mental_health_day():
	cursor.play_message("Nice to take a day off.")
	for i in range(CardsCollection.cards_in_hand.size() - 1, -1, -1):
		if CardsCollection.cards_in_hand[i].card_data.card_type == CardData.CARD_TYPE.OBSTACLE:
			CardsCollection.cards_in_hand[i].delete_card()
			
	_delete_self()
			
func _execute_therapy():
	var obstacles : Array[Card] = []
	for card in CardsCollection.cards_in_hand:
		if card.card_data.card_type == CardData.CARD_TYPE.OBSTACLE:
			obstacles.append(card)
	if obstacles.is_empty():
		return
		
	var card = obstacles.pick_random()
	cursor.play_message("Phew")
	card.delete_card()
	var hand: Hand = get_tree().get_first_node_in_group("hand")
	hand._update_hand()
	
func _execute_new_hobby():
	cursor.play_message("Let's try something new...")
	var select_conditions: Array[Callable] = [func(card: Card): return card.card_data.card_type != CardData.CARD_TYPE.OBSTACLE]
	var result := await CardsController.select_cards(1, select_conditions, self)
	if result.is_empty():
		return
	result[0].delete_card()
	var card := await card_rewards_menu.create_random_card(result[0].global_position, 1.0, false, true)
	if card.card_data.get_target_type() == CardData.target_type.SINGLE:
		var project_target = null
		for project in projects_manager.projects:
			if !project.active:
				continue
			var conditions : Array[Callable] = []
			for condition in card.card_data.get_target_conditions():
				if condition is Callable:
					if condition.call(project) == false:
						continue
				project_target = project
				break
			if project_target != null:
				break
		if card.card_data.get_target_conditions().is_empty():
			project_target = projects_manager.projects[0]
		if project_target != null:
			await card.play_card_effect(project_target)
	else:
		await card.play_card_effect(null)
		
	var hand: Hand = get_tree().get_first_node_in_group("hand")
	hand._update_hand()
	
# DRAW EFFECTS
func _draw_effect_comparison():
	cursor.play_message("+20 Stress (Comparison)")
	game_manager.stress += 20
	projects_manager.projects[randi() % projects_manager.projects.size()].progress(3)
	
func _draw_effect_addiction():
	cursor.play_message("-3 Hours (Addiction)")
	game_manager.hours -= 3
	
#func _draw_effect_forgot_my_lunch():
	#cursor.play_message("Forgot my lunch :(")
	#SignalBus.cost_multiplier *= 2.0
	#SignalBus.alter_cost.emit()
	#SignalBus.start_card_played.connect(_forgot_my_lunch_reset_card_played, CONNECT_ONE_SHOT)
	#SignalBus.new_day_started.connect(_forgot_my_lunch_reset_new_day, CONNECT_ONE_SHOT)
	
func _execute_strong_start(target: Project):
	if target.current_progress == 0:
		cursor.play_message("Started Strong!")
		target.progress(6)
	else:
		target.progress(2)
		
func _execute_revision(target: Project):
	cursor.play_message("Let's change things around")
	var split_progress = target.current_progress / (projects_manager.projects.size() - 1)
	target.set_progress(0)
	for i in range (projects_manager.projects.size() - 1, -1, -1):
		if projects_manager.projects[i] == target:
			continue
		await projects_manager.projects[i].progress(split_progress)
		
func _execute_syncing_up(target: Project):
	target.progress(3)
	if target == null || !target.active:
		return
		
	var synced := false
	for i in range (projects_manager.projects.size() - 1, -1, -1):
		if projects_manager.projects[i] == target:
			continue
		if projects_manager.projects[i].current_progress == target.current_progress:
			synced = true
	if synced && target != null && target.active:
		cursor.play_message("Synced up!")
		GameManager.hours += 3
		for i in range(0,3):
			await CardsController.draw_card_from_deck()
			await get_tree().create_timer(.2).timeout

func _execute_glass_half_full(target: Project):
	cursor.play_message("Things are looking up")
	target.progress((target.target_progress - target.current_progress) / 2)
	
func _execute_extra_credit(target: Project):
	cursor.play_message("I can do it... I think")
	target.target_progress *= 2
	target.progress(0) # update the label

func _execute_overcome_adversity():
	cursor.play_message("This is nothing.")
	var obstacle_count = 0
	for card in CardsCollection.cards_in_hand:
		if card.card_data.card_type == CardData.CARD_TYPE.OBSTACLE:
			obstacle_count += 1
	game_manager.hours += (2 * obstacle_count)
	cursor.play_message("+ " + str(2 * obstacle_count) + " Hours")
	
func _execute_routine():
	var result := await CardsController.select_cards(1, [func(card: Card): return card.perm_cost > 0], self)
	if result.is_empty():
		return
	cursor.play_message("Permanent cost decreased!")
	result[0].perm_cost -= 1
	result[0].calibrate_cost()
	_delete_self()
	
func _execute_sleep_deprived():
	cursor.play_message("So sleepy...")
	_delete_self()
	
func _execute_walk_the_dog():
	cursor.play_message("Let's go, Butters.")
	for status in player_status_manager.statuses:
		if status.status_data.effect == PlayerStatusData.player_status_effect.CUTE_DOG:
			status.status_data.counter += 1
			return
	player_status_manager.add_status(load("res://status/player_status/data/statuses/cute_dog.tres") as PlayerStatusData)
	
func _draw_effect_anxiety():
	cursor.play_message("+10 Stress (Anxiety)")
	game_manager.stress += 10
	
func _dusk_effect_forgot_my_lunch():
	cursor.play_message("Forgot my lunch :(")
	player_status_manager.add_status(load("res://status/player_status/data/statuses/forgot_lunch.tres") as PlayerStatusData)
	
func _dusk_effect_anxiety():
	cursor.play_message("+10 Stress (Anxiety)")
	game_manager.stress += 15
	
func _dusk_effect_comparison():
	cursor.play_message("+20 Stress (Comparison)")
	game_manager.stress += 25
	await projects_manager.projects[randi() % projects_manager.projects.size()].progress(3)
	
func _dusk_effect_addiction():
	cursor.play_message("-3 Hours (Addiction)")
	player_status_manager.add_status(load("res://status/player_status/data/statuses/addiction.tres") as PlayerStatusData)
	
func _on_panel_mouse_entered() -> void:
	if state == states.READY || state == states.DRAGGING || state == states.PREVIEW_PICKING || state == states.RETURNING:
		SignalBus.node_hovered.emit(panel)

func _on_panel_mouse_exited() -> void:
	SignalBus.node_stop_hovered.emit(panel)
