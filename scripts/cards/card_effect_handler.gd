class_name CardEffectHandler
extends RefCounted
## Thin dispatcher: routes game lifecycle events to each card's CardEffect.
##
## The handler holds no per-effect logic — it iterates the relevant cards and
## calls the matching hook on `card.effect`. Smoke Bomb charge tracking is the
## one exception: charges are cross-cutting state consumed by the dice UI.

signal effect_hook_called(card_name: String, hook: String, holder_name: String)

var _card_charges: Dictionary = {}

func apply_immediate(card: CardData, player_index: int) -> void:
	if card.effect != null:
		card.effect.apply_immediate(player_index)
		if card.effect.effect_id == CardEffectId.Id.EXTRA_TURN:
			TurnManager.pending_extra_turn = true
	if card.card_type == CardData.CardType.ONE_TIME \
			or card.card_type == CardData.CardType.ACTIONABLE:
		PlayerManager.players[player_index].spent_one_time_cards.append(card)
		var hand := PlayerManager.players[player_index].cards_in_hand
		if hand.has(card):
			PlayerManager.remove_card_from_hand(player_index, card)
		elif card.effect != null:
			for c in hand:
				if c.effect != null and c.effect.effect_id == card.effect.effect_id:
					PlayerManager.remove_card_from_hand(player_index, c)
					break

func on_roll_finalized(player_index: int, final_faces: Array) -> void:
	for card in PlayerManager.players[player_index].cards_in_hand.duplicate():
		if card.card_type == CardData.CardType.PERMANENT and card.effect != null:
			card.effect.on_roll_finalized(player_index, final_faces)
			effect_hook_called.emit(card.card_name, "on_roll_finalized", PlayerManager.players[player_index].player_name)

func use_smoke_bomb_charge(card: CardData, player_index: int) -> void:
	if not _card_charges.has(card) or _card_charges[card] <= 0:
		return
	_card_charges[card] -= 1
	PlayerManager.players[player_index].extra_rerolls_available += 1
	if _card_charges[card] == 0:
		_card_charges.erase(card)
		PlayerManager.players[player_index].spent_one_time_cards.append(card)
		var hand := PlayerManager.players[player_index].cards_in_hand
		var to_remove: CardData = card if hand.has(card) else null
		if to_remove == null:
			for c in hand:
				if c.effect != null and c.effect.effect_id == CardEffectId.Id.SMOKE_BOMB:
					to_remove = c
					break
		if to_remove != null:
			PlayerManager.remove_card_from_hand(player_index, to_remove)

func _on_card_purchased(player_index: int, card: CardData) -> void:
	if (card.card_type == CardData.CardType.PERMANENT \
			or card.card_type == CardData.CardType.ACTIONABLE) and card.effect != null:
		card.effect.on_acquired(player_index)
		if card.effect.effect_id == CardEffectId.Id.SMOKE_BOMB:
			_card_charges[card] = (card.effect as SmokeBombEffect).charges
		elif card.effect.effect_id == CardEffectId.Id.GOLD_BATTERY:
			# add_card_to_hand duplicates the resource, so `card` here is the pre-dup
			# original. Find the freshly added instance by its effect_id and charges == 0.
			for c in PlayerManager.players[player_index].cards_in_hand:
				if c.effect != null and c.effect.effect_id == CardEffectId.Id.GOLD_BATTERY \
						and c.charges == 0:
					c.charges = 6
					break
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
	# Reset per-turn modifier flags
	p.damage_dealt_this_turn = 0
	p.die_count_modifier = 0
	p.extra_rerolls_available = 0
	p.has_free_reroll_after_max = false
	p.free_reroll_threes = false
	p.war_drums_triggered = false
	p.nimble_dodge_used_this_turn = false
	p.nimble_dodge_active = false
	p.die_picker_used_this_turn = false
	p.die_jacker_used_this_turn = false
	# repeat_turn_used stays true through a repeated turn to block re-triggering
	if not TurnManager.is_repeated_turn:
		p.repeat_turn_used = false
	# Apply PERMANENT card passives; skip income/damage passives on repeated turns
	for card in p.cards_in_hand.duplicate():
		if card.card_type == CardData.CardType.PERMANENT and card.effect != null:
			if TurnManager.is_repeated_turn and card.effect.is_income_passive():
				continue
			if card.effect.effect_id == CardEffectId.Id.GOLD_BATTERY:
				continue  # handled separately below (needs card reference for charges)
			card.effect.on_turn_started(player_index)
			effect_hook_called.emit(card.card_name, "on_turn_started", p.player_name)
	# Gold Battery: dispense gold and decrement charge counter (skip on repeated turns)
	if not TurnManager.is_repeated_turn:
		for card in p.cards_in_hand.duplicate():
			if card.effect != null and card.effect.effect_id == CardEffectId.Id.GOLD_BATTERY \
					and card.charges > 0:
				PlayerManager.add_gold(player_index, 2)
				card.charges -= 1
				if card.charges <= 0:
					PlayerManager.remove_card_from_hand(player_index, card)
				break
	# Apply shrink penalty after PERMANENT loop (die_count_modifier already set by PERMANENT cards)
	if p.shrink_stacks > 0:
		p.die_count_modifier -= p.shrink_stacks

func _on_turn_ended(player_index: int) -> void:
	if player_index >= PlayerManager.players.size():
		return
	for card in PlayerManager.players[player_index].cards_in_hand.duplicate():
		if card.card_type == CardData.CardType.PERMANENT and card.effect != null:
			card.effect.on_turn_ended(player_index)
			effect_hook_called.emit(card.card_name, "on_turn_ended", PlayerManager.players[player_index].player_name)
	var p := PlayerManager.players[player_index]
	if p.shrink_stacks > 0:
		p.shrink_stacks -= 1
	p.camouflage_active = false
	if p.poison_stacks > 0:
		PlayerManager.apply_damage(player_index, p.poison_stacks)
		if p.is_eliminated:
			return

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
		CardEffectId.Id.WILDCARD_DIE:
			for c in PlayerManager.players[player_index].cards_in_hand.duplicate():
				if c.effect != null and c.effect.effect_id == CardEffectId.Id.WILDCARD_DIE:
					apply_immediate(c, player_index)
					break
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
		CardEffectId.Id.GOLD_EXTRA_REROLL:
			if PlayerManager.spend_gold(player_index, 1):
				PlayerManager.players[player_index].extra_rerolls_available += 1

func apply_die_jacker(player_index: int) -> void:
	var p := PlayerManager.players[player_index]
	if p.die_jacker_used_this_turn:
		return
	p.die_jacker_used_this_turn = true
	for i in PlayerManager.players.size():
		if i != player_index and not PlayerManager.players[i].is_eliminated:
			PlayerManager.players[i].die_jacker_pending = true

func _on_position_changed(player_index: int, new_pos: PlayerData.PlayerPosition) -> void:
	for card in PlayerManager.players[player_index].cards_in_hand.duplicate():
		if card.card_type == CardData.CardType.PERMANENT and card.effect != null:
			card.effect.on_position_changed(player_index, new_pos)

func complete_buy_from_others(buyer_index: int, card: CardData) -> void:
	var owner_index := -1
	for i in PlayerManager.players.size():
		if PlayerManager.players[i].cards_in_hand.has(card):
			owner_index = i
			break
	if owner_index < 0 or owner_index == buyer_index:
		return
	if not PlayerManager.spend_gold(buyer_index, card.gold_cost):
		return
	PlayerManager.remove_card_from_hand(owner_index, card)
	PlayerManager.add_card_to_hand(buyer_index, card)
