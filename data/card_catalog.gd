class_name CardCatalog

# DirAccess.open("res://...") returns null on Android (resources are packed into APK).
# Preloaded paths are resolved at export time and work on all platforms.
const _CARD_PATHS: Array[String] = [
	"res://data/cards/card_001_lucky_strike.tres",
	"res://data/cards/card_002_iron_hide.tres",
	"res://data/cards/card_003_gem_rush.tres",
	"res://data/cards/card_004_gold_vein.tres",
	"res://data/cards/card_005_berserker.tres",
	"res://data/cards/card_006_miners_luck.tres",
	"res://data/cards/card_007_healing_brew.tres",
	"res://data/cards/card_008_vault_claim.tres",
	"res://data/cards/card_009_quick_hands.tres",
	"res://data/cards/card_010_war_cry.tres",
	"res://data/cards/card_011_corroding_blade.tres",
	"res://data/cards/card_012_thrifty_trader.tres",
	"res://data/cards/card_013_vault_champion.tres",
	"res://data/cards/card_014_shadow_runner.tres",
	"res://data/cards/card_015_tunnel_fighter.tres",
	# DISABLED (audit): camouflage_active only set on own turn — never fires on opponent attacks
	#"res://data/cards/card_016_stone_skin.tres",
	"res://data/cards/card_017_gold_cart.tres",
	"res://data/cards/card_018_perfect_roll.tres",
	"res://data/cards/card_019_guild_scribe.tres",
	"res://data/cards/card_020_ambush_strike.tres",
	"res://data/cards/card_021_spoils_collector.tres",
	"res://data/cards/card_022_gold_cache.tres",
	"res://data/cards/card_023_gold_counter.tres",
	"res://data/cards/card_024_war_tax.tres",
	"res://data/cards/card_025_iron_constitution.tres",
	"res://data/cards/card_026_extra_axe.tres",
	"res://data/cards/card_027_chain_strike.tres",
	"res://data/cards/card_028_time_stopper.tres",
	"res://data/cards/card_029_bloodlust.tres",
	"res://data/cards/card_030_gold_sense.tres",
	"res://data/cards/card_031_blast_furnace.tres",
	"res://data/cards/card_032_treasure_seeker.tres",
	"res://data/cards/card_033_healing_draught.tres",
	# DISABLED (audit): PAID_HEALING has no handler — no-op stub
	#"res://data/cards/card_034_healers_forge.tres",
	"res://data/cards/card_035_pacifist_miner.tres",
	"res://data/cards/card_036_die_picker.tres",
	"res://data/cards/card_037_cave_in.tres",
	"res://data/cards/card_038_second_wind.tres",
	"res://data/cards/card_039_mercenary_squad.tres",
	"res://data/cards/card_040_iron_boots.tres",
	"res://data/cards/card_041_forge_master.tres",
	# DISABLED (audit): bots never offered recycle picker — only works for humans
	#"res://data/cards/card_042_recycle.tres",
	# DISABLED (audit): complete_mimic only calls on_turn_started — misses on_acquired, on_turn_ended, dice passives
	#"res://data/cards/card_043_copycat.tres",
	"res://data/cards/card_044_gold_battery.tres",
	"res://data/cards/card_045_militia.tres",
	# DISABLED (audit): nova only fires in OUTSIDE→occupied-vault branch; in-vault and empty-vault claws skip it
	#"res://data/cards/card_046_shockwave_axe.tres",
	"res://data/cards/card_047_gold_reactor.tres",
	"res://data/cards/card_048_combo_master.tres",
	# DISABLED (audit): interrupt explicitly skips bots — inconsistent behavior
	#"res://data/cards/card_049_sharp_eye.tres",
	"res://data/cards/card_050_merchants_touch.tres",
	"res://data/cards/card_051_wildcard.tres",
	"res://data/cards/card_052_toxic_blade.tres",
	"res://data/cards/card_053_plague_blade.tres",
	"res://data/cards/card_054_die_jacker.tres",
	"res://data/cards/card_055_healing_flask.tres",
	"res://data/cards/card_056_trollish_hide.tres",
	"res://data/cards/card_057_underdogs_pride.tres",
	# DISABLED (audit): immediately AoEs shrink on all players at purchase — wrong mechanic vs. description
	#"res://data/cards/card_058_weakening_curse.tres",
	"res://data/cards/card_059_great_hall.tres",
	"res://data/cards/card_060_smoke_bomb.tres",
	"res://data/cards/card_061_empty_purse.tres",
	"res://data/cards/card_062_flexible_tactics.tres",
	"res://data/cards/card_063_berserker_rush.tres",
	"res://data/cards/card_064_focus_crystal.tres",
	"res://data/cards/card_065_vault_dweller.tres",
	"res://data/cards/card_066_tax_collection.tres",
	"res://data/cards/card_067_stubborn_fighter.tres",
	# DISABLED (audit): gold_dodge_active cleared same turn it's set — protection window is empty
	#"res://data/cards/card_068_dodge_roll.tres",
	"res://data/cards/card_069_festival_grounds.tres",
	"res://data/cards/card_070_war_band.tres",
	"res://data/cards/card_071_life_drain.tres",
	"res://data/cards/card_072_intimidating_warcry.tres",
	"res://data/cards/card_073_shield_bearer.tres",
	"res://data/cards/card_074_thorned_armor.tres",
	"res://data/cards/card_075_slow_grinder.tres",
	"res://data/cards/card_076_nimble_dodge.tres",
	"res://data/cards/card_077_heavy_strike.tres",
	"res://data/cards/card_078_war_drums.tres",
	# DISABLED (audit): TRICKSTER_BARGAIN has no effect logic and no UI — completely unimplemented
	#"res://data/cards/card_079_tricksters_bargain.tres",
]

static func load_all_cards() -> Array[CardData]:
	var cards: Array[CardData] = []
	for path in _CARD_PATHS:
		var card := load(path) as CardData
		if card != null:
			cards.append(card)
	return cards
