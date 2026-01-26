class_name PromiseQueue
extends Node

class Promise:
	var callable: Callable
	var await_completion : bool
	signal result_signal

	static func create_promise(_callable: Callable, _await_completion: bool) -> Promise:
		var promise = Promise.new()
		promise.callable = _callable
		promise.await_completion = _await_completion
		return promise


var queue: Array[Promise] = []
var processing := false
var tree := Engine.get_main_loop() as SceneTree

var paused := 0:
	set(value):
		paused = value
		if paused < 0:
			paused = 0

func enqueue(func_ref: Callable, await_completion := false) -> Signal:
	var promise = Promise.create_promise(func_ref, await_completion)
	queue.append(promise)
	if !processing:
		processing = true
		call_deferred("_process_queue")
	return promise.result_signal
	
func enqueue_delay(seconds: float) -> Signal:
	return enqueue(func(): await tree.create_timer(seconds * Globals.animation_speed_scale).timeout)
	
func clear_queue():
	queue.clear()
	
func _process_queue() -> void:
	while !queue.is_empty():
		while paused > 0:
			await tree.process_frame
		var item: Promise = queue.pop_front()
		var fn: Callable = item.callable
		var result_signal = item.result_signal
		
		var result = await fn.call()
		result_signal.emit(result)
	processing = false
	_on_queue_finished()

func unpause_after_delay(delay: float) -> void:
	await tree.create_timer(delay * Globals.animation_speed_scale).timeout
	paused -= 1
	
func pause_queue_and_do_things(callables: Array[Callable]):
	paused += 1
	for callable in callables:
		await callable.call()
	paused -= 1

func _on_queue_finished() -> void:
	pass
