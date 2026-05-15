extends HBoxContainer

const CARD_HAND := preload("res://scenes/players/card_hand.tscn")

func _ready() -> void:
	GameManager.game_started.connect(_build_hands)

func _build_hands() -> void:
	for child in get_children():
		child.queue_free()
	for i in PlayerManager.players.size():
		var hand := CARD_HAND.instantiate()
		hand.player_index = i
		add_child(hand)
