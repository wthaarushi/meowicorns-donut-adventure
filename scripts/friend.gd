extends Sprite2D

signal picked(cat_id: String)

var cat_id: String = ""
var orbit: Dictionary = {}
var center: Vector2 = Vector2.ZERO

var _angle: float = 0.0
var _leaving: bool = false
var _moving: bool = false
var _last_x: float = 0.0
var _flap: float = 0.0
var _label: Label

func _ready() -> void:
	_angle = float(orbit.get("phase", 0.0))
	var area := Area2D.new()
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(34, 30)
	shape.shape = box
	area.add_child(shape)
	area.input_event.connect(_on_input)
	area.mouse_entered.connect(_set_hover.bind(true))
	area.mouse_exited.connect(_set_hover.bind(false))
	add_child(area)
	_label = Label.new()
	_label.text = "Equip"
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.position = Vector2(-18, -30)
	_label.size = Vector2(60, 12)
	_label.scale = Vector2(0.6, 0.6)
	_label.add_theme_color_override("font_color", Color(0.5, 0.25, 0.6, 0.85))
	_label.add_theme_color_override("font_shadow_color", Color(1, 1, 1, 0.8))
	_label.add_theme_constant_override("shadow_offset_x", 1)
	_label.add_theme_constant_override("shadow_offset_y", 1)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)
	_last_x = position.x

func _process(delta: float) -> void:
	_flap += delta * float(orbit.get("flap", 6.0))
	frame = 6 + int(_flap) % 2
	if _leaving:
		position.x -= 260.0 * delta
		modulate.a -= delta * 2.0
		if modulate.a <= 0.0:
			queue_free()
		return
	if _moving:
		flip_h = position.x < _last_x
		_last_x = position.x
		return
	_angle += delta * float(orbit.get("speed", 1.0))
	var anchor: Vector2 = center + orbit.get("anchor", Vector2(0, -70))
	position = anchor + Vector2(0, sin(_angle) * float(orbit.get("bob", 6.0)))
	flip_h = anchor.x > center.x

func move_to(target: Vector2, seconds: float) -> void:
	_moving = true
	_label.hide()
	var tween := create_tween()
	tween.tween_property(self, "position", position.lerp(target, 0.5) + Vector2(0, -50.0), seconds * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", target, seconds * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tween.finished
	_moving = false
	_label.show()

func _set_hover(on: bool) -> void:
	if _leaving or _moving:
		return
	modulate = Color(1.25, 1.2, 1.3) if on else Color.WHITE
	_label.add_theme_color_override("font_color", Color(0.85, 0.25, 0.6) if on else Color(0.5, 0.25, 0.6, 0.85))

func _on_input(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if _leaving or _moving:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		picked.emit(cat_id)

func leave() -> void:
	_leaving = true
	_label.hide()
