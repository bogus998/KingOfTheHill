extends GutTest

func before_each() -> void:
	PlayerManager.setup([{"name": "Thorin", "is_bot": false}])
	CardShop.reset()
	PlayerManager.players[0].gems = 10

# ── Deck loading ──────────────────────────────────────────────────────────────

func test_deck_loads_all_cards() -> void:
	var total := CardShop.visible_cards.size() + CardShop._deck.size()
	assert_eq(total, CardCatalog.load_all_cards().size())

func test_three_cards_visible_at_start() -> void:
	assert_eq(CardShop.visible_cards.size(), 3)

# ── purchase ──────────────────────────────────────────────────────────────────

func test_purchase_deducts_gem_cost() -> void:
	var cost := CardShop.visible_cards[0].gem_cost
	CardShop.purchase(0, 0)
	assert_eq(PlayerManager.players[0].gems, 10 - cost)

func test_purchase_replenishes_visible_slot() -> void:
	CardShop.purchase(0, 0)
	assert_eq(CardShop.visible_cards.size(), 3)

func test_purchase_returns_true_on_success() -> void:
	assert_true(CardShop.purchase(0, 0))

func test_purchase_returns_false_when_insufficient_gems() -> void:
	PlayerManager.players[0].gems = 0
	assert_false(CardShop.purchase(0, 0))

func test_purchase_does_not_deduct_on_failure() -> void:
	PlayerManager.players[0].gems = 0
	CardShop.purchase(0, 0)
	assert_eq(PlayerManager.players[0].gems, 0)

func test_purchase_emits_card_purchased_signal() -> void:
	watch_signals(CardShop)
	CardShop.purchase(0, 0)
	assert_signal_emitted(CardShop, "card_purchased")

func test_permanent_card_added_to_hand() -> void:
	var card := CardData.new()
	card.card_type = CardData.CardType.PERMANENT
	card.gem_cost = 1
	CardShop.visible_cards[0] = card
	CardShop.purchase(0, 0)
	assert_eq(PlayerManager.players[0].cards_in_hand.size(), 1)

# ── refresh ───────────────────────────────────────────────────────────────────

func test_refresh_costs_2_gems() -> void:
	CardShop.refresh_pool(0)
	assert_eq(PlayerManager.players[0].gems, 8)

func test_refresh_returns_true_on_success() -> void:
	assert_true(CardShop.refresh_pool(0))

func test_refresh_returns_false_when_insufficient_gems() -> void:
	PlayerManager.players[0].gems = 1
	assert_false(CardShop.refresh_pool(0))

func test_refresh_emits_shop_updated() -> void:
	watch_signals(CardShop)
	CardShop.refresh_pool(0)
	assert_signal_emitted(CardShop, "shop_updated")
