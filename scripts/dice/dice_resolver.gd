class_name DiceResolver

enum DieFace { ONE = 1, TWO = 2, THREE = 3, GEM = 4, CLAW = 5, HEART = 6 }

static func resolve(faces: Array) -> Dictionary:
	var result := { "gold": 0, "gems": 0, "claws": 0, "hearts": 0 }
	var counts := {}
	for f in faces:
		counts[f] = counts.get(f, 0) + 1
	for num in [DieFace.ONE, DieFace.TWO, DieFace.THREE]:
		var count: int = counts.get(num, 0)
		if count >= 3:
			result["gold"] += num + (count - 3)
	result["gems"] = counts.get(DieFace.GEM, 0)
	result["claws"] = counts.get(DieFace.CLAW, 0)
	result["hearts"] = counts.get(DieFace.HEART, 0)
	return result

static func has_all_six_faces(faces: Array) -> bool:
	var found := {}
	for f in faces:
		found[f] = true
	return found.size() == 6

static func has_combo_one_two_three(faces: Array) -> bool:
	var has_one := false
	var has_two := false
	var has_three := false
	for f in faces:
		if f == DieFace.ONE: has_one = true
		elif f == DieFace.TWO: has_two = true
		elif f == DieFace.THREE: has_three = true
	return has_one and has_two and has_three

static func count_face(faces: Array, face: DieFace) -> int:
	var count := 0
	for f in faces:
		if f == face:
			count += 1
	return count
