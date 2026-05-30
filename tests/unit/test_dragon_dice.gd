extends GutTest

var dice: DragonDice

func before_each() -> void:
	dice = DragonDice.new()

# ── Magnitude rolls stay in range ─────────────────────────────────────────────

func test_fire_in_range() -> void:
	for _i in 200:
		var v := dice.roll_fire()
		assert_between(v, 1, 3)

func test_hoard_in_range() -> void:
	for _i in 200:
		var v := dice.roll_hoard()
		assert_between(v, 1, 3)

# ── Action distribution sanity ────────────────────────────────────────────────

func test_all_actions_appear() -> void:
	var seen := {}
	for _i in 2000:
		seen[dice.roll_action()] = true
	assert_eq(seen.size(), 5, "every action face should occur over many rolls")

func test_environment_is_roughly_double_weight() -> void:
	var counts := {}
	for a in DragonDice.Action.values():
		counts[a] = 0
	var n := 6000
	for _i in n:
		counts[dice.roll_action()] += 1
	# ENVIRONMENT has weight 2/6; the single-weight faces have 1/6 each.
	# Expect env ≈ 2000, singles ≈ 1000. Use loose bounds for randomness.
	assert_between(counts[DragonDice.Action.ENVIRONMENT], 1600, 2400)
	assert_between(counts[DragonDice.Action.FIRE], 700, 1300)

func test_magnitude_distribution_even() -> void:
	var counts := {1: 0, 2: 0, 3: 0}
	var n := 6000
	for _i in n:
		counts[dice.roll_fire()] += 1
	# Each magnitude is 2/6 ≈ 2000. Loose bounds.
	for m in [1, 2, 3]:
		assert_between(counts[m], 1600, 2400)
