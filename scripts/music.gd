extends Node

const TRACKS := {
	"main": preload("res://audio/music/music.wav"),
	"fly": preload("res://audio/music/music_fly.wav"),
}

var _a := AudioStreamPlayer.new()
var _b := AudioStreamPlayer.new()
var _current: AudioStreamPlayer
var _track: String = ""
var _volume_db: float = -6.0
var _tween: Tween

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for name in TRACKS:
		var stream: AudioStreamWAV = TRACKS[name]
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = int(stream.get_length() * stream.mix_rate)
	add_child(_a)
	add_child(_b)
	_current = _a
	set_volume(Progress.music_volume)
	play_track("main")

func _other() -> AudioStreamPlayer:
	return _b if _current == _a else _a

func _kill_tween() -> void:
	if _tween:
		_tween.kill()

func play_track(name: String, fade: float = 0.6) -> void:
	if name == _track:
		return
	_track = name
	var next := _other()
	var previous := _current
	next.stream = TRACKS[name]
	next.volume_db = -80.0
	next.play()
	_kill_tween()
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(next, "volume_db", _volume_db, fade)
	_tween.tween_property(previous, "volume_db", -80.0, fade)
	_tween.chain().tween_callback(previous.stop)
	_current = next

func stop(fade: float = 0.5) -> void:
	_track = ""
	_kill_tween()
	_other().stop()
	_tween = create_tween()
	_tween.tween_property(_current, "volume_db", -80.0, fade)
	_tween.tween_callback(_current.stop)

func set_volume(linear: float) -> void:
	_volume_db = linear_to_db(linear) - 6.0 if linear > 0.0 else -80.0
	if _tween and _tween.is_running():
		_kill_tween()
		_other().stop()
	if _current:
		_current.volume_db = _volume_db
