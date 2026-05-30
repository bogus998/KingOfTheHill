extends GutTest

var meter: ThresholdMeter

func before_each() -> void:
	meter = ThresholdMeter.new()
	meter.set_threshold(5)

# ── Initial state ─────────────────────────────────────────────────────────────

func test_starts_at_zero() -> void:
	assert_eq(meter.value, 0)

func test_starts_untripped() -> void:
	assert_false(meter.is_tripped)

# ── Accumulation ──────────────────────────────────────────────────────────────

func test_add_increases_value() -> void:
	meter.add(2)
	assert_eq(meter.value, 2)

func test_add_emits_value_changed() -> void:
	watch_signals(meter)
	meter.add(2)
	assert_signal_emitted_with_parameters(meter, "value_changed", [2])

# ── Threshold crossing ────────────────────────────────────────────────────────

func test_does_not_trip_below_threshold() -> void:
	meter.add(4)
	assert_false(meter.is_tripped)

func test_trips_when_reaching_threshold() -> void:
	meter.add(5)
	assert_true(meter.is_tripped)

func test_trips_when_overshooting_threshold() -> void:
	meter.add(7)
	assert_true(meter.is_tripped)

func test_emits_threshold_reached_on_crossing() -> void:
	watch_signals(meter)
	meter.add(5)
	assert_signal_emitted(meter, "threshold_reached")

func test_does_not_emit_threshold_reached_below() -> void:
	watch_signals(meter)
	meter.add(4)
	assert_signal_not_emitted(meter, "threshold_reached")

# ── Latch ─────────────────────────────────────────────────────────────────────

func test_latched_meter_ignores_further_adds() -> void:
	meter.add(5)
	meter.add(3)
	assert_eq(meter.value, 5)

func test_threshold_reached_fires_only_once() -> void:
	watch_signals(meter)
	meter.add(5)
	meter.add(5)
	assert_signal_emit_count(meter, "threshold_reached", 1)

# ── Reset ─────────────────────────────────────────────────────────────────────

func test_reset_clears_value() -> void:
	meter.add(5)
	meter.reset()
	assert_eq(meter.value, 0)

func test_reset_clears_tripped() -> void:
	meter.add(5)
	meter.reset()
	assert_false(meter.is_tripped)

func test_can_trip_again_after_reset() -> void:
	meter.add(5)
	meter.reset()
	watch_signals(meter)
	meter.add(5)
	assert_signal_emitted(meter, "threshold_reached")

# ── would_trip ────────────────────────────────────────────────────────────────

func test_would_trip_true_when_amount_reaches_threshold() -> void:
	meter.add(3)
	assert_true(meter.would_trip(2))

func test_would_trip_false_when_amount_below_threshold() -> void:
	meter.add(3)
	assert_false(meter.would_trip(1))

# ── Threshold change mid-life ─────────────────────────────────────────────────

func test_changing_threshold_affects_next_add() -> void:
	meter.set_threshold(3)
	meter.add(3)
	assert_true(meter.is_tripped)
