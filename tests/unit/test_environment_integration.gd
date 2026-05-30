extends GutTest
## M-Dragon-6: query-card environment effects consulted at integration points.

func before_each() -> void:
	GameManager.start_game({"players": [
		{"name": "Thorin", "is_bot": false},
		{"name": "Gimli",  "is_bot": false},
	]})

func after_each() -> void:
	EnvironmentManager.active_card = null
	EnvironmentManager.pending_card = null

# ── Dice (DicePoolController) ──────────────────────────────────────────────────

func test_trembling_ground_caps_rolls() -> void:
	var pool: Node = add_child_autofree(preload("res://scenes/dice/dice_pool.tscn").instantiate())
	EnvironmentManager.active_card = TremblingGroundEffect.new()
	assert_eq(pool.get_max_rolls(), 2)

func test_lucky_vein_grants_extra_roll() -> void:
	var pool: Node = add_child_autofree(preload("res://scenes/dice/dice_pool.tscn").instantiate())
	EnvironmentManager.active_card = LuckyVeinEffect.new()
	assert_eq(pool.get_max_rolls(), 4)

func test_cave_collapse_reduces_dice() -> void:
	var pool: Node = add_child_autofree(preload("res://scenes/dice/dice_pool.tscn").instantiate())
	EnvironmentManager.active_card = CaveCollapseEffect.new()
	pool._update_die_visibility()
	assert_eq(pool.get_dice_count(), 4)

# ── Shop (CardShop) ───────────────────────────────────────────────────────────

func test_dragons_shadow_blocks_purchase() -> void:
	PlayerManager.add_gold(0, 99)
	EnvironmentManager.active_card = DragonsShadowEffect.new()
	var before := CardShop.visible_cards.size()
	assert_false(CardShop.purchase(0, 0))
	assert_eq(CardShop.visible_cards.size(), before)

func test_drought_raises_cost() -> void:
	var base: int = CardShop.visible_cards[0].gold_cost
	PlayerManager.add_gold(0, base)            # exactly base — one short under Drought
	EnvironmentManager.active_card = DroughtEffect.new()
	assert_false(CardShop.purchase(0, 0))

func test_black_market_lowers_cost() -> void:
	var base: int = CardShop.visible_cards[0].gold_cost
	PlayerManager.add_gold(0, maxi(0, base - 1))
	EnvironmentManager.active_card = BlackMarketEffect.new()
	assert_true(CardShop.purchase(0, 0))

# ── Vault (VaultController) ───────────────────────────────────────────────────

func test_siege_blocks_single_claw_entry() -> void:
	var vault: Node = add_child_autofree(load("res://scripts/game/vault_controller.gd").new())
	EnvironmentManager.active_card = SiegeEffect.new()
	vault.handle_claws(0, 1)
	assert_eq(PlayerManager.players[0].position, PlayerData.PlayerPosition.OUTSIDE)

func test_siege_allows_two_claw_entry() -> void:
	var vault: Node = add_child_autofree(load("res://scripts/game/vault_controller.gd").new())
	EnvironmentManager.active_card = SiegeEffect.new()
	vault.handle_claws(0, 2)
	assert_eq(PlayerManager.players[0].position, PlayerData.PlayerPosition.AT_VAULT)

# ── Damage cap (PlayerManager) ────────────────────────────────────────────────

func test_pacifist_curse_caps_turn_damage() -> void:
	EnvironmentManager.active_card = PacifistCurseEffect.new()
	var hp := PlayerManager.players[1].health
	PlayerManager.apply_damage(1, 5, 0)
	assert_eq(PlayerManager.players[1].health, hp - 2)
	PlayerManager.apply_damage(1, 5, 0)
	assert_eq(PlayerManager.players[1].health, hp - 2)   # already capped this turn

# ── Vault-holder gold (PlayerManager.add_gold) ────────────────────────────────

func test_rich_deposit_bonus_for_vault_holder() -> void:
	PlayerManager.set_position(0, PlayerData.PlayerPosition.AT_VAULT)
	EnvironmentManager.active_card = RichDepositEffect.new()
	var g := PlayerManager.players[0].gold
	PlayerManager.add_gold(0, 1)
	assert_eq(PlayerManager.players[0].gold, g + 3)      # 1 + 2 bonus

func test_rich_deposit_no_bonus_outside() -> void:
	EnvironmentManager.active_card = RichDepositEffect.new()
	var g := PlayerManager.players[0].gold
	PlayerManager.add_gold(0, 1)
	assert_eq(PlayerManager.players[0].gold, g + 1)

func test_restless_hoard_blocks_vault_holder_gold() -> void:
	PlayerManager.set_position(0, PlayerData.PlayerPosition.AT_VAULT)
	EnvironmentManager.active_card = RestlessHoardEffect.new()
	var g := PlayerManager.players[0].gold
	PlayerManager.add_gold(0, 5)
	assert_eq(PlayerManager.players[0].gold, g)

# ── Silence (CardEffectHandler) ───────────────────────────────────────────────

func _player_with_income_card() -> CardEffectHandler:
	var handler := CardEffectHandler.new()
	var card := CardData.new()
	card.card_type = CardData.CardType.PERMANENT
	var eff := GoldPerTurnEffect.new(1)
	eff.effect_id = CardEffectId.Id.GOLD_PER_TURN_1
	card.effect = eff
	PlayerManager.players[0].cards_in_hand.append(card)
	return handler

func test_silence_suppresses_turn_passive() -> void:
	var handler := _player_with_income_card()
	EnvironmentManager.active_card = SilenceEffect.new()
	var g := PlayerManager.players[0].gold
	handler._on_turn_started(0)
	assert_eq(PlayerManager.players[0].gold, g)

func test_passive_fires_without_silence() -> void:
	var handler := _player_with_income_card()
	var g := PlayerManager.players[0].gold
	handler._on_turn_started(0)
	assert_eq(PlayerManager.players[0].gold, g + 1)
