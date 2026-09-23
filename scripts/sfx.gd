extends Node

const SOUNDS := {
	"jump": preload("res://audio/sfx/jump.wav"),
	"duck": preload("res://audio/sfx/duck.wav"),
	"donut": preload("res://audio/sfx/donut.wav"),
	"die": preload("res://audio/sfx/die.wav"),
	"start": preload("res://audio/sfx/start.wav"),
	"land": preload("res://audio/sfx/land.wav"),
	"power": preload("res://audio/sfx/power.wav"),
	"flap": preload("res://audio/sfx/flap.wav"),
	"achieve": preload("res://audio/sfx/achieve.wav"),
	"victory": preload("res://audio/sfx/victory.wav"),
	"tick": preload("res://audio/sfx/tick.wav"),
	"burst": preload("res://audio/sfx/burst.wav"),
	"drop": preload("res://audio/sfx/drop.wav"),
	"voice_meowicorn": preload("res://audio/sfx/voice_meowicorn.wav"),
	"voice_cherry": preload("res://audio/sfx/voice_cherry.wav"),
	"voice_mango": preload("res://audio/sfx/voice_mango.wav"),
	"voice_lemon": preload("res://audio/sfx/voice_lemon.wav"),
	"voice_minty": preload("res://audio/sfx/voice_minty.wav"),
	"voice_blueberry": preload("res://audio/sfx/voice_blueberry.wav"),
	"voice_plum": preload("res://audio/sfx/voice_plum.wav"),
	"voice_midnight": preload("res://audio/sfx/voice_midnight.wav"),
}

var _players: Dictionary = {}
var _volume_db: float = -12.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for name in SOUNDS:
		var player := AudioStreamPlayer.new()
		player.stream = SOUNDS[name]
		player.volume_db = _volume_db
		add_child(player)
		_players[name] = player
	set_volume(Progress.sfx_volume)

func set_volume(linear: float) -> void:
	_volume_db = linear_to_db(linear) - 8.0 if linear > 0.0 else -80.0
	for player in _players.values():
		player.volume_db = _volume_db

func play(name: String, pitch: float = 1.0) -> void:
	var player: AudioStreamPlayer = _players.get(name)
	if player:
		player.pitch_scale = pitch
		player.play()

func play_voice(cat_id: String, pitch: float = 1.0) -> void:
	play("voice_" + cat_id, pitch)
