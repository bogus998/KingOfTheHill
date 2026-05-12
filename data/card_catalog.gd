class_name CardCatalog

static func load_all_cards() -> Array[CardData]:
	var cards: Array[CardData] = []
	var dir := DirAccess.open("res://data/cards")
	if dir == null:
		return cards
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var card := load("res://data/cards/" + file_name) as CardData
			if card != null:
				cards.append(card)
		file_name = dir.get_next()
	dir.list_dir_end()
	return cards
