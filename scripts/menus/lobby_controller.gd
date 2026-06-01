extends Control
## LAN lobby (Phase 2). Two visual states in one scene:
##   CONNECT — choose to host or join (manual IP, or QR scan when available)
##   LOBBY   — live roster; host shows the join address + QR and a Start button
##
## All transport lives in [[network_manager]]. The Start button locks the roster
## into a player config and broadcasts it; every peer then loads the game scene.
##
## QR uses the `QR` addon (addons/QRPlugin). Generation runs through a native
## Android/iOS singleton, so on desktop it is unavailable and the on-screen join
## address is the fallback. Scanning decodes an Image fed to scan_qr_image(); the
## camera-frame source is the remaining device-only piece (see _on_scan_pressed).

const GAME_SCENE := "res://scenes/game/main_game.tscn"
const MENU_SCENE := "res://scenes/menus/main_menu.tscn"
const JOIN_SCHEME := "dwarf-koth://"

enum View { CONNECT, LOBBY }

var _name_field: LineEdit
var _ip_field: LineEdit
var _status_label: Label
var _address_label: Label
var _qr_rect: TextureRect
var _roster: VBoxContainer
var _start_button: Button
var _connect_panel: VBoxContainer
var _lobby_panel: VBoxContainer

func _ready() -> void:
	_build_ui()
	NetworkManager.peer_list_changed.connect(_refresh_roster)
	NetworkManager.connection_failed.connect(_on_connection_failed)
	NetworkManager.connection_lost.connect(_on_connection_lost)
	NetworkManager.game_starting.connect(_on_game_starting)
	_show_view(View.CONNECT)

# --- UI construction --------------------------------------------------------

func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var root := VBoxContainer.new()
	root.custom_minimum_size = Vector2(600, 0)
	center.add_child(root)

	var title := Label.new()
	title.text = "LAN Multiplayer"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(title)

	var name_row := HBoxContainer.new()
	var name_lbl := Label.new()
	name_lbl.text = "Your name:"
	name_lbl.custom_minimum_size = Vector2(120, 0)
	_name_field = LineEdit.new()
	_name_field.text = "Dwarf"
	_name_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_row.add_child(name_lbl)
	name_row.add_child(_name_field)
	root.add_child(name_row)

	_connect_panel = _build_connect_panel()
	_lobby_panel = _build_lobby_panel()
	root.add_child(_connect_panel)
	root.add_child(_lobby_panel)

	_status_label = Label.new()
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_status_label)

func _build_connect_panel() -> VBoxContainer:
	var panel := VBoxContainer.new()

	var host_button := Button.new()
	host_button.text = "Host Game"
	host_button.custom_minimum_size = Vector2(0, 56)
	host_button.pressed.connect(_on_host_pressed)
	panel.add_child(host_button)

	var join_row := HBoxContainer.new()
	_ip_field = LineEdit.new()
	_ip_field.text = "127.0.0.1"
	_ip_field.placeholder_text = "Host IP"
	_ip_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var join_button := Button.new()
	join_button.text = "Join"
	join_button.pressed.connect(_on_join_pressed)
	join_row.add_child(_ip_field)
	join_row.add_child(join_button)
	panel.add_child(join_row)

	var scan_button := Button.new()
	scan_button.text = "Scan QR"
	scan_button.custom_minimum_size = Vector2(0, 56)
	scan_button.pressed.connect(_on_scan_pressed)
	panel.add_child(scan_button)

	var back_button := Button.new()
	back_button.text = "Back"
	back_button.custom_minimum_size = Vector2(0, 56)
	back_button.pressed.connect(_on_back_pressed)
	panel.add_child(back_button)

	return panel

func _build_lobby_panel() -> VBoxContainer:
	var panel := VBoxContainer.new()

	_address_label = Label.new()
	_address_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(_address_label)

	_qr_rect = TextureRect.new()
	_qr_rect.custom_minimum_size = Vector2(220, 220)
	_qr_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_qr_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.add_child(_qr_rect)

	var roster_title := Label.new()
	roster_title.text = "Players"
	panel.add_child(roster_title)

	_roster = VBoxContainer.new()
	panel.add_child(_roster)

	_start_button = Button.new()
	_start_button.text = "Start Game"
	_start_button.custom_minimum_size = Vector2(0, 56)
	_start_button.pressed.connect(_on_start_pressed)
	panel.add_child(_start_button)

	var leave_button := Button.new()
	leave_button.text = "Leave"
	leave_button.custom_minimum_size = Vector2(0, 56)
	leave_button.pressed.connect(_on_leave_pressed)
	panel.add_child(leave_button)

	return panel

# --- Connect actions --------------------------------------------------------

func _on_host_pressed() -> void:
	NetworkManager.local_player_name = _player_name()
	var err: Error = NetworkManager.start_host()
	if err != OK:
		_status_label.text = "Could not host (error %d)" % err
		return
	var url := "%s%s:%d" % [JOIN_SCHEME, NetworkManager.get_local_ip(), NetworkManager.DEFAULT_PORT]
	_address_label.text = "Others join: %s:%d\n%s" % [
		NetworkManager.get_local_ip(), NetworkManager.DEFAULT_PORT, url]
	_render_qr(url)
	_show_view(View.LOBBY)
	_refresh_roster()

func _on_join_pressed() -> void:
	_connect_to(_ip_field.text.strip_edges())

func _connect_to(ip: String) -> void:
	if ip.is_empty():
		_status_label.text = "Enter a host IP first."
		return
	NetworkManager.local_player_name = _player_name()
	var err: Error = NetworkManager.start_client(ip)
	if err != OK:
		_status_label.text = "Could not connect (error %d)" % err
		return
	_address_label.text = "Connecting to %s…" % ip
	_qr_rect.texture = null
	_show_view(View.LOBBY)

func _on_scan_pressed() -> void:
	# The QR addon decodes an Image (scan_qr_image) and emits qr_detected; it does
	# not capture the camera. A CameraServer/CameraFeed frame source still needs to
	# drive it on-device. Until that is wired, manual IP entry is the path.
	if not Engine.has_singleton(QR.PLUGIN_SINGLETON_NAME):
		_status_label.text = "QR scanning is only available on the Android/iOS build."
		return
	_status_label.text = "Camera scan not wired yet — enter the host IP to join."

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MENU_SCENE)

# --- Lobby actions ----------------------------------------------------------

func _on_start_pressed() -> void:
	NetworkManager.start_game_broadcast()

func _on_leave_pressed() -> void:
	NetworkManager.stop()
	_show_view(View.CONNECT)
	_status_label.text = ""

func _on_game_starting() -> void:
	get_tree().change_scene_to_file(GAME_SCENE)

# --- Roster / state ---------------------------------------------------------

func _refresh_roster() -> void:
	if not _roster:
		return
	for child in _roster.get_children():
		child.queue_free()
	for p in NetworkManager.lobby_players:
		var label := Label.new()
		var you := "  (you)" if p["seat"] == NetworkManager.my_player_id else ""
		label.text = "Seat %d — %s%s" % [p["seat"], p["name"], you]
		_roster.add_child(label)
	# Only the host can start, and only with at least two players.
	_start_button.visible = NetworkManager.is_host()
	_start_button.disabled = NetworkManager.lobby_players.size() < 2

func _on_connection_failed() -> void:
	_show_view(View.CONNECT)
	_status_label.text = "Connection failed — check the IP and that the host is on the same Wi-Fi."

func _on_connection_lost() -> void:
	if NetworkManager.mode == NetworkManager.Mode.SINGLE:
		_show_view(View.CONNECT)
		_status_label.text = "Host disconnected."

func _show_view(view: View) -> void:
	_connect_panel.visible = view == View.CONNECT
	_lobby_panel.visible = view == View.LOBBY

func _player_name() -> String:
	var n := _name_field.text.strip_edges()
	return n if not n.is_empty() else "Dwarf"

## Renders a QR for `url`. QR generation runs through the addon's native singleton,
## so on desktop it is unavailable and the join-address text is the fallback.
func _render_qr(url: String) -> void:
	_qr_rect.texture = null
	if not Engine.has_singleton(QR.PLUGIN_SINGLETON_NAME):
		return
	var qr := QR.new()
	add_child(qr)
	var img: Image = qr.generate_qr_image(url, 512)
	qr.queue_free()
	if img != null:
		_qr_rect.texture = ImageTexture.create_from_image(img)

## Parses a scanned "dwarf-koth://<ip>:<port>" URL into a host IP and connects.
func _on_qr_detected(data: String) -> void:
	if not data.begins_with(JOIN_SCHEME):
		_status_label.text = "Scanned code is not a game invite."
		return
	var host_port := data.substr(JOIN_SCHEME.length())
	var ip := host_port.split(":")[0]
	_connect_to(ip)
