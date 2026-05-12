extends GutTest

# ── Three-of-a-kind scoring ───────────────────────────────────────────────────

func test_three_ones_score_1_gold() -> void:
	var r := DiceResolver.resolve([
		DiceResolver.DieFace.ONE,   DiceResolver.DieFace.ONE,   DiceResolver.DieFace.ONE,
		DiceResolver.DieFace.TWO,   DiceResolver.DieFace.THREE, DiceResolver.DieFace.GEM,
	])
	assert_eq(r["gold"], 1)
	assert_eq(r["gems"], 1)
	assert_eq(r["claws"], 0)
	assert_eq(r["hearts"], 0)

func test_four_twos_score_3_gold() -> void:
	var r := DiceResolver.resolve([
		DiceResolver.DieFace.TWO,  DiceResolver.DieFace.TWO,  DiceResolver.DieFace.TWO,
		DiceResolver.DieFace.TWO,  DiceResolver.DieFace.CLAW, DiceResolver.DieFace.HEART,
	])
	assert_eq(r["gold"], 3)
	assert_eq(r["claws"], 1)
	assert_eq(r["hearts"], 1)

func test_six_threes_score_6_gold() -> void:
	var r := DiceResolver.resolve([
		DiceResolver.DieFace.THREE, DiceResolver.DieFace.THREE, DiceResolver.DieFace.THREE,
		DiceResolver.DieFace.THREE, DiceResolver.DieFace.THREE, DiceResolver.DieFace.THREE,
	])
	assert_eq(r["gold"], 6)

# ── No triple → 0 gold ────────────────────────────────────────────────────────

func test_no_triple_scores_0_gold() -> void:
	var r := DiceResolver.resolve([
		DiceResolver.DieFace.ONE,  DiceResolver.DieFace.TWO,  DiceResolver.DieFace.THREE,
		DiceResolver.DieFace.GEM,  DiceResolver.DieFace.CLAW, DiceResolver.DieFace.HEART,
	])
	assert_eq(r["gold"], 0)
	assert_eq(r["gems"], 1)
	assert_eq(r["claws"], 1)
	assert_eq(r["hearts"], 1)

# ── Non-number faces score individually ───────────────────────────────────────

func test_three_claws_two_gems_one_heart() -> void:
	var r := DiceResolver.resolve([
		DiceResolver.DieFace.CLAW, DiceResolver.DieFace.CLAW, DiceResolver.DieFace.CLAW,
		DiceResolver.DieFace.GEM,  DiceResolver.DieFace.GEM,  DiceResolver.DieFace.HEART,
	])
	assert_eq(r["claws"], 3)
	assert_eq(r["gems"], 2)
	assert_eq(r["hearts"], 1)
	assert_eq(r["gold"], 0)

func test_two_claws_score_2_claws() -> void:
	var r := DiceResolver.resolve([
		DiceResolver.DieFace.CLAW, DiceResolver.DieFace.CLAW,
		DiceResolver.DieFace.ONE,  DiceResolver.DieFace.ONE,
		DiceResolver.DieFace.GEM,  DiceResolver.DieFace.HEART,
	])
	assert_eq(r["claws"], 2)
	assert_eq(r["gold"], 0)

func test_six_gems_score_6_gems() -> void:
	var r := DiceResolver.resolve([
		DiceResolver.DieFace.GEM, DiceResolver.DieFace.GEM, DiceResolver.DieFace.GEM,
		DiceResolver.DieFace.GEM, DiceResolver.DieFace.GEM, DiceResolver.DieFace.GEM,
	])
	assert_eq(r["gems"], 6)
	assert_eq(r["gold"], 0)
