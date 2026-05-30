extends GutTest

var tracker: BuildupTracker

func _config() -> BuildupConfig:
	var cfg := BuildupConfig.new()
	var r1 := AccumulationRule.new()
	r1.event_id = &"small"
	r1.amount = 1
	var r2 := AccumulationRule.new()
	r2.event_id = &"big"
	r2.amount = 2
	cfg.rules = [r1, r2]
	return cfg

func before_each() -> void:
	tracker = BuildupTracker.new(_config(), 5)

# ── Initial state ─────────────────────────────────────────────────────────────

func test_starts_at_zero() -> void:
	assert_eq(tracker.value, 0)

func test_starts_untripped() -> void:
	assert_false(tracker.is_tripped)

# ── Event → amount mapping ────────────────────────────────────────────────────

func test_report_known_event_adds_its_amount() -> void:
	tracker.report(&"big")
	assert_eq(tracker.value, 2)

func test_report_unknown_event_is_noop() -> void:
	tracker.report(&"nonexistent")
	assert_eq(tracker.value, 0)

func test_count_multiplier() -> void:
	tracker.report(&"big", 3)
	assert_eq(tracker.value, 6)

# ── Signal relay ──────────────────────────────────────────────────────────────

func test_relays_value_changed() -> void:
	watch_signals(tracker)
	tracker.report(&"small")
	assert_signal_emitted_with_parameters(tracker, "value_changed", [1])

func test_relays_threshold_reached() -> void:
	watch_signals(tracker)
	tracker.report(&"small", 5)
	assert_signal_emitted(tracker, "threshold_reached")

# ── Reset & threshold change ──────────────────────────────────────────────────

func test_reset_clears_value() -> void:
	tracker.report(&"big")
	tracker.reset()
	assert_eq(tracker.value, 0)

func test_set_threshold_affects_subsequent_trip() -> void:
	tracker.set_threshold(2)
	tracker.report(&"big")
	assert_true(tracker.is_tripped)

func test_null_config_yields_inert_tracker() -> void:
	var t := BuildupTracker.new(null, 3)
	t.report(&"small")
	assert_eq(t.value, 0)
