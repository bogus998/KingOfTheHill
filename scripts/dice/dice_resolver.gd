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
