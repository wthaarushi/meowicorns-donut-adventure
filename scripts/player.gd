class_name Player
extends CharacterBody2D

signal died(cause: String)
signal flight_changed(flying: bool)

@export var speed: float = 150.0
@export var speed_gain_per_second: float = 2.5
@export var max_speed: float = 300.0
@export var jump_velocity: float = -520.0
@export var rise_gravity: float = 1.0
@export var fall_gravity: float = 1.8
@export var fast_fall_gravity: float = 4.0
@export var coyote_time: float = 0.12
@export var jump_buffer_time: float = 0.12
@export var short_hop: float = 0.5
@export var fall_limit: float = 1300.0
@export var fly_duration: float = 8.0
@export var fly_speed_multiplier: float = 1.8
@export var flap_velocity: float = -250.0
@export var fly_gravity: float = 0.7
@export var fly_ceiling: float = 320.0

const STAND_BOX := Vector2(22, 26)
const DUCK_BOX := Vector2(22, 12)
const FRAME_JUMP := 4
const FRAME_DUCK := 5
const FRAME_FLY := 6

var active: bool = false
var flying: bool = false
var shield: bool = false
var run_speed: float = 0.0
var fly_time_left: float = 0.0
var cat_id: String = ""

var _voice_pitch: float = 1.0
var _base: Dictionary = {}
var _coyote: float = 0.0
var _buffer: float = 0.0
var _ducking: bool = false
var _fast_falling: bool = false
var _anim_time: float = 0.0
var _flap_anim: float = 0.0
var _dead: bool = false
var _was_on_floor: bool = true

@onready var sprite: Sprite2D = $Sprite2D
@onready var hitbox: CollisionShape2D = $CollisionShape2D
@onready var ground: TileMapLayer = get_node("../Ground")

func _ready() -> void:
	_base = {"speed": speed, "max_speed": max_speed, "jump_velocity": jump_velocity, "fly_duration": fly_duration}
	apply_cat(Progress.current())
	_set_ducking(false)

func apply_cat(cat: Dictionary) -> void:
	cat_id = cat["id"]
	_voice_pitch = float(cat.get("pitch", 1.0))
	sprite.texture = load(Progress.texture_path(cat_id))
	speed = _base["speed"] * float(cat.get("speed_mult", 1.0))
	max_speed = _base["max_speed"] * float(cat.get("speed_mult", 1.0))
	jump_velocity = _base["jump_velocity"] * float(cat.get("jump_mult", 1.0))
	fly_duration = _base["fly_duration"] + float(cat.get("fly_bonus", 0.0))
	shield = bool(cat.get("shield", false))
	if cat.has("max_speed"):
		max_speed = float(cat["max_speed"])
		speed = minf(speed, max_speed)
	run_speed = speed

func _physics_process(delta: float) -> void:
	if _dead:
		return
	if flying:
		_fly(delta)
	else:
		_run(delta)
	move_and_slide()
	if is_on_floor() and not _was_on_floor and active and not flying:
		Sfx.play("land")
		_squash(Vector2(1.3, 0.7))
	_was_on_floor = is_on_floor()
	_animate(delta)
	if global_position.y > fall_limit:
		die("fall")

func _run(delta: float) -> void:
	if is_on_floor():
		_coyote = coyote_time
		_fast_falling = false
	else:
		_coyote -= delta
		var gravity_scale := fast_fall_gravity if _fast_falling else (rise_gravity if velocity.y < 0.0 else fall_gravity)
		velocity += get_gravity() * gravity_scale * delta
		velocity.y = minf(velocity.y, 1400.0)

	if not active:
		velocity.x = move_toward(velocity.x, 0.0, 1500.0 * delta)
		if _ducking:
			_set_ducking(false)
		return

	_buffer = jump_buffer_time if Input.is_action_just_pressed("jump") else _buffer - delta
	if _buffer > 0.0 and _coyote > 0.0:
		velocity.y = jump_velocity
		_buffer = 0.0
		_coyote = 0.0
		Sfx.play("jump", _voice_pitch)
		_squash(Vector2(0.75, 1.3))
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= short_hop

	if Input.is_action_just_pressed("duck") and not is_on_floor() and not _fast_falling:
		_fast_falling = true
		velocity.y = maxf(velocity.y, 260.0)
		Sfx.play("duck", 0.8)
		_squash(Vector2(0.8, 1.2))

	var want_duck := Input.is_action_pressed("duck") and is_on_floor()
	if want_duck != _ducking:
		_set_ducking(want_duck)
		if want_duck:
			Sfx.play("duck")

	run_speed = minf(run_speed + speed_gain_per_second * delta, max_speed)
	velocity.x = run_speed
	sprite.position.y = move_toward(sprite.position.y, 0.0, 20.0 * delta)

func _fly(delta: float) -> void:
	fly_time_left -= delta
	if fly_time_left <= 0.0:
		stop_flying()
		return
	velocity += get_gravity() * fly_gravity * delta
	if Input.is_action_just_pressed("jump"):
		velocity.y = flap_velocity
		_flap_anim = 0.16
		Sfx.play("flap", _voice_pitch * randf_range(0.95, 1.1))
		_squash(Vector2(0.9, 1.15))
	if Input.is_action_pressed("duck"):
		velocity.y += 450.0 * delta
	var surface: float = ground.surface_y(global_position.x)
	if global_position.y < surface - fly_ceiling and velocity.y < 0.0:
		velocity.y = 0.0
	if global_position.y > surface - 20.0:
		global_position.y = surface - 20.0
		velocity.y = minf(velocity.y, flap_velocity * 0.6)
	velocity.y = clampf(velocity.y, -300.0, 340.0)
	velocity.x = run_speed * fly_speed_multiplier
	_flap_anim -= delta

func start_flying() -> bool:
	if flying or _dead:
		return false
	flying = true
	fly_time_left = fly_duration
	_flap_anim = 0.0
	_fast_falling = false
	_set_ducking(false)
	velocity.y = flap_velocity
	Sfx.play("power")
	flight_changed.emit(true)
	return true

func stop_flying() -> void:
	flying = false
	velocity.y = -120.0
	flight_changed.emit(false)

func _animate(delta: float) -> void:
	if flying:
		sprite.frame = FRAME_FLY + (1 if _flap_anim > 0.0 else 0)
		sprite.rotation = lerpf(sprite.rotation, clampf(velocity.y / 650.0, -0.45, 0.5), 10.0 * delta)
		return
	sprite.rotation = lerpf(sprite.rotation, 0.0, 10.0 * delta)
	if _ducking:
		sprite.frame = FRAME_DUCK
	elif not is_on_floor():
		sprite.frame = FRAME_JUMP
	elif active:
		_anim_time += delta * run_speed / 16.0
		sprite.frame = int(_anim_time) % 4
	else:
		_anim_time += delta * 2.5
		sprite.frame = FRAME_DUCK
		sprite.position.y = sin(_anim_time) * 1.5

func _squash(to: Vector2) -> void:
	var tween := create_tween()
	tween.tween_property(sprite, "scale", to, 0.06)
	tween.tween_property(sprite, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _set_ducking(on: bool) -> void:
	_ducking = on
	var box := hitbox.shape as RectangleShape2D
	box.size = DUCK_BOX if on else STAND_BOX
	hitbox.position = Vector2(0, 8) if on else Vector2(0, 1)

func absorb_hit() -> bool:
	if not shield:
		return false
	shield = false
	Sfx.play("power", 0.7)
	var tween := create_tween()
	for i in range(4):
		tween.tween_property(sprite, "modulate", Color(2.0, 1.6, 2.4), 0.08)
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.08)
	return true

func die(cause: String) -> void:
	if _dead:
		return
	_dead = true
	active = false
	flying = false
	velocity = Vector2.ZERO
	Sfx.play("die", _voice_pitch)
	hitbox.set_deferred("disabled", true)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(sprite, "rotation", TAU * 1.5, 0.7).set_ease(Tween.EASE_IN)
	tween.tween_property(sprite, "position:y", -90.0, 0.35).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(sprite, "position:y", 40.0, 0.35).set_ease(Tween.EASE_IN)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.7)
	await tween.finished
	died.emit(cause)
