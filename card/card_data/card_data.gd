class_name CardData
extends Resource

const NO_EFFECT := "NO_EFFECT"

@export var card_name: String

@export var card_cost: int

@export var card_png: CompressedTexture2D

@export_multiline  var card_description: String

@export var card_type: CARD_TYPE

@export var card_effect: CARD_EFFECT

@export var title_font: CARD_FONT = CARD_FONT.FIVE_BY_SEVEN

@export var desc_line_spacing := -2

## If the card title is too long, and overlapping the cost panel, increase this offset to move it off center.
@export_range(0, 12) var card_title_offset := 0

var effect_map: Dictionary[CARD_EFFECT, String] = {
	CARD_EFFECT.NEW_DAY: "_execute_new_day",
	CARD_EFFECT.MEDITATION: "_execute_meditation",
	CARD_EFFECT.ORGANIZE: "_execute_organize",
	CARD_EFFECT.BRAIN_BLAST: "_execute_brain_blast",
	CARD_EFFECT.CLEAN: "_execute_clean",
	CARD_EFFECT.SMALL_STEP: "_execute_small_step",
	CARD_EFFECT.COMPARISON: NO_EFFECT,
	CARD_EFFECT.TOUCH_GRASS: "_execute_touch_grass",
	CARD_EFFECT.MENTAL_HEALTH_DAY: "_execute_mental_health_day",
	CARD_EFFECT.FRIENDSHIP: "_execute_friendship",
	CARD_EFFECT.GRIND_LOGIC: "_execute_grind",
	CARD_EFFECT.GRIND_CREATIVITY: "_execute_grind",
	CARD_EFFECT.GRIND_WISDOM: "_execute_grind",
	CARD_EFFECT.COMMUNITY_SUPPORT: "_execute_community_support",
	CARD_EFFECT.SLEEP_DEPRIVED: NO_EFFECT,
	CARD_EFFECT.ADDICTION: NO_EFFECT,
	CARD_EFFECT.THERAPY: "_execute_therapy",
	CARD_EFFECT.NEW_HOBBY: "_execute_new_hobby",
	CARD_EFFECT.FORGOT_MY_LUNCH: NO_EFFECT,
	CARD_EFFECT.STRONG_START: "_execute_strong_start",
	CARD_EFFECT.REVISION: "_execute_revision",
	CARD_EFFECT.INSPIRED_LOGIC: "_execute_inspired",
	CARD_EFFECT.INSPIRED_CREATIVITY: "_execute_inspired",
	CARD_EFFECT.INSPIRED_WISDOM: "_execute_inspired",
	CARD_EFFECT.SYNCING_UP: "_execute_syncing_up",
	CARD_EFFECT.GLASS_HALF_FULL: "_execute_glass_half_full",
	CARD_EFFECT.EXTRA_CREDIT: "_execute_extra_credit",
	CARD_EFFECT.OVERCOME_ADVERSITY: "_execute_overcome_adversity",
	CARD_EFFECT.ROUTINE: "_execute_routine",
	CARD_EFFECT.ANXIETY: NO_EFFECT,
	CARD_EFFECT.GRIND: "_execute_grind",
	CARD_EFFECT.WALK_THE_DOG: "_execute_walk_the_dog"
}

var draw_effect_map: Dictionary[CARD_EFFECT, String] = {
	CARD_EFFECT.NEW_DAY: NO_EFFECT,
	CARD_EFFECT.MEDITATION: NO_EFFECT,
	CARD_EFFECT.ORGANIZE: NO_EFFECT,
	CARD_EFFECT.BRAIN_BLAST: NO_EFFECT,
	CARD_EFFECT.CLEAN: NO_EFFECT,
	CARD_EFFECT.SMALL_STEP: NO_EFFECT,
	CARD_EFFECT.COMPARISON: NO_EFFECT,
	CARD_EFFECT.TOUCH_GRASS: NO_EFFECT,
	CARD_EFFECT.MENTAL_HEALTH_DAY: NO_EFFECT,
	CARD_EFFECT.FRIENDSHIP: NO_EFFECT,
	CARD_EFFECT.GRIND_LOGIC: NO_EFFECT,
	CARD_EFFECT.GRIND_CREATIVITY: NO_EFFECT,
	CARD_EFFECT.GRIND_WISDOM: NO_EFFECT,
	CARD_EFFECT.COMMUNITY_SUPPORT: NO_EFFECT,
	CARD_EFFECT.SLEEP_DEPRIVED: NO_EFFECT,
	CARD_EFFECT.ADDICTION: NO_EFFECT,
	CARD_EFFECT.THERAPY: NO_EFFECT,
	CARD_EFFECT.NEW_HOBBY: NO_EFFECT,
	CARD_EFFECT.FORGOT_MY_LUNCH: NO_EFFECT,
	CARD_EFFECT.STRONG_START: NO_EFFECT,
	CARD_EFFECT.REVISION: NO_EFFECT,
	CARD_EFFECT.INSPIRED_LOGIC: NO_EFFECT,
	CARD_EFFECT.INSPIRED_CREATIVITY: NO_EFFECT,
	CARD_EFFECT.INSPIRED_WISDOM: NO_EFFECT,
	CARD_EFFECT.SYNCING_UP: NO_EFFECT,
	CARD_EFFECT.GLASS_HALF_FULL: NO_EFFECT,
	CARD_EFFECT.EXTRA_CREDIT: NO_EFFECT,
	CARD_EFFECT.OVERCOME_ADVERSITY: NO_EFFECT,
	CARD_EFFECT.ROUTINE: NO_EFFECT,
	CARD_EFFECT.ANXIETY: NO_EFFECT,
	CARD_EFFECT.GRIND: NO_EFFECT,
	CARD_EFFECT.WALK_THE_DOG: NO_EFFECT
}

var dusk_effect_map: Dictionary[CARD_EFFECT, String] = {
	CARD_EFFECT.NEW_DAY: NO_EFFECT,
	CARD_EFFECT.MEDITATION: NO_EFFECT,
	CARD_EFFECT.ORGANIZE: NO_EFFECT,
	CARD_EFFECT.BRAIN_BLAST: NO_EFFECT,
	CARD_EFFECT.CLEAN: NO_EFFECT,
	CARD_EFFECT.SMALL_STEP: NO_EFFECT,
	CARD_EFFECT.COMPARISON: "_dusk_effect_comparison",
	CARD_EFFECT.TOUCH_GRASS: NO_EFFECT,
	CARD_EFFECT.MENTAL_HEALTH_DAY: NO_EFFECT,
	CARD_EFFECT.FRIENDSHIP: NO_EFFECT,
	CARD_EFFECT.GRIND_LOGIC: NO_EFFECT,
	CARD_EFFECT.GRIND_CREATIVITY: NO_EFFECT,
	CARD_EFFECT.GRIND_WISDOM: NO_EFFECT,
	CARD_EFFECT.COMMUNITY_SUPPORT: NO_EFFECT,
	CARD_EFFECT.SLEEP_DEPRIVED: NO_EFFECT,
	CARD_EFFECT.ADDICTION: "_dusk_effect_addiction",
	CARD_EFFECT.THERAPY: NO_EFFECT,
	CARD_EFFECT.NEW_HOBBY: NO_EFFECT,
	CARD_EFFECT.FORGOT_MY_LUNCH: "_dusk_effect_forgot_my_lunch",
	CARD_EFFECT.STRONG_START: NO_EFFECT,
	CARD_EFFECT.REVISION: NO_EFFECT,
	CARD_EFFECT.INSPIRED_LOGIC: NO_EFFECT,
	CARD_EFFECT.INSPIRED_CREATIVITY: NO_EFFECT,
	CARD_EFFECT.INSPIRED_WISDOM: NO_EFFECT,
	CARD_EFFECT.SYNCING_UP: NO_EFFECT,
	CARD_EFFECT.GLASS_HALF_FULL: NO_EFFECT,
	CARD_EFFECT.EXTRA_CREDIT: NO_EFFECT,
	CARD_EFFECT.OVERCOME_ADVERSITY: NO_EFFECT,
	CARD_EFFECT.ROUTINE: NO_EFFECT,
	CARD_EFFECT.ANXIETY: "_dusk_effect_anxiety",
	CARD_EFFECT.GRIND: NO_EFFECT,
	CARD_EFFECT.WALK_THE_DOG: NO_EFFECT
}

var target_type_map: Dictionary[CARD_EFFECT, target_type] = {
	CARD_EFFECT.NEW_DAY: target_type.ALL,
	CARD_EFFECT.MEDITATION: target_type.ALL,
	CARD_EFFECT.ORGANIZE: target_type.ALL,
	CARD_EFFECT.BRAIN_BLAST: target_type.ALL,
	CARD_EFFECT.CLEAN: target_type.ALL,
	CARD_EFFECT.SMALL_STEP: target_type.SINGLE,
	CARD_EFFECT.COMPARISON: target_type.UNPLAYABLE,
	CARD_EFFECT.TOUCH_GRASS: target_type.ALL,
	CARD_EFFECT.MENTAL_HEALTH_DAY: target_type.ALL,
	CARD_EFFECT.FRIENDSHIP: target_type.ALL,
	CARD_EFFECT.GRIND_LOGIC: target_type.SINGLE,
	CARD_EFFECT.GRIND_CREATIVITY: target_type.SINGLE,
	CARD_EFFECT.GRIND_WISDOM: target_type.SINGLE,
	CARD_EFFECT.COMMUNITY_SUPPORT: target_type.ALL,
	CARD_EFFECT.SLEEP_DEPRIVED: target_type.UNPLAYABLE,
	CARD_EFFECT.ADDICTION: target_type.UNPLAYABLE,
	CARD_EFFECT.THERAPY: target_type.ALL,
	CARD_EFFECT.NEW_HOBBY: target_type.ALL,
	CARD_EFFECT.FORGOT_MY_LUNCH: target_type.UNPLAYABLE,
	CARD_EFFECT.STRONG_START: target_type.SINGLE,
	CARD_EFFECT.REVISION: target_type.SINGLE,
	CARD_EFFECT.INSPIRED_LOGIC: target_type.SINGLE,
	CARD_EFFECT.INSPIRED_CREATIVITY: target_type.SINGLE,
	CARD_EFFECT.INSPIRED_WISDOM: target_type.SINGLE,
	CARD_EFFECT.SYNCING_UP: target_type.SINGLE,
	CARD_EFFECT.GLASS_HALF_FULL: target_type.SINGLE,
	CARD_EFFECT.EXTRA_CREDIT: target_type.SINGLE,
	CARD_EFFECT.OVERCOME_ADVERSITY: target_type.ALL,
	CARD_EFFECT.ROUTINE: target_type.ALL,
	CARD_EFFECT.ANXIETY: target_type.UNPLAYABLE,
	CARD_EFFECT.GRIND: target_type.SINGLE,
	CARD_EFFECT.WALK_THE_DOG: target_type.ALL
}

## Project targeted cards must have project bound.
var target_conditions_map: Dictionary[CARD_EFFECT, Array] = {
	CARD_EFFECT.GRIND_LOGIC: [_project_is_logic],
	CARD_EFFECT.GRIND_CREATIVITY: [_project_is_creativity],
	CARD_EFFECT.GRIND_WISDOM: [_project_is_wisdom],
	CARD_EFFECT.COMMUNITY_SUPPORT: [_no_community_support_in_play],
	CARD_EFFECT.INSPIRED_LOGIC: [_project_is_logic],
	CARD_EFFECT.INSPIRED_CREATIVITY: [_project_is_creativity],
	CARD_EFFECT.INSPIRED_WISDOM: [_project_is_wisdom]
}

enum CARD_TYPE {
	TECH,
	ART,
	SPIRIT,
	OBSTACLE
}

enum CARD_FONT {
	THREE_BY_SIX,
	FIVE_BY_SEVEN
}

enum CARD_EFFECT {
	NEW_DAY,
	MEDITATION,
	ORGANIZE,
	BRAIN_BLAST,
	CLEAN,
	SMALL_STEP,
	COMPARISON,
	TOUCH_GRASS,
	MENTAL_HEALTH_DAY,
	FRIENDSHIP,
	GRIND_LOGIC,
	GRIND_CREATIVITY,
	GRIND_WISDOM,
	COMMUNITY_SUPPORT,
	SLEEP_DEPRIVED,
	ADDICTION,
	THERAPY,
	NEW_HOBBY,
	FORGOT_MY_LUNCH,
	STRONG_START,
	REVISION,
	INSPIRED_LOGIC,
	INSPIRED_CREATIVITY,
	INSPIRED_WISDOM,
	SYNCING_UP,
	GLASS_HALF_FULL,
	EXTRA_CREDIT,
	OVERCOME_ADVERSITY,
	ROUTINE,
	ANXIETY,
	GRIND,
	WALK_THE_DOG
}

enum target_type {
	SINGLE,
	MULTI,
	ALL,
	UNPLAYABLE
}

func _no_community_support_in_play() -> bool:
	for connection in SignalBus.card_played.get_connections():
		var callable : Callable = connection["callable"]
		if callable.get_method() == "_trigger_community_support":
			return false
	return true

func _project_not_creativity(project: Project):
	return project.template.type != project.template.project_type.CREATIVITY
	
func _project_is_creativity(project: Project):
	return project.template.type == project.template.project_type.CREATIVITY
	
func _project_is_logic(project: Project):
	return project.template.type == project.template.project_type.LOGIC
	
func _project_is_wisdom(project: Project):
	return project.template.type == project.template.project_type.WISDOM

func get_target_type() -> target_type:
	return target_type_map[card_effect]

func get_target_conditions() -> Array:
	if target_conditions_map.has(card_effect):
		return target_conditions_map[card_effect]
	return []

func get_font() -> Font:
	var font: Font
	if title_font == CARD_FONT.THREE_BY_SIX:
		font = load("res://fonts/m3x6.ttf")
		return font
	font = load("res://fonts/m5x7.ttf")
	return font
