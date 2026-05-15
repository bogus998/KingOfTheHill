extends HBoxContainer

const PLAYER_PANEL := preload("res://scenes/players/player_panel.tscn")

@onready var _left: HBoxContainer = $PlayersLeft
@onready var _right: HBoxContainer = $PlayersRight

func _ready() -> void:
	GameManager.game_started.connect(_build_panels)

func _build_panels() -> void:
	for child in _left.get_children():
		child.queue_free()
	for child in _right.get_children():
		child.queue_free()
	var count := PlayerManager.players.size()
	var left_count := int(ceil(count / 2.0))
	for i in count:
		var panel := PLAYER_PANEL.instantiate()
		panel.player_index = i
		if i < left_count:
			_left.add_child(panel)
		else:
			_right.add_child(panel)
