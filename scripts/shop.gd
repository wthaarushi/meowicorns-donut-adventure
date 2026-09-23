extends Control

signal closed

const CARD_HOME := Vector2(170, 50)
const CARD_LEFT := Vector2(30, 50)
const STATS_HOME := Vector2(214, 44)
const STATS_HIDDEN := Vector2(300, 44)
const ARROWS_HOME := [Vector2(64, 96), Vector2(376, 96)]
const ARROWS_WIDE := [Vector2(-14, 96), Vector2(446, 100)]
const PORTRAIT_CENTER := 70.0
const NAME_SCALE_OPEN := 0.75
const INDENT_OPEN := 6.0
const SLIDE_TIME := 0.45

var index: int = 0

var _stats_open: bool = false
var _busy: bool = false
var _just_opened: bool = false
var _bob: float = 0.0
var _align: float = 0.0

var _card: Control
var _portrait: TextureRect
var _name_label: Label
var _status_row: HBoxContainer
var _status_label: Label
var _price_icon: TextureRect
var _best_label: Label
var _dots: HBoxContainer
var _wallet_label: Label
var _left_btn: Button
var _right_btn: Button
var _stats_panel: PanelContainer
var _tagline_label: Label
var _stats_label: Label
var _perk_label: Label
var _action_button: Button

func _ready() -> void:
	_build()
	visibility_changed.connect(_on_visibility_changed)

func _build() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_CENTER)
	root.offset_left = -240
	root.offset_right = 240
	root.offset_top = -160
	root.offset_bottom = 160
	add_child(root)

	var title := Ui.title("Shop")
	title.position = Vector2(0, 0)
	root.add_child(title)

	var wallet_row := HBoxContainer.new()
	wallet_row.position = Vector2(290, 6)
	wallet_row.size = Vector2(140, 20)
	wallet_row.alignment = BoxContainer.ALIGNMENT_END
	wallet_row.add_theme_constant_override("separation", 6)
	root.add_child(wallet_row)
	_wallet_label = Ui.label("0", Ui.GOLD)
	_wallet_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	wallet_row.add_child(_wallet_label)
	wallet_row.add_child(Ui.icon(load("res://art/icon_bag.png"), Vector2(20, 20)))

	Ui.close_button(root, Vector2(446, 0)).pressed.connect(hide)

	var stats_btn := Ui.cloud_button("icon_stats", 32.0)
	stats_btn.position = Vector2(446, 40)
	stats_btn.pressed.connect(_toggle_stats)
	root.add_child(stats_btn)
	var s_key := Ui.keycap("s")
	s_key.position = Vector2(418, 45)
	root.add_child(s_key)

	_left_btn = Ui.cloud_button("icon_left")
	_left_btn.position = ARROWS_HOME[0]
	_left_btn.pressed.connect(_move.bind(-1))
	root.add_child(_left_btn)
	_right_btn = Ui.cloud_button("icon_right")
	_right_btn.position = ARROWS_HOME[1]
	_right_btn.pressed.connect(_move.bind(1))
	root.add_child(_right_btn)

	_card = Control.new()
	_card.position = CARD_HOME
	_card.size = Vector2(140, 170)
	root.add_child(_card)
	_portrait = Ui.icon(null, Vector2(160, 100))
	_portrait.position = Vector2(-10, 0)
	_portrait.size = Vector2(160, 100)
	_card.add_child(_portrait)

	_name_label = Ui.label("", Ui.INK, 16, false)
	_name_label.position = Vector2(0, 106)
	_card.add_child(_name_label)
	_status_row = HBoxContainer.new()
	_status_row.position = Vector2(0, 130)
	_status_row.add_theme_constant_override("separation", 6)
	_card.add_child(_status_row)
	_status_label = Ui.label("", Ui.GOLD, 8, false)
	_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_status_row.add_child(_status_label)
	_price_icon = Ui.icon(Ui.atlas("res://art/donut.png", Rect2(0, 0, 16, 16)), Vector2(16, 16))
	_status_row.add_child(_price_icon)
	_best_label = Ui.label("", Color(0.6, 0.75, 1), 8, false)
	_best_label.position = Vector2(0, 150)
	_card.add_child(_best_label)

	_dots = HBoxContainer.new()
	_dots.position = Vector2(140, 246)
	_dots.size = Vector2(200, 10)
	_dots.alignment = BoxContainer.ALIGNMENT_CENTER
	_dots.add_theme_constant_override("separation", 6)
	root.add_child(_dots)
	for i in range(Progress.CATS.size()):
		var dot := TextureRect.new()
		dot.custom_minimum_size = Vector2(8, 8)
		dot.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		dot.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_dots.add_child(dot)

	var arrows := HBoxContainer.new()
	arrows.position = Vector2(190, 264)
	arrows.size = Vector2(100, 16)
	arrows.alignment = BoxContainer.ALIGNMENT_CENTER
	arrows.add_theme_constant_override("separation", 6)
	arrows.scale = Vector2(0.7, 0.7)
	arrows.pivot_offset = Vector2(50, 0)
	root.add_child(arrows)
	arrows.add_child(Ui.keycap("left"))
	arrows.add_child(Ui.keycap("right"))

	_action_button = Button.new()
	_action_button.focus_mode = Control.FOCUS_NONE
	_action_button.position = Vector2(170, 288)
	_action_button.size = Vector2(140, 24)
	_action_button.icon = load("res://art/key_space.png")
	_action_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_action_button.add_theme_color_override("font_color", Ui.INK)
	_action_button.add_theme_color_override("font_hover_color", Ui.PINK)
	_action_button.add_theme_color_override("font_disabled_color", Color(Ui.INK, 0.4))
	_action_button.add_theme_constant_override("h_separation", 8)
	for style in ["normal", "hover", "pressed", "disabled", "focus"]:
		_action_button.add_theme_stylebox_override(style, StyleBoxEmpty.new())
	_action_button.pressed.connect(_on_action)
	root.add_child(_action_button)

	_stats_panel = PanelContainer.new()
	_stats_panel.position = STATS_HIDDEN
	_stats_panel.size = Vector2(196, 0)
	_stats_panel.modulate.a = 0.0
	_stats_panel.visible = false
	_stats_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stats_panel.add_theme_stylebox_override("panel", Ui.box(Color(1, 1, 1, 0.15), 10, 10))
	root.add_child(_stats_panel)
	var stats_box := VBoxContainer.new()
	stats_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stats_box.custom_minimum_size = Vector2(176, 0)
	stats_box.add_theme_constant_override("separation", 8)
	_stats_panel.add_child(stats_box)
	_tagline_label = _wrapped_label(Ui.INK)
	stats_box.add_child(_tagline_label)
	_stats_label = Ui.label("", Ui.INK, 8, false)
	_stats_label.add_theme_constant_override("line_spacing", 5)
	stats_box.add_child(_stats_label)
	_perk_label = _wrapped_label(Ui.MINT)
	stats_box.add_child(_perk_label)

func _wrapped_label(color: Color) -> Label:
	var l := Ui.label("", color, 8, false)
	l.custom_minimum_size = Vector2(176, 0)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_constant_override("line_spacing", 3)
	return l

func _on_visibility_changed() -> void:
	if visible:
		_just_opened = true
		_busy = false
		index = Progress.index_of(Progress.selected)
		_set_stats(false, true)
		_card.position = CARD_HOME
		_card.modulate = Color.WHITE
		_refresh()
	else:
		closed.emit()

func _process(delta: float) -> void:
	if not visible:
		return
	_bob += delta * 3.0
	_portrait.position.y = sin(_bob) * 2.0
	_layout_info()
	if _just_opened:
		_just_opened = false
		return
	if Input.is_action_just_pressed("left"):
		_move(-1)
	elif Input.is_action_just_pressed("right"):
		_move(1)
	elif Input.is_action_just_pressed("jump"):
		_on_action()
	elif Input.is_action_just_pressed("duck"):
		_toggle_stats()
	elif Input.is_action_just_pressed("settings") or Input.is_action_just_pressed("shop"):
		hide()

func _move(dir: int) -> void:
	if _busy:
		return
	_busy = true
	index = wrapi(index + dir, 0, Progress.CATS.size())
	Sfx.play("duck", 1.3)
	var home := CARD_LEFT if _stats_open else CARD_HOME
	var out := create_tween().set_parallel(true)
	out.tween_property(_card, "position:x", home.x - dir * 40.0, 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	out.tween_property(_card, "modulate:a", 0.0, 0.14)
	await out.finished
	_refresh()
	_card.position.x = home.x + dir * 40.0
	var back := create_tween().set_parallel(true)
	back.tween_property(_card, "position:x", home.x, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	back.tween_property(_card, "modulate:a", 1.0, 0.16)
	await back.finished
	_busy = false

func _layout_info() -> void:
	_name_label.scale = Vector2.ONE * lerpf(1.0, NAME_SCALE_OPEN, _align)
	for label in [_name_label, _status_row, _best_label]:
		var width: float = label.get_combined_minimum_size().x * label.scale.x
		label.position.x = lerpf(PORTRAIT_CENTER - width * 0.5, INDENT_OPEN, _align)

func _toggle_stats() -> void:
	_set_stats(not _stats_open, false)

func _set_stats(open: bool, instant: bool) -> void:
	_stats_open = open
	var card_target := CARD_LEFT if open else CARD_HOME
	var panel_target := STATS_HOME if open else STATS_HIDDEN
	var arrows: Array = ARROWS_WIDE if open else ARROWS_HOME
	_stats_panel.visible = true
	_stats_panel.reset_size()
	if instant:
		_align = 1.0 if open else 0.0
		_card.position = card_target
		_stats_panel.position = panel_target
		_stats_panel.modulate.a = 1.0 if open else 0.0
		_stats_panel.visible = open
		_left_btn.position = arrows[0]
		_right_btn.position = arrows[1]
		return
	Sfx.play("jump", 1.5 if open else 1.2)
	var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	for pair in [[_left_btn, arrows[0]], [_right_btn, arrows[1]], [_card, card_target], [_stats_panel, panel_target]]:
		tween.tween_property(pair[0], "position", pair[1], SLIDE_TIME)
	tween.tween_property(self, "_align", 1.0 if open else 0.0, SLIDE_TIME)
	tween.tween_property(_stats_panel, "modulate:a", 1.0 if open else 0.0, SLIDE_TIME * 0.7)
	if not open:
		tween.chain().tween_callback(func(): _stats_panel.visible = false)

func _on_action() -> void:
	var id: String = Progress.CATS[index]["id"]
	if Progress.is_unlocked(id):
		Progress.select(id)
		Sfx.play_voice(id)
	elif Progress.buy(id):
		Sfx.play("power")
		Sfx.play_voice(id)
		var pop := create_tween()
		pop.tween_property(_portrait, "scale", Vector2(1.15, 1.15), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		pop.tween_property(_portrait, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		Sfx.play("die", 1.6)
		var shake := create_tween()
		var x := _card.position.x
		for i in range(3):
			shake.tween_property(_card, "position:x", x + 4.0, 0.04)
			shake.tween_property(_card, "position:x", x - 4.0, 0.04)
		shake.tween_property(_card, "position:x", x, 0.04)
	_refresh()

func _pips(value: int) -> String:
	return "*".repeat(value) + "-".repeat(5 - value)

func _refresh() -> void:
	var cat: Dictionary = Progress.CATS[index]
	var id: String = cat["id"]
	var owned := Progress.is_unlocked(id)
	var equipped := Progress.selected == id
	_wallet_label.text = str(Progress.wallet)
	_portrait.texture = Ui.portrait(id)
	_portrait.modulate = Color.WHITE if owned else Color(0.55, 0.5, 0.6)
	_name_label.text = cat["name"]
	_price_icon.visible = not owned
	if equipped:
		_status_label.text = "Equipped"
		_status_label.add_theme_color_override("font_color", Ui.MINT)
	elif owned:
		_status_label.text = "Owned"
		_status_label.add_theme_color_override("font_color", Ui.INK)
	else:
		_status_label.text = "Not owned   %d" % int(cat["price"])
		_status_label.add_theme_color_override("font_color", Ui.GOLD)
	_best_label.text = ("Best run  %d" % Progress.best_for(id)) if owned else "Locked"
	for i in range(_dots.get_child_count()):
		_dots.get_child(i).texture = load("res://art/dot_full.png" if i == index else "res://art/dot_empty.png")
	_tagline_label.text = cat["tagline"]
	var lines := PackedStringArray()
	for key in ["Speed", "Jump", "Flight", "Health", "Luck", "Appetite"]:
		lines.append("%-9s %s" % [key, _pips(int(cat["stats"].get(key, 3)))])
	_stats_label.text = "\n".join(lines)
	_perk_label.text = "Perk: " + cat["perk"]
	if owned:
		_action_button.text = "Equipped" if equipped else "Equip"
		_action_button.disabled = equipped
	else:
		_action_button.text = "Buy" if Progress.can_afford(id) else "Not enough donuts"
		_action_button.disabled = not Progress.can_afford(id)
