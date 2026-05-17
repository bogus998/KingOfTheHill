extends GutTest

# ── Three-of-a-kind scoring ───────────────────────────────────────────────────

func test_three_ones_score_1_gems() -> void:
	var r := DiceResolver.resolve([
		DiceResolver.DieFace.ONE,   DiceResolver.DieFace.ONE,   DiceResolver.DieFace.ONE,
		DiceResolver.DieFace.TWO,   DiceResolver.DieFace.THREE, DiceResolver.DieFace.GOLD,
	])
	assert_eq(r["gems"], 1)
	assert_eq(r["gold"], 1)
	assert_eq(r["claws"], 0)
	assert_eq(r["hearts"], 0)

func test_four_twos_score_3_gems() -> void:
	var r := DiceResolver.resolve([
		DiceResolver.DieFace.TWO,  DiceResolver.DieFace.TWO,  DiceResolver.DieFace.TWO,
		DiceResolver.DieFace.TWO,  DiceResolver.DieFace.CLAW, DiceResolver.DieFace.HEART,
	])
	assert_eq(r["gems"], 3)
	assert_eq(r["claws"], 1)
	assert_eq(r["hearts"], 1)

func test_six_threes_score_6_gems() -> void:
	var r := DiceResolver.resolve([
		DiceResolver.DieFace.THREE, DiceResolver.DieFace.THREE, DiceResolver.DieFace.THREE,
		DiceResolver.DieFace.THREE, DiceResolver.DieFace.THREE, DiceResolver.DieFace.THREE,
	])
	assert_eq(r["gems"], 6)

# ── No triple → 0 gems ────────────────────────────────────────────────────────

func test_no_triple_scores_0_gems() -> void:
	var r := DiceResolver.resolve([
		DiceResolver.DieFace.ONE,  DiceResolver.DieFace.TWO,  DiceResolver.DieFace.THREE,
		DiceResolver.DieFace.GOLD,  DiceResolver.DieFace.CLAW, DiceResolver.DieFace.HEART,
	])
	assert_eq(r["gems"], 0)
	assert_eq(r["gold"], 1)
	assert_eq(r["claws"], 1)
	assert_eq(r["hearts"], 1)

# ── Non-number faces score individually ───────────────────────────────────────

func test_three_claws_two_gold_one_heart() -> void:
	var r := DiceResolver.resolve([
		DiceResolver.DieFace.CLAW, DiceResolver.DieFace.CLAW, DiceResolver.DieFace.CLAW,
		DiceResolver.DieFace.GOLD,  DiceResolver.DieFace.GOLD,  DiceResolver.DieFace.HEART,
	])
	assert_eq(r["claws"], 3)
	assert_eq(r["gold"], 2)
	assert_eq(r["hearts"], 1)
	assert_eq(r["gems"], 0)

func test_two_claws_score_2_claws() -> void:
	var r := DiceResolver.resolve([
		DiceResolver.DieFace.CLAW, DiceResolver.DieFace.CLAW,
		DiceResolver.DieFace.ONE,  DiceResolver.DieFace.ONE,
		DiceResolver.DieFace.GOLD,  DiceResolver.DieFace.HEART,
	])
	assert_eq(r["claws"], 2)
	assert_eq(r["gems"], 0)

func test_six_gold_score_6_gold() -> void:
	var r := DiceResolver.resolve([
		DiceResolver.DieFace.GOLD, DiceResolver.DieFace.GOLD, DiceResolver.DieFace.GOLD,
		DiceResolver.DieFace.GOLD, DiceResolver.DieFace.GOLD, DiceResolver.DieFace.GOLD,
	])
	assert_eq(r["gold"], 6)
	assert_eq(r["gems"], 0)

# ── has_all_six_faces ─────────────────────────────────────────────────────────

func test_has_all_six_faces_true_with_exactly_one_each() -> void:
	assert_true(DiceResolver.has_all_six_faces([
		DiceResolver.DieFace.ONE,  DiceResolver.DieFace.TWO,   DiceResolver.DieFace.THREE,
		DiceResolver.DieFace.GOLD,  DiceResolver.DieFace.CLAW,  DiceResolver.DieFace.HEART,
	]))

func test_has_all_six_faces_false_when_missing_a_face() -> void:
	assert_false(DiceResolver.has_all_six_faces([
		DiceResolver.DieFace.ONE,  DiceResolver.DieFace.TWO,   DiceResolver.DieFace.THREE,
		DiceResolver.DieFace.GOLD,  DiceResolver.DieFace.GOLD,   DiceResolver.DieFace.HEART,
	]))

func test_has_all_six_faces_true_with_duplicates_in_7_dice() -> void:
	assert_true(DiceResolver.has_all_six_faces([
		DiceResolver.DieFace.ONE,  DiceResolver.DieFace.ONE,   DiceResolver.DieFace.TWO,
		DiceResolver.DieFace.THREE, DiceResolver.DieFace.GOLD,  DiceResolver.DieFace.CLAW,
		DiceResolver.DieFace.HEART,
	]))

# ── has_combo_one_two_three ───────────────────────────────────────────────────

func test_has_combo_one_two_three_true() -> void:
	assert_true(DiceResolver.has_combo_one_two_three([
		DiceResolver.DieFace.ONE, DiceResolver.DieFace.TWO, DiceResolver.DieFace.THREE,
		DiceResolver.DieFace.GOLD, DiceResolver.DieFace.CLAW, DiceResolver.DieFace.HEART,
	]))

func test_has_combo_one_two_three_false_missing_two() -> void:
	assert_false(DiceResolver.has_combo_one_two_three([
		DiceResolver.DieFace.ONE, DiceResolver.DieFace.ONE, DiceResolver.DieFace.THREE,
		DiceResolver.DieFace.GOLD, DiceResolver.DieFace.CLAW, DiceResolver.DieFace.HEART,
	]))

func test_has_combo_one_two_three_false_all_same() -> void:
	assert_false(DiceResolver.has_combo_one_two_three([
		DiceResolver.DieFace.GOLD, DiceResolver.DieFace.GOLD, DiceResolver.DieFace.GOLD,
		DiceResolver.DieFace.GOLD, DiceResolver.DieFace.GOLD, DiceResolver.DieFace.GOLD,
	]))

# ── count_face ────────────────────────────────────────────────────────────────

func test_count_face_returns_correct_count() -> void:
	var faces := [
		DiceResolver.DieFace.ONE, DiceResolver.DieFace.ONE, DiceResolver.DieFace.TWO,
		DiceResolver.DieFace.THREE, DiceResolver.DieFace.GOLD, DiceResolver.DieFace.HEART,
	]
	assert_eq(DiceResolver.count_face(faces, DiceResolver.DieFace.ONE), 2)
	assert_eq(DiceResolver.count_face(faces, DiceResolver.DieFace.TWO), 1)

func test_count_face_returns_zero_when_absent() -> void:
	var faces := [
		DiceResolver.DieFace.ONE, DiceResolver.DieFace.TWO, DiceResolver.DieFace.THREE,
		DiceResolver.DieFace.GOLD, DiceResolver.DieFace.GOLD, DiceResolver.DieFace.HEART,
	]
	assert_eq(DiceResolver.count_face(faces, DiceResolver.DieFace.CLAW), 0)
