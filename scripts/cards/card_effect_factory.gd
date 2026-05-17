class_name CardEffectFactory
## Constructs a CardEffect instance for a given CardEffectId.
##
## This is a construction helper for tests and migration tooling only. Runtime
## gameplay never calls it — cards carry their effect as a sub-resource and the
## handler reads `card.effect` directly. Ids without a concrete subclass fall
## through to a no-op base CardEffect (not-yet-implemented stubs).

static func create(id: CardEffectId.Id) -> CardEffect:
	var e := _build(id)
	e.effect_id = id
	return e

static func _build(id: CardEffectId.Id) -> CardEffect:
	match id:
		# ── Immediate / ONE_TIME ──────────────────────────────────────────────
		CardEffectId.Id.GAIN_GOLD_1: return GainGoldEffect.new(1)
		CardEffectId.Id.GAIN_GOLD_2: return GainGoldEffect.new(2)
		CardEffectId.Id.GAIN_GOLD_3: return GainGoldEffect.new(3)
		CardEffectId.Id.GAIN_GOLD_4: return GainGoldEffect.new(4)
		CardEffectId.Id.GAIN_GEMS_2: return GainGemsEffect.new(2)
		CardEffectId.Id.GAIN_GEMS_9: return GainGemsEffect.new(9)
		CardEffectId.Id.HEAL_2: return HealEffect.new(2)
		CardEffectId.Id.HEAL_3: return HealEffect.new(3)
		CardEffectId.Id.DAMAGE_ALL_2: return DamageAllEffect.new(2, false)
		CardEffectId.Id.DAMAGE_ALL_INCLUDING_SELF_3: return DamageAllEffect.new(3, true)
		CardEffectId.Id.GOLD_2_DAMAGE_ALL_3: return GoldAndDamageAllEffect.new(2, 3)
		CardEffectId.Id.GOLD_2_HEAL_3: return GoldAndHealEffect.new(2, 3)
		CardEffectId.Id.GOLD_2_TAKE_2_DAMAGE: return GoldForSelfDamageEffect.new(2, 2)
		CardEffectId.Id.GOLD_4_TAKE_3_DAMAGE: return GoldForSelfDamageEffect.new(4, 3)
		CardEffectId.Id.GOLD_5_TAKE_4_DAMAGE: return GoldForSelfDamageEffect.new(5, 4)
		CardEffectId.Id.STEAL_GOLD_5_ALL: return StealGoldEffect.new(5)
		CardEffectId.Id.WAR_BAND: return WarBandEffect.new()
		CardEffectId.Id.GOLD_2_STEAL_GEMS: return GoldAndStealGemsEffect.new(2)
		CardEffectId.Id.WILDCARD_DIE: return WildcardDieEffect.new()

		# ── Permanent turn-start passives ─────────────────────────────────────
		CardEffectId.Id.GEM_PER_TURN_1: return GemPerTurnEffect.new(1)
		CardEffectId.Id.PASSIVE_DAMAGE_1_PER_TURN: return PassiveDamageEffect.new(1)
		CardEffectId.Id.VAULT_BONUS_GOLD_2: return VaultGoldEffect.new(2)
		CardEffectId.Id.VAULT_DWELLER: return VaultGoldEffect.new(1)
		CardEffectId.Id.EXTRA_DIE: return ExtraDieEffect.new()
		CardEffectId.Id.BONUS_REROLL_1: return BonusRerollEffect.new()
		CardEffectId.Id.FREE_REROLL_THREES: return FreeRerollThreesEffect.new()
		CardEffectId.Id.SET_DIE_TO_ONE: return SetDieToOneEffect.new()

		# ── Permanent purchase-time stat modifiers ────────────────────────────
		CardEffectId.Id.DAMAGE_REDUCTION_1: return DamageReductionEffect.new(1)
		CardEffectId.Id.HEALTH_CAP_PLUS_2: return HealthCapEffect.new(2)
		CardEffectId.Id.REGEN_BONUS: return RegenBonusEffect.new(1)
		CardEffectId.Id.GEM_BONUS_ON_GAIN: return GemBonusOnGainEffect.new(1)
		CardEffectId.Id.SMOKE_BOMB: return SmokeBombEffect.new(3)
		CardEffectId.Id.GOLD_ON_PURCHASE: return GoldOnPurchaseEffect.new(1)

		# ── Permanent turn-end passives ───────────────────────────────────────
		CardEffectId.Id.UNDERDOG_GOLD: return UnderdogGoldEffect.new()
		CardEffectId.Id.GEM_IF_EMPTY: return GemIfEmptyEffect.new()
		CardEffectId.Id.GOLD_PER_6GEMS: return GoldPerGemsEffect.new(6)
		CardEffectId.Id.GOLD_IF_NO_DAMAGE: return GoldIfNoDamageEffect.new()
		CardEffectId.Id.HEAVY_STRIKE_GOLD: return HeavyStrikeGoldEffect.new()

		# ── Permanent dice / roll-finalized passives ──────────────────────────
		CardEffectId.Id.ALL_FACES_BONUS: return AllFacesBonusEffect.new(9)
		CardEffectId.Id.COMBO_MASTER: return ComboMasterEffect.new(2)
		CardEffectId.Id.TRIPLE_ONE_GOLD_BONUS_2: return TripleOneGoldEffect.new(2)
		CardEffectId.Id.TRIPLE_ONE_EXTRA_TURN: return TripleOneExtraTurnEffect.new()
		CardEffectId.Id.TRIPLE_TWO_DAMAGE_2: return TripleTwoDamageEffect.new(2)
		CardEffectId.Id.WAR_DRUMS: return WarDrumsEffect.new()

		# ── Event-triggered passives ──────────────────────────────────────────
		CardEffectId.Id.REFLECTIVE_1: return ReflectiveEffect.new(1)
		CardEffectId.Id.LIFE_DRAIN: return LifeDrainEffect.new(1)
		CardEffectId.Id.CHAIN_DAMAGE_1: return ChainDamageEffect.new(1)
		CardEffectId.Id.GEM_ON_HEAVY_DAMAGE: return GemOnHeavyDamageEffect.new(2, 1)
		CardEffectId.Id.GOLD_ON_KILL: return GoldOnKillEffect.new(3)
		CardEffectId.Id.GOLD_2_ENTER_VAULT: return GoldOnEnterVaultEffect.new(2)

		# ── Not yet implemented — no-op stub ──────────────────────────────────
		_: return CardEffect.new()
