extends GutTest

var _vault: Node = null

func before_each() -> void:
	GameManager.start_game({"players": [
		{"name": "Thorin", "is_bot": false},
		{"name": "Gimli",  "is_bot": false},
	]})
	_vault = add_child_autofree(load("res://scripts/game/vault_controller.gd").new())

# ── Enter empty vault ─────────────────────────────────────────────────────────

func test_enter_empty_vault_sets_position() -> void:
	_vault.handle_claws(0, 1)
	assert_eq(PlayerManager.players[0].position, PlayerData.PlayerPosition.AT_VAULT)

func test_enter_empty_vault_awards_1_gems() -> void:
	_vault.handle_claws(0, 1)
	assert_eq(PlayerManager.players[0].gems, 1)

func test_enter_empty_vault_emits_vault_entered() -> void:
	watch_signals(_vault)
	_vault.handle_claws(0, 1)
	assert_signal_emitted(_vault, "vault_entered")

# ── Attack from outside → vault player takes damage ──────────────────────────

func test_outside_attack_damages_vault_player() -> void:
	PlayerManager.set_position(1, PlayerData.PlayerPosition.AT_VAULT)
	_vault.handle_claws(0, 2)
	assert_eq(PlayerManager.players[1].health, 8)

func test_outside_attack_emits_escape_requested() -> void:
	PlayerManager.set_position(1, PlayerData.PlayerPosition.AT_VAULT)
	watch_signals(_vault)
	_vault.handle_claws(0, 1)
	assert_signal_emitted(_vault, "escape_requested")

func test_outside_attacker_stays_outside_pending_dialog() -> void:
	PlayerManager.set_position(1, PlayerData.PlayerPosition.AT_VAULT)
	_vault.handle_claws(0, 1)
	assert_eq(PlayerManager.players[0].position, PlayerData.PlayerPosition.OUTSIDE)

# ── Attack at vault → all outside players take damage ────────────────────────

func test_vault_player_attacks_outside_players() -> void:
	PlayerManager.set_position(0, PlayerData.PlayerPosition.AT_VAULT)
	_vault.handle_claws(0, 2)
	assert_eq(PlayerManager.players[1].health, 8)

func test_vault_player_attack_emits_vault_attacked() -> void:
	PlayerManager.set_position(0, PlayerData.PlayerPosition.AT_VAULT)
	watch_signals(_vault)
	_vault.handle_claws(0, 1)
	assert_signal_emitted(_vault, "vault_attacked")

# ── handle_flee ───────────────────────────────────────────────────────────────

func test_flee_moves_defender_outside() -> void:
	PlayerManager.set_position(1, PlayerData.PlayerPosition.AT_VAULT)
	_vault.handle_flee(0)
	assert_eq(PlayerManager.players[1].position, PlayerData.PlayerPosition.OUTSIDE)

func test_flee_moves_attacker_to_vault() -> void:
	PlayerManager.set_position(1, PlayerData.PlayerPosition.AT_VAULT)
	_vault.handle_flee(0)
	assert_eq(PlayerManager.players[0].position, PlayerData.PlayerPosition.AT_VAULT)

# ── handle_stay ───────────────────────────────────────────────────────────────

func test_stay_leaves_vault_occupant_unchanged() -> void:
	PlayerManager.set_position(1, PlayerData.PlayerPosition.AT_VAULT)
	_vault.handle_stay()
	assert_eq(PlayerManager.players[1].position, PlayerData.PlayerPosition.AT_VAULT)

# ── Entering occupied vault directly is not possible ─────────────────────────

func test_cannot_enter_occupied_vault_directly() -> void:
	PlayerManager.set_position(1, PlayerData.PlayerPosition.AT_VAULT)
	_vault.handle_claws(0, 1)
	assert_eq(PlayerManager.players[0].position, PlayerData.PlayerPosition.OUTSIDE)
