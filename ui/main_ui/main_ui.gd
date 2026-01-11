class_name MainUi
extends Control

@export var day_label : Label
@export var deadline_label : RichTextLabel
@export var score_label : Label
@export var target_label : Label
@export var progress_bar : ProgressBar

@export var stress_label : RichTextLabel
@export var stress_accumulation_bar : ProgressBar
@export var stress_accumulation_label : Label

var cursor: Cursor

var shake_stress_label = false

var curr_deadline_index = 0
var deadlines : Array[Deadline]

class Deadline:
	var day: int
	var target_score: int

	static func create_deadline(_day: int, _target_score: int) -> Deadline:
		var deadline = Deadline.new()
		deadline.day = _day
		deadline.target_score = _target_score
		return deadline


func _ready() -> void:
	stress_accumulation_bar.max_value = GameManager.MAX_STRESS_ACCUMULATION
	stress_accumulation_bar.value = 0
	cursor = get_tree().get_first_node_in_group("cursor")
	initialize_deadlines()
	
func set_stress_label(stress: int):
	var text = "Stress: "
	if shake_stress_label:
		text += "[color=#ab5675][shake rate=25.0 level=15 connected=1]" + str(stress) + "[/shake][/color]"
	else:
		text += str(stress)
	stress_label.text = text
	
func set_stress_accumulation_bar(target_value: int):
	shake_stress_label = true
	set_stress_label(GameManager.stress)
	var curr_value := stress_accumulation_bar.value
	while curr_value != target_value:
		curr_value += 1
		await _tween_progress_bar(stress_accumulation_bar, curr_value, .025)
		stress_accumulation_label.text = str(int(curr_value)) + "/" + str(GameManager.MAX_STRESS_ACCUMULATION)
	shake_stress_label = false
	set_stress_label(GameManager.stress)
		
func reset_stress_accumulation_bar():
	shake_stress_label = true
	set_stress_label(GameManager.stress)
	await _tween_progress_bar(stress_accumulation_bar, 0, .5)
	stress_accumulation_label.text = str(int(0)) + "/10"
	shake_stress_label = false
	set_stress_label(GameManager.stress)

func set_day_label(day: int):
	day_label.text = "Day : " + str(day)
	
func _tween_progress_bar(bar: ProgressBar, new_value: float, duration: float = 0.5) -> void:
	var tween := get_tree().create_tween()
	await tween.tween_property(bar, "value", new_value, duration).set_trans(Tween.TRANS_LINEAR).finished
	
func set_score_label(score: int):
	score_label.text = "Score : " + str(score)
	
	if curr_deadline_index == deadlines.size():
		progress_bar.value = deadlines.back().target_score
		print("You win")
		return
		
	if score >= deadlines[curr_deadline_index].target_score:
		deadline_met(score)
		return
	
	target_label.text = "Target: " + str(deadlines[curr_deadline_index].target_score)
	
	if GameManager.day != deadlines[curr_deadline_index].day:
		deadline_label.text = "Deadline: Day " + str(deadlines[curr_deadline_index].day)
	else:
		deadline_label.text = "Deadline: [color=#ab5675][shake rate=25.0 level=15 connected=1]Day " + str(deadlines[curr_deadline_index].day) + "[/shake][/color]"
		
	var previous_target = 0
	if curr_deadline_index != 0:
		previous_target = deadlines[curr_deadline_index - 1].target_score
	progress_bar.min_value = previous_target
	progress_bar.max_value = deadlines[curr_deadline_index].target_score
	progress_bar.value = score

func deadline_met(score: int):
	curr_deadline_index += 1
	cursor.play_message("Yes! I met my deadline.")
	set_score_label(score)
	
func check_game_over() -> bool:
	if deadlines[clamp(curr_deadline_index, 0, deadlines.size() - 1)].day < GameManager.day:
		get_tree().change_scene_to_file("res://ui/game_over_menu/game_over_menu.tscn")
		return true
	return false
		
func initialize_deadlines():
	deadlines.append_array(
		[
			Deadline.create_deadline(10,25),
			Deadline.create_deadline(20,50),
			Deadline.create_deadline(30,100),
			Deadline.create_deadline(40,200),
			Deadline.create_deadline(50,350)
		]
	)
	curr_deadline_index = 0
	set_score_label(0)
