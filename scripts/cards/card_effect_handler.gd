class_name CardEffectHandler
extends RefCounted

func apply_immediate(card: CardData, player_index: int) -> void:
	_apply_effect(card.effect_id, player_index)
	if card.card_type == CardData.CardType.ONE_TIME:
		PlayerManager.players[player_index].spent_one_time_cards.append(card)
		PlayerManager.remove_card_from_hand(player_index, card)

func _on_card_purchased(player_index: int, card: CardData) -> void:
	# Apply static modifiers for permanent cards on purchase
	if card.card_type == CardData.CardType.PERMANENT:
		match card.effect_id:
			"damage_reduction_1":
				PlayerManager.players[player_index].damage_reduction += 1
			"health_cap_plus_2":
				PlayerManager.players[player_index].max_health += 2
				PlayerManager.apply_heal(player_index, 2)
			"regen_bonus":
				PlayerManager.players[player_index].heal_bonus += 1
			"gem_bonus_on_gain":
				PlayerManager.players[player_index].gem_gain_bonus += 1
	if card.card_type == CardData.CardType.ONE_TIME:
		apply_immediate(card, player_index)
	# Fire gold_on_purchase for any permanent in hand (including the just-bought card)
	for c in PlayerManager.players[player_index].cards_in_hand:
		if c.card_type == CardData.CardType.PERMANENT and c.effect_id == "gold_on_purchase":
			PlayerManager.add_gold(player_index, 1)

func _on_turn_started(player_index: int) -> void:
	if player_index >= PlayerManager.players.size():
		return
	PlayerManager.players[player_index].damage_dealt_this_turn = 0
	for card in PlayerManager.players[player_index].cards_in_hand.duplicate():
		if card.card_type == CardData.CardType.PERMANENT:
			_apply_effect(card.effect_id, player_index)

func _on_turn_ended(player_index: int) -> void:
	if player_index >= PlayerManager.players.size():
		return
	for card in PlayerManager.players[player_index].cards_in_hand.duplicate():
		if card.card_type == CardData.CardType.PERMANENT:
			_apply_turn_end_effect(card.effect_id, player_index)

func _apply_effect(effect_id: String, player_index: int) -> void:
	match effect_id:
		# ── Gain gold (immediate / ONE_TIME) ─────────────────────────────────
		"gain_gold_1":  PlayerManager.add_gold(player_index, 1)
		"gain_gold_2":  PlayerManager.add_gold(player_index, 2)
		"gain_gold_3":  PlayerManager.add_gold(player_index, 3)
		"gain_gold_4":  PlayerManager.add_gold(player_index, 4)
		# ── Gain gems ────────────────────────────────────────────────────────
		"gain_gems_2":  PlayerManager.add_gems(player_index, 2)
		"gain_gems_9":  PlayerManager.add_gems(player_index, 9)
		# ── Heal ─────────────────────────────────────────────────────────────
		"heal_2":       PlayerManager.apply_heal(player_index, 2)
		"heal_3":       PlayerManager.apply_heal(player_index, 3)
		# ── Damage others ────────────────────────────────────────────────────
		"damage_all_2":               _damage_others(player_index, 2)
		"damage_all_including_self_3": _damage_all(player_index, 3)
		# ── Combined (gold + damage / heal / self-damage) ────────────────────
		"gold_2_damage_all_3":
			PlayerManager.add_gold(player_index, 2)
			_damage_others(player_index, 3)
		"gold_2_heal_3":
			PlayerManager.add_gold(player_index, 2)
			PlayerManager.apply_heal(player_index, 3)
		"gold_2_take_2_damage":
			PlayerManager.add_gold(player_index, 2)
			PlayerManager.apply_damage(player_index, 2)
		"gold_4_take_3_damage":
			PlayerManager.add_gold(player_index, 4)
			PlayerManager.apply_damage(player_index, 3)
		"gold_5_take_4_damage":
			PlayerManager.add_gold(player_index, 5)
			PlayerManager.apply_damage(player_index, 4)
		# ── Steal / special ──────────────────────────────────────────────────
		"steal_gold_5_all":  _steal_gold_from_others(player_index, 5)
		"war_band":          _apply_war_band(player_index)
		"gold_2_steal_gems":
			PlayerManager.add_gold(player_index, 2)
			_steal_half_gems_from_others(player_index)
		# ── Permanent turn-start passives ────────────────────────────────────
		"gem_per_turn_1": PlayerManager.add_gems(player_index, 1)
		"passive_damage_1_per_turn": _damage_others(player_index, 1)
		"vault_bonus_gold_2":
			if PlayerManager.players[player_index].position == PlayerData.PlayerPosition.AT_VAULT:
				PlayerManager.add_gold(player_index, 2)
		"vault_dweller":
			if PlayerManager.players[player_index].position == PlayerData.PlayerPosition.AT_VAULT:
				PlayerManager.add_gold(player_index, 1)

func _apply_turn_end_effect(effect_id: String, player_index: int) -> void:
	match effect_id:
		"underdog_gold": _apply_underdog_gold(player_index)
		"gem_if_empty":
			if PlayerManager.players[player_index].gems == 0:
				PlayerManager.add_gems(player_index, 1)
		"gold_per_6gems":
			var bonus: int = PlayerManager.players[player_index].gems / 6
			if bonus > 0:
				PlayerManager.add_gold(player_index, bonus)
		"gold_if_no_damage":
			if PlayerManager.players[player_index].damage_dealt_this_turn == 0:
				PlayerManager.add_gold(player_index, 1)
		"heavy_strike_gold":
			if PlayerManager.players[player_index].damage_dealt_this_turn >= 3:
				PlayerManager.add_gold(player_index, 2)

# ── Helpers ───────────────────────────────────────────────────────────────────

func _damage_others(source_index: int, amount: int) -> void:
	for i in PlayerManager.players.size():
		if i != source_index and not PlayerManager.players[i].is_eliminated:
			PlayerManager.apply_damage(i, amount, source_index)

func _damage_all(source_index: int, amount: int) -> void:
	for i in PlayerManager.players.size():
		if not PlayerManager.players[i].is_eliminated:
			PlayerManager.apply_damage(i, amount, source_index)

func _steal_gold_from_others(source_index: int, amount: int) -> void:
	for i in PlayerManager.players.size():
		if i != source_index and not PlayerManager.players[i].is_eliminated:
			var p := PlayerManager.players[i]
			var stolen: int = min(p.gold, amount)
			if stolen > 0:
				p.gold -= stolen
				PlayerManager.gold_changed.emit(i, p.gold)
				PlayerManager.add_gold(source_index, stolen)

func _steal_half_gems_from_others(source_index: int) -> void:
	for i in PlayerManager.players.size():
		if i != source_index and not PlayerManager.players[i].is_eliminated:
			var lose: int = PlayerManager.players[i].gems / 2
			if lose > 0:
				PlayerManager.spend_gems(i, lose)
				PlayerManager.add_gems(source_index, lose)

func _apply_war_band(player_index: int) -> void:
	var card_count: int = PlayerManager.players[player_index].cards_in_hand.size()
	for _i in card_count:
		PlayerManager.add_gold(player_index, 1)
		PlayerManager.apply_damage(player_index, 1)

func _apply_underdog_gold(player_index: int) -> void:
	if PlayerManager.players[player_index].is_eliminated:
		return
	var my_gold: int = PlayerManager.players[player_index].gold
	for i in PlayerManager.players.size():
		if i != player_index and not PlayerManager.players[i].is_eliminated:
			if PlayerManager.players[i].gold < my_gold:
				return
	PlayerManager.add_gold(player_index, 1)

# ── Signal callbacks (connect via main_game_controller) ───────────────────────

func _on_damage_applied(attacker_index: int, target_index: int, amount: int) -> void:
	if amount <= 0 or attacker_index < 0 or attacker_index == target_index:
		return
	if _has_card(target_index, "reflective_1"):
		PlayerManager.apply_damage(attacker_index, 1)
	if _has_card(attacker_index, "life_drain"):
		PlayerManager.apply_heal(attacker_index, 1)
	if _has_card(attacker_index, "chain_damage_1"):
		for i in PlayerManager.players.size():
			if i != attacker_index and i != target_index and not PlayerManager.players[i].is_eliminated:
				PlayerManager.apply_damage(i, 1)
	if amount >= 2 and _has_card(target_index, "gem_on_heavy_damage"):
		PlayerManager.add_gems(target_index, 1)

func _on_player_eliminated(eliminated_index: int) -> void:
	for i in PlayerManager.players.size():
		if i != eliminated_index and not PlayerManager.players[i].is_eliminated:
			if _has_card(i, "gold_on_kill"):
				PlayerManager.add_gold(i, 3)

func _on_position_changed(player_index: int, new_pos: PlayerData.PlayerPosition) -> void:
	if new_pos == PlayerData.PlayerPosition.AT_VAULT:
		if _has_card(player_index, "gold_2_enter_vault"):
			PlayerManager.add_gold(player_index, 2)

func _has_card(player_index: int, effect_id: String) -> bool:
	for card in PlayerManager.players[player_index].cards_in_hand:
		if card.effect_id == effect_id:
			return true
	return false
