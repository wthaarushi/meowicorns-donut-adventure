extends Area2D

signal collected(golden: bool)

var deadly: bool = true
var kind: String = ""
var golden: bool = false
var hits_flyer: bool = false
var move_left: float = 0.0
var frames: int = 1
var fps: float = 8.0
var player: Player
var ground: TileMapLayer

var _taken: bool = false
var _t: float = 0.0
var _frame_t: float = 0.0
var _base_y: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	_base_y = position.y
	_t = randf() * TAU
	_frame_t = randf() * frames
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if frames > 1:
		_frame_t += delta * fps
		sprite.frame = int(_frame_t) % frames
	if move_left > 0.0:
		position.x -= move_left * delta
		position.y = _base_y - absf(sin(_t + _frame_t * 2.0)) * 2.0
		if not ground.has_ground_at(position.x):
			queue_free()
			return
	elif deadly:
		_t += delta * 2.0
		position.y = _base_y + sin(_t) * 1.5
	else:
		_t += delta * (6.0 if golden else 4.0)
		position.y = _base_y + sin(_t) * (5.0 if golden else 3.0)
		if golden:
			modulate = Color.WHITE.lerp(Color(1.4, 1.3, 0.8), (sin(_t * 2.0) + 1.0) * 0.5)
	if position.x < player.global_position.x - 500.0:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if _taken or not body is Player:
		return
	var cat := body as Player
	if deadly and cat.flying and not hits_flyer:
		return
	_taken = true
	if deadly:
		if cat.absorb_hit():
			_vanish(Vector2(1.6, 1.6), 0.12, 0.0)
		else:
			cat.die(kind)
		return
	collected.emit(golden)
	set_deferred("monitoring", false)
	_vanish(Vector2(1.7, 1.7), 0.15, -16.0)

func _vanish(to_scale: Vector2, seconds: float, rise: float) -> void:
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", to_scale, seconds)
	tween.tween_property(self, "modulate:a", 0.0, seconds)
	if rise != 0.0:
		tween.tween_property(self, "position:y", position.y + rise, seconds)
	tween.chain().tween_callback(queue_free)
