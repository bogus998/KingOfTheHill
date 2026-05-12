extends PanelContainer

@export var player_index: int = -1

@onready var _name_label: Label = $VBoxContainer/NameLabel
@onready var _health_label: Label = $VBoxContainer/HealthRow/HealthLabel
@onready var _gold_label: Label = $VBoxContainer/GoldRow/GoldLabel
@onready var _gems_label: Label = $VBoxContainer/GemsRow/GemsLabel
@onready var _position_label: Label = $VBoxContainer/PositionLabel

func _ready() -> void:
	PlayerManager.player_damaged.connect(_on_stat_changed)
	PlayerManager.player_healed.connect(_on_stat_changed)
	PlayerManager.gold_changed.connect(_on_stat_changed)
	PlayerManager.gem_changed.connect(_on_stat_changed)
	PlayerManager.position_changed.connect(_on_position_changed)
	PlayerManager.player_eliminated.connect(_on_eliminated)
	GameManager.game_started.connect(_refresh)
	_refresh()

func _on_stat_changed(idx: int, _value: int) -> void:
	if idx == player_index:
		_refresh()

func _on_position_changed(idx: int, _pos: PlayerData.PlayerPosition) -> void:
	if idx == player_index:
		_refresh()

func _on_eliminated(idx: int) -> void:
	if idx == player_index:
		modulate = Color(0.5, 0.5, 0.5)

func _refresh() -> void:
	if player_index < 0 or player_index >= PlayerManager.players.size():
		return
	var p := PlayerManager.players[player_index]
	_name_label.text = p.player_name
	_health_label.text = str(p.health)
	_gold_label.text = str(p.gold)
	_gems_label.text = str(p.gems)
	_position_label.text = "In Vault" if p.position == PlayerData.PlayerPosition.AT_VAULT else "Outside"
