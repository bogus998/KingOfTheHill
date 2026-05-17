extends Control

const MIN_PLAYERS := 2
const MAX_PLAYERS := 4

@onready var _players_container: VBoxContainer = $CenterContainer/VBox/PlayersContainer
@onready var _add_button: Button = $CenterContainer/VBox/AddPlayerButton
@onready var _start_button: Button = $CenterContainer/VBox/StartButton

# Each entry: { row, index_label, name_field, type_option, remove_button, name_is_custom }
var _rows: Array[Dictionary] = []

func _ready() -> void:
	_add_button.pressed.connect(add_player)
	_start_button.pressed.connect(_on_start)
	$CenterContainer/VBox/BackButton.pressed.connect(_on_back)
	add_player()  # start with a single Human row

func add_player() -> void:
	if _rows.size() >= MAX_PLAYERS:
		return

	var row := HBoxContainer.new()

	var index_label := Label.new()
	index_label.custom_minimum_size = Vector2(70, 0)

	var name_field := LineEdit.new()
	name_field.custom_minimum_size = Vector2(150, 0)

	var type_option := OptionButton.new()
	type_option.add_item("Human")  # index 0
	type_option.add_item("Bot")    # index 1
	type_option.selected = 0

	var remove_button := Button.new()
	remove_button.text = "X"

	row.add_child(index_label)
	row.add_child(name_field)
	row.add_child(type_option)
	row.add_child(remove_button)
	_players_container.add_child(row)

	var entry := {
		"row": row,
		"index_label": index_label,
		"name_field": name_field,
		"type_option": type_option,
		"remove_button": remove_button,
		"name_is_custom": false,
	}
	_rows.append(entry)

	name_field.text_changed.connect(func(_t): entry["name_is_custom"] = true)
	type_option.item_selected.connect(func(_id): _refresh_ui())
	remove_button.pressed.connect(func(): _remove_row(entry))

	_refresh_ui()

func remove_player(index: int) -> void:
	if index < 0 or index >= _rows.size():
		return
	_remove_row(_rows[index])

func set_player_type(index: int, is_bot: bool) -> void:
	if index < 0 or index >= _rows.size():
		return
	_rows[index]["type_option"].selected = 1 if is_bot else 0
	_refresh_ui()

func set_player_name(index: int, name_text: String) -> void:
	if index < 0 or index >= _rows.size():
		return
	_rows[index]["name_field"].text = name_text
	_rows[index]["name_is_custom"] = true
	_refresh_ui()

func get_player_count() -> int:
	return _rows.size()

func get_player_configs() -> Array[Dictionary]:
	var configs: Array[Dictionary] = []
	for i in _rows.size():
		var entry: Dictionary = _rows[i]
		var is_bot: bool = entry["type_option"].selected == 1
		var name_text: String = entry["name_field"].text.strip_edges()
		if name_text.is_empty():
			name_text = _default_name(i, is_bot)
		configs.append({"name": name_text, "is_bot": is_bot})
	return configs

func _remove_row(entry: Dictionary) -> void:
	if _rows.size() <= 1:
		return
	_rows.erase(entry)
	entry["row"].queue_free()
	_refresh_ui()

func _default_name(index: int, is_bot: bool) -> String:
	if is_bot:
		return "bot_%d" % (index + 1)
	return "Player %d" % (index + 1)

func _refresh_ui() -> void:
	for i in _rows.size():
		var entry: Dictionary = _rows[i]
		entry["index_label"].text = "Player %d:" % (i + 1)
		entry["remove_button"].disabled = _rows.size() <= 1
		if not entry["name_is_custom"]:
			var is_bot: bool = entry["type_option"].selected == 1
			entry["name_field"].text = _default_name(i, is_bot)
	_add_button.disabled = _rows.size() >= MAX_PLAYERS
	_start_button.disabled = _rows.size() < MIN_PLAYERS

func _on_start() -> void:
	GameManager.pending_config = {"players": get_player_configs()}
	get_tree().change_scene_to_file("res://scenes/game/main_game.tscn")

func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn")
