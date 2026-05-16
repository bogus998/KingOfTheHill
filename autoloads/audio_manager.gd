extends Node

const _STREAM_PATHS: Dictionary = {
	"dice_roll":   "res://assets/audio/sfx/dice_roll.ogg",
	"die_hold":    "res://assets/audio/sfx/die_hold.ogg",
	"gold_gain":   "res://assets/audio/sfx/gold_gain.ogg",
	"damage":      "res://assets/audio/sfx/damage.ogg",
	"heal":        "res://assets/audio/sfx/heal.ogg",
	"card_buy":    "res://assets/audio/sfx/card_buy.ogg",
	"vault_enter": "res://assets/audio/sfx/vault_enter.ogg",
	"vault_flee":  "res://assets/audio/sfx/vault_flee.ogg",
	"game_over":   "res://assets/audio/sfx/game_over.ogg",
	"music_main":  "res://assets/audio/music/main_theme.ogg",
}

var _music_player: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
var _streams: Dictionary = {}

func _ready() -> void:
	_music_player = AudioStreamPlayer.new()
	add_child(_music_player)
	for i in 4:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_sfx_pool.append(p)
	_preload_streams()
	PlayerManager.player_damaged.connect(_on_player_damaged)
	PlayerManager.player_healed.connect(_on_player_healed)
	PlayerManager.gold_changed.connect(_on_gold_changed)
	CardShop.card_purchased.connect(_on_card_purchased)
	GameManager.game_started.connect(_on_game_started)
	GameManager.game_ended.connect(_on_game_ended)

func play_sfx(event: String) -> void:
	var stream: AudioStream = _streams.get(event)
	if stream == null:
		return
	for player in _sfx_pool:
		if not player.playing:
			player.stream = stream
			player.play()
			return

func play_music(track: String) -> void:
	var stream: AudioStream = _streams.get(track)
	if stream == null:
		return
	if _music_player.playing and _music_player.stream == stream:
		return
	_music_player.stream = stream
	_music_player.play()

func stop_music() -> void:
	_music_player.stop()

func _preload_streams() -> void:
	for event: String in _STREAM_PATHS:
		var path: String = _STREAM_PATHS[event]
		if ResourceLoader.exists(path):
			_streams[event] = load(path)

func _on_player_damaged(_idx: int, _hp: int) -> void:       play_sfx("damage")
func _on_player_healed(_idx: int, _hp: int) -> void:        play_sfx("heal")
func _on_gold_changed(_idx: int, _gold: int) -> void:       play_sfx("gold_gain")
func _on_card_purchased(_idx: int, _card: CardData) -> void: play_sfx("card_buy")
func _on_game_started() -> void:                             play_music("music_main")
func _on_game_ended(_winner: int, _reason: String) -> void:
	play_sfx("game_over")
	stop_music()
