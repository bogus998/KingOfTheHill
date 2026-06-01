class_name DragonHUD
extends Control
## Overlay that surfaces the dragon/environment state to players.
##
## Built entirely in code and mounted on the game's OverlayLayer, so it needs no
## edits to the main scene. Binds to [[dragon_manager]] / [[environment_manager]]
## signals: an always-visible rage meter, a warning banner when an awakening is
## pending, the dragon dice-roll presentation, an outcome banner describing what
## the awakening did, the active environment banner, and a simple dragon avatar
## that rests at the bottom while asleep and rises to the centre when awake.

const DRAGON_SIZE := Vector2(160, 96)

var _rage_label: Label
var _rage_bar: ProgressBar
var _warning: Label
var _outcome: Label
var _env_banner: Label
var _roller: DragonDiceRoller
var _dragon: ColorRect
var _dragon_label: Label
var _info_panel: PanelContainer

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Dragon avatar (added first so the text banners draw over it).
	_dragon = ColorRect.new()
	_dragon.color = Color(0.45, 0.12, 0.12)
	_dragon.size = DRAGON_SIZE
	_dragon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_dragon)
	_dragon_label = Label.new()
	_dragon_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dragon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dragon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_dragon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dragon.add_child(_dragon_label)
	_set_dragon_awake(false)
	_dragon.position = _dragon_sleep_pos()

	var top := VBoxContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.alignment = BoxContainer.ALIGNMENT_CENTER
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top)

	_rage_label = _make_label(top)
	_rage_bar = ProgressBar.new()
	_rage_bar.custom_minimum_size = Vector2(240, 16)
	_rage_bar.show_percentage = false
	_rage_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rage_bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	top.add_child(_rage_bar)

	var info_btn := Button.new()
	info_btn.text = "ℹ Rage Info"
	info_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	info_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	info_btn.pressed.connect(_on_rage_info_pressed)
	top.add_child(info_btn)

	_warning = _make_label(top)
	_warning.add_theme_color_override("font_color", Color(1.0, 0.45, 0.2))
	_warning.visible = false

	_outcome = _make_label(top)
	_outcome.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3))
	_outcome.visible = false

	_env_banner = _make_label(top)
	_env_banner.add_theme_color_override("font_color", Color(0.5, 0.85, 1.0))
	_env_banner.visible = false

	_roller = preload("res://scenes/dragon/dragon_dice_roller.tscn").instantiate() as DragonDiceRoller
	_roller.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_roller)

	_build_info_panel()

	DragonManager.rage_changed.connect(_on_rage_changed)
	DragonManager.awakening_pending.connect(_on_awakening_pending)
	DragonManager.awakening_started.connect(_on_awakening_started)
	DragonManager.awakening_resolved.connect(_on_awakening_resolved)
	EnvironmentManager.card_activated.connect(_on_card_activated)
	EnvironmentManager.card_dismissed.connect(_on_card_dismissed)
	PlayerManager.players_setup.connect(_on_new_game)
	_update_rage()

func _make_label(parent: Node) -> Label:
	var l := Label.new()
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l

# ── Rage info window ──────────────────────────────────────────────────────────

## Actions that feed the rage meter, mirroring data/dragon/rage_rules.tres.
const _RAGE_SOURCES: Array[String] = [
	"Hold the vault a 2nd turn in a row   +1",
	"Hold the vault a 3rd+ turn in a row   +2",
	"Deal 3+ damage in a single turn   +1",
	"Buy 2+ cards in one turn   +1",
	"Refresh the card shop   +1",
]

func _build_info_panel() -> void:
	_info_panel = PanelContainer.new()
	_info_panel.visible = false
	add_child(_info_panel)
	_info_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)

	var vbox := VBoxContainer.new()
	_info_panel.add_child(vbox)

	var title := Label.new()
	title.text = "🔥 What angers the dragon"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	for source in _RAGE_SOURCES:
		var row := Label.new()
		row.text = source
		vbox.add_child(row)

	var close_btn := Button.new()
	close_btn.text = "Close"
	close_btn.pressed.connect(func() -> void: _info_panel.visible = false)
	vbox.add_child(close_btn)

func _on_rage_info_pressed() -> void:
	_info_panel.visible = not _info_panel.visible

# ── Rage meter ────────────────────────────────────────────────────────────────

func _update_rage() -> void:
	_rage_label.text = "🔥 Dragon Rage  %d / %d" % [DragonManager.rage, DragonManager.rage_threshold]
	_rage_bar.max_value = maxi(1, DragonManager.rage_threshold)
	_rage_bar.value = DragonManager.rage

func _on_rage_changed(_value: int) -> void:
	_update_rage()

# ── Awakening ─────────────────────────────────────────────────────────────────

func _on_awakening_pending() -> void:
	_warning.text = "⚠ The dragon will awaken at the end of this round!"
	_warning.visible = true

func _on_awakening_started() -> void:
	_warning.visible = false
	_move_dragon(true)

func _on_awakening_resolved(summary: Dictionary) -> void:
	_update_rage()
	_outcome.text = _describe(summary)
	_outcome.visible = true
	await _roller.play(summary.get("action", 0), summary.get("fire", 0), summary.get("hoard", 0))
	if not is_instance_valid(self):
		return
	await get_tree().create_timer(2.0).timeout
	if not is_instance_valid(self):
		return
	_move_dragon(false)
	_outcome.visible = false

## Human-readable description of what an awakening did.
func _describe(summary: Dictionary) -> String:
	var fire: int = summary.get("fire", 0)
	var hoard: int = summary.get("hoard", 0)
	match summary.get("action", -1):
		DragonDice.Action.FIRE:
			return "🔥 Dragon Fire! Every player takes %d damage." % fire
		DragonDice.Action.HOARD:
			return "💰 Hoard Greed! Every player loses %d gold." % hoard
		DragonDice.Action.SLUMBER:
			return "😴 The dragon grumbles and settles back to sleep."
		DragonDice.Action.ENVIRONMENT:
			return "🌍 The dragon roars! Next round: %s" % _drawn_env_name()
		DragonDice.Action.WRATH:
			return "🐉 FULL WRATH! %d fire, %d gold lost, and next round: %s" % [fire, hoard, _drawn_env_name()]
	return ""

func _drawn_env_name() -> String:
	if EnvironmentManager.pending_card != null:
		return EnvironmentManager.pending_card.card_name
	return "an unknown environment"

# ── Environment banner ────────────────────────────────────────────────────────

func _on_card_activated(card: EnvironmentEffect) -> void:
	_env_banner.text = "🌍 %s — %s" % [card.card_name, card.description]
	_env_banner.visible = true

func _on_card_dismissed(_card: EnvironmentEffect) -> void:
	_env_banner.visible = false

# ── Dragon avatar ─────────────────────────────────────────────────────────────

func _set_dragon_awake(awake: bool) -> void:
	_dragon_label.text = "🐉 DRAGON" if awake else "😴 dragon"

func _move_dragon(awake: bool) -> void:
	_set_dragon_awake(awake)
	var target := _dragon_awake_pos() if awake else _dragon_sleep_pos()
	create_tween().tween_property(_dragon, "position", target, 0.5)

func _dragon_sleep_pos() -> Vector2:
	var vp := get_viewport_rect().size
	return Vector2(vp.x * 0.5 - DRAGON_SIZE.x * 0.5, vp.y - DRAGON_SIZE.y - 20.0)

func _dragon_awake_pos() -> Vector2:
	var vp := get_viewport_rect().size
	return Vector2(vp.x * 0.5 - DRAGON_SIZE.x * 0.5, vp.y * 0.3 - DRAGON_SIZE.y * 0.5)

# ── New game reset ────────────────────────────────────────────────────────────

func _on_new_game() -> void:
	_warning.visible = false
	_outcome.visible = false
	_env_banner.visible = false
	_info_panel.visible = false
	_set_dragon_awake(false)
	_dragon.position = _dragon_sleep_pos()
	_update_rage()
