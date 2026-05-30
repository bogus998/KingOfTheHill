class_name EnvironmentDeck
## Loads every EnvironmentEffect resource from disk. Mirrors [[card_catalog]].
##
## Cards are drawn with replacement (the dragon can draw the same environment
## twice), so the loader just returns the full pool and the caller picks at random.

const ENV_DIR := "res://data/environment/"

static func load_all() -> Array[EnvironmentEffect]:
	var cards: Array[EnvironmentEffect] = []
	var dir := DirAccess.open(ENV_DIR)
	if dir == null:
		push_error("EnvironmentDeck: cannot open %s" % ENV_DIR)
		return cards
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var res := load(ENV_DIR + file_name)
			if res is EnvironmentEffect:
				cards.append(res)
		file_name = dir.get_next()
	dir.list_dir_end()
	return cards
