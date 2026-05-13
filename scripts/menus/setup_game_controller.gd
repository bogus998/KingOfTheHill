extends Control

@onready var _title_label: Label = $VBox/TitleLabel
@onready var _count_row: HBoxContainer = $VBox/PlayerCountRow
@onready var _spin_box: SpinBox = $VBox/PlayerCountRow/SpinBox
@onready var _names_container: VBoxContainer = $VBox/NamesContainer

var _name_fields: Array = []

func _ready() -> void:
	if GameManager.game_mode == "vs_ai":
		_title_label.text = "VS AI Setup"
		_count_row.visible = false
		_build_name_fields(1)
	else:
		_title_label.text = "Hot-Seat Setup"
		_spin_box.value_changed.connect(_on_player_count_changed)
		_build_name_fields(2)
	$VBox/StartButton.pressed.connect(_on_start)
	$VBox/BackButton.pressed.connect(_on_back)

func _build_name_fields(count: int) -> void:
	for child in _names_container.get_children():
		child.queue_free()
	_name_fields.clear()
	for i in count:
		var row := HBoxContainer.new()
		var lbl := Label.new()
		lbl.text = "Player %d:" % (i + 1)
		lbl.custom_minimum_size = Vector2(80, 0)
		var field := LineEdit.new()
		field.placeholder_text = "Player %d" % (i + 1)
		field.custom_minimum_size = Vector2(150, 0)
		row.add_child(lbl)
		row.add_child(field)
		_names_container.add_child(row)
		_name_fields.append(field)

func _on_player_count_changed(value: float) -> void:
	_build_name_fields(int(value))

func _on_start() -> void:
	var players: Array[Dictionary] = []
	for i in _name_fields.size():
		var name_text: String = _name_fields[i].text.strip_edges()
		if name_text.is_empty():
			name_text = "Player %d" % (i + 1)
		players.append({"name": name_text, "is_bot": false})
	if GameManager.game_mode == "vs_ai":
		players.append({"name": "Bot", "is_bot": true})
	GameManager.pending_config = {"players": players, "mode": GameManager.game_mode}
	get_tree().change_scene_to_file("res://scenes/game/main_game.tscn")

func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn")
