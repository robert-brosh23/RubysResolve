class_name DiceController
extends Node2D

@onready var die_sprite = $DieSprite
@onready var animation_player = $AnimationPlayer

func _ready() -> void:
	die_sprite.visible = false
	
func roll() -> int:
	die_sprite.visible = true
	animation_player.play("roll_die")
	var stop_time = randf_range(0.01, 0.02)
	while stop_time < .3:
		stop_time = randf_range(stop_time * 1.1, stop_time * 1.5)
		die_sprite.frame = randi_range(0,5)
		await get_tree().create_timer(stop_time).timeout
		
	await get_tree().create_timer(.5).timeout
	die_sprite.visible = false
	return die_sprite.frame + 1
