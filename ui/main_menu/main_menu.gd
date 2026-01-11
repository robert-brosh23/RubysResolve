class_name MainMenu extends Control

const STARTING_VOLUME_DB := -10.0

@export var cursor: Cursor

@export var start_button: Button
@export var options_button: Button
@export var credits_button: Button
@export var credits_return_to_main_button: Button
@export var options_return_to_main_button: Button

@export var master_volume_slider: HSlider
@export var music_volume_slider: HSlider
@export var sfx_volume_slider: HSlider

@export var main_menu_screen: Control
@export var credits_menu_screen: MarginContainer
@export var options_menu_screen: MarginContainer

var song := preload("res://audio/music/game_jam_song_clippeed.mp3")
var sound_discard_card := preload("res://audio/sfx/place_card.wav")

func _ready() -> void:
	start_button.focus_mode = FOCUS_NONE
	options_button.focus_mode = FOCUS_NONE
	credits_button.focus_mode = FOCUS_NONE
	credits_return_to_main_button.focus_mode = FOCUS_NONE
	
	AudioPlayer.reset()
	_reset_sliders()
	AudioPlayer.play_sound(song, false, AudioPlayer.Bus.MUSIC, true)
	
	main_menu_screen.visible = true
	credits_menu_screen.visible = false
	
func _reset_sliders():
	if GameManager.debug_enabled:
		AudioPlayer.music_volume = -40
		
	master_volume_slider.value = AudioPlayer.master_volume
	_on_master_volume_slider_value_changed(master_volume_slider.value)
	music_volume_slider.value = AudioPlayer.music_volume
	_on_music_volume_slider_value_changed(music_volume_slider.value)
	sfx_volume_slider.value = AudioPlayer.sfx_volume
	_on_sfx_volume_slider_value_changed(sfx_volume_slider.value)
	
	
func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/tutorial_scene/tutorial_scene.tscn")
	#get_tree().change_scene_to_file("res://main.tscn")
	
func _on_credits_pressed() -> void:
	main_menu_screen.visible = false
	credits_menu_screen.visible = true

func _on_credits_return_to_main_pressed() -> void:
	main_menu_screen.visible = true
	credits_menu_screen.visible = false

func _on_options_pressed() -> void:
	main_menu_screen.visible = false
	options_menu_screen.visible = true
	
func _on_options_return_to_main_pressed() -> void:
	main_menu_screen.visible = true
	options_menu_screen.visible = false


func _on_start_button_mouse_entered() -> void:
	SignalBus.node_hovered.emit(start_button)


func _on_start_button_mouse_exited() -> void:
	SignalBus.node_stop_hovered.emit(start_button)


func _on_options_mouse_entered() -> void:
	SignalBus.node_hovered.emit(options_button)


func _on_options_mouse_exited() -> void:
	SignalBus.node_stop_hovered.emit(options_button)


func _on_credits_mouse_entered() -> void:
	SignalBus.node_hovered.emit(credits_button)


func _on_credits_mouse_exited() -> void:
	SignalBus.node_stop_hovered.emit(credits_button)


func _on_credits_return_to_main_mouse_entered() -> void:
	SignalBus.node_hovered.emit(credits_return_to_main_button)


func _on_credits_return_to_main_mouse_exited() -> void:
	SignalBus.node_stop_hovered.emit(credits_return_to_main_button)


func _on_options_return_to_main_mouse_entered() -> void:
	SignalBus.node_hovered.emit(options_return_to_main_button)


func _on_options_return_to_main_mouse_exited() -> void:
	SignalBus.node_stop_hovered.emit(options_return_to_main_button)

func _on_master_volume_slider_value_changed(value: float) -> void:
	if value < -39.9:
		value = -500
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), value)
	
func _on_music_volume_slider_value_changed(value: float) -> void:
	if value < -39.9:
		value = -500
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), value)

func _on_sfx_volume_slider_value_changed(value: float) -> void:
	if value < -39.9:
		value = -500
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Sfx"), value)
