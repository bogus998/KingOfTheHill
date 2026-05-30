class_name ThresholdMeter
extends RefCounted
## Generic, project-agnostic accumulator that trips once a threshold is crossed.
##
## Feed it values with `add()`; it announces every change via `value_changed` and
## fires `threshold_reached` exactly once when the running value first reaches the
## threshold. It then latches (`is_tripped`) and ignores further additions until
## `reset()`. It holds no game knowledge — what feeds it and what happens on a
## trip are entirely the caller's concern.

signal value_changed(value: int)
signal threshold_reached(value: int)

var value: int = 0
var threshold: int = 0
var is_tripped: bool = false

func add(amount: int) -> void:
	if is_tripped:
		return
	value += amount
	value_changed.emit(value)
	if value >= threshold:
		is_tripped = true
		threshold_reached.emit(value)

func reset() -> void:
	value = 0
	is_tripped = false
	value_changed.emit(value)

func set_threshold(t: int) -> void:
	threshold = t

func would_trip(amount: int) -> bool:
	return value + amount >= threshold
