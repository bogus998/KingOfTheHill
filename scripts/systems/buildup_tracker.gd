class_name BuildupTracker
extends RefCounted
## Couples a ThresholdMeter with a data-driven event→amount lookup.
##
## Built from a BuildupConfig and a starting threshold. Callers detect events
## (and any game-side conditions) themselves, then `report()` the event id; the
## tracker translates it to an increment and feeds the meter. Unknown event ids
## are ignored. It relays the meter's `value_changed` / `threshold_reached`
## signals so consumers can subscribe to the tracker directly.

signal value_changed(value: int)
signal threshold_reached(value: int)

var _meter: ThresholdMeter
var _amounts: Dictionary = {}  # StringName -> int

func _init(config: BuildupConfig, starting_threshold: int = 0) -> void:
	_meter = ThresholdMeter.new()
	_meter.set_threshold(starting_threshold)
	_meter.value_changed.connect(func(v: int) -> void: value_changed.emit(v))
	_meter.threshold_reached.connect(func(v: int) -> void: threshold_reached.emit(v))
	if config != null:
		for rule in config.rules:
			if rule != null:
				_amounts[rule.event_id] = rule.amount

func report(event_id: StringName, count: int = 1) -> void:
	if not _amounts.has(event_id):
		return
	_meter.add(_amounts[event_id] * count)

func set_threshold(t: int) -> void:
	_meter.set_threshold(t)

func reset() -> void:
	_meter.reset()

var value: int:
	get: return _meter.value

var is_tripped: bool:
	get: return _meter.is_tripped
