extends PanelContainer

signal view_cards_requested

@onready var _name_label: Label = $VBoxContainer/NameLabel
@onready var _health_bar: ProgressBar = $VBoxContainer/HealthBarContainer/HealthBar
@onready var _hp_label: Label = $VBoxContainer/HealthBarContainer/HPLabel
@onready var _gems_label: Label = $VBoxContainer/GemsLabel
@onready var _gold_label: Label = $VBoxContainer/GoldLabel
@onready var _view_cards_btn: Button = $VBoxContainer/ViewCardsButton

func _ready() -> void:
	PlayerManager.player_damaged.connect(_on_damaged)
	PlayerManager.player_healed.connect(_on_healed)
	PlayerManager.gem_changed.connect(_on_gem_changed)
	PlayerManager.gold_changed.connect(_on_gold_changed)
	PlayerManager.player_eliminated.connect(_on_eliminated)
	TurnManager.turn_started.connect(func(_idx): _refresh())
	GameManager.game_started.connect(_refresh)
	add_to_group(NetworkManager.REFRESH_GROUP)  # LAN client: redraw on host snapshot
	_view_cards_btn.pressed.connect(func(): view_cards_requested.emit())
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = Color(0.8, 0.1, 0.1)
	_health_bar.add_theme_stylebox_override("fill", fill_style)
	_refresh()

## LAN client: redraw from current manager state after a host snapshot.
func refresh() -> void:
	_refresh()

func _on_damaged(idx: int, new_hp: int) -> void:
	if idx != TurnManager.current_player_index:
		return
	_health_bar.value = new_hp
	_hp_label.text = "%d / %d" % [new_hp, PlayerManager.players[idx].max_health]
	_flash_damage()

func _on_healed(idx: int, new_hp: int) -> void:
	if idx != TurnManager.current_player_index:
		return
	_health_bar.value = new_hp
	_hp_label.text = "%d / %d" % [new_hp, PlayerManager.players[idx].max_health]

func _on_gem_changed(idx: int, new_gems: int) -> void:
	if idx != TurnManager.current_player_index:
		return
	_gems_label.text = "💎 %d/20" % new_gems

func _on_gold_changed(idx: int, new_gold: int) -> void:
	if idx != TurnManager.current_player_index:
		return
	_gold_label.text = "🪙 %d" % new_gold

func _on_eliminated(idx: int) -> void:
	if idx == TurnManager.current_player_index:
		modulate = Color(0.5, 0.5, 0.5)

func _flash_damage() -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate", Color(1.0, 0.25, 0.25), 0.05)
	tw.tween_property(self, "modulate", Color.WHITE, 0.35)
	tw.tween_callback(func():
		if TurnManager.current_player_index < PlayerManager.players.size():
			if PlayerManager.players[TurnManager.current_player_index].is_eliminated:
				modulate = Color(0.5, 0.5, 0.5)
	)

func _refresh() -> void:
	if TurnManager.current_player_index >= PlayerManager.players.size():
		return
	var p := PlayerManager.players[TurnManager.current_player_index]
	_name_label.text = p.player_name
	_health_bar.value = p.health
	_hp_label.text = "%d / %d" % [p.health, p.max_health]
	_gems_label.text = "💎 %d/20" % p.gems
	_gold_label.text = "🪙 %d" % p.gold
	_view_cards_btn.text = "View Cards (%d)" % p.cards_in_hand.size()
	modulate = Color(0.5, 0.5, 0.5) if p.is_eliminated else Color.WHITE
