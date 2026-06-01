class_name WatchOverlay
extends Control
## LAN: covers a player's screen while it is NOT their turn. It swallows all touch
## input (so a watcher can't drive someone else's turn) yet leaves the board visible,
## and shows a "Waiting for <name>…" banner. Hidden entirely in single-player/hot-seat,
## where the pass-device screen handles turn hand-off instead.
##
## Self-managing, mirroring DragonHUD: it reacts to TurnManager.turn_started (host, and
## the client's initial local start) and joins the snapshot refresh group (LAN client,
## where apply() fires no simulation signals so turn_started never reaches it).

var _label: Label

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP  # eat touches while watching

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.12)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	var banner := PanelContainer.new()
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(banner)
	banner.set_anchors_and_offsets_preset(
		Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 120)
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.add_child(_label)

	TurnManager.turn_started.connect(_on_turn_started)
	add_to_group(NetworkManager.REFRESH_GROUP)
	_apply_state()

func _on_turn_started(_player_index: int) -> void:
	_apply_state()

## LAN client: a host snapshot was applied (a turn boundary). Update visibility.
func refresh() -> void:
	_apply_state()

## Show only in multiplayer, and only when it isn't this device's turn.
func _apply_state() -> void:
	if not NetworkManager.is_multiplayer() or PlayerManager.players.is_empty():
		visible = false
		return
	var idx := TurnManager.current_player_index
	if idx == NetworkManager.my_player_id:
		visible = false
	else:
		_label.text = "👀 Waiting for %s…" % PlayerManager.players[idx].player_name
		visible = true
