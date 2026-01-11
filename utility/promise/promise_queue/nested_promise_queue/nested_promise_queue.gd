## [PromiseQueue] which deletes itself when cleared.
class_name NestedPromiseQueue extends PromiseQueue

signal finished

func _on_queue_finished() -> void:
	finished.emit()
	queue_free()

static func create_nested_promise_queue(callables: Array[Callable]) -> Signal:
	var nested_queue := NestedPromiseQueue.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(nested_queue)

	nested_queue.paused = true
	for callable in callables:
		nested_queue.enqueue(callable)
	nested_queue.paused = false
	
	return nested_queue.finished
