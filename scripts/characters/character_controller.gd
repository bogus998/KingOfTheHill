class_name CharacterController
extends AnimatedSprite2D

const _SPRITE_BASE: String = "res://assets/characters/dwarf_merchant/rotations/"
const _DIRS: Array[String] = [
	"north", "north_east", "east", "south_east",
	"south", "south_west", "west", "north_west"
]
const _DIR_FILES: Array[String] = [
	"north", "north-east", "east", "south-east",
	"south", "south-west", "west", "north-west"
]
# Angles in degrees, matching _DIRS order (atan2 convention: 0=east, 90=south)
const _DIR_ANGLES: Array[float] = [270.0, 315.0, 0.0, 45.0, 90.0, 135.0, 180.0, 225.0]
const _VAULT_POSITION: Vector2 = Vector2(960, 540)

static var _shared_frames: SpriteFrames

@export var player_index: int = 0


func _ready() -> void:
	_ensure_frames()
	sprite_frames = _shared_frames
	PlayerManager.players_setup.connect(_on_players_setup)
	PlayerManager.position_changed.connect(_on_position_changed)
	PlayerManager.player_eliminated.connect(_on_player_eliminated)
	_refresh_visibility()
	if visible:
		_update_facing()


func _exit_tree() -> void:
	if PlayerManager.players_setup.is_connected(_on_players_setup):
		PlayerManager.players_setup.disconnect(_on_players_setup)
	if PlayerManager.position_changed.is_connected(_on_position_changed):
		PlayerManager.position_changed.disconnect(_on_position_changed)
	if PlayerManager.player_eliminated.is_connected(_on_player_eliminated):
		PlayerManager.player_eliminated.disconnect(_on_player_eliminated)


static func _ensure_frames() -> void:
	if _shared_frames != null:
		return
	_shared_frames = SpriteFrames.new()
	_shared_frames.remove_animation("default")
	for i: int in _DIRS.size():
		var anim: String = "idle_" + _DIRS[i]
		var tex: Texture2D = load(_SPRITE_BASE + _DIR_FILES[i] + ".png")
		_shared_frames.add_animation(anim)
		_shared_frames.add_frame(anim, tex)
		_shared_frames.set_animation_loop(anim, true)
		_shared_frames.set_animation_speed(anim, 5.0)


func _refresh_visibility() -> void:
	visible = player_index < PlayerManager.players.size()


func _update_facing() -> void:
	var data: PlayerData = PlayerManager.players[player_index]
	if data.is_eliminated:
		visible = false
		return

	if data.position == PlayerData.PlayerPosition.AT_VAULT:
		play("idle_south")
		return

	var dir: Vector2 = _VAULT_POSITION - global_position
	var angle: float = rad_to_deg(atan2(dir.y, dir.x))
	if angle < 0.0:
		angle += 360.0

	var best: int = 0
	var best_diff: float = 999.0
	for i: int in _DIR_ANGLES.size():
		var diff: float = abs(angle - _DIR_ANGLES[i])
		if diff > 180.0:
			diff = 360.0 - diff
		if diff < best_diff:
			best_diff = diff
			best = i

	play("idle_" + _DIRS[best])


func _on_position_changed(idx: int, _new_pos: PlayerData.PlayerPosition) -> void:
	if idx == player_index:
		_update_facing()


func _on_players_setup() -> void:
	_refresh_visibility()
	if visible:
		_update_facing()


func _on_player_eliminated(idx: int) -> void:
	if idx == player_index:
		visible = false
