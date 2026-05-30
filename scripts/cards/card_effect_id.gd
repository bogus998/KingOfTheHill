class_name CardEffectId
## Stable identity tag for every card effect.
##
## Each value corresponds to one card "flavour". The behaviour itself lives on a
## CardEffect Resource subclass; this enum is the serialisable identity used for
## queries (e.g. VaultController checks) and for distinguishing effects that share
## a parameterised CardEffect class.

enum Id {
	NONE,

	# ── Immediate / ONE_TIME ──────────────────────────────────────────────────
	GAIN_GEMS_1,
	GAIN_GEMS_2,
	GAIN_GEMS_3,
	GAIN_GEMS_4,
	GAIN_GOLD_2,
	GAIN_GOLD_9,
	HEAL_2,
	HEAL_3,
	DAMAGE_ALL_2,
	DAMAGE_ALL_INCLUDING_SELF_3,
	GEM_2_DAMAGE_ALL_3,
	GEM_2_HEAL_3,
	GEM_2_TAKE_2_DAMAGE,
	GEM_4_TAKE_3_DAMAGE,
	GEM_5_TAKE_4_DAMAGE,
	STEAL_GEM_5_ALL,
	WAR_BAND,
	GEM_2_STEAL_GOLD,
	WILDCARD_DIE,

	# ── Permanent turn-start passives ─────────────────────────────────────────
	GOLD_PER_TURN_1,
	PASSIVE_DAMAGE_1_PER_TURN,
	VAULT_BONUS_GEM_2,
	VAULT_DWELLER,
	EXTRA_DIE,
	BONUS_REROLL_1,
	FREE_REROLL_THREES,
	SET_DIE_TO_ONE,

	# ── Permanent purchase-time stat modifiers ────────────────────────────────
	DAMAGE_REDUCTION_1,
	HEALTH_CAP_PLUS_2,
	REGEN_BONUS,
	GOLD_BONUS_ON_GAIN,
	SMOKE_BOMB,
	GEM_ON_PURCHASE,

	# ── Permanent turn-end passives ───────────────────────────────────────────
	UNDERDOG_GEM,
	GOLD_IF_EMPTY,
	GEM_PER_6GOLD,
	GEM_IF_NO_DAMAGE,
	HEAVY_STRIKE_GEM,

	# ── Permanent dice / roll-finalized passives ──────────────────────────────
	ALL_FACES_BONUS,
	COMBO_MASTER,
	TRIPLE_ONE_GEM_BONUS_2,
	TRIPLE_ONE_EXTRA_TURN,
	TRIPLE_TWO_DAMAGE_2,
	WAR_DRUMS,

	# ── Event-triggered passives ──────────────────────────────────────────────
	REFLECTIVE_1,
	LIFE_DRAIN,
	CHAIN_DAMAGE_1,
	GOLD_ON_HEAVY_DAMAGE,
	GEM_ON_KILL,
	GEM_2_ENTER_VAULT,

	# ── Not yet implemented (no-op stubs, reserved for future milestones) ─────
	BUY_FROM_OTHERS,
	CAMOUFLAGE,
	CLAW_BONUS_DAMAGE_1,
	DIE_JACKER,     # implemented — panel-triggered, handled in main_game_controller
	EXTRA_TURN,
	GOLD_BATTERY,
	GOLD_DIE_CHANGE, # implemented — panel-triggered, handled in main_game_controller
	GOLD_DISCOUNT_1,
	GOLD_DODGE,
	GOLD_EXTRA_REROLL,
	GEM_PER_CLAW,
	INTIMIDATING_ROAR,
	MIMIC,
	NIMBLE_DODGE,
	NO_FLEE_DAMAGE,
	NOVA_ATTACK,
	OPPORTUNIST,
	PAID_HEALING,
	PEEK_DECK,
	POISON,
	RAPID_HEALING,
	RECYCLE_CARDS,
	RESPAWN,
	SHIELD_BEARER,
	SHRINK,
	SLOW_GRINDER,
	TRICKSTER_BARGAIN,
	TUNNEL_FIGHTER,
}
