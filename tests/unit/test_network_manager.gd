extends GutTest
## Unit coverage for the NetworkManager autoload (Phase 1 — Foundation).
## The two-peer connect/sync flow is verified manually with two editor
## instances; these tests cover the local, transport-free surface.

func after_each() -> void:
	NetworkManager.stop()

# ── Default (single-player) state ─────────────────────────────────────────────

func test_defaults_to_single_mode() -> void:
	assert_eq(NetworkManager.mode, NetworkManager.Mode.SINGLE)

func test_single_mode_is_not_multiplayer() -> void:
	assert_false(NetworkManager.is_multiplayer())
	assert_false(NetworkManager.is_host())
	assert_false(NetworkManager.is_client())

func test_send_action_is_noop_in_single_mode() -> void:
	# Must not crash or RPC when there is no peer.
	NetworkManager.send_action({"type": "roll"})
	assert_eq(NetworkManager.mode, NetworkManager.Mode.SINGLE)

# ── Host helpers ──────────────────────────────────────────────────────────────

func test_start_host_enters_host_mode() -> void:
	assert_eq(NetworkManager.start_host(), OK)
	assert_true(NetworkManager.is_host())
	assert_true(NetworkManager.is_multiplayer())

func test_host_takes_seat_zero() -> void:
	NetworkManager.start_host()
	assert_eq(NetworkManager.my_player_id, 0)

func test_host_seeds_own_lobby_slot() -> void:
	NetworkManager.local_player_name = "Thorin"
	NetworkManager.start_host()
	assert_eq(NetworkManager.lobby_players.size(), 1)
	assert_eq(NetworkManager.lobby_players[0]["seat"], 0)
	assert_eq(NetworkManager.lobby_players[0]["name"], "Thorin")

func test_stop_returns_to_single_mode() -> void:
	NetworkManager.start_host()
	NetworkManager.stop()
	assert_eq(NetworkManager.mode, NetworkManager.Mode.SINGLE)
	assert_eq(NetworkManager.lobby_players.size(), 0)

# ── Local IP ──────────────────────────────────────────────────────────────────

func test_get_local_ip_returns_ipv4() -> void:
	var ip: String = NetworkManager.get_local_ip()
	assert_true(ip.contains("."), "expected a dotted IPv4 string, got: %s" % ip)
	assert_false(ip.contains(":"), "expected IPv4, not IPv6")
