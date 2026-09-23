extends Node

enum State { MENU, PLAYING, DEAD }

const ThingScript := preload("res://scripts/thing.gd")
const DecoScript := preload("res://scripts/deco.gd")
const FriendScript := preload("res://scripts/friend.gd")

const TEX := {
	"donut": preload("res://art/donut.png"),
	"golden": preload("res://art/golden_donut.png"),
	"puddle": preload("res://art/puddle.png"),
	"dog": preload("res://art/dog.png"),
	"cloud": preload("res://art/raincloud.png"),
	"skycloud": preload("res://art/skycloud.png"),
}

const MENU_ZOOM := 1.7
const PLAY_ZOOM := 1.25
const FLY_ZOOM := 1.05
const PLAY_OFFSET := Vector2(150, -30)
const MENU_OFFSET := Vector2(0, -34)
const CHAIN_HEIGHT := 140.0
const TOAST_HIDDEN := Vector2(-60, -20)
const TOAST_SHOWN := Vector2(8, 48)
const DEATH_LINES := {
	"dog": ["%s got bit by a dog", "%s pet the wrong dog", "%s lost to a dog", "%s forgot dogs run too"],
	"puddle": ["%s got wet. Ew.", "%s missed the puddle", "%s took a surprise bath", "%s stepped in a puddle"],
	"cloud": ["%s got rained on", "%s hugged a sad cloud", "%s forgot to duck", "%s bonked a sad cloud"],
	"fall": ["%s fell out of the sky", "%s forgot she had wings", "%s discovered gravity", "%s tried to walk on air"],
}
const COUNTDOWN_CUES := [[3.0, "tick"], [2.0, "tick"], [1.0, "tick"], [0.75, "burst"], [0.5, "burst"], [0.25, "burst"]]
const PERSONALITY := {
	"meowicorn": {"speed": 1.0, "bob": 6.0, "flap": 6.0},
	"cherry": {"speed": 1.8, "bob": 5.0, "flap": 10.0},
	"mango": {"speed": 1.2, "bob": 7.0, "flap": 7.0},
	"lemon": {"speed": 1.5, "bob": 4.0, "flap": 9.0},
	"minty": {"speed": 1.4, "bob": 9.0, "flap": 8.0},
	"blueberry": {"speed": 0.7, "bob": 8.0, "flap": 4.0},
	"plum": {"speed": 0.9, "bob": 5.0, "flap": 5.0},
	"midnight": {"speed": 0.5, "bob": 4.0, "flap": 3.5},
}

var state: State = State.MENU
var score: int = 0
var donuts: int = 0

var _start_x: float = 0.0
var _next_spawn_x: float = 0.0
var _next_golden_x: float = 0.0
var _next_chain_x: float = 0.0
var _next_hazard_x: float = 0.0
var _next_cloud_x: float = 0.0
var _rng := RandomNumberGenerator.new()
var _swapping: bool = false
var _snore_timer: float = 0.0
var _record_broken: bool = false
var _cue: int = 0
var _toasts: Array = []
var _toast_busy: bool = false
var _toast: PanelContainer
var _toast_label: Label

@onready var player: Player = $Player
@onready var camera: Camera2D = $Player/Camera2D
@onready var ground: TileMapLayer = $Ground
@onready var things: Node2D = $Things
@onready var friends: Node2D = $Friends
@onready var score_label: Label = $HUD/Stats/Rows/ScoreRow/ScoreLabel
@onready var donut_label: Label = $HUD/Stats/Rows/DonutRow/DonutLabel
@onready var total_label: Label = $HUD/Stats/Rows/TotalRow/TotalLabel
@onready var best_label: Label = $HUD/Stats/Rows/BestRow/BestLabel
@onready var best_row: HBoxContainer = $HUD/Stats/Rows/BestRow
@onready var fly_row: VBoxContainer = $HUD/FlyRow
@onready var fly_time_label: Label = $HUD/FlyRow/TimeLabel
@onready var start_panel: Control = $HUD/StartPanel
@onready var dead_panel: Control = $HUD/DeadPanel
@onready var dead_label: Label = $HUD/DeadPanel/DeadLabel
@onready var dead_donut_label: Label = $HUD/DeadPanel/DonutRow/DonutLabel
@onready var settings_panel: Control = $HUD/SettingsPanel
@onready var music_slider: HSlider = $HUD/SettingsPanel/Box/MusicSlider
@onready var sfx_slider: HSlider = $HUD/SettingsPanel/Box/SfxSlider
@onready var shop_panel: Control = $HUD/ShopPanel
@onready var help_panel: Control = $HUD/HelpPanel
@onready var pause_panel: Control = $HUD/PausePanel
@onready var pause_button: Button = $HUD/PauseButton
@onready var achievements_panel: Control = $HUD/AchievementsPanel

func _ready() -> void:
	_rng.randomize()
	_start_x = player.global_position.x
	_next_spawn_x = _start_x + 900.0
	_next_golden_x = _start_x + _rng.randf_range(2200.0, 3200.0)
	_next_cloud_x = _start_x + 300.0
	player.died.connect(_on_player_died)
	player.flight_changed.connect(_on_flight_changed)
	_wire_menus()
	_update_hud()
	if Progress.retry_pending:
		Progress.retry_pending = false
		_start_run(true)
		return
	camera.zoom = Vector2.ONE * MENU_ZOOM
	camera.offset = MENU_OFFSET
	camera.reset_smoothing()
	Music.play_track("main", 0.8)
	_spawn_friends()

func _wire_menus() -> void:
	for panel in [dead_panel, fly_row, settings_panel, shop_panel, help_panel, pause_panel, achievements_panel]:
		panel.hide()
	start_panel.show()
	music_slider.value = Progress.music_volume
	sfx_slider.value = Progress.sfx_volume
	music_slider.value_changed.connect(_on_volume_changed)
	sfx_slider.value_changed.connect(_on_volume_changed)
	shop_panel.closed.connect(_on_shop_closed)
	help_panel.closed.connect(_on_overlay_closed)
	achievements_panel.closed.connect(_on_overlay_closed)
	Progress.achievement_unlocked.connect(_on_achievement)
	var grid := "PausePanel/Root/Grid/"
	var buttons := [
		[_toggle_settings, ["StartPanel/SettingsButton", "DeadPanel/SettingsButton", "SettingsPanel/CloseButton", grid + "Cell2/SettingsButton"]],
		[_open_shop, ["StartPanel/ShopButton", "DeadPanel/ShopButton"]],
		[_open_help, ["StartPanel/HelpButton", grid + "Cell3/HelpButton"]],
		[_open_achievements, ["StartPanel/TrophyButton", grid + "Cell4/TrophyButton"]],
		[_go_to_menu, ["DeadPanel/MenuButton", grid + "Cell5/MenuButton"]],
		[_toggle_pause, ["PauseButton", "PausePanel/Root/CloseButton", grid + "Cell0/ResumeButton"]],
		[_retry, [grid + "Cell1/RestartButton"]],
	]
	for entry in buttons:
		for path in entry[1]:
			$HUD.get_node(path).pressed.connect(entry[0])
	_build_toast()

func _overlay_open() -> bool:
	return shop_panel.visible or help_panel.visible or achievements_panel.visible or settings_panel.visible

func _process(delta: float) -> void:
	if shop_panel.visible or help_panel.visible or achievements_panel.visible:
		return
	if Input.is_action_just_pressed("settings"):
		if state == State.PLAYING:
			_toggle_pause()
		else:
			_toggle_settings()
	if settings_panel.visible or pause_panel.visible:
		return
	if state != State.PLAYING:
		if Input.is_action_just_pressed("shop"):
			_open_shop()
			return
		if Input.is_action_just_pressed("help"):
			_open_help()
			return
	match state:
		State.MENU:
			_snore(delta)
			if Input.is_action_just_pressed("jump"):
				_start_run()
		State.PLAYING:
			_spawn_sky_clouds(player.flying)
			if player.flying:
				_spawn_chains()
			else:
				_spawn_ahead()
			_update_hud()
		State.DEAD:
			if Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("restart"):
				_retry()
	if Input.is_action_just_pressed("restart") and state == State.PLAYING:
		_retry()

func _start_run(instant: bool = false) -> void:
	state = State.PLAYING
	player.active = true
	start_panel.hide()
	pause_button.show()
	Sfx.play("start")
	Sfx.play_voice(Progress.selected)
	Music.play_track("main", 0.5)
	if instant:
		camera.zoom = Vector2.ONE * PLAY_ZOOM
		camera.offset = PLAY_OFFSET
		camera.reset_smoothing()
		return
	_zoom_to(PLAY_ZOOM, 0.9)
	create_tween().tween_property(camera, "offset", PLAY_OFFSET, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	for friend in friends.get_children():
		friend.leave()

func _retry() -> void:
	Progress.retry_pending = true
	get_tree().paused = false
	get_tree().reload_current_scene()

func _spawn_ahead() -> void:
	var px := player.global_position.x
	while _next_spawn_x < px + 1000.0:
		var x := _next_spawn_x
		if ground.is_flat_around(x, 80.0):
			_spawn_obstacle(x)
		if _rng.randf() < 0.6:
			_spawn_donut_arc(x + _rng.randf_range(160.0, 260.0))
		_next_spawn_x += _rng.randf_range(360.0, 620.0) * (player.run_speed / 150.0)
	if _next_golden_x < px + 1000.0:
		if ground.has_ground_at(_next_golden_x):
			_make_thing(TEX.golden, Vector2(_next_golden_x, ground.surface_y(_next_golden_x) - 100.0), Vector2(16, 16), {"deadly": false, "golden": true, "frames": 8, "fps": 7.0})
		_next_golden_x += _rng.randf_range(2600.0, 4000.0) * _golden_mult()
	_next_chain_x = maxf(_next_chain_x, px + 500.0)

func _spawn_obstacle(x: float) -> void:
	var gy: float = ground.surface_y(x)
	var roll := _rng.randf()
	if roll < 0.4:
		_make_thing(TEX.puddle, Vector2(x, gy - 4), Vector2(28, 6), {"kind": "puddle"})
	elif roll < 0.7:
		_make_thing(TEX.dog, Vector2(x + 200.0, gy - 11), Vector2(26, 16), {"kind": "dog", "move_left": 80.0, "frames": 3, "fps": 10.0})
	else:
		_make_thing(TEX.cloud, Vector2(x, gy - 24), Vector2(28, 12), {"kind": "cloud", "frames": 3, "fps": 4.0})

func _spawn_donut_arc(x: float) -> void:
	var gy: float = ground.surface_y(x)
	var lift := 96.0 if _rng.randf() < 0.5 else 48.0
	for i in range(3):
		_make_donut(Vector2(x + i * 26.0, gy - lift - sin(i * PI / 2.0) * 22.0))

func _spawn_chains() -> void:
	var px := player.global_position.x
	_next_hazard_x = maxf(_next_hazard_x, px + 700.0)
	while _next_hazard_x < px + 1400.0:
		var gy: float = ground.surface_y(_next_hazard_x)
		_make_thing(TEX.cloud, Vector2(_next_hazard_x, gy - _rng.randf_range(90.0, 290.0)), Vector2(28, 12), {"kind": "cloud", "hits_flyer": true, "frames": 3, "fps": 4.0})
		_next_hazard_x += _rng.randf_range(420.0, 800.0)
	while _next_chain_x < px + 1400.0:
		var count := _rng.randi_range(8, 14)
		var wave := _rng.randf_range(20.0, 70.0)
		var lift: float = CHAIN_HEIGHT - _rng.randf_range(-130.0, 60.0)
		for i in range(count):
			var cx := _next_chain_x + i * 30.0
			_make_donut(Vector2(cx, ground.surface_y(cx) - lift + sin(i * 0.7) * wave))
		_next_chain_x += count * 30.0 + _rng.randf_range(120.0, 260.0)
	_next_spawn_x = maxf(_next_spawn_x, px + 1100.0)

func _spawn_sky_clouds(dense: bool) -> void:
	var px := player.global_position.x
	while _next_cloud_x < px + 1400.0:
		var gy: float = ground.surface_y(_next_cloud_x)
		var lift := _rng.randf_range(150.0, 330.0) if dense else _rng.randf_range(230.0, 340.0)
		var cloud := Sprite2D.new()
		cloud.texture = TEX.skycloud
		cloud.hframes = 6
		cloud.frame = _rng.randi_range(0, 5)
		cloud.position = Vector2(_next_cloud_x, gy - lift)
		cloud.z_index = -1
		cloud.scale = Vector2.ONE * _rng.randf_range(0.8, 1.4)
		cloud.set_script(DecoScript)
		cloud.set("drift", _rng.randf_range(6.0, 18.0))
		cloud.set("player", player)
		things.add_child(cloud)
		_next_cloud_x += _rng.randf_range(140.0, 260.0) if dense else _rng.randf_range(500.0, 900.0)

func _make_donut(pos: Vector2) -> void:
	_make_thing(TEX.donut, pos, Vector2(14, 14), {"deadly": false, "frames": 8, "fps": 5.0})

func _make_thing(tex: Texture2D, pos: Vector2, box: Vector2, props: Dictionary) -> void:
	var area := Area2D.new()
	area.position = pos
	area.set_script(ThingScript)
	for key in props:
		area.set(key, props[key])
	area.set("player", player)
	area.set("ground", ground)
	var sprite := Sprite2D.new()
	sprite.name = "Sprite2D"
	sprite.texture = tex
	sprite.hframes = int(props.get("frames", 1))
	area.add_child(sprite)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = box
	shape.shape = rect
	area.add_child(shape)
	things.add_child(area)
	if not bool(props.get("deadly", true)):
		area.connect("collected", _on_donut)

func _golden_mult() -> float:
	return float(Progress.current().get("golden_mult", 1.0))

func _on_donut(golden: bool) -> void:
	donuts += 1
	if golden:
		if player.start_flying():
			Progress.record_flight()
		Sfx.play_voice(Progress.selected, 1.1)
	else:
		Sfx.play("donut", randf_range(0.95, 1.1))

func _on_flight_changed(flying: bool) -> void:
	fly_row.visible = flying
	if flying:
		_cue = 0
		fly_time_label.modulate = Color.WHITE
		_zoom_to(FLY_ZOOM, 0.5)
		Music.play_track("fly", 0.4)
		return
	_zoom_to(PLAY_ZOOM, 0.8)
	_next_golden_x = maxf(_next_golden_x, player.global_position.x + _rng.randf_range(3800.0, 5200.0) * _golden_mult())
	if state == State.PLAYING:
		Sfx.play("drop")
		Music.play_track("main", 1.0)

func _zoom_to(value: float, seconds: float) -> void:
	create_tween().tween_property(camera, "zoom", Vector2.ONE * value, seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _update_hud() -> void:
	var distance := int((player.global_position.x - _start_x) / 10.0)
	score = maxi(0, distance) + donuts * int(Progress.current().get("donut_value", 10))
	score_label.text = str(score)
	donut_label.text = str(donuts)
	total_label.text = str(Progress.wallet + donuts)
	var best := Progress.best_for(Progress.selected)
	best_label.text = str(maxi(best, score if _record_broken else 0))
	if not _record_broken and best > 0 and score > best and state == State.PLAYING:
		_record_broken = true
		_celebrate()
	if player.flying:
		_update_countdown()

func _update_countdown() -> void:
	var left: float = player.fly_time_left
	fly_time_label.text = "%.1f" % left
	if _cue >= COUNTDOWN_CUES.size() or left > float(COUNTDOWN_CUES[_cue][0]):
		return
	var sound: String = COUNTDOWN_CUES[_cue][1]
	_cue += 1
	Sfx.play(sound, 1.0 + _cue * 0.08)
	fly_time_label.modulate = Color(1, 0.55, 0.6) if sound == "burst" else Color(1, 0.8, 0.5)
	fly_time_label.pivot_offset = fly_time_label.size * 0.5
	fly_time_label.scale = Vector2(1.4, 1.4)
	create_tween().tween_property(fly_time_label, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_player_died(cause: String) -> void:
	state = State.DEAD
	fly_row.hide()
	pause_button.hide()
	Music.stop(0.4)
	var previous_best := Progress.best_for(Progress.selected)
	Progress.finish_run(score, donuts)
	var record := previous_best > 0 and score > previous_best
	var lines: Array = DEATH_LINES.get(cause, DEATH_LINES["fall"])
	var headline: String = lines[_rng.randi() % lines.size()] % Progress.current()["name"]
	dead_label.text = "%s\n%s\nScore  %d\nBest   %d\n" % [headline, "New record!" if record else "", score, Progress.best_for(Progress.selected)]
	dead_donut_label.text = "+%d" % donuts
	dead_panel.show()
	if record:
		_celebrate()

func _friend_ids() -> Array:
	var ids := []
	for cat in Progress.CATS:
		if cat["id"] != Progress.selected and Progress.is_unlocked(cat["id"]):
			ids.append(cat["id"])
	return ids

func _perch(slot: int, count: int) -> Vector2:
	var radius := clampf(18.0 * count, 90.0, 126.0)
	var t := 0.5 if count == 1 else float(slot) / float(count - 1)
	var angle := lerpf(deg_to_rad(190.0), deg_to_rad(-10.0), t)
	return Vector2(cos(angle) * radius, -sin(angle) * radius * 0.42 - 14.0)

func _spawn_friends() -> void:
	var ids := _friend_ids()
	for slot in range(ids.size()):
		_add_friend(ids[slot], slot, player.global_position)

func _add_friend(id: String, slot: int, at: Vector2) -> Sprite2D:
	var friend := Sprite2D.new()
	friend.texture = load(Progress.texture_path(id))
	friend.hframes = 8
	friend.position = at
	friend.set_script(FriendScript)
	friend.set("cat_id", id)
	var orbit: Dictionary = PERSONALITY.get(id, PERSONALITY["meowicorn"]).duplicate()
	orbit["anchor"] = _perch(slot, _friend_ids().size())
	orbit["slot"] = slot
	orbit["phase"] = slot * 1.3
	friend.set("orbit", orbit)
	friend.set("center", Vector2(player.global_position.x, ground.surface_y(player.global_position.x) - 14.0))
	friend.connect("picked", _on_friend_picked)
	friends.add_child(friend)
	return friend

func _on_friend_picked(cat_id: String) -> void:
	if _swapping or state != State.MENU or _overlay_open():
		return
	var picked: Sprite2D
	for friend in friends.get_children():
		if friend.cat_id == cat_id:
			picked = friend
			break
	if picked == null:
		return
	_swapping = true
	var slot: int = picked.orbit["slot"]
	var previous := Progress.selected
	Progress.select(cat_id)
	Sfx.play_voice(cat_id)
	var outgoing := _add_friend(previous, slot, player.global_position)
	outgoing.move_to(picked.position, 0.7)
	player.sprite.visible = false
	await picked.move_to(player.global_position, 0.7)
	player.apply_cat(Progress.current())
	player.sprite.visible = true
	picked.queue_free()
	_swapping = false

func _toggle_pause() -> void:
	if state != State.PLAYING:
		return
	var pausing := not get_tree().paused
	get_tree().paused = pausing
	pause_panel.visible = pausing
	pause_button.visible = not pausing
	if not pausing:
		settings_panel.hide()
		help_panel.hide()

func _on_overlay_closed() -> void:
	if state == State.PLAYING and get_tree().paused:
		pause_panel.show()

func _toggle_settings() -> void:
	settings_panel.visible = not settings_panel.visible
	if state == State.PLAYING:
		pause_panel.visible = not settings_panel.visible

func _on_volume_changed(_value: float) -> void:
	Music.set_volume(music_slider.value)
	Sfx.set_volume(sfx_slider.value)
	Progress.set_volumes(music_slider.value, sfx_slider.value)

func _open_shop() -> void:
	if state != State.PLAYING:
		settings_panel.hide()
		shop_panel.show()

func _on_shop_closed() -> void:
	if Progress.selected != player.cat_id:
		get_tree().reload_current_scene()

func _open_help() -> void:
	if state == State.PLAYING and not get_tree().paused:
		return
	settings_panel.hide()
	pause_panel.hide()
	help_panel.show()

func _go_to_menu() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _snore(delta: float) -> void:
	_snore_timer -= delta
	if _snore_timer > 0.0 or _swapping:
		return
	_snore_timer = 1.4
	var z := Label.new()
	z.text = "z"
	z.scale = Vector2(0.5, 0.5)
	z.add_theme_color_override("font_color", Color(0.45, 0.25, 0.6, 0.9))
	z.position = player.global_position + Vector2(12, -16)
	z.z_index = 3
	things.add_child(z)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(z, "position", z.position + Vector2(14, -20), 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(z, "scale", Vector2(0.8, 0.8), 1.6)
	tween.tween_property(z, "modulate:a", 0.0, 1.6).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(z.queue_free)

func _open_achievements() -> void:
	if state == State.PLAYING and not get_tree().paused:
		return
	settings_panel.hide()
	pause_panel.hide()
	achievements_panel.show()

func _build_toast() -> void:
	_toast = PanelContainer.new()
	_toast.add_theme_stylebox_override("panel", Ui.box(Color(1, 1, 1, 0.8), 8, 8))
	_toast.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_toast.offset_left = -130
	_toast.offset_right = 130
	_toast.offset_top = TOAST_HIDDEN.x
	_toast.offset_bottom = TOAST_HIDDEN.y
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_toast.add_child(row)
	row.add_child(Ui.icon(load("res://art/icon_trophy.png"), Vector2(24, 24)))
	_toast_label = Ui.label("", Ui.INK_DARK, 8, false)
	_toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_toast_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_toast_label)
	_toast.hide()
	$HUD.add_child(_toast)

func _on_achievement(id: String) -> void:
	_toasts.append(Progress.achievement(id)["name"])
	_next_toast()

func _next_toast() -> void:
	if _toast_busy or _toasts.is_empty():
		return
	_toast_busy = true
	_toast_label.text = "Achievement!  " + _toasts.pop_front()
	_toast.show()
	Sfx.play("achieve")
	var tween := create_tween()
	tween.tween_property(_toast, "offset_top", TOAST_SHOWN.x, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(_toast, "offset_bottom", TOAST_SHOWN.y, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(2.4)
	tween.tween_property(_toast, "offset_top", TOAST_HIDDEN.x, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(_toast, "offset_bottom", TOAST_HIDDEN.y, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tween.finished
	_toast.hide()
	_toast_busy = false
	_next_toast()

func _celebrate() -> void:
	Sfx.play("victory")
	_sprinkles()
	best_row.pivot_offset = best_row.size
	var pulse := create_tween()
	for i in range(3):
		pulse.tween_property(best_row, "scale", Vector2(1.25, 1.25), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		pulse.tween_property(best_row, "scale", Vector2.ONE, 0.16)

func _sprinkles() -> void:
	for side in [0.0, 1.0]:
		var p := CPUParticles2D.new()
		p.position = Vector2(640.0 * side, 60.0)
		p.amount = 26
		p.lifetime = 2.6
		p.one_shot = true
		p.explosiveness = 0.35
		p.direction = Vector2(1.0 if side == 0.0 else -1.0, -0.8)
		p.spread = 22.0
		p.initial_velocity_min = 140.0
		p.initial_velocity_max = 240.0
		p.gravity = Vector2(0, 260)
		p.scale_amount_min = 2.0
		p.scale_amount_max = 3.0
		p.angular_velocity_min = -200.0
		p.angular_velocity_max = 200.0
		var ramp := Gradient.new()
		ramp.set_color(0, Color(1, 0.6, 0.8))
		ramp.set_color(1, Color(0.6, 0.85, 1))
		ramp.add_point(0.33, Color(1, 0.9, 0.5))
		ramp.add_point(0.66, Color(0.7, 1, 0.8))
		p.color_initial_ramp = ramp
		p.emitting = true
		$HUD.add_child(p)
		get_tree().create_timer(3.5).timeout.connect(p.queue_free)
