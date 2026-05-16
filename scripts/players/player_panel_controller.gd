extends PanelContainer

@export var player_index: int = -1

@onready var _name_label: Label = $VBoxContainer/NameLabel
@onready var _health_label: Label = $VBoxContainer/HealthRow/HealthLabel
@onready var _gold_label: Label = $VBoxContainer/GoldRow/GoldLabel
@onready var _gems_label: Label = $VBoxContainer/GemsRow/GemsLabel
@onready var _position_label: Label = $VBoxContainer/PositionLabel

var _displayed_gold: int = 0
var _displayed_gems: int = 0

func _ready() -> void:
	PlayerManager.player_damaged.connect(_on_damaged)
	PlayerManager.player_healed.connect(_on_healed)
	PlayerManager.gold_changed.connect(_on_gold_changed)
	PlayerManager.gem_changed.connect(_on_gem_changed)
	PlayerManager.position_changed.connect(_on_position_changed)
	PlayerManager.player_eliminated.connect(_on_eliminated)
	GameManager.game_started.connect(_refresh)
	_refresh()

func _on_damaged(idx: int, new_hp: int) -> void:
	if idx != player_index:
		return
	_health_label.text = str(new_hp)
	_flash_damage()

func _on_healed(idx: int, new_hp: int) -> void:
	if idx != player_index:
		return
	_health_label.text = str(new_hp)

func _on_gold_changed(idx: int, new_gold: int) -> void:
	if idx != player_index:
		return
	_animate_value(_gold_label, _displayed_gold, new_gold)
	_displayed_gold = new_gold

func _on_gem_changed(idx: int, new_gems: int) -> void:
	if idx != player_index:
		return
	_animate_value(_gems_label, _displayed_gems, new_gems)
	_displayed_gems = new_gems

func _on_position_changed(idx: int, _pos: PlayerData.PlayerPosition) -> void:
	if idx == player_index:
		_refresh()

func _on_eliminated(idx: int) -> void:
	if idx == player_index:
		modulate = Color(0.5, 0.5, 0.5)

func _flash_damage() -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate", Color(1.0, 0.25, 0.25), 0.05)
	tw.tween_property(self, "modulate", Color.WHITE, 0.35)
	tw.tween_callback(func():
		if player_index >= 0 and player_index < PlayerManager.players.size():
			if PlayerManager.players[player_index].is_eliminated:
				modulate = Color(0.5, 0.5, 0.5)
	)

func _animate_value(label: Label, from: int, to: int) -> void:
	var tw := create_tween()
	tw.tween_method(func(v: float): label.text = str(int(v)), float(from), float(to), 0.4)

func _refresh() -> void:
	if player_index < 0 or player_index >= PlayerManager.players.size():
		return
	var p := PlayerManager.players[player_index]
	_name_label.text = p.player_name
	_health_label.text = str(p.health)
	_gold_label.text = str(p.gold)
	_displayed_gold = p.gold
	_gems_label.text = str(p.gems)
	_displayed_gems = p.gems
	_position_label.text = "In Vault" if p.position == PlayerData.PlayerPosition.AT_VAULT else "Outside"
