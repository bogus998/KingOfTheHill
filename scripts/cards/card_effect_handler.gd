class_name CardEffectHandler
extends RefCounted
## Thin dispatcher: routes game lifecycle events to each card's CardEffect.
##
## The handler holds no per-effect logic — it iterates the relevant cards and
## calls the matching hook on `card.effect`. Smoke Bomb charge tracking is the
## one exception: charges are cross-cutting state consumed by the dice UI.

var _card_charges: Dictionary = {}

func apply_immediate(card: CardData, player_index: int) -> void:
	if card.effect != null:
		card.effect.apply_immediate(player_index)
	if card.card_type == CardData.CardType.ONE_TIME:
		PlayerManager.players[player_index].spent_one_time_cards.append(card)
		PlayerManager.remove_card_from_hand(player_index, card)

func on_roll_finalized(player_index: int, final_faces: Array) -> void:
	for card in PlayerManager.players[player_index].cards_in_hand.duplicate():
		if card.card_type == CardData.CardType.PERMANENT and card.effect != null:
			card.effect.on_roll_finalized(player_index, final_faces)

func use_smoke_bomb_charge(card: CardData, player_index: int) -> void:
	if not _card_charges.has(card) or _card_charges[card] <= 0:
		return
	_card_charges[card] -= 1
	PlayerManager.players[player_index].extra_rerolls_available += 1
	if _card_charges[card] == 0:
		_card_charges.erase(card)
		PlayerManager.players[player_index].spent_one_time_cards.append(card)
		PlayerManager.remove_card_from_hand(player_index, card)

func _on_card_purchased(player_index: int, card: CardData) -> void:
	if card.card_type == CardData.CardType.PERMANENT and card.effect != null:
		card.effect.on_acquired(player_index)
		if card.effect.effect_id == CardEffectId.Id.SMOKE_BOMB:
			_card_charges[card] = (card.effect as SmokeBombEffect).charges
	if card.card_type == CardData.CardType.ONE_TIME:
		apply_immediate(card, player_index)
	# Notify every permanent in hand (including the just-bought card) of the buy.
	for c in PlayerManager.players[player_index].cards_in_hand:
		if c.card_type == CardData.CardType.PERMANENT and c.effect != null:
			c.effect.on_any_card_purchased(player_index, card)

func _on_turn_started(player_index: int) -> void:
	if player_index >= PlayerManager.players.size():
		return
	var p := PlayerManager.players[player_index]
	# Poison tick before per-turn reset
	if p.poison_stacks > 0:
		PlayerManager.apply_damage(player_index, p.poison_stacks)
		p.poison_stacks -= 1
		if p.is_eliminated:
			return
	# Reset per-turn modifier flags
	p.damage_dealt_this_turn = 0
	p.die_count_modifier = 0
	p.extra_rerolls_available = 0
	p.has_free_reroll_after_max = false
	p.free_reroll_threes = false
	p.can_set_die_before_roll = false
	p.war_drums_triggered = false
	p.nimble_dodge_used_this_turn = false
	p.nimble_dodge_active = false
	# repeat_turn_used stays true through a repeated turn to block re-triggering
	if not TurnManager.is_repeated_turn:
		p.repeat_turn_used = false
	# Apply PERMANENT card passives; skip income/damage passives on repeated turns
	for card in p.cards_in_hand.duplicate():
		if card.card_type == CardData.CardType.PERMANENT and card.effect != null:
			if TurnManager.is_repeated_turn and card.effect.is_income_passive():
				continue
			card.effect.on_turn_started(player_index)
	# Apply shrink penalty after PERMANENT loop (die_count_modifier already set by PERMANENT cards)
	if p.shrink_stacks > 0:
		p.die_count_modifier -= p.shrink_stacks

func _on_turn_ended(player_index: int) -> void:
	if player_index >= PlayerManager.players.size():
		return
	for card in PlayerManager.players[player_index].cards_in_hand.duplicate():
		if card.card_type == CardData.CardType.PERMANENT and card.effect != null:
			card.effect.on_turn_ended(player_index)
	var p := PlayerManager.players[player_index]
	if p.shrink_stacks > 0:
		p.shrink_stacks -= 1
	p.camouflage_active = false
	p.gold_dodge_active = false

func _on_damage_applied(attacker_index: int, target_index: int, amount: int) -> void:
	if amount <= 0 or attacker_index < 0 or attacker_index == target_index:
		return
	for i in PlayerManager.players.size():
		for card in PlayerManager.players[i].cards_in_hand.duplicate():
			if card.card_type == CardData.CardType.PERMANENT and card.effect != null:
				card.effect.on_damage_applied(i, attacker_index, target_index, amount)

func _on_player_eliminated(eliminated_index: int) -> void:
	for i in PlayerManager.players.size():
		for card in PlayerManager.players[i].cards_in_hand.duplicate():
			if card.card_type == CardData.CardType.PERMANENT and card.effect != null:
				card.effect.on_player_eliminated(i, eliminated_index)

func apply_active_ability(effect_id: CardEffectId.Id, player_index: int) -> void:
	match effect_id:
		CardEffectId.Id.RAPID_HEALING:
			if PlayerManager.spend_gold(player_index, 2):
				PlayerManager.apply_heal(player_index, 1)
		CardEffectId.Id.NIMBLE_DODGE:
			var p := PlayerManager.players[player_index]
			if not p.nimble_dodge_used_this_turn:
				if PlayerManager.spend_gold(player_index, 1):
					p.nimble_dodge_active = true
					p.nimble_dodge_used_this_turn = true
		CardEffectId.Id.SLOW_GRINDER:
			if PlayerManager.spend_gold(player_index, 3):
				PlayerManager.add_gems(player_index, 1)

func _on_position_changed(player_index: int, new_pos: PlayerData.PlayerPosition) -> void:
	for card in PlayerManager.players[player_index].cards_in_hand.duplicate():
		if card.card_type == CardData.CardType.PERMANENT and card.effect != null:
			card.effect.on_position_changed(player_index, new_pos)
