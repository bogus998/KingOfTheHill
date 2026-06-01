extends Node
## LAN multiplayer transport (Phase 1 — Foundation).
##
## Owns the ENet peer and routes player input host-ward and authoritative state
## client-ward. The host runs the entire game simulation; clients send action
## dictionaries and render the snapshots/events the host broadcasts. In SINGLE
## mode every method is a no-op so the existing hot-seat game is unaffected.
##
## Seat = player index used by [[player_manager]]/[[turn_manager]]. The host is
## always seat 0; clients receive their seat on connect and it is locked once the
## game starts. See the [[game_state_serializer]] for what gets synced.

const DEFAULT_PORT := 7777
const MAX_CLIENTS := 3   # up to 4 players total (host + 3)

## Interface contract (Godot duck-typed, see godot-interfaces skill): any node that
## must redraw after a host snapshot joins this group and implements `refresh()`.
## On the client, _receive_snapshot notifies the whole group with one call_group.
const REFRESH_GROUP := "snapshot_refreshable"

enum Mode { SINGLE, HOST, CLIENT }

signal peer_list_changed()            ## lobby roster changed (host or client)
signal action_received(action: Dictionary)   ## host-side: a client input arrived
signal snapshot_received(state: Dictionary)   ## client-side: full state to apply
signal event_received(event: Dictionary)      ## client-side: mid-turn delta to animate
signal connection_failed()            ## client could not reach the host
signal connection_lost()              ## host vanished / peer dropped mid-session
signal game_starting()                ## host locked the lobby and launched the game

var mode: Mode = Mode.SINGLE
var my_player_id: int = 0             ## this device's seat (host = 0)
var local_player_name: String = "Player"
## Locked lobby roster: [{ "peer_id": int, "seat": int, "name": String }, ...]
var lobby_players: Array[Dictionary] = []
## Player config locked at game start (the GameManager.start_game dict).
var game_config: Dictionary = {}

func _ready() -> void:
	# Host pushes the authoritative state to clients at every turn boundary.
	TurnManager.turn_started.connect(_on_turn_started)

## Host: snapshot the resolved state (and whose turn it now is) and broadcast it.
## No-op for clients / single-player (broadcast_snapshot guards on host).
func _on_turn_started(_player_index: int) -> void:
	if is_host():
		broadcast_snapshot(GameStateSerializer.snapshot())

func is_multiplayer() -> bool:
	return mode != Mode.SINGLE

func is_host() -> bool:
	return mode == Mode.HOST

func is_client() -> bool:
	return mode == Mode.CLIENT

## Returns the first private-range IPv4 address (the LAN address others connect
## to). Falls back to 127.0.0.1 if none is found.
func get_local_ip() -> String:
	for addr in IP.get_local_addresses():
		if not addr.contains(".") or addr.contains(":"):
			continue  # skip IPv6
		if addr.begins_with("192.168.") or addr.begins_with("10.") \
				or _is_172_private(addr):
			return addr
	return "127.0.0.1"

func _is_172_private(addr: String) -> bool:
	if not addr.begins_with("172."):
		return false
	var second: int = addr.split(".")[1].to_int()
	return second >= 16 and second <= 31

# --- Connection lifecycle ---------------------------------------------------

func start_host(port: int = DEFAULT_PORT) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var err: Error = peer.create_server(port, MAX_CLIENTS)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	mode = Mode.HOST
	my_player_id = 0
	lobby_players = [{ "peer_id": 1, "seat": 0, "name": local_player_name }]
	_connect_multiplayer_signals()
	peer_list_changed.emit()
	return OK

func start_client(ip: String, port: int = DEFAULT_PORT) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var err: Error = peer.create_client(ip, port)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	mode = Mode.CLIENT
	lobby_players.clear()
	_connect_multiplayer_signals()
	return OK

## Tear down the peer and return to single-player (hot-seat) mode.
func stop() -> void:
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	_disconnect_multiplayer_signals()
	mode = Mode.SINGLE
	my_player_id = 0
	lobby_players.clear()
	game_config = {}

func _connect_multiplayer_signals() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func _disconnect_multiplayer_signals() -> void:
	for sig in ["peer_connected", "peer_disconnected", "connected_to_server",
			"connection_failed", "server_disconnected"]:
		for c in multiplayer.get_signal_connection_list(sig):
			multiplayer.disconnect(sig, c["callable"])

# --- Multiplayer callbacks --------------------------------------------------

func _on_peer_connected(_id: int) -> void:
	# Host waits for the client to register its name before assigning a seat.
	pass

func _on_peer_disconnected(id: int) -> void:
	if not is_host():
		return
	for i in range(lobby_players.size() - 1, -1, -1):
		if lobby_players[i]["peer_id"] == id:
			lobby_players.remove_at(i)
	_sync_lobby.rpc(lobby_players)
	peer_list_changed.emit()
	connection_lost.emit()

func _on_connected_to_server() -> void:
	_register_client.rpc_id(1, local_player_name)

func _on_connection_failed() -> void:
	stop()
	connection_failed.emit()

func _on_server_disconnected() -> void:
	stop()
	connection_lost.emit()

# --- Lobby RPCs -------------------------------------------------------------

## Client -> host: announce presence; host assigns the next free seat.
@rpc("any_peer", "call_remote", "reliable")
func _register_client(player_name: String) -> void:
	if not is_host():
		return
	var sender: int = multiplayer.get_remote_sender_id()
	var seat: int = lobby_players.size()
	lobby_players.append({ "peer_id": sender, "seat": seat, "name": player_name })
	_assign_seat.rpc_id(sender, seat)
	_sync_lobby.rpc(lobby_players)
	peer_list_changed.emit()

## Host -> one client: tell it which seat it owns.
@rpc("authority", "call_remote", "reliable")
func _assign_seat(seat: int) -> void:
	my_player_id = seat

## Host -> all clients: replicate the lobby roster.
@rpc("authority", "call_remote", "reliable")
func _sync_lobby(players: Array) -> void:
	lobby_players.assign(players)
	peer_list_changed.emit()

## Host: lock the lobby into a player config and launch the game on every peer.
## Seats are already locked by the roster; the config is ordered by seat.
func start_game_broadcast() -> void:
	if not is_host():
		return
	game_config = _build_config()
	_begin_game.rpc(game_config)
	game_starting.emit()

func _build_config() -> Dictionary:
	var ordered: Array[Dictionary] = lobby_players.duplicate()
	ordered.sort_custom(func(a, b): return a["seat"] < b["seat"])
	var players: Array[Dictionary] = []
	for p in ordered:
		players.append({ "name": p["name"], "is_bot": false })
	return { "players": players }

## Host -> all clients: store the locked config and signal the scene swap.
@rpc("authority", "call_remote", "reliable")
func _begin_game(config: Dictionary) -> void:
	game_config = config
	game_starting.emit()

# --- Gameplay routing -------------------------------------------------------

## Client -> host: submit a player input for the host to validate and execute.
func send_action(action: Dictionary) -> void:
	if not is_client():
		return
	_receive_action.rpc_id(1, action)

@rpc("any_peer", "call_remote", "reliable")
func _receive_action(action: Dictionary) -> void:
	if not is_host():
		return
	var enriched := action.duplicate()
	enriched["sender_seat"] = _seat_for_peer(multiplayer.get_remote_sender_id())
	action_received.emit(enriched)

## Host -> all clients: full authoritative state (sent on turn boundaries).
func broadcast_snapshot(state: Dictionary) -> void:
	if not is_host():
		return
	_receive_snapshot.rpc(state)

@rpc("authority", "call_remote", "reliable")
func _receive_snapshot(state: Dictionary) -> void:
	snapshot_received.emit(state)
	# Rebuild the authoritative managers silently (apply emits no simulation
	# signals), then notify every refreshable view to redraw from the new state.
	GameStateSerializer.apply(state)
	get_tree().call_group(REFRESH_GROUP, "refresh")

## Host -> all clients: a mid-turn delta to animate (dice faces, dragon result).
func broadcast_event(event: Dictionary) -> void:
	if not is_host():
		return
	_receive_event.rpc(event)

@rpc("authority", "call_remote", "reliable")
func _receive_event(event: Dictionary) -> void:
	event_received.emit(event)

func _seat_for_peer(peer_id: int) -> int:
	for p in lobby_players:
		if p["peer_id"] == peer_id:
			return p["seat"]
	return -1
