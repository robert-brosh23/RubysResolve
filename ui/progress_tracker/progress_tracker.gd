class_name ProgressTracker
extends PanelContainer

@export var score_label : Label
@export var target_label : Label
@export var deadline_label : RichTextLabel
@export var progress_bar : ProgressBar

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

func initialize_deadlines():
	deadlines.append_array(
		[
			Deadline.create_deadline(10,50),
			Deadline.create_deadline(20,115),
			Deadline.create_deadline(30,200),
			Deadline.create_deadline(40,300),
			Deadline.create_deadline(50,500)
		]
	)
	curr_deadline_index = 0
	set_score_label(0)

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
	set_score_label(score)
	
func _ready():
	initialize_deadlines()
