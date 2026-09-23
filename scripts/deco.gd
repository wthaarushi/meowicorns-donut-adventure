extends Sprite2D

var drift: float = 10.0
var player: Node2D

var _t: float = 0.0
var _base_y: float = 0.0

func _ready() -> void:
	_base_y = position.y
	_t = randf() * TAU

func _process(delta: float) -> void:
	_t += delta * 0.6
	position.x -= drift * delta
	position.y = _base_y + sin(_t) * 3.0
	if position.x < player.global_position.x - 600.0:
		queue_free()
